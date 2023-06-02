#include "Hitters.as";
#include "HittersTC.as";
#include "Knocked.as";
#include "DeityCommon.as";
#include "TurretAmmo.as";

const f32 radius = 128.0f;
const f32 damage = 5.00f;
const u32 delay = 90;
const u8 maxAmmo = 250;

void onInit(CBlob@ this)
{
	this.Tag("builder always hit");
	this.Tag("heavy weight");

	this.set_f32("pickup_priority", 16.00f);
	this.getShape().SetRotationsAllowed(false);

	this.getCurrentScript().tickFrequency = 3;
	this.getCurrentScript().runFlags |= Script::tick_not_ininventory | Script::tick_not_attached;

	this.set_bool("security_state", true);

	this.set_u16("ammoCount", 0);
	this.set_u16("maxAmmo", 250);
	this.set_string("ammoName", "mat_battery");
	this.set_string("ammoInventoryName", "Batteries");
	this.set_string("ammoIconName", "$mat_battery$");
	if (this.getTeamNum() == 3) this.set_u16("ammoCount", 100);
	Turret_onInit(this);
}

void onInit(CSprite@ this)
{
	this.SetEmitSound("Zapper_Loop.ogg");
	this.SetEmitSoundVolume(0.0f);
	this.SetEmitSoundSpeed(0.0f);
	this.SetEmitSoundPaused(false);

	CSpriteLayer@ zap = this.addSpriteLayer("zap", "Zapper_Lightning.png", 128, 12);

	if (zap !is null)
	{
		Animation@ anim = zap.addAnimation("default", 1, false);
		int[] frames = {0, 1, 2, 3, 4, 5, 6, 7};
		anim.AddFrames(frames);
		zap.SetRelativeZ(-1.0f);
		zap.SetVisible(false);
		zap.setRenderStyle(RenderStyle::additive);
		zap.SetOffset(Vec2f(0, 0));
	}
}

bool doesCollideWithBlob(CBlob@ this, CBlob@ blob)
{
	return blob.getShape().isStatic() && blob.isCollidable();
}

bool canBePickedUp(CBlob@ this, CBlob@ byBlob)
{
	return byBlob.getTeamNum() == this.getTeamNum();
}

void GetButtonsFor(CBlob@ this, CBlob@ caller)
{
	if (caller.getTeamNum() == this.getTeamNum())
	{
		if (this.getDistanceTo(caller) <= 48)
		{
			Turret_AddButtons(this, caller);
		}
	}
}

void onTick(CBlob@ this)
{
	if (this.get_bool("security_state"))
	{
		const u16 fuel = this.get_u16("ammoCount");
		if (fuel == 0) return;

		this.getSprite().SetEmitSoundVolume(0.45f);
		this.getSprite().SetEmitSoundSpeed(0.75f + f32(fuel) / 50.0f * 0.35f);

		if (this.get_u32("next zap") > getGameTime()) return;

		CMap@ map = getMap();
		CBlob@[] blobsInRadius;
		if (this.getMap().getBlobsInRadius(this.getPosition(), radius, @blobsInRadius))
		{
			int index = -1;
			f32 s_dist = 1337;
			u8 myTeam = this.getTeamNum();

			CBlob@[] spawns;
			getBlobsByName("ruins", @spawns);
			getBlobsByTag("faction_base", @spawns);

			for (uint i = 0; i < blobsInRadius.length; i++)
			{
				CBlob@ b = blobsInRadius[i];
				u8 team = b.getTeamNum();
				if (team == myTeam || map.rayCastSolid(this.getPosition(), b.getPosition())) continue;

				for (uint s = 0; s < spawns.length; s++)
				{
					//Anti spawn killing
					CBlob@ spawn = spawns[s];
					if (b is spawn && spawn.get_bool("isActive") && spawn.getTeamNum() != this.getTeamNum() && 
					    !map.rayCastSolid(this.getPosition(), b.getPosition())) return;
				}

				if (b.hasTag("flesh") && !b.hasTag("passive") && !b.hasTag("dead"))
				{
					f32 dist = (b.getPosition() - this.getPosition()).Length();
					if (dist < s_dist)
					{
						s_dist = dist;
						index = i;
					}
				}
			}

			if (index < 0) return;

			CBlob@ target = blobsInRadius[index];
			CPlayer@ host = this.getDamageOwnerPlayer();
			if (target !is null) 
			{
				CPlayer@ _target = target.getPlayer();
				if (host !is null && _target is host) //recognizes host and changes team
				{
					this.server_setTeamNum(_target.getBlob().getTeamNum());
					print("change");
					return;
				}
				Zap(this, target);
			}
		}
	}
}

void onTick(CSprite@ this)
{
	this.SetFacingLeft(false);
}

void onCommand(CBlob@ this, u8 cmd, CBitStream @params)
{
	if (cmd == this.getCommandID("security_set_state"))
	{
		bool state = params.read_bool();

		CSprite@ head = this.getSprite();
		if (head !is null)
		{
			head.SetFrameIndex(state ? 0 : 1);
		}

		this.getSprite().PlaySound(state ? "Security_TurnOn" : "Security_TurnOff", 0.30f, 1.00f);
		this.set_bool("security_state", state);
	}
	else Turret_onCommand(this, cmd, params);
}

void Zap(CBlob@ this, CBlob@ target)
{
	if (this.get_u32("next zap") > getGameTime()) return;

	Vec2f dir = target.getPosition() - this.getPosition();
	f32 dist = Maths::Abs(dir.Length());
	dir.Normalize();

	SetKnocked(target, 60);
	this.set_u32("next zap", getGameTime() + delay);

	if (isServer())
	{
		this.server_Hit(target, target.getPosition(), Vec2f(0, 0), damage, HittersTC::electric, true);
		if (this.getTeamNum() != 3) this.sub_u16("ammoCount", Maths::Max(0, 5));
	}

	if (isClient())
	{
		bool flip = this.isFacingLeft();

		CSpriteLayer@ zap = this.getSprite().getSpriteLayer("zap");
		if (zap !is null)
		{
			zap.ResetTransform();
			zap.SetFrameIndex(0);
			zap.ScaleBy(Vec2f(dist / 128.0f - 0.1f, 1.0f));
			zap.TranslateBy(Vec2f((dist / 2), 2.0f));
			zap.RotateBy(-dir.Angle(), Vec2f());
			zap.SetVisible(true);
		}

		this.getSprite().PlaySound("Zapper_Zap" + XORRandom(3), 1.00f, 1.00f);
	}
}

void onDie(CBlob@ this)
{
	const u16 ammoCount = this.get_u16("ammoCount");
	if (ammoCount > 0 && isServer())
	{
		server_CreateBlob("mat_battery", -1, this.getPosition()).server_SetQuantity(ammoCount);
	}
}