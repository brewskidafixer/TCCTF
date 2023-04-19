
void onInit(CBlob@ this)
{
	f32 acceleration = 1.00f + (0.01f * XORRandom(400));
	
	this.set_f32("gyromat_value", acceleration);
	this.set_u8("gyromat_count", 1);
	
	this.setInventoryName("Accelerated Gyromat\n+" + Maths::Round(this.get_f32("gyromat_value") * 100.00f) + "% speed");
	this.set_f32("pickup_priority", 0.03f);
	
	{
		Animation@ animation = this.getSprite().getAnimation("default");
		if (animation !is null)
		{
			animation.time = v_fastrender ? 0.0f : (6.00f / acceleration);
		}
	}

	this.addCommandID("upgrade");
}

void GetButtonsFor(CBlob@ this, CBlob@ caller)
{
	if (this.isOverlapping(caller))
	{
		CBlob@ carried = caller.getCarriedBlob();

		if (carried != null && carried.getName() == "gyromat")
		{
			CBitStream params;
			params.write_u16(caller.getNetworkID());
			CButton@ button = caller.CreateGenericButton(23, Vec2f(0, -6), this, this.getCommandID("upgrade"), "Combine Gyromats", params);
		}
	}
}

void onCommand(CBlob@ this, u8 cmd, CBitStream @params) //Mutate command
{
	if (cmd == this.getCommandID("upgrade"))
	{
		CBlob@ caller = getBlobByNetworkID(params.read_u16());
		if (caller !is null)
		{
			CBlob@ carried = caller.getCarriedBlob();
			if (carried !is null && carried.getName() == "gyromat")
			{
				u8 gyrocount = carried.get_u8("gyromat_count") + this.get_u8("gyromat_count");
				if (gyrocount <= 4)
				{
					this.add_f32("gyromat_value", carried.get_f32("gyromat_value"));
					this.add_u8("gyromat_count", carried.get_u8("gyromat_count"));
					
					this.setInventoryName("Accelerated Gyromat\n+" + Maths::Round(this.get_f32("gyromat_value") * 100.00f) + "% speed");
					carried.server_Die();
				}
				else if (caller.isMyPlayer()) client_AddToChat("Cannot combine! Max number of combinations is 4!", SColor(0xff444444));
			}
		}
	}
}