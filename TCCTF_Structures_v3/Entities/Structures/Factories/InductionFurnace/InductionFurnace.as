#include "MakeMat.as";

void onInit(CSprite@ this)
{
	// Building
	this.SetZ(-50); //-60 instead of -50 so sprite layers are behind ladders
}

const string[] matNames = { 
	"mat_wood",
	"mat_copper",
	"mat_iron",
	"mat_gold",
	"mat_ironingot",
	"mat_mithril"
};

const string[] matNamesResult = { 
	"mat_coal",
	"mat_copperingot",
	"mat_ironingot",
	"mat_goldingot",
	"mat_steelingot",
	"mat_mithrilingot"
};

const int[] matRatio = { 
	10,
	10,
	10,
	25,
	4,
	40
};

const int[] coalRatio = {
	0,
	0,
	0,
	0,
	5,
	25
};

void onInit(CBlob@ this)
{
	this.set_TileType("background tile", CMap::tile_castle_back);
	this.getShape().getConsts().mapCollisions = false;
	this.getCurrentScript().tickFrequency = 150;

	this.Tag("ignore extractor");
	this.Tag("builder always hit");
	this.set_u8("bulk_modifier", 2);

	CSprite@ sprite = this.getSprite();
	if (sprite !is null)
	{
		sprite.SetEmitSound("InductionFurnace_Loop.ogg");
		sprite.SetEmitSoundVolume(0.50f);
		sprite.SetEmitSoundSpeed(1.0f);
		sprite.SetEmitSoundPaused(false);
	}
}

void onTick(CBlob@ this)
{
	CInventory@ inv = this.getInventory();
	if (inv !is null)
	{
		for (u8 i = 0; i < 6; i++)
		{
			u8 bulk = Maths::Min(inv.getCount(matNames[i])/matRatio[i], this.get_u8("bulk_modifier"));
			if (bulk > 0)
			{
				if (coalRatio[i] > 0) bulk = Maths::Min(inv.getCount("mat_coal")/coalRatio[i], bulk);
				if (this.hasBlob(matNames[i], matRatio[i]*bulk) && (coalRatio[i] == 0 || this.hasBlob("mat_coal", coalRatio[i]*bulk)))
				{
					if (isServer())
					{
						CBlob @mat = server_CreateBlob(matNamesResult[i], -1, this.getPosition());
						mat.server_SetQuantity(4*bulk);
						mat.Tag("justmade");
						this.TakeBlob(matNames[i], matRatio[i]*bulk);
						if (coalRatio[i] > 0) this.TakeBlob("mat_coal", coalRatio[i]*bulk);
					}

					this.getSprite().PlaySound("ProduceSound.ogg", 0.5f);
					this.getSprite().PlaySound("BombMake.ogg", 0.5f);
				}
			}
		}
	}
}

void onCollision(CBlob@ this, CBlob@ blob, bool solid)
{
	if (blob is null) return;
	if (blob.hasTag("justmade")){
		blob.Untag("justmade");
		return;
	}
	if (!blob.isAttached() && blob.hasTag("material"))
	{
		for (u8 i = 0; i < 5; i++)
		{
			if (blob.getName() == matNames[i])
			{
				putInInventory(this, blob);
				return;
			}
		}
		if (blob.getName() == "mat_coal") putInInventory(this, blob);
	}
}

void putInInventory(CBlob@ this, CBlob@ blob)
{
	if (isServer()) this.server_PutInInventory(blob);
	if (isClient()) this.getSprite().PlaySound("bridge_open.ogg");
}

bool isInventoryAccessible(CBlob@ this, CBlob@ forBlob)
{
	return forBlob !is null && forBlob.isOverlapping(this);
}

void onAddToInventory( CBlob@ this, CBlob@ blob )
{
	if (blob.getName() != "gyromat") return;
	gyroCheck(this);
}

void onRemoveFromInventory(CBlob@ this, CBlob@ blob)
{
	if (blob.getName() != "gyromat") return;
	gyroCheck(this);
}

void gyroCheck(CBlob@ this)
{
	if (!this.exists("gyromat_acceleration"))
	{
		print("ERROR: no gyromat acceleration?!");
		return;
	}
	f32 gyrovalue = this.get_f32("gyromat_acceleration");
	u8 bulk = Maths::Round(Maths::FastSqrt(gyrovalue));
	f32 speed = gyrovalue/bulk;
	this.set_u8("bulk_modifier", 2 * bulk);
	this.getCurrentScript().tickFrequency = 150/speed;
}