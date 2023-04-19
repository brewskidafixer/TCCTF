#include "Explosion.as";
#include "GunCommon.as";
#include "VehicleFuel.as";

const Vec2f arm_offset = Vec2f(-4, 10);
const Vec2f gun_clampAngle = Vec2f(-10, 90);
const u16 maxAmmo = 500;

void onInit(CBlob@ this)
{
	this.Tag("aerial");
	this.Tag("heavy weight");
	
	this.set_u16("controller_blob_netid", 0);
	this.set_u16("controller_player_netid", 0);
	
	this.addCommandID("offblast");
	
	this.getShape().SetRotationsAllowed(true);
	this.getCurrentScript().tickFrequency = 0;

	GunSettings settings = GunSettings();

	settings.B_GRAV = Vec2f(0, 0.008); //Bullet Gravity
	settings.B_TTL = 14; //Bullet Time to live
	settings.B_SPEED = 60; //Bullet speed
	settings.B_DAMAGE = 1.5f; //Bullet damage
	settings.MUZZLE_OFFSET = Vec2f(-2,13);
	settings.G_RECOIL = 0;

	this.set("gun_settings", @settings);
	this.set_f32("CustomShootVolume", 1.0f);
	this.set_u16("ammoCount", 0);

	this.set_f32("max_fuel", 1000);
	this.set_f32("fuel_consumption_modifier", 0.20f);
	this.get_u32("fireDelayGun");

	this.SetLightRadius(16.0f);
	this.SetLightColor(SColor(255, 255, 0, 0));

	this.addCommandID("addAmmo");
	this.addCommandID("takeAmmo");
	this.addCommandID("shoot");
	this.addCommandID("load_fuel");
}

void onInit(CSprite@ this)
{
	this.SetZ(20);

	// Add arm
	CSpriteLayer@ mini = this.addSpriteLayer("arm", "MachineGun_Top.png", 32, 8);
	if (mini !is null)
	{
		mini.SetOffset(arm_offset);
		mini.SetRelativeZ(-50.0f);
		mini.SetVisible(true);
	}

	// Add muzzle flash
	CSpriteLayer@ flash = this.addSpriteLayer("muzzle_flash", "MuzzleFlash.png", 16, 8);
	if (flash !is null)
	{
		GunSettings@ settings;
		this.getBlob().get("gun_settings", @settings);

		Animation@ anim = flash.addAnimation("default", 1, false);
		int[] frames = {0, 1, 2, 3, 4, 5, 6, 7};
		anim.AddFrames(frames);
		flash.SetRelativeZ(1.0f);
		flash.SetOffset(Vec2f(arm_offset) + Vec2f(-20.5f, -1));
		flash.SetVisible(false);
		// flash.setRenderStyle(RenderStyle::additive);
	}

	this.SetEmitSound("Helichopper_Loop.ogg");
	this.SetEmitSoundSpeed(1.50f);
	this.SetEmitSoundVolume(0.60f);
	this.SetEmitSoundPaused(true);
}

s32 getHeight(CBlob@ this)
{
	CMap@ map = getMap();
	Vec2f pos = this.getPosition();

	Vec2f point;
	if (map.rayCastSolidNoBlobs(pos, pos + Vec2f(0, 1000), point))
	{
		return Maths::Max((point.y - pos.y - 8) / 8.00f, 0);
	}
	else return map.tilemapheight + 50- pos.y / 8;
}

bool doesCollideWithBlob(CBlob@ this, CBlob@ blob)
{
    return this.getTeamNum() != blob.getTeamNum();
}

