// Princess brain

#include "Hitters.as";
#include "HittersTC.as";
#include "Explosion.as";
#include "FireParticle.as"
#include "FireCommon.as";
#include "RunnerCommon.as";
#include "BrainCommon.as";
#include "ThrowCommon.as";
#include "NightVision.as";

void onInit(CBlob@ this)
{
	this.getSprite().addSpriteLayer("isOnScreen","NoTexture.png",1,1);
	this.set_u32("nextAttack", 0);
	this.set_u32("nextBomb", 0);

	this.set_f32("minDistance", 32);
	this.set_f32("chaseDistance", 200);
	this.set_f32("maxDistance", 400);

	this.set_f32("inaccuracy", 0.00f);
	this.set_u8("reactionTime", 10);
	this.set_u8("attackDelay", 0);
	this.set_bool("bomber", true);
	this.set_bool("raider", true);

	this.SetDamageOwnerPlayer(null);

	this.Tag("can open door");
	this.Tag("combat chicken");
	this.Tag("npc");
	this.Tag("flesh");
	this.Tag("player");

	this.getCurrentScript().tickFrequency = 1;

	this.set_f32("voice pitch", 0.50f);

	if (isServer())
	{
		this.set_u16("stolen coins", 750);

		string gun_config;
		string ammo_config;

		switch(XORRandom(12))
		{
			case 0:
			case 1:
			case 2:
				gun_config = "autoshotgun";
				ammo_config = "mat_shotgunammo";

				this.set_u8("attackDelay", 0);
				this.set_u8("reactionTime", 5);
				this.set_f32("chaseDistance", 100);
				this.set_f32("minDistance", 64);
				this.set_f32("maxDistance", 500);
				this.set_bool("bomber", true);

				break;

			case 3:
			case 4:
				gun_config = "flamethrower";
				ammo_config = "mat_oil";

				this.set_u8("reactionTime", 30);
				this.set_u8("attackDelay", 0);
				this.set_f32("chaseDistance", 100);
				this.set_f32("minDistance", 64);
				this.set_f32("maxDistance", 200);

				break;

			case 5:
			case 6:
				gun_config = "sniper";
				ammo_config = "mat_rifleammo";

				this.set_u8("reactionTime", 45);
				this.set_u8("attackDelay", 0);
				this.set_f32("chaseDistance", 1337); // No chasing, they're snipers
				this.set_f32("minDistance", 128);
				this.set_f32("maxDistance", 800);
				this.set_bool("bomber", false);
				this.set_f32("inaccuracy", 0.025f);

				break;

			case 7:
				gun_config = "grenadelauncher";
				ammo_config = "mat_grenade";

				this.set_u8("reactionTime", 10);
				this.set_u8("attackDelay", 20);
				this.set_f32("chaseDistance", 250);
				this.set_f32("minDistance", 100);
				this.set_f32("maxDistance", 700);
				this.set_bool("bomber", true);
				this.set_f32("inaccuracy", 0.02f);

				break;

			default:
				gun_config = "assaultrifle";
				ammo_config = "mat_rifleammo";

				this.set_u8("reactionTime", 10);
				this.set_u8("attackDelay", 2);
				this.set_f32("chaseDistance", 200);
				this.set_f32("minDistance", 100);
				this.set_f32("maxDistance", 500);
				this.set_bool("bomber", true);
				this.set_f32("inaccuracy", 0.001f);

				break;
		}

		CBlob@ ammo = server_CreateBlob(ammo_config, this.getTeamNum(), this.getPosition());
		ammo.server_SetQuantity(ammo.maxQuantity);
		this.server_PutInInventory(ammo);

		CBlob@ gun = server_CreateBlob(gun_config, this.getTeamNum(), this.getPosition());
		if (gun !is null)
		{
			gun.Tag("chickengun");
			this.server_Pickup(gun);

			if (gun.hasCommandID("reload"))
			{
				CBitStream stream;
				gun.SendCommand(gun.getCommandID("reload"), stream);
			}
		}

		// CBrain@ brain = this.getBrain();
		// if (brain !is null)
		// {

		// }
	}
}

void onSetPlayer(CBlob@ this, CPlayer@ player)
{
	if (player !is null) player.SetScoreboardVars("ScoreboardIcons.png", 16, Vec2f(16, 16));
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
		moveVars.walkFactor *= 1.10f;
		moveVars.jumpFactor *= 1.30f;
	}
	if (!this.hasTag("temp"))
	{
		nightVision(this);
		this.Tag("temp");
	}

	if (getGameTime() % 30 == 0) this.set_u8("mode", 0);

	if (this.getHealth() < 0.0 && this.hasTag("dead"))
	{
		this.getSprite().PlaySound("Wilhelm.ogg", 1.8f, 1.8f);

		if (isServer())
		{
			this.server_SetPlayer(null);
			CBlob@ carried = this.getCarriedBlob();

			if (carried !is null)
			{
				carried.server_DetachFrom(this);
			}
		}

		this.getCurrentScript().runFlags |= Script::remove_after_this;
	}

	if (isClient())
	{
		if (getGameTime() > this.get_u32("next sound") && XORRandom(100) < 5)
		{
			// this.getSprite().PlaySound("scoutchicken_vo_perish.ogg", 0.8f, 1.5f);
			this.set_u32("next sound", getGameTime() + 100);
		}
	}

	if (this.isMyPlayer())
	{
		if (this.isKeyJustPressed(key_action3))
		{
			client_SendThrowOrActivateCommand(this);
		}
	}
}

f32 onHit(CBlob@ this, Vec2f worldPoint, Vec2f velocity, f32 damage, CBlob@ hitterBlob, u8 customData)
{
	switch (customData)
	{
		case Hitters::fire:
		case Hitters::burn:
		case HittersTC::radiation:
			damage = 0.00f;
			break;
	}

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