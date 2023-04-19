#include "CargoAttachmentCommon.as"

void onInit(CBlob@ this)
{
	this.getSprite().SetZ(-10.0f);
	
	this.inventoryButtonPos = Vec2f(-22, 0);
	this.set_Vec2f("store_offset", Vec2f(4, 0));
	this.set_u16("capacity", 75);
	this.Tag("smart_storage");
}

void onCollision(CBlob@ this, CBlob@ blob, bool solid)
{
	if (blob !is null)
	{
		TryToAttachCargo(this, blob);
	}
}

bool canBePickedUp(CBlob@ this, CBlob@ byBlob)
{
	return false;
}

bool isInventoryAccessible(CBlob@ this, CBlob@ forBlob)
{
	return forBlob !is null && (this.getTeamNum() == forBlob.getTeamNum() && this.getDistanceTo(forBlob) <= 48);	
}

void GetButtonsFor( CBlob@ this, CBlob@ caller )
{
	if (caller !is null)
	{
		if (this.getTeamNum() == caller.getTeamNum() && this.getDistanceTo(caller) <= 48)
		{
			CInventory @inv = caller.getInventory();
			if (inv !is null)
			{
				if (inv.getItemsCount() > 0)
				{
					CBitStream params;
					params.write_u16(caller.getNetworkID());
					caller.CreateGenericButton(28, Vec2f(8, 0), this, this.getCommandID("sv_store"), "Store", params);
				}
			}
		}
	}
}

void onAttach(CBlob@ this, CBlob@ attached, AttachmentPoint @attachedPoint)
{
	if (attached.hasTag("player"))
		attached.Tag("invincible");
}

void onDetach(CBlob@ this, CBlob@ detached, AttachmentPoint@ attachedPoint)
{
	if (detached.hasTag("player"))
		detached.Untag("invincible");
}