void onTick(CBlob@ this)
{
	const f32 fuel = GetFuel(this);
	if (fuel > 0)
	{
		const bool left = this.isKeyPressed(key_left);
		const bool right = this.isKeyPressed(key_right);
		const bool up = this.isKeyPressed(key_up);
		const bool down = this.isKeyPressed(key_down);

		f32 h = (left ? -1 : 0) + (right ? 1 : 0); 
		f32 v = (up ? -1 : 0) + (down ? 1 : 0); 
		
		Vec2f vel = Vec2f(h, v);
		Vec2f gravity = Vec2f(0, -sv_gravity * this.getMass() / 25.00f);
		Vec2f force = (vel * this.getMass() * 0.35f);
		
		this.getSprite().SetEmitSoundSpeed(Maths::Min(0.0001f + Maths::Abs(force.getLength() * 1.50f), 1.10f));

		this.AddForce(force + gravity);
		this.setAngleDegrees((this.getVelocity().x * 2.00f) + (this.isFacingLeft() ? -5 : 5));

		if (this.getTickSinceCreated() % 5 == 0)
		{
			f32 taken = this.get_f32("fuel_consumption_modifier") * (this.getVelocity().getLength() + getHeight(this)/2);
			TakeFuel(this, taken);
		}
	}
	
	CSprite@ sprite = this.getSprite();

	CSpriteLayer@ minigun = sprite.getSpriteLayer("arm");
	if (minigun !is null)
	{
		Vec2f pos = this.getPosition();
		Vec2f aimPos = this.getAimPos();
		const bool flip = this.isFacingLeft();
		
		this.SetFacingLeft((aimPos - pos).x <= 0);

		if (this.get_bool("lastTurn") != flip)
		{
			this.set_bool("lastTurn", flip);
			minigun.ResetTransform();
		}

		Vec2f aimvector = aimPos - minigun.getWorldTranslation();
		aimvector.RotateBy(-this.getAngleDegrees());

		const f32 flip_factor = flip ? -1: 1;
		const f32 angle = constrainAngle(-aimvector.Angle() + (flip ? 180 : 0)) * flip_factor;
		const f32 clampedAngle = (Maths::Clamp(angle, gun_clampAngle.x, gun_clampAngle.y) * flip_factor);

		this.set_f32("gunAngle", clampedAngle);

		minigun.ResetTransform();
		minigun.RotateBy(clampedAngle, Vec2f(5 * flip_factor, 1));

		CSpriteLayer@ flash = sprite.getSpriteLayer("muzzle_flash");
		if (flash !is null)
		{
			GunSettings@ settings;
			this.get("gun_settings", @settings);

			flash.ResetTransform();
			flash.SetRelativeZ(1.0f);
			flash.RotateBy(clampedAngle, Vec2f(25 * flip_factor, 1.5f));
		}

		if (this.isKeyPressed(key_action1))
		{
			if (isClient() && this.isMyPlayer())
			{
				if (getGameTime() > this.get_u32("fireDelayGun"))
				{
					CBitStream params;
					params.write_s32(this.get_f32("gunAngle"));
					params.write_Vec2f(minigun.getWorldTranslation());
					this.SendCommand(this.getCommandID("shoot"), params);
					this.set_u32("fireDelayGun", getGameTime() + 3);
				}
			}
		}
		else if (this.isKeyJustPressed(key_action2))
		{
			ResetPlayer(this);
			return;
		}
		if (this.isKeyJustPressed(key_action3) || this.getHealth() <= 0.0f)
		{
			ResetPlayer(this);
			if (isServer())
			{
				this.server_Die();
			}
			return;
		}
	}
}

f32 constrainAngle(f32 x)
{
	x = (x + 180) % 360;
	if (x < 0) x += 360;
	return x - 180;
}

void ResetPlayer(CBlob@ this)
{
	this.Untag("projectile");
	this.SetLight(false);
	this.getSprite().SetEmitSoundPaused(true);
	this.getCurrentScript().tickFrequency = 0;

	CPlayer@ ply = getPlayerByNetworkId(this.get_u16("controller_player_netid"));
	CBlob@ blob = getBlobByNetworkID(this.get_u16("controller_blob_netid"));
	if (blob !is null && ply !is null && !blob.hasTag("dead"))
	{
		this.set_bool("offblast", false);
		this.set_u16("controller_blob_netid", 0);
		this.set_u16("controller_player_netid", 0);

		if (isServer()) blob.server_SetPlayer(ply);
	}
	else if (isServer()) this.server_Die();
}

