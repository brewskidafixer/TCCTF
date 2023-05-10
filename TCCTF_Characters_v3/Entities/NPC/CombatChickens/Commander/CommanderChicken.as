// Princess brain

#include "Hitters.as";
#include "Explosion.as";
#include "FireParticle.as"
#include "FireCommon.as";
#include "RunnerCommon.as";
#include "MakeCrate.as";
#include "ThrowCommon.as";
#include "Survival_Structs.as";

u32 next_commander_event = 0; // getGameTime() + (30 * 60 * 5) + XORRandom(30 * 60 * 5));
bool dry_shot = true;

void onInit(CBlob@ this)
{
	this.set_u32("nextAttack", 0);
	this.set_u32("nextBomb", 0);

	this.set_f32("minDistance", 32);
	this.set_f32("chaseDistance", 200);
	this.set_f32("maxDistance", 400);

	this.set_f32("inaccuracy", 0.01f);
	this.set_u8("reactionTime", 20);
	this.set_u8("attackDelay", 0);
	this.set_bool("bomber", false);
	this.set_bool("raider", false);

	// this.set_u32("next_event", getGameTime() + (30 * 60 * 5) + XORRandom(30 * 60 * 5));

	next_commander_event = getGameTime(); // + (30 * 60 * 5) + XORRandom(30 * 60 * 5));
	this.addCommandID("commander_order_recon_squad");

	this.SetDamageOwnerPlayer(null);

	this.Tag("can open door");
	this.Tag("combat chicken");
	this.Tag("npc");
	this.Tag("flesh");
	this.Tag("player");

	this.getCurrentScript().tickFrequency = 1;

	this.set_f32("voice pitch", 1.50f);
	this.getSprite().addSpriteLayer("isOnScreen","NoTexture.png",1,1);
	if (isServer())
	{
		this.set_u16("stolen coins", 850);

		string gun_config;
		string ammo_config;

		switch(XORRandom(6))
		{
			case 0:
				gun_config = "autoshotgun";
				ammo_config = "mat_shotgunammo";

				this.set_u8("reactionTime", 5);
				this.set_u8("attackDelay", 1);
				this.set_f32("chaseDistance", 50);
				this.set_f32("minDistance", 8);
				this.set_f32("maxDistance", 400);
				this.set_bool("bomber", true);
				this.set_f32("inaccuracy", 0.00f);

				break;

			case 1:
			case 2:
				gun_config = "sar";
				ammo_config = "mat_rifleammo";
				
				this.set_u8("reactionTime", 5);
				this.set_u8("attackDelay", 1);
				this.set_f32("chaseDistance", 400);
				this.set_f32("minDistance", 64);
				this.set_f32("maxDistance", 600);
				
				break;

			case 3:
			case 4:
				gun_config = "carbine";
				ammo_config = "mat_rifleammo";
				
				this.set_u8("attackDelay", 1);
				this.set_u8("reactionTime", 10);
				this.set_f32("chaseDistance", 100);
				this.set_f32("minDistance", 8);
				this.set_f32("maxDistance", 300);
				
				break;		

			default:
				gun_config = "beagle";
				ammo_config = "mat_rifleammo";

				this.set_u8("reactionTime", 2);
				this.set_u8("attackDelay", 2);
				this.set_f32("chaseDistance", 100);
				this.set_f32("minDistance", 32);
				this.set_f32("maxDistance", 300);
				this.set_f32("inaccuracy", 0.00f);
				break;
		}

		u8 team = this.getTeamNum();
		Vec2f pos = this.getPosition();
		CBlob@ phone = server_CreateBlob("phone", team, pos);
		this.server_PutInInventory(phone);

		// gun and ammo
		CBlob@ ammo = server_CreateBlob(ammo_config, team, pos);
		ammo.server_SetQuantity(ammo.maxQuantity);
		this.server_PutInInventory(ammo);

		CBlob@ gun = server_CreateBlob(gun_config, team, pos);
		if (gun !is null)
		{
			this.server_Pickup(gun);

			if (gun.hasCommandID("reload"))
			{
				CBitStream stream;
				gun.SendCommand(gun.getCommandID("reload"), stream);
			}
		}
	}
}

void onSetPlayer(CBlob@ this, CPlayer@ player)
{
	if (player !is null) player.SetScoreboardVars("ScoreboardIcons.png", 17, Vec2f(16, 16));
}

bool canBePickedUp(CBlob@ this, CBlob@ byBlob)
{
	return this.hasTag("dead");
}

void onTick(CBlob@ this)
{
	RunnerMoveVars@ moveVars;
	if (this.get("moveVars", @moveVars))
	{
		moveVars.walkFactor *= 1.15f;
		moveVars.jumpFactor *= 1.50f;
	}

	if (this.getHealth() < 0.0 && this.hasTag("dead"))
	{
		this.getSprite().PlaySound("Wilhelm.ogg", 1.8f, 1.8f);

		if (isServer())
		{
			this.server_SetPlayer(null);
			server_DropCoins(this.getPosition(), Maths::Max(0, Maths::Min(this.get_u16("stolen coins"), 5000)));
			CBlob@ carried = this.getCarriedBlob();

			if (carried !is null)
			{
				carried.server_DetachFrom(this);
			}
		}

		this.getCurrentScript().runFlags |= Script::remove_after_this;
	}

	if (this.isMyPlayer())
	{
		if (this.isKeyJustPressed(key_action3))
		{
			client_SendThrowOrActivateCommand(this);
		}
	}

	if (isClient())
	{
		if (getGameTime() > this.get_u32("next sound") && XORRandom(100) < 5)
		{
			// this.getSprite().PlaySound("scoutchicken_vo_perish.ogg", 0.8f, 1.5f);
			this.set_u32("next sound", getGameTime() + 100);
		}
	}
}

f32 onHit(CBlob@ this, Vec2f worldPoint, Vec2f velocity, f32 damage, CBlob@ hitterBlob, u8 customData)
{
	if (isClient())
	{
		if (getGameTime() > this.get_u32("next sound") - 50)
		{
			this.getSprite().PlaySound("scoutchicken_vo_hit" + (1 + XORRandom(3)) + ".ogg", 1, 0.8f);
			this.set_u32("next sound", getGameTime() + 60);
		}
	}

	return damage;
}

bool doesCollideWithBlob(CBlob@ this, CBlob@ blob)
{
	return this.getTeamNum() != blob.getTeamNum();
}
