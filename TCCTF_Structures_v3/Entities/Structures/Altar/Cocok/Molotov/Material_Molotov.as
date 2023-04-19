#include "ParticleSparks.as";

void onInit(CBlob@ this)
{
	this.Tag("explosive");
	this.maxQuantity = 100;
}

void onCommand(CBlob@ this, u8 cmd, CBitStream @params)
{
    if (cmd == this.getCommandID("activate"))
    {
		if (isClient())
		{
			this.getSprite().PlaySound("Lighter_Use", 1.00f, 0.90f + (XORRandom(100) * 0.30f));
			sparks(this.getPosition(), 1, 0.25f);
		}
		
        if(isServer())
        {
    		AttachmentPoint@ point = this.getAttachments().getAttachmentPointByName("PICKUP");
            if (point !is null)
			{
				CBlob@ holder = point.getOccupied();
				if(holder !is null)
				{
					CBlob@ blob = server_CreateBlob("molotov", this.getTeamNum(), this.getPosition());
					holder.server_Pickup(blob);
					int8 remain = this.getQuantity() - 1;
					if (remain > 0)
					{
						this.server_SetQuantity(remain);
						holder.server_PutInInventory(this);
						this.Untag("activated");
					}
					else
					{
						this.Tag("dead");
						this.server_Die();
					}
				}
			}
        }
    }
}