void onDie(CBlob@ this)
{
	if (isServer())
	{
		this.set_f32("map_damage_radius", 48.0f);
		this.set_f32("map_damage_ratio", 0.4f);
		f32 angle = this.get_f32("bomb angle");
		Explode(this, 50.0f, 20.0f);
		
		for (int i = 0; i < 4; i++) 
		{
			Vec2f dir = getRandomVelocity(angle, 1, 40);
			LinearExplosion(this, dir, 40.0f + XORRandom(64), 48.0f, 6, 1.0f, Hitters::explosion);
		}

		Vec2f pos = this.getPosition() + this.get_Vec2f("explosion_offset").RotateBy(this.getAngleDegrees());
		CMap@ map = getMap();

		if (isServer())
		{
			for (int i = 0; i < 5; i++)
			{
				CBlob@ blob = server_CreateBlob("flame", -1, this.getPosition());
				blob.setVelocity(Vec2f(XORRandom(10) - 5, -XORRandom(10)));
				blob.server_SetTimeToDie(5 + XORRandom(5));
			}
		}

		this.getSprite().Gib();
	}
}

void GetButtonsFor(CBlob@ this, CBlob@ caller)
{
	if (this.getDistanceTo(caller) <= 48)
	{
		if (caller.getName() == "uav") return;

		if (caller.getTeamNum() == this.getTeamNum())
		{
			const u16 ammoCount = this.get_u16("ammoCount");
			if (ammoCount < maxAmmo)
			{
				CBitStream params;
				params.write_u16(caller.getNetworkID());
				caller.CreateGenericButton("$icon_gatlingammo$", Vec2f(-8, 0), this, 
					this.getCommandID("addAmmo"), getTranslatedString("Insert Gatling Gun Ammo"), params);
			}
			{
				CBitStream params;
				CBlob@ carried = caller.getCarriedBlob();
				if (carried !is null && this.get_f32("fuel_count") < this.get_f32("max_fuel"))
				{
					string fuel_name = carried.getName();
					bool isValid = fuel_name == "mat_fuel";

					if (isValid)
					{
						params.write_netid(caller.getNetworkID());
						CButton@ button = caller.CreateGenericButton("$" + fuel_name + "$", Vec2f(8, 0), this, this.getCommandID("load_fuel"), "Load " + carried.getInventoryName() + "\n(" + this.get_f32("fuel_count") + " / " + this.get_f32("max_fuel") + ")", params);
					}
				}
			}
			if (!this.get_bool("offblast"))
			{
				CPlayer@ ply = caller.getPlayer();
				if (ply !is null)
				{
					CBitStream params;
					params.write_u16(ply.getNetworkID());
					params.write_u16(caller.getNetworkID());
					
					caller.CreateGenericButton(11, Vec2f(0, -8), this, this.getCommandID("offblast"), "Control UAV", params);
				}
			}
		}
	}
}

