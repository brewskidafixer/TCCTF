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
	this.set_u8("drill_count", 1);
	this.set_u8("spam", 0);
	this.getSprite().SetZ(-50); //background
	this.getShape().getConsts().mapCollisions = false;

	this.Tag("builder always hit");
	
	this.getCurrentScript().tickFrequency = 15;
	
	this.set_bool("isActive", false);
	this.set_u8("bedrock_count", 0);
	this.set_bool("bedrock_drillrig", false);
	this.set_f32("gyro_bonus", 1.0f);
	this.addCommandID("sv_toggle");
	CBlob@[] blobs;
	if (getMap().getBlobsAtPosition(this.getPosition(), @blobs))
	{
		for (u8 i = 0; i < blobs.length; i++)
		{
			if (blobs[i].getName() == "drillrig" && blobs[i] !is this)
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
		Vec2f drillPos = this.getPosition();
		if (this.get_bool("bedrock_drillrig"))
		{
			u8 index = XORRandom(resources.length);
			MakeMat(this, drillPos, resources[index], (1 + XORRandom(resourceYields[index]))*(this.get_f32("gyro_bonus") + this.get_u8("drill_count")));
		}
		else
		{
			CMap@ map = getMap();
			
			for (u8 i = 0; i<this.get_u8("drill_count");i++)
			{
				f32 depth = XORRandom(64);
				Vec2f pos = Vec2f(drillPos.x + (XORRandom(48) - 24) * (1 - depth / 64), Maths::Min(drillPos.y + 16 + depth, (map.tilemapheight * map.tilesize) - 8));

				this.server_HitMap(pos, Vec2f(0, 0), 1.3f, Hitters::drill);
			}
			this.add_u8("spam", 1);
			if (this.get_u8("spam") > 150)
			{
				this.set_u8("spam", 0);
				CBitStream params;
				params.write_bool(false);
				this.SendCommand(this.getCommandID("sv_toggle"), params);
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
			this.add_u8("bedrock_count", 1);
			if (this.get_u8("bedrock_count") >= 5)
			{
				this.set_bool("bedrock_drillrig", true);
				this.getCurrentScript().tickFrequency = 60;
			}
		}
	}
}

void onDie(CBlob@ this)
{
	if (isServer() && !this.hasTag("temp"))
	{
		server_CreateBlob("drill", this.getTeamNum(), this.getPosition());
	}
}

void onCommand(CBlob@ this, u8 cmd, CBitStream @params)
{
	if (cmd == this.getCommandID("sv_toggle"))
	{
		bool active = params.read_bool();
		
		this.set_bool("isActive", active);
		if (!v_fastrender)
		{
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
	
	bool active = this.get_bool("isActive");
	CBitStream params;
	params.write_bool(!active);
	
	CButton@ buttonEject = caller.CreateGenericButton(active ? 27 : 23, Vec2f(0, -8), this, this.getCommandID("sv_toggle"), (active ? "Turn Off" : "Turn On"), params);
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