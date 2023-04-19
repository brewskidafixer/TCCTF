#include "Hitters.as";
#include "Explosion.as";

const Vec2f arm_offset = Vec2f(-2, -4);

// const u8 explosions_max = 25;

f32 sound_delay;

string[] particles = 
{
	"LargeSmoke",
	"Explosion.png",
	"LargeFire.png",
	"FireFlash.png",
};

void onInit(CBlob@ this)
{
	this.Tag("map_damage_dirt");
	this.getShape().SetStatic(true);
	this.set_f32("map_damage_ratio", 0.125f);

	if (!this.exists("boom_frequency")) this.set_u8("boom_frequency", 3);
	if (!this.exists("boom_start")) this.set_u8("boom_start", 0);
	if (!this.exists("boom_end")) this.set_u8("boom_end", 20);
	if (!this.exists("boom_delay")) this.set_u32("boom_delay", 9);
	if (!this.exists("flash_delay")) this.set_u32("flash_delay", 0);
	if (!this.exists("mithril_amount")) this.set_f32("mithril_amount", 150);
	if (!this.exists("flash_distance")) this.set_f32("flash_distance", 2500);
	if (!this.exists("custom_explosion_sound")) this.set_string("custom_explosion_sound", "Nuke_Kaboom");

	if (isClient())
	{
		Vec2f pos = getDriver().getWorldPosFromScreenPos(getDriver().getScreenCenterPos());
		f32 distance = Maths::Abs(this.getPosition().x - pos.x) / 8;
		sound_delay = (Maths::Abs(this.getPosition().x - pos.x) / 8) / (340 * 0.4f);
	}
}

void DoExplosion(CBlob@ this)
{
	CRules@ rules = getRules();
	if (!shouldExplode(this, rules))
	{
		addToNextTick(this, rules, DoExplosion);
		return;
	}
	// SetScreenFlash(255 * (1.00f - (f32(this.get_u8("boom_start")) / f32(explosions_max))), 255, 255, 255);

	const f32 modifier = f32(this.get_u8("boom_start")) / f32(this.get_u8("boom_end"));
	const f32 invModifier = 1.00f - modifier;

	this.set_f32("map_damage_radius", 256.0f * modifier);

	this.set_Vec2f("explosion_offset", Vec2f(0, 0));
	Explode(this, 144.0f * modifier, 144.0f * (1.00f - modifier));

	if (!this.hasTag("no side blast"))
	{
		for (int i = 0; i < 2; i++)
		{
			this.set_Vec2f("explosion_offset", Vec2f((100 - XORRandom(200)) / 50.0f, (100 - XORRandom(200)) / 400.0f) * 128 * modifier);
			Explode(this, 128.0f * modifier, 64.0f * (1 - modifier));
		}
	}

	if (isServer())
	{
		if (!this.hasTag("no fallout") && XORRandom(100) < 75 * (invModifier * invModifier))
		{
			CBlob@ blob = server_CreateBlob("falloutgas", this.getTeamNum(), this.getPosition());
			// blob.setVelocity(Vec2f(30 - XORRandom(120), -10 - XORRandom(20)) * (0.5f + modifier));
			blob.setPosition(this.getPosition() + Vec2f(128 - XORRandom(256), 50 - XORRandom(100)) * (0.75f + modifier));
		}
	}
}

void onTick(CBlob@ this)
{
	if (this.get_u8("boom_start") == this.get_u8("boom_end")) 
	{
		if (isServer()) this.server_Die();
		this.Tag("dead");

		return;
	}

	if (this.hasTag("dead")) return;

	u32 ticks = this.getTickSinceCreated();

	if (ticks >= this.get_u32("boom_delay") && ticks % this.get_u8("boom_frequency") == 0 && this.get_u8("boom_start") < this.get_u8("boom_end"))
	{
		DoExplosion(this);
		this.set_u8("boom_start", this.get_u8("boom_start") + 1);

		// f32 modifier = 1.00f - (float(this.get_u8("boom_start")) / float(this.get_u8("boom_end")));
		// this.SetLightRadius(1024.5f * modifier);
	}

	if (isClient())
	{
		if (ticks > (sound_delay * 30) && !this.hasTag("sound_played"))
		{
			this.Tag("sound_played");

			f32 modifier = 1.00f - (sound_delay / 3.0f);
			// print("modifier: " + modifier);
			
			if (modifier > 0.01f && !this.hasTag("no_sound"))
			{
				Sound::Play(this.get_string("custom_explosion_sound"), this.getPosition(), 1.25f, modifier);
			}
		}
	}
}

void MakeParticle(CBlob@ this, const Vec2f pos, const Vec2f vel, const f32 time, const string filename = "SmallSteam")
{
	ParticleAnimated(filename, this.getPosition() + pos, vel, float(XORRandom(360)), 2.8f + XORRandom(100) * 0.01f, time, XORRandom(100) * -0.00005f, true);
}