void onCommand(CBlob@ this, u8 cmd, CBitStream@ params)
{
	if (cmd == this.getCommandID("shoot"))
	{
		if (this.get_u16("ammoCount") > 0)
		{
			this.sub_u16("ammoCount", 1);
			this.Sync("ammoCount", true);
			f32 angle = params.read_s32();
			ShootGun(this, angle, params.read_Vec2f());
		}
	}
	else if (cmd == this.getCommandID("load_fuel"))
	{
		CBlob@ caller = getBlobByNetworkID(params.read_netid());
		if (caller !is null)
		{
			CBlob@ carried = caller.getCarriedBlob();

			if (carried !is null)
			{
				string fuel_name = carried.getName();
				f32 fuel_modifier = 1.00f;
				bool isValid = false;

				fuel_modifier = GetFuelModifier(fuel_name, isValid, 2);

				if (isValid)
				{
					u16 remain = GiveFuel(this, carried.getQuantity(), fuel_modifier);

					if (remain == 0)
					{
						carried.Tag("dead");
						carried.server_Die();
					}
					else
					{
						carried.server_SetQuantity(remain);
					}
				}
			}
		}
	}
	else if (cmd == this.getCommandID("addAmmo"))
	{

		//mat_gatlingammo
		u16 blobNum = 0;
		if (!params.saferead_u16(blobNum))
		{
			warn("addAmmo");
			return;
		}
		CBlob@ blob = getBlobByNetworkID(blobNum);
		if (blob is null) return;

		CInventory@ invo = blob.getInventory();
		if (invo !is null)
		{
			u16 ammoCount = invo.getCount("mat_gatlingammo");
			ammoCount = Maths::Min(ammoCount, maxAmmo - this.get_u16("ammoCount"));
			if (ammoCount > 0)
			{
				this.Sync("ammoCount", true);
				this.add_u16("ammoCount", ammoCount);
				this.Sync("ammoCount", true);
				invo.server_RemoveItems("mat_gatlingammo", ammoCount);
			}
		}

		CBlob@ attachedBlob = blob.getAttachments().getAttachmentPointByName("PICKUP").getOccupied();
		if (attachedBlob !is null && attachedBlob.getName() == "mat_gatlingammo")
		{
			const u16 ammoCount = Maths::Min(attachedBlob.getQuantity(), maxAmmo - this.get_u16("ammoCount"));
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
			const u16 ammoCount = Maths::Min(this.get_u16("ammoCount"), 500);
			if (ammoCount > 0)
			{
				this.sub_u16("ammoCount", ammoCount);
				if (isServer())
				{
					CBlob@ ammo = server_CreateBlob("mat_gatlingammo", -1, caller.getPosition());
					ammo.server_SetQuantity(ammoCount);
					caller.server_PutInInventory(ammo);
				}
			}
		}
	}
	else if (cmd == this.getCommandID("offblast"))
	{
		const u16 player_netid = params.read_u16();
		const u16 caller_netid = params.read_u16();

		CPlayer@ ply = getPlayerByNetworkId(player_netid);
		CBlob@ caller = getBlobByNetworkID(caller_netid);
		if (ply !is null && caller !is null)
		{
			if (isServer()) this.server_SetPlayer(ply);
			this.set_u16("controller_player_netid", player_netid);
			this.set_u16("controller_blob_netid", caller_netid);
			this.Tag("projectile");
			this.set_bool("offblast", true);
			
			this.set_u32("no_explosion_timer", getGameTime() + 30);
			
			CSprite@ sprite = this.getSprite();
			sprite.SetEmitSoundPaused(false);
			
			this.SetLight(true);
			this.SetLightRadius(128.0f);
			this.SetLightColor(SColor(255, 255, 100, 0));
			
			this.getCurrentScript().tickFrequency = 1;
		}
	}
}

void ShootGun(CBlob@ this, f32 angle, Vec2f gunPos)
{
	if (isServer())
	{
		f32 sign = (this.isFacingLeft() ? -1 : 1);
		angle += ((XORRandom(400) - 100) / 100.0f);
		angle += this.getAngleDegrees();

		GunSettings@ settings;
		this.get("gun_settings", @settings);

		Vec2f fromBarrel = Vec2f((settings.MUZZLE_OFFSET.x + 0) * -sign, settings.MUZZLE_OFFSET.y);
		fromBarrel.RotateBy(this.getAngleDegrees());
		shootGun(this.getNetworkID(), angle, this.getNetworkID(), this.getPosition() + fromBarrel);
	}

	if (isClient())
	{
		CSpriteLayer@ flash = this.getSprite().getSpriteLayer("muzzle_flash");
		if (flash !is null)
		{
			//Turn on muzzle flash
			flash.SetFrameIndex(0);
			flash.SetVisible(true);
		}
		this.getSprite().PlaySound("Helichopper_Shoot.ogg", 1.00f);
	}

	this.set_u32("fireDelayGunSprite", getGameTime() + 4);
}

void shootGun(const u16 gunID, const f32 aimangle, const u16 hoomanID, const Vec2f pos) 
{
	CRules@ rules = getRules();
	CBitStream params;

	params.write_netid(hoomanID);
	params.write_netid(gunID);
	params.write_f32(aimangle);
	params.write_Vec2f(pos);
	params.write_u32(getGameTime());

	rules.SendCommand(rules.getCommandID("fireGun"), params);
}

