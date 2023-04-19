

// this.set_u16("ammoCount", 0);
// this.set_u16("this.get_u16("maxAmmo")", 0);
// this.set_string("this.get_string("ammoName")", "mat_gatlingammo");
// this.set_string("ammoInventoryName", "Gatling Gun Ammo");
// this.set_string("ammoIconName", "$icon_gatlingammo$");

void Turret_onInit(CBlob@ this)
{
	this.addCommandID("addAmmo");
	this.addCommandID("takeAmmo");
}

void Turret_AddButtons(CBlob@ this, CBlob@ caller)
{
	const u16 ammoCount = this.get_u16("ammoCount");
	const string ammoInventoryName = (this.exists("ammoInventoryName")) ? this.get_string("ammoInventoryName") : "Gatling Gun Ammo";
	if (ammoCount > 0)
	{
		CBitStream params;
		params.write_u16(caller.getNetworkID());
		caller.CreateGenericButton(20, Vec2f(0, 4), this, 
			this.getCommandID("takeAmmo"), getTranslatedString("Take "+ammoInventoryName), params);
	}
	if (ammoCount < this.get_u16("maxAmmo"))
	{
		const string ammoIconName = (this.exists("ammoIconName")) ? this.get_string("ammoIconName") : "$"+this.get_string("ammoName")+"$";

		CBitStream params;
		params.write_u16(caller.getNetworkID());
		caller.CreateGenericButton(ammoIconName, Vec2f(0, -3), this, 
			this.getCommandID("addAmmo"), getTranslatedString("Insert "+ammoInventoryName), params);
	}
}

void Turret_onCommand(CBlob@ this, u8 cmd, CBitStream @params)
{
	if (cmd == this.getCommandID("addAmmo"))
	{
		//mat_gatlingammo
		u16 blobNum = 0;
		if (!params.saferead_u16(blobNum))
		{
			warn("Failed safread addAmmo for "+this.getName());
			return;
		}
		CBlob@ blob = getBlobByNetworkID(blobNum);
		if (blob is null) return;

		CInventory@ invo = blob.getInventory();
		if (invo !is null)
		{
			u16 ammoCount = invo.getCount(this.get_string("ammoName"));
			ammoCount = Maths::Min(ammoCount, this.get_u16("maxAmmo") - this.get_u16("ammoCount"));
			if (ammoCount > 0)
			{
				this.Sync("ammoCount", true);
				this.add_u16("ammoCount", ammoCount);
				this.Sync("ammoCount", true);
				invo.server_RemoveItems(this.get_string("ammoName"), ammoCount);
			}
		}

		CBlob@ attachedBlob = blob.getAttachments().getAttachmentPointByName("PICKUP").getOccupied();
		if (attachedBlob !is null && attachedBlob.getName() == this.get_string("ammoName"))
		{
			const u16 ammoCount = Maths::Min(attachedBlob.getQuantity(), this.get_u16("maxAmmo") - this.get_u16("ammoCount"));
			const u16 leftOver = attachedBlob.getQuantity() - ammoCount;
			this.add_u16("ammoCount", ammoCount);
			if (leftOver <= 0) attachedBlob.server_Die();
			else attachedBlob.server_SetQuantity(leftOver);
		}
	}
	else if (cmd == this.getCommandID("takeAmmo"))
	{
		CBlob@ caller = getBlobByNetworkID(params.read_u16());
		if (caller !is null)
		{
			const u16 ammoCount = Maths::Min(this.get_u16("ammoCount"), this.get_u16("maxAmmo")/5);
			if (ammoCount > 0)
			{
				this.sub_u16("ammoCount", ammoCount);
				if (isServer())
				{
					CBlob@ ammo = server_CreateBlob(this.get_string("ammoName"), -1, caller.getPosition());
					ammo.server_SetQuantity(ammoCount);
					caller.server_PutInInventory(ammo);
				}
			}
		}
	}
}

void onRender(CSprite@ this)
{
	if (v_fastrender) return;
	CBlob@ blob = this.getBlob();
	CBlob@ localBlob = getLocalPlayerBlob();
	if (blob is null) return;
	if (localBlob is null) return;
	if (localBlob.isMyPlayer())
	{
		Vec2f mouseWorld = getControls().getMouseWorldPos();
		bool mouseOnBlob = (mouseWorld - blob.getPosition()).getLength() < this.getBlob().getRadius();
		if (mouseOnBlob)
		{
			renderAmmo(blob);
		}
	}
}

void renderAmmo(CBlob@ blob)
{
	Vec2f pos2d1 = blob.getInterpolatedScreenPos() - Vec2f(0, 10);

	Vec2f pos2d = blob.getInterpolatedScreenPos() - Vec2f(0, 60);
	Vec2f dim = Vec2f(20, 8);
	const f32 y = blob.getHeight() * 2.4f;

	Vec2f ul = Vec2f(pos2d.x - dim.x, pos2d.y + y);
	Vec2f lr = Vec2f(pos2d.x - dim.x + 2.0f * dim.x, pos2d.y + y + dim.y);

	if (blob.isFacingLeft())
	{
		ul -= Vec2f(8, 0);
		lr -= Vec2f(8, 0);

		f32 max_dist = ul.x - lr.x;
		ul.x += max_dist + dim.x * 2.0f;
		lr.x += max_dist + dim.x * 2.0f;
	}

	f32 dist = lr.x - ul.x;
	Vec2f upperleft((ul.x + (dist / 2.0f)) - 5.0f + 4.0f, pos2d1.y + blob.getHeight() + 40);
	Vec2f lowerright((ul.x + (dist / 2.0f))  + 5.0f + 4.0f, upperleft.y + 20);

	//GUI::DrawRectangle(upperleft - Vec2f(0,20), lowerright , SColor(255,0,0,255));

	u16 ammo = blob.get_u16("ammoCount");

	string reqsText = "" + ammo;

	u8 numDigits = reqsText.size();

	upperleft -= Vec2f((float(numDigits) * 4.0f), 0);
	lowerright += Vec2f((float(numDigits) * 4.0f), 0);

	GUI::DrawRectangle(upperleft, lowerright);
	GUI::SetFont("menu");
	GUI::DrawText(reqsText, upperleft + Vec2f(2, 1), color_white);
}