// Flesh hit

#include "Hitters.as";
#include "HittersTC.as";

void onInit(CBlob@ this)
{
	this.Tag("flesh");
}

f32 getGibHealth(CBlob@ this)
{
	if (this.exists("gib health"))
	{
		return this.get_f32("gib health");
	}

	return 0.0f;
}

f32 onHit(CBlob@ this, Vec2f worldPoint, Vec2f velocity, f32 damage, CBlob@ hitterBlob, u8 customData)
{
	f32 dmg = damage;

	switch (customData)
	{
		// TC		
		case HittersTC::bullet_low_cal:
		case HittersTC::bullet_high_cal:
		case HittersTC::shotgun:
			dmg *= 0.60f;
			break;
			
		case HittersTC::radiation:
			// dmg = Maths::Max((dmg * 2.00f) * (this.get_u8("radpilled") * 0.10f), 0);
			dmg *= 1.00f / (1.00f + this.get_u8("radpilled") * 10.00f);
			break;
		// Vanilla
		case Hitters::builder:
			dmg *= 1.75f;
			break;

		case HittersTC::electric:
			return dmg;
			break;

		case Hitters::spikes:
		case Hitters::sword:
		case Hitters::arrow:
		case Hitters::stab:
		case Hitters::drill:
			dmg *= 1.25f;
			break;

		case Hitters::bomb_arrow:
		case Hitters::bomb:
			dmg *= 1.50f;
			break;

		case Hitters::keg:
		case Hitters::explosion:
		case Hitters::crush:
			dmg *= 2.00f;
			break;

		case Hitters::cata_stones:
		case Hitters::flying: // boat ram
			dmg *= 4.00f;
			break;
		
		case Hitters::fire:
		case Hitters::burn:
			dmg *= 2.00f;
			break;

	}

	if (isServer())
	{
		if (customData == HittersTC::radiation)
		{
			if (this.hasTag("human") && !this.hasTag("transformed") && this.getHealth() <= 0.125f && XORRandom(2) == 0)
			{
				CBlob@ man = server_CreateBlob("mithrilman", this.getTeamNum(), this.getPosition());
				if (this.getPlayer() !is null) man.server_SetPlayer(this.getPlayer());
				this.Tag("transformed");
				this.server_Die();
			}
		}
	}
	
	if (this.hasTag("equipment support"))
	{
		/*
		const bool isBullet = (
			customData == HittersTC::bullet_low_cal || customData == HittersTC::bullet_high_cal || 
			customData == HittersTC::shotgun || customData == HittersTC::railgun_lance);
		*/
		string headname = this.get_string("equipment_head");
		string torsoname = this.get_string("equipment_torso");
		string bootsname = this.get_string("equipment_boots");
		
		if (headname != "" && this.exists(headname+"_health"))
		{
			f32 armorMaxHealth = 25.0f;
			f32 ratio = 0.0f;

			if (headname == "militaryhelmet") armorMaxHealth = 25.0f;
			else if (headname == "mediumhelmet") armorMaxHealth = 40.0f;
			else if (headname == "heavyhelmet") armorMaxHealth = 70.0f;
			else if (headname == "scubagear") armorMaxHealth = 10.0f;
			else if (headname == "bucket") armorMaxHealth = 10.0f;
			else if (headname == "pumpkin") armorMaxHealth = 5.0f;
			else if (headname == "minershelmet") armorMaxHealth = 10.0f;

			if (headname == "lighthelmet")
			{
				switch (customData)
				{
					case HittersTC::bullet_low_cal:
					case HittersTC::shotgun:
						ratio = 0.60f;
						break;

					case HittersTC::bullet_high_cal:
					case HittersTC::railgun_lance:
						ratio = 0.40f;
						break;

					default:
						ratio = 0.10f;
						break;
				}
			}
			else if (headname == "mediumhelmet")
			{
				switch (customData)
				{
					case HittersTC::bullet_low_cal:
					case HittersTC::shotgun:
						ratio = 0.70f;
						break;

					case HittersTC::bullet_high_cal:
					case HittersTC::railgun_lance:
						ratio = 0.65f;
						break;

					default:
						ratio = 0.20f;
						break;
				}
			}
			else if (headname == "heavyhelmet")
			{
				switch (customData)
				{
					case HittersTC::bullet_low_cal:
					case HittersTC::shotgun:
						ratio = 0.80f;
						break;

					case HittersTC::bullet_high_cal:
					case HittersTC::railgun_lance:
						ratio = 0.75f;
						break;

					default:
						ratio = 0.30f;
						break;
				}
			}
			else if (headname == "scubagear" || headname == "bucket" || headname == "pumpkin" || headname == "minershelmet")
				ratio = 0.30f;
					
			f32 armorHealth = armorMaxHealth - this.get_f32(headname+"_health");
			ratio *= armorHealth / armorMaxHealth;

			this.add_f32(headname+"_health", (ratio*dmg));
			f32 playerDamage = Maths::Clamp((1.00f - ratio) * dmg, 0, dmg);
			dmg = playerDamage;
		}
		if (torsoname != "" && this.exists(torsoname+"_health"))
		{
			f32 armorMaxHealth = 30.0f;
			f32 ratio = 0.0f;

			if (torsoname == "lightvest") armorMaxHealth = 30.0f;
			else if (torsoname == "mediumvest") armorMaxHealth = 60.0f;
			else if (torsoname == "heavyvest") armorMaxHealth = 100.0f;
			else if (torsoname == "keg") armorMaxHealth = 10.0f;

			if (torsoname == "lightvest")
			{
				switch (customData)
				{
					case HittersTC::bullet_low_cal:
					case HittersTC::shotgun:
						ratio = 0.60f;
						break;

					case HittersTC::bullet_high_cal:
					case HittersTC::railgun_lance:
						ratio = 0.40f;
						break;

					default:
						ratio = 0.20f;
						break;
				}
			}
			else if (torsoname == "mediumvest")
			{
				switch (customData)
				{
					case HittersTC::bullet_low_cal:
					case HittersTC::shotgun:
						ratio = 0.80f;
						break;

					case HittersTC::bullet_high_cal:
					case HittersTC::railgun_lance:
						ratio = 0.70f;
						break;

					default:
						ratio = 0.30f;
						break;
				}
			}
			else if (torsoname == "heavyvest")
			{
				switch (customData)
				{
					case HittersTC::bullet_low_cal:
					case HittersTC::shotgun:
						ratio = 0.90f;
						break;

					case HittersTC::bullet_high_cal:
					case HittersTC::railgun_lance:
						ratio = 0.80f;
						break;

					default:
						ratio = 0.40f;
						break;
				}
			}
			else if (torsoname == "keg")
			{
				ratio = 0.60f;
			}
			f32 armorHealth = armorMaxHealth - this.get_f32(torsoname+"_health");
			ratio *= armorHealth / armorMaxHealth;

			this.add_f32(torsoname+"_health", (ratio*dmg));
			f32 playerDamage = Maths::Clamp((1.00f - ratio) * dmg, 0, dmg);
			dmg = playerDamage;
		}

		if (bootsname != "" && this.exists(bootsname+"_health"))
		{
			f32 armorMaxHealth = 10.0f;
			f32 ratio = 0.0f;
			if (bootsname == "combatboots") armorMaxHealth = 10.0f;
			if (bootsname == "combatboots")
			{
				switch (customData)
				{
					case Hitters::fall:
						ratio = 0.30f;
						break;

					default: 
						ratio = 0.10f;
						break;
				}
			}
			f32 armorHealth = armorMaxHealth - this.get_f32(bootsname+"_health");
			ratio *= armorHealth / armorMaxHealth;

			this.add_f32(bootsname+"_health", (ratio*dmg));
			f32 playerDamage = Maths::Clamp((1.00f - ratio) * dmg, 0, dmg);
			dmg = playerDamage;
		}
	}
	
	// if (this.get_f32("crak_effect") > 0) dmg *= 0.30f;
	
	this.Damage(dmg, hitterBlob);

	f32 gibHealth = getGibHealth(this);

	if (this.getHealth() <= gibHealth)
	{
		this.getSprite().Gib();
		this.Tag("do gib");
		
		this.server_Die();
	}

	return 0.0f; //done, we've used all the damage
}

void onDie(CBlob@ this)
{
	if (this.hasTag("do gib"))
	{
		//int frac = Maths::Min(1000, this.getMass()) * 0.50f;
		int frac = (this.getMass()* Maths::Max(1,this.getQuantity())) * 0.50f;
		f32 radius = this.getRadius();
		f32 explodium_amount = this.get_f32("propeskoed") * 0.50f;
	
		if (isServer())
		{
			Vec2f vel = Vec2f(XORRandom(4) - 2, -2 - XORRandom(4));
			
			if (explodium_amount > 0.00f)
			{
				CBlob@ blob = server_CreateBlob("mat_dangerousmeat", this.getTeamNum(), this.getPosition());
				blob.server_SetQuantity(1 + ((frac * 0.40f + XORRandom(frac)) * 0.2f));
				//blob.setVelocity(vel);
			}
			else
			{
				CBlob@ blob = server_CreateBlob("mat_meat", this.getTeamNum(), this.getPosition());

				if (blob !is null)
				{
					blob.server_SetQuantity(1 + (frac * 0.25f + XORRandom(frac)));
						
					blob.setVelocity(vel);
				}
			}
		}
	}
}
