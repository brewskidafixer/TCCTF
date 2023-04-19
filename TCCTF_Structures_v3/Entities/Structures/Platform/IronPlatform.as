#include "Hitters.as";
#include "HittersTC.as";
#include "ParticleSparks.as";
#include "MinableMatsCommon.as";

void onInit(CBlob@ this)
{
	this.SetFacingLeft(XORRandom(128) > 64);

	this.getSprite().getConsts().accurateLighting = true;
	this.getShape().getConsts().waterPasses = false;

	CShape@ shape = this.getShape();
	shape.AddPlatformDirection(Vec2f(0, -1), 89, false);
	shape.SetRotationsAllowed(false);
	
	this.server_setTeamNum(-1); //allow anyone to break them

	this.set_TileType("background tile", CMap::tile_castle_back);

	this.Tag("blocks sword");

	
	HarvestBlobMat[] mats = {};
	mats.push_back(HarvestBlobMat(3.0f, "mat_ironingot"));
	this.set("minableMats", mats);	
}

void onSetStatic(CBlob@ this, const bool isStatic)
{
	if (!isStatic) return;

	this.getSprite().PlaySound("/build_wall.ogg");
}

bool canBePickedUp(CBlob@ this, CBlob@ byBlob)
{
	return false;
}

f32 onHit(CBlob@ this, Vec2f worldPoint, Vec2f velocity, f32 damage, CBlob@ hitterBlob, u8 customData)
{
	switch (customData)
	{
		case HittersTC::bullet_low_cal:
		case HittersTC::shotgun:
			damage *= 0.70f;
			break;
		case Hitters::builder:
		case Hitters::drill:
			damage *= 2;
			break;
	}
	return damage;
}