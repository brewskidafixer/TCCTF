// A script by TFlippy & Pirate-Rob

#include "Requirements.as";
#include "ShopCommon.as";
#include "Descriptions.as";
#include "CheckSpam.as";
#include "CTFShopCommon.as";
#include "MakeMat.as";
#include "BuilderHittable.as";
#include "Hitters.as";

const string[] resources = 
{
	"mat_iron",
	"mat_copper",
	"mat_stone",
	"mat_gold",
	"mat_coal",
	"mat_dirt"
};

const u8[] resourceYields = 
{
	3,
	3,
	7,
	1,
	1,
	4
};

void onInit(CBlob@ this)
{
	this.set_u8("drill_count", 3);
	this.getSprite().SetZ(-50); //background
	this.getShape().getConsts().mapCollisions = false;

	this.Tag("builder always hit");
	
	this.getCurrentScript().tickFrequency = 60;
	
	this.set_bool("isActive", false);
	this.set_u8("bedrock_count", 0);
	this.set_bool("bedrock_drillrig", false);
	this.set_f32("gyro_bonus", 1.0f);
	this.addCommandID("sv_toggle");
	this.addCommandID("cl_toggle");
	CBlob@[] blobs;
	if (getMap().getBlobsAtPosition(this.getPosition(), @blobs))
	{
		for (u8 i = 0; i < blobs.length; i++)
		{
			if (blobs[i].getName() == "powerdrillrig" && blobs[i] !is this)
			{
				this.Tag("temp");
				if (blobs[i].hasTag("temp")) blobs[i].Untag("temp");
				else
				{
					blobs[i].add_u8("drill_count", this.get_u8("drill_count"));
					this.server_Die();
				}
			}
		}
	}
}

void onInit(CSprite@ this)
{
	this.SetEmitSound("Drill.ogg");
	this.SetEmitSoundVolume(0.1f);
	this.SetEmitSoundSpeed(0.5f);
	
	this.SetEmitSoundPaused(!this.getBlob().get_bool("isActive"));
}

void onTick(CBlob@ this)
{
	if (isServer())
	{
		if (!this.get_bool("isActive")) return;
		if (this.get_bool("bedrock_drillrig"))
		{
			u8 index = XORRandom(resources.length);
			MakeMat(this, this.getPosition(), resources[index], (1 + XORRandom(resourceYields[index]))*(this.get_f32("gyro_bonus")*2 + this.get_u8("drill_count")));
		}
		else
		{
			CMap@ map = getMap();
			
			for (u8 i = 0; i<this.get_u8("drill_count");i++)
			{
				f32 depth = XORRandom(48);
				Vec2f pos = Vec2f(this.getPosition().x + (XORRandom(32) - 16) * (1 - depth / 48), Maths::Min(this.getPosition().y + 16 + depth, (map.tilemapheight * map.tilesize) - 8));

				this.server_HitMap(pos, Vec2f(0, 0), 1.3f, Hitters::drill);
			}
		}
	}
}

void onHitMap(CBlob@ this, Vec2f worldPoint, Vec2f velocity, f32 damage, u8 customData)
{
	if (isServer())
	{
		TileType tile = getMap().getTile(worldPoint).type;
		
		if (tile == CMap::tile_bedrock)
		{
			u8 index = XORRandom(resources.length);
			MakeMat(this, this.getPosition(), resources[index], 1 + XORRandom(resourceYields[index])*this.get_f32("gyro_bonus"));

			this.add_u8("bedrock_count", 1);
			if (this.get_u8("bedrock_count") >= 9) this.set_bool("bedrock_drillrig", true);
		}
	}
}

void onDie(CBlob@ this)
{
	if (isServer() && !this.hasTag("temp"))
	{
		server_CreateBlob("powerdrill", this.getTeamNum(), this.getPosition());
	}
}

void onCommand(CBlob@ this, u8 cmd, CBitStream @params)
{
	if (isServer())
	{
		if (cmd == this.getCommandID("sv_toggle"))
		{
			bool active = params.read_bool();
			
			this.set_bool("isActive", active);
			if (!v_fastrender)
			{
				CBitStream stream;
				stream.write_bool(active);
				this.SendCommand(this.getCommandID("cl_toggle"), stream);
			}
		}
	}
	
	if (isClient())
	{
		if (cmd == this.getCommandID("cl_toggle"))
		{		
			bool active = params.read_bool();
		
			// print("cl: " + active);
		
			this.set_bool("isActive", active);
		
			CSprite@ sprite = this.getSprite();
		
			sprite.PlaySound("LeverToggle.ogg");
			sprite.SetEmitSoundPaused(!active);
			sprite.SetAnimation(active ? "active" : "inactive");
		}
	}
}

void GetButtonsFor(CBlob@ this, CBlob@ caller)
{
	if (!this.isOverlapping(caller)) return;
	
	CBitStream params;
	params.write_bool(!this.get_bool("isActive"));
	
	CButton@ buttonEject = caller.CreateGenericButton(11, Vec2f(0, -8), this, this.getCommandID("sv_toggle"), (this.get_bool("isActive") ? "Turn Off" : "Turn On"), params);
}

void onAddToInventory( CBlob@ this, CBlob@ blob )
{
	if(blob.getName() != "gyromat") return;

	this.set_f32("gyro_bonus", (this.exists("gyromat_acceleration") ? this.get_f32("gyromat_acceleration") : 1.0f));
}

void onRemoveFromInventory(CBlob@ this, CBlob@ blob)
{
	if(blob.getName() != "gyromat") return;
	
	this.set_f32("gyro_bonus", (this.exists("gyromat_acceleration") ? this.get_f32("gyromat_acceleration") : 1.0f));
}

bool isInventoryAccessible(CBlob@ this, CBlob@ forBlob)
{
	return (forBlob.getName() == "extractor" || forBlob.getName() == "filterextractor" || forBlob.isOverlapping(this));
}