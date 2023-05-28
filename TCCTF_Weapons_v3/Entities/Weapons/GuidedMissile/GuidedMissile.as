#include "Hitters.as";
#include "Explosion.as";

string[] particles = 
{
	"LargeSmoke",
	"Explosion.png"
};

const u32 fuel_timer_max = 30 * 4.5f;

void onInit(CBlob@ this)
{
	this.Tag("explosive");
	this.Tag("heavy weight");
	this.Tag("canlink");

	this.addCommandID("offblast");
	this.addCommandID("link");

	this.set_u32("no_explosion_timer", 0);
	this.set_u32("fuel_timer", 0);
	this.set_f32("velocity", 0.0f);
	this.set_f32("max_velocity", 18.0f);
	this.set_string("custom name", this.getInventoryName());

	this.set_u16("controller_blob_netid", 0);
	this.set_u16("controller_player_netid", 0);
	this.set_u16("remote_id", 0);

	this.getShape().SetRotationsAllowed(true);

	this.getCurrentScript().tickFrequency = 0;
}

void onTick(CBlob@ this)
{
	if (this.hasTag("offblast"))
	{
		AttachmentPoint@ point = this.getAttachments().getAttachmentPointByName("PICKUP");
		if (point !is null && point.getOccupied() !is null)
		{
			this.server_DetachFromAll();
		}

		Vec2f dir;

		if (this.get_u32("fuel_timer") > getGameTime())
		{
			CPlayer@ controller = this.getPlayer();
			this.set_f32("velocity", Maths::Min(this.get_f32("velocity") + 0.3f, this.get_f32("max_velocity")));

			CBlob@ blob = getBlobByNetworkID(this.get_u16("controller_blob_netid"));
			bool isControlled = blob !is null && !blob.hasTag("dead");

			if (!isControlled || controller is null || this.get_f32("velocity") < this.get_f32("max_velocity") * 0.75f)
			{
				dir = Vec2f(0, 1);
				dir.RotateBy(this.getAngleDegrees());
			}
			else
			{
				dir = (this.getPosition() - this.getAimPos());
				dir.Normalize();
			}

			// print(this.getAimPos().x + " " + this.getAimPos().y);

			const f32 ratio = 0.10f;

			Vec2f nDir = (this.get_Vec2f("direction") * (1.00f - ratio)) + (dir * ratio);
			nDir.Normalize();

			//this.SetFacingLeft(false); //causes bugs with sprite for some odd reason

			this.set_f32("velocity", Maths::Min(this.get_f32("velocity") + 0.75f, 20.0f));
			this.set_Vec2f("direction", nDir);

			this.setAngleDegrees(-nDir.getAngleDegrees() + 90 + 180);
			this.setVelocity(-nDir * this.get_f32("velocity"));

			if (isClient())
			{
				if (!v_fastrender) MakeParticle(this, -dir, XORRandom(100) < 30 ? ("SmallSmoke" + (1 + XORRandom(2))) : "SmallExplosion" + (1 + XORRandom(3)));
			}
		}
		else
		{
			this.setAngleDegrees(-this.getVelocity().Angle() + 90);
			//this.getSprite().SetEmitSoundPaused(true);

			if(isClient())
			{
				CSprite@ sprite = this.getSprite();
				f32 modifier = Maths::Max(0, this.getVelocity().y * 0.04f);
				sprite.SetEmitSound("Shell_Whistle.ogg");
				sprite.SetEmitSoundPaused(false);
				sprite.SetEmitSoundVolume(Maths::Max(0, modifier));
			}
		}

		if (this.isKeyJustPressed(key_action3) || this.getHealth() <= 0.0f)
		{
			if (isServer())
			{
				ResetPlayer(this);
				return;
			}
		}
	}
}

bool doesCollideWithBlob( CBlob@ this, CBlob@ blob )
{
	return blob.getTeamNum() != this.getTeamNum(); // && blob.isCollidable();
}

void MakeParticle(CBlob@ this, const Vec2f vel, const string filename = "SmallSteam")
{
	if (!isClient()) return;

	Vec2f offset = Vec2f(0, 16).RotateBy(this.getAngleDegrees());
	ParticleAnimated(filename, this.getPosition() + offset, vel, float(XORRandom(360)), 1.0f, 2 + XORRandom(3), -0.1f, false);
}

