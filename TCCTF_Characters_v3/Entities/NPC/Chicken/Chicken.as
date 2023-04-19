//script for a chicken

#include "AnimalConsts.as";

const u8 DEFAULT_PERSONALITY = SCARED_BIT;
//const int MAX_EGGS = 2; //maximum symultaneous eggs
const int MAX_CHICKENS_TO_HATCH = 2;
const f32 CHICKEN_LIMIT_RADIUS = 120.0f;

int g_lastSoundPlayedTime = 0;
//int g_layEggInterval = 0;

void onInit(CSprite@ this)
{
	this.ReloadSprites(0, 0); //always blue
	this.addSpriteLayer("isOnScreen","NoTexture.png",1,1);
	this.getCurrentScript().tickFrequency = 120;
}

void onInit(CBlob@ this)
{
	this.set_f32("bite damage", 0.25f);
	this.set_f32("pickup_priority", 0.05f);

	//brain
	this.set_u8(personality_property, DEFAULT_PERSONALITY);
	this.set_f32(target_searchrad_property, 30.0f);
	this.set_f32(terr_rad_property, 75.0f);
	this.set_u8(target_lose_random, 14);

	this.addCommandID("write");

	//for shape
	this.getShape().SetRotationsAllowed(false);

	//for flesh hit
	this.set_f32("gib health", -0.0f);
	this.Tag("flesh");
	this.Tag("passive");

	this.getShape().SetOffset(Vec2f(0, 0));

	this.set_u8("number of steaks", 1);
	this.maxQuantity = 64;

	this.getCurrentScript().runFlags |= Script::tick_blob_in_proximity;
	this.getCurrentScript().runProximityTag = "player";
	this.getCurrentScript().runProximityRadius = 320.0f;

	// attachment

	//todo: some tag-based keys to take interference (doesn't work on net atm)
	/*AttachmentPoint@ att = this.getAttachments().getAttachmentPointByName("PICKUP");
	att.SetKeysToTake(key_action1);*/

	// movement

	this.server_setTeamNum(250);

	AnimalVars@ vars;
	if (!this.get("vars", @vars))
		return;
	vars.walkForce.Set(1.0f, -0.1f);
	vars.runForce.Set(2.0f, -1.0f);
	vars.slowForce.Set(1.0f, 0.0f);
	vars.jumpForce.Set(0.0f, -20.0f);
	vars.maxVelocity = 1.1f;

	if (!this.exists("voice_pitch")) this.set_f32("voice pitch", 2.00f);
}

void onTick(CSprite@ this)
{
	if (v_fastrender) return;
	CBlob@ blob = this.getBlob();

	if (!blob.hasTag("dead"))
	{
		if(!this.getSpriteLayer("isOnScreen").isOnScreen()){
			return;
		}

		f32 x = Maths::Abs(blob.getVelocity().x);
		if (blob.isAttached())
		{
			AttachmentPoint@ ap = blob.getAttachmentPoint(0);
			if (ap !is null && ap.getOccupied() !is null)
			{
				if (Maths::Abs(ap.getOccupied().getVelocity().y) > 0.2f)
				{
					this.SetAnimation("fly");
				}
				else
					this.SetAnimation("idle");
			}
		}
		else if (!blob.isOnGround())
		{
			this.SetAnimation("fly");
		}
		else if (x > 0.02f)
		{
			this.SetAnimation("walk");
		}
		else
		{
			if (this.isAnimationEnded())
			{
				uint r = XORRandom(20);
				if (r == 0)
					this.SetAnimation("peck_twice");
				else if (r < 5)
					this.SetAnimation("peck");
				else
					this.SetAnimation("idle");
			}
		}
		Vec2f vel=blob.getVelocity();
		if(vel.x!=0.0f){
			this.SetFacingLeft(vel.x<0.0f ? true : false);
		}
	}
	else
	{
		this.SetAnimation("dead");
		this.getCurrentScript().runFlags |= Script::remove_after_this;
		this.PlaySound("/ScaredChicken");
	}
}