void onRender(CSprite@ this)
{
	if (this is null) return; //can happen with bad reload

	// draw only for local player
	CBlob@ blob = this.getBlob();
	CBlob@ localBlob = getLocalPlayerBlob();

	if (blob is null)
	{
		return;
	}

	if (localBlob is null)
	{
		return;
	}

	if (localBlob is blob)
	{
		drawFuelCount(blob);
		renderAmmo(blob);
	}

	Vec2f mouseWorld = getControls().getMouseWorldPos();
	bool mouseOnBlob = (mouseWorld - blob.getPosition()).getLength() < this.getBlob().getRadius();
	f32 fuel = blob.get_f32("fuel_count");
	if (fuel <= 0 && (mouseOnBlob || blob is localBlob))
	{
		Vec2f pos = blob.getInterpolatedScreenPos();

		GUI::SetFont("menu");
		GUI::DrawTextCentered("Requires fuel!", Vec2f(pos.x, pos.y + 100 + Maths::Sin(getGameTime() / 5.0f) * 5.0f), SColor(255, 255, 55, 55));
		GUI::DrawTextCentered("(Fuel)", Vec2f(pos.x, pos.y + 115 + Maths::Sin(getGameTime() / 5.0f) * 5.0f), SColor(255, 255, 55, 55));
	}
}

const f32 fuel_factor = 100.00f;

void renderAmmo(CBlob@ blob)
{
	Vec2f pos2d1 = blob.getInterpolatedScreenPos() - Vec2f(0, 10);

	Vec2f pos2d = blob.getInterpolatedScreenPos() - Vec2f(0, 60);
	Vec2f dim = Vec2f(20, 8);
	const f32 y = blob.getHeight() * 2.4f;
	f32 charge_percent = 1.0f;

	Vec2f ul = Vec2f(pos2d.x - dim.x, pos2d.y + y);
	Vec2f lr = Vec2f(pos2d.x - dim.x + charge_percent * 2.0f * dim.x, pos2d.y + y + dim.y);

	if (blob.isFacingLeft())
	{
		ul -= Vec2f(8, 0);
		lr -= Vec2f(8, 0);

		f32 max_dist = ul.x - lr.x;
		ul.x += max_dist + dim.x * 2.0f;
		lr.x += max_dist + dim.x * 2.0f;
	}

	f32 dist = lr.x - ul.x;
	Vec2f upperleft((ul.x + (dist / 2.0f)) - 5.0f + 4.0f, pos2d1.y + blob.getHeight() + 56);
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

void drawFuelCount(CBlob@ this)
{
	// draw ammo count
	Vec2f pos2d1 = this.getInterpolatedScreenPos() - Vec2f(0, 10);

	Vec2f pos2d = this.getInterpolatedScreenPos() - Vec2f(0, 60);
	Vec2f dim = Vec2f(20, 8);
	const f32 y = this.getHeight() * 2.4f;
	f32 charge_percent = 1.0f;

	Vec2f ul = Vec2f(pos2d.x - dim.x, pos2d.y + y);
	Vec2f lr = Vec2f(pos2d.x - dim.x + charge_percent * 2.0f * dim.x, pos2d.y + y + dim.y);

	if (this.isFacingLeft())
	{
		ul -= Vec2f(8, 0);
		lr -= Vec2f(8, 0);

		f32 max_dist = ul.x - lr.x;
		ul.x += max_dist + dim.x * 2.0f;
		lr.x += max_dist + dim.x * 2.0f;
	}

	f32 dist = lr.x - ul.x;
	Vec2f upperleft((ul.x + (dist / 2.0f) - 10) + 4.0f, pos2d1.y + this.getHeight() + 30);
	Vec2f lowerright((ul.x + (dist / 2.0f) + 10), upperleft.y + 20);

	//GUI::DrawRectangle(upperleft - Vec2f(0,20), lowerright , SColor(255,0,0,255));

	int fuel = this.get_f32("fuel_count");
	string reqsText = "Fuel: " + fuel + " / " + this.get_f32("max_fuel");

	u8 numDigits = reqsText.size() - 1;

	upperleft -= Vec2f((float(numDigits) * 4.0f), 0);
	lowerright += Vec2f((float(numDigits) * 4.0f), 18);

	// GUI::DrawRectangle(upperleft, lowerright);
	GUI::SetFont("menu");
	GUI::DrawTextCentered(reqsText, this.getInterpolatedScreenPos() + Vec2f(0, 48), color_white);
}

bool canBePutInInventory(CBlob@ this, CBlob@ inventoryBlob)
{
	return false;
}

bool canBePickedUp(CBlob@ this, CBlob@ byBlob)
{
	return false;
}