void DoExplosion(CBlob@ this)
{
	CRules@ rules = getRules();
	if (!shouldExplode(this, rules))
	{
		addToNextTick(this, rules, DoExplosion);
		return;
	}

	if (this.hasTag("dead")) return;

	f32 random = XORRandom(16);
	f32 modifier = 1 + Maths::Log(this.getQuantity());
	f32 angle = -this.get_f32("bomb angle");
	// print("Modifier: " + modifier + "; Quantity: " + this.getQuantity());

	this.set_f32("map_damage_radius", (40.0f + random) * modifier);
	this.set_f32("map_damage_ratio", 0.25f);

	Explode(this, 30.0f + random, 16.0f);

	for (int i = 0; i < 4 * modifier; i++) 
	{
		Vec2f dir = getRandomVelocity(angle, 1, 120);
		dir.x *= 2;
		dir.Normalize();

		LinearExplosion(this, dir, 8.0f + XORRandom(16) + (modifier * 8), 8 + XORRandom(24), 3, 0.125f, Hitters::explosion);
	}

	if (isServer())
	{
		Vec2f pos = this.getPosition();
		CMap@ map = getMap();
		for (int i = 0; i < 3; i++)
		{
			CBlob@ blob = server_CreateBlob("flame", -1, pos);
			blob.setVelocity(Vec2f(XORRandom(10) - 5, -XORRandom(5)-2));
			blob.server_SetTimeToDie(10 + XORRandom(5));
		}
		
		for (int i = 0; i < 20; i++)
		{
			map.server_setFireWorldspace(pos + Vec2f(8 - XORRandom(16), 8 - XORRandom(16)) * 8, true);
		}
	}

	if(isClient())
	{
		Vec2f pos = this.getPosition();
		CMap@ map = getMap();

		this.Tag("dead");
		this.getSprite().Gib();
	}
}

void onDie(CBlob@ this)
{
	CBlob@ remote = getBlobByNetworkID(this.get_u16("remote_id"));
	if (remote !is null)
	{
		CBitStream params;
		params.write_u16(this.getNetworkID());
		remote.SendCommand(remote.getCommandID("unlink"), params);
	}
	// if (this.hasTag("offblast")) DoExplosion(this, Vec2f(0, 0));
	DoExplosion(this);
}

void onCollision(CBlob@ this, CBlob@ blob, bool solid)
{
	if (isServer())
	{
		if ((blob !is null ? !blob.isCollidable() : !solid)) return;
		if (this.hasTag("offblast") && this.get_u32("no_explosion_timer") < getGameTime()) 
		{
			ResetPlayer(this);
		}
	}
}

void ResetPlayer(CBlob@ this)
{
	this.getCurrentScript().tickFrequency = 0;
	if (isServer())
	{
		CPlayer@ ply = getPlayerByNetworkId(this.get_u16("controller_player_netid"));
		CBlob@ blob = getBlobByNetworkID(this.get_u16("controller_blob_netid"));
		if (blob !is null && ply !is null && !blob.hasTag("dead"))
		{
			blob.server_SetPlayer(ply);
		}

		this.server_Die();
	}
}

void GetButtonsFor(CBlob@ this, CBlob@ caller)
{
	if (this.hasTag("offblast") || this.isAttachedTo(caller)) return;
	if (!this.hasTag("canlink")) return;

	CPlayer@ ply = caller.getPlayer();
	if (ply !is null && (caller.getPosition() - this.getPosition()).Length() <= 24)
	{
		CBitStream params;
		params.write_u16(caller.getNetworkID());
		params.write_u16(ply.getNetworkID());

		caller.CreateGenericButton(11, Vec2f(0.0f, -5.0f), this, this.getCommandID("offblast"), "Off blast!", params);
	}
}

void onCommand(CBlob@ this, u8 cmd, CBitStream@ params)
{
	if (cmd == this.getCommandID("offblast"))
	{
		const u16 caller_netid = params.read_u16();
		const u16 player_netid = params.read_u16();

		CBlob@ caller = getBlobByNetworkID(caller_netid);
		CPlayer@ ply = getPlayerByNetworkId(player_netid);

		if (this.hasTag("offblast")) return;

		this.Tag("aerial");
		this.Tag("projectile");
		this.Tag("offblast");

		this.set_u32("no_explosion_timer", getGameTime() + 10);
		this.set_u32("fuel_timer", getGameTime() + fuel_timer_max);

		this.set_u16("controller_blob_netid", caller_netid);
		this.set_u16("controller_player_netid", player_netid);

		if (isServer() && ply !is null && caller !is null)
		{
			this.server_SetPlayer(ply);
		}

		if (isClient())
		{
			CSprite@ sprite = this.getSprite();
			sprite.SetEmitSound("CruiseMissile_Loop.ogg");
			sprite.SetEmitSoundSpeed(1.0f);
			sprite.SetEmitSoundVolume(0.3f);
			sprite.SetEmitSoundPaused(false);
			sprite.PlaySound("CruiseMissile_Launch.ogg", 2.00f, 1.00f);

			this.SetLight(true);
			this.SetLightRadius(128.0f);
			this.SetLightColor(SColor(255, 255, 100, 0));
		}
		this.getCurrentScript().tickFrequency = 1;
	}
	else if (cmd == this.getCommandID("link"))
	{
		u16 remote;
		if (params.saferead_netid(remote))
		{
			CBlob@ remoteBlob = getBlobByNetworkID(remote);
			if (remoteBlob is null) return;
			this.set_u16("remote_id", remote);
			this.Untag("canlink");
			if (isServer())
			{
				CBitStream stream;
				stream.write_u16(this.getNetworkID());
				remoteBlob.SendCommand(remoteBlob.getCommandID("link"), stream);
			}
		}
	}
}

bool canBePickedUp(CBlob@ this, CBlob@ byBlob)
{
	return !this.hasTag("offblast");
}