bool canBePickedUp(CBlob@ this, CBlob@ byBlob)
{
	return true;
}

bool doesCollideWithBlob(CBlob@ this, CBlob@ blob)
{
	if (blob !is null)
	{
		string blobName = blob.getName();
		return blobName != "chicken" && blobName != "egg" && (blob.isCollidable() && !blob.hasTag("player"));
	}
	return false;
}

void onTick(CBlob@ this)
{
	Vec2f vel=this.getVelocity();
	if(vel.x!=0.0f)
	{
		this.SetFacingLeft(vel.x<0.0f ? true : false);
	}

	if (this.isAttached())
	{
		AttachmentPoint@ att = this.getAttachmentPoint(0);   //only have one
		if (att !is null)
		{
			CBlob@ b = att.getOccupied();
			if (b !is null)
			{
				Vec2f vel = b.getVelocity();
				if (vel.y > 0.5f)
				{
					b.AddForce(Vec2f(0, -20));
				}
			}
		}
	}
	else if (!this.isOnGround())
	{
		Vec2f vel = this.getVelocity();
		if (vel.y > 0.5f)
		{
			this.AddForce(Vec2f(0, -10));
		}
	}
}

void onCollision(CBlob@ this, CBlob@ blob, bool solid, Vec2f normal, Vec2f point1)
{
	if (blob is null)
		return;

	if (blob.getRadius() > this.getRadius() && g_lastSoundPlayedTime + 25 < getGameTime() && blob.hasTag("flesh"))
	{
		this.getSprite().PlaySound("/ScaredChicken");
		g_lastSoundPlayedTime = getGameTime();
	}
	if (isServer() && blob.getName() == "grain") layEgg(this, blob);
}

void layEgg(CBlob@ this, CBlob@ blob)
{
	f32 gameTime = getGameTime();
	if (this.get_f32("egg_cooldown") > gameTime) return;
	int chickenCount = 0;
	CBlob@[] blobs;
	getMap().getBlobsInRadius(this.getPosition(), CHICKEN_LIMIT_RADIUS, @blobs);
	for (uint step = 0; step < blobs.length; ++step)
	{
		CBlob@ other = blobs[step];
		if (other.getName() == "chicken")
		{
			chickenCount++;
			u8 cur_quantity = this.getQuantity();
			u8 other_quantity = other.getQuantity();
			if (this !is other)
			{
				if (cur_quantity < 64 && other_quantity < 64)
				{
					other.set_bool("chicken_merging", true);
					if (this.get_bool("chicken_merging")) return;
					u8 taken = Maths::Min(64 - cur_quantity, other_quantity);
					if (other_quantity - taken > 0) other.server_SetQuantity(other_quantity - taken);
					else
					{
						chickenCount--;
						other.server_Die();
					}
					this.server_SetQuantity(cur_quantity + taken);
				}
			}
			if (chickenCount >= MAX_CHICKENS_TO_HATCH)
			{
				this.set_f32("egg_cooldown", gameTime + 600);
				return;
			}
		}
	}
	if (chickenCount < MAX_CHICKENS_TO_HATCH)
	{
		u8 grain = blob.getQuantity();
		u8 chickens = this.getQuantity();
		u8 eggs = Maths::Min(chickens, grain);
		u8 remain = grain - eggs;
		if (chickens * eggs == 0)
		{
			//print("Error | Chickens: "+chickens+"| Eggs: "+eggs);
			this.set_f32("egg_cooldown", gameTime + 900);
			return;
		}
		if (remain > 0) blob.server_SetQuantity(remain);
		else blob.server_Die();
		server_CreateBlob("egg", -1, this.getPosition() + Vec2f(0.0f, -5.0f)).server_SetQuantity(eggs);
		this.set_f32("egg_cooldown", gameTime + (900/chickens*eggs));
	}
}