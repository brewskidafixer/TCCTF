//bf_piglet
#include "AnimalConsts.as";
#include "Knocked.as";

const int MAX_CHICKENS_TO_HATCH = 3;
const f32 CHICKEN_LIMIT_RADIUS = 120.0f;
//sprite
void onInit(CSprite@ this)
{
	this.ReloadSprites(0,0);
	this.SetZ(-20.0f);
}

void onTick(CSprite@ this)
{
	CBlob@ blob = this.getBlob();
	if (blob.hasTag("dead")) 
	{
		this.getCurrentScript().removeIfTag = "dead";
		return;
	}
	else
	{
		f32 x = Maths::Abs(blob.getVelocity().x);

		if (Maths::Abs(x) > 0.2f)
		{
			this.SetAnimation("walk");
		}
		else
		{
			this.SetAnimation("idle");
		}
		
		if (blob.get_u32("next oink") < getGameTime() && XORRandom(100) < 30) 
		{
			blob.set_u32("next oink", getGameTime() + 200);
			this.PlaySound("BF_PigOink" + (1 + XORRandom(3)), 1, 1);
		}
	}
}

void onInit(CBlob@ this)
{
	f32 gameTime = getGameTime();
	this.set_f32("bite damage", 0.1f);
	this.maxQuantity = 64;

	//brain
	this.set_u8(personality_property, SCARED_BIT);
	this.set_f32(target_searchrad_property, 30.0f);
	this.set_f32(terr_rad_property, 75.0f);
	this.set_u8(target_lose_random, 14);

	this.addCommandID("write");

	//for shape
	this.getShape().SetRotationsAllowed(false);

	//for flesh hit
	this.set_f32("gib health", -2.0f);	  	
	this.Tag("flesh");
	this.Tag("passive");

	this.getShape().SetOffset(Vec2f(0, 2));

	this.set_u8( "maxStickiedTime", 40 );

	AnimalVars@ vars;
	if (!this.get( "vars", @vars )) return;

	vars.walkForce.Set(10.0f, -0.1f);
	vars.runForce.Set(20.0f, -1.0f);
	vars.slowForce.Set(10.0f, 0.0f);
	vars.jumpForce.Set(0.0f, -20.0f);
	vars.maxVelocity = 2.2f;

	this.set_u8("number of steaks", 5);
	this.set_u32("next oink", gameTime);
	this.set_u32("next squeal", gameTime);

	if (!this.exists("voice_pitch")) this.set_f32("voice pitch", 1.50f);
}

void onTick(CBlob@ this)
{
	if (!this.hasTag("dead"))
	{
		f32 x = this.getVelocity().x;
		if (Maths::Abs(x) > 1.0f)
		{
			this.SetFacingLeft(x < 0);
		}
		else
		{
			if (this.isKeyPressed(key_left)) 
			{
				this.SetFacingLeft(true);
			}
			if (this.isKeyPressed(key_right)) 
			{
				this.SetFacingLeft(false);
			}
		}

		if (this.getHealth() < 0)
		{
			this.getSprite().SetAnimation("dead");

			this.Tag("dead");
			// this.getCurrentScript().removeIfTag = "dead";
		}
	}
}

f32 onHit(CBlob@ this, Vec2f worldPoint, Vec2f velocity, f32 damage, CBlob@ hitterBlob, u8 customData)
{
	if (!this.hasTag("dead") && getGameTime() > this.get_u32("next squeal"))
	{
		this.getSprite().PlaySound("BF_PigSqueal" + (1 + XORRandom(2)), 1.00f, 1.0f);
		this.set_u32("next squeal", getGameTime() + 90);
		this.AddForce(Vec2f(0.0f, -180.0f));
	}

	return damage;
}

bool canBePickedUp(CBlob@ this, CBlob@ byBlob)
{
	return true;
}

bool doesCollideWithBlob(CBlob@ this, CBlob@ blob)
{
	return blob !is null && blob.getName() != "piglet" && (blob.isCollidable() && !blob.hasTag("player"));
}

void onCollision(CBlob@ this, CBlob@ blob, bool solid, Vec2f normal, Vec2f point1)
{
	if (blob is null) return;
	if (this.hasTag("dead")) return;

	if (blob.getName() == "grain") layEgg(this, blob);
	else if (blob.getName() == "mat_mithril" && blob.getQuantity() > 25)
	{
		if (isServer())
		{
			CBlob@ bagel = server_CreateBlob("pigger", this.getTeamNum(), this.getPosition());
			bagel.server_SetQuantity(this.getQuantity());
			this.server_Die();
		}
		else
		{
			ParticleZombieLightning(this.getPosition());
		}
	}
}

void layEgg(CBlob@ this, CBlob@ blob)
{
	if (isServer())
	{
		u8 grain = blob.getQuantity();
		if (grain < 5) return;
		f32 gameTime = getGameTime();
		if (this.get_f32("egg_cooldown") > gameTime) return;
		int chickenCount = 0;
		CBlob@[] blobs;
		getMap().getBlobsInRadius(this.getPosition(), CHICKEN_LIMIT_RADIUS, @blobs);
		for (uint step = 0; step < blobs.length; ++step)
		{
			CBlob@ other = blobs[step];
			if (other.getName() == "piglet")
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
			u8 chickens = this.getQuantity();
			u8 eggs = Maths::Min(chickens, grain/10);
			u8 remain = grain - eggs*10;
			if (chickens * eggs == 0)
			{
				//print("Error | Piglets: "+chickens+" | Eggs: "+eggs);
				this.set_f32("egg_cooldown", gameTime + 900);
				return;
			}
			if (remain > 0) blob.server_SetQuantity(remain);
			else blob.server_Die();
			CBlob@ piglet = server_CreateBlob("piglet", -1, this.getPosition() + Vec2f(0.0f, -5.0f));
			piglet.server_SetQuantity(eggs);
			piglet.set_f32("egg_cooldown", gameTime + 1800);
			this.set_f32("egg_cooldown", gameTime + (900/chickens*eggs));
		}
	}
}

void onCommand(CBlob@ this, u8 cmd, CBitStream @params)
{
	if (cmd == this.getCommandID("write"))
	{
		if (isServer())
		{
			CBlob @caller = getBlobByNetworkID(params.read_u16());
			CBlob @carried = getBlobByNetworkID(params.read_u16());

			if (caller !is null && carried !is null)
			{
				this.set_string("text", carried.get_string("text"));
				this.Sync("text", true);
				carried.server_Die();
			}
		}
		if (isClient())
		{
			this.setInventoryName(this.get_string("text") + " the piglet");
		}
	}
}

void GetButtonsFor(CBlob@ this, CBlob@ caller)
{
	if (caller is null) return;
	if (!this.isOverlapping(caller)) return;

	//rename the piglet
	CBlob@ carried = caller.getCarriedBlob();
	if(carried !is null && carried.getName() == "paper")
	{
		CBitStream params;
		params.write_u16(caller.getNetworkID());
		params.write_u16(carried.getNetworkID());

		CButton@ buttonWrite = caller.CreateGenericButton("$icon_paper$", Vec2f(0, 0), this, this.getCommandID("write"), "Rename", params);
	}
}
