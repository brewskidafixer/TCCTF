#include "RunnerCommon.as";
#include "Hitters.as";
#include "Knocked.as"
#include "FireCommon.as"
#include "Help.as"
#include "Survival_Structs.as";
#include "Logging.as";
#include "DeityCommon.as";

void onInit(CBlob@ this)
{
	this.getCurrentScript().removeIfTag = "dead";
	this.Tag("medium weight");

	//default player minimap dot - not for migrants
	if (this.getName() != "migrant")
	{
		this.SetMinimapVars("GUI/Minimap/MinimapIcons.png", 8, Vec2f(8, 8));
	}

	this.set_s16(burn_duration , 130);

	//fix for tiny chat font
	this.SetChatBubbleFont("hud");
	this.maxChatBubbleLines = 4;

	setKnockable(this);
	if (this.get_u8("deity_id") == Deity::mithrios)
	{
		CBlob@ altar = getBlobByName("altar_mithrios");
		if (altar !is null)
		{
			f32 power = altar.get_f32("deity_power");
			u8 light_intensity = u8(255.00f * Maths::Clamp(power / 500.00f, 0.00f, 1.00f));
			
			this.SetLight(true);
			this.SetLightRadius(128.00f * power / 25.0f);
			this.SetLightColor(SColor(255, light_intensity, 0, 0));
		}
	}
}

void onTick(CBlob@ this)
{
	DoKnockedUpdate(this);

	u8 deity_id = this.get_u8("deity_id");
	switch (deity_id)
	{
		case Deity::mithrios:
		{
			CBlob@ altar = getBlobByName("altar_mithrios");
			if (altar !is null)
			{
				f32 power = altar.get_f32("deity_power");
			
				RunnerMoveVars@ moveVars;
				if (this.get("moveVars", @moveVars))
				{
					moveVars.walkFactor *= 1.00f + Maths::Clamp(power * 0.0009f, 0.00f, 0.50f);
				}
			}
		}
		break;
	
		case Deity::ivan:
		{
			RunnerMoveVars@ moveVars;
			if (this.get("moveVars", @moveVars))
			{
				moveVars.walkFactor *= 1.20f;
				moveVars.jumpFactor *= 1.15f;
			}
		}
		break;
		
		case Deity::dragonfriend:
		{
			if (this.isKeyJustPressed(key_eat) && this.getTeamNum() < 7 && !(getKnocked(this) > 0 || this.get_f32("babbyed") > 0.00f))
			{
				if (getGameTime() >= this.get_u32("nextDragonFireball"))
				{
					CBlob@ altar = getBlobByName("altar_dragonfriend");
					if (altar !is null)
					{
						f32 power = altar.get_f32("deity_power");
						
						Vec2f vel = this.getAimPos() - this.getPosition();
						vel.Normalize();
						vel *= 13.00f;
						
						if (isServer())
						{
							CBlob@ fireball = server_CreateBlobNoInit("fireball");
							fireball.setPosition(this.getPosition());
							fireball.setVelocity(vel);
							fireball.server_setTeamNum(this.getTeamNum());
							fireball.set_f32("power", power);
							fireball.Init();
						}
						
						if (isClient())
						{
							this.getSprite().PlaySound("KegExplosion", 1.00f, 1.50f);
						}
						
						this.setVelocity(this.getVelocity() - (vel * 0.50f));
						
						
						u32 cooldown = (30 * 15);
						if (this.get_f32("fumes_effect") > 0.00f)
						{
							cooldown /= 5.00f;
						}
						
						this.set_u32("nextDragonFireball", getGameTime() + cooldown);
					}
				}
				else
				{
					if (this.isMyPlayer()) 
					{
						Sound::Play("/NoAmmo");
					}
				}
			}
		}
	}
}

void onSetPlayer(CBlob@ this, CPlayer@ player)
{
	if (isClient() && this.isMyPlayer())
	{
		CCamera@ cam = getCamera();
		cam.setRotation(0, 0, 0);
		
		if (isClient() && this.isMyPlayer()) 
		{
			if (getRules().get_bool("raining"))
			{
				getMap().CreateSkyGradient("skygradient_rain.png");
			}
			else
			{
				getMap().CreateSkyGradient("skygradient.png");	
			}
		}
		//print("reset camera");
	}
}

f32 onHit(CBlob@ this, Vec2f worldPoint, Vec2f velocity, f32 damage, CBlob@ hitterBlob, u8 customData)
{
	if ((customData == Hitters::suicide || customData == Hitters::nothing) && (getKnocked(this) > 0 || this.hasTag("no_suicide")))
	{
		return 0;
	}

	u8 deity_id = this.get_u8("deity_id");
	switch (deity_id)
	{
		case Deity::mithrios:
		{
			if (hitterBlob !is null && hitterBlob !is this)
			{
				CBlob@ altar = getBlobByName("altar_mithrios");
				if (altar !is null)
				{
					
					f32 ratio = Maths::Clamp(altar.get_f32("deity_power") * 0.0001f, 0.00f, 0.50f);
					f32 inv_ratio = 1.00f - ratio;

					damage *= inv_ratio;
				}
			}
		}
		break;

		case Deity::dragonfriend:
		{
			if ((customData == Hitters::fire || customData == Hitters::burn))
			{
				CBlob@ altar = getBlobByName("altar_dragonfriend");
				if (altar !is null)
				{
					f32 ratio = Maths::Clamp(altar.get_f32("deity_power") * 0.00001f, 0.00f, 1.00f);
					f32 inv_ratio = 1.00f - ratio;
					damage *= inv_ratio;
				}
			}
		}
		break;
	}

	return damage;
}

// pick up efffects
// something was picked up

void onAddToInventory(CBlob@ this, CBlob@ blob)
{
	this.getSprite().PlaySound("/PutInInventory.ogg");
}

void onAttach(CBlob@ this, CBlob@ attached, AttachmentPoint @attachedPoint)
{
	this.getSprite().PlaySound("/Pickup.ogg");

	if (attached !is null && isServer())
	{
		CPlayer@ player = this.getPlayer();
		if (player !is null)
		{
			tcpr("[PPU] " + player.getUsername() + " has picked up " + attached.getName());
		}
		else
		{
			tcpr("[BPU] " + this.getName() + " has picked up " + attached.getName());
		}
	}

	if (isClient())
	{
		RemoveHelps(this, "help throw");

		if (!attached.hasTag("activated"))
			SetHelp(this, "help throw", "", "$" + attached.getName() + "$" + "Throw    $KEY_C$", "", 2);
	}

	// check if we picked a player - don't just take him out of the box
	/*if (attached.hasTag("player"))
	this.server_DetachFrom( attached ); CRASHES*/
}

bool isDangerous(CBlob@ blob)
{
	return blob.hasTag("explosive") || blob.hasTag("weapon") || blob.hasTag("dangerous");
}

// set the Z back
void onDetach(CBlob@ this, CBlob@ detached, AttachmentPoint@ attachedPoint)
{
	if (detached !is null && isServer())
	{
		CPlayer@ player = this.getPlayer();
		if (player !is null)
		{
			tcpr("[PDI] " + player.getUsername() + " has dropped " + detached.getName());
		}
		else
		{
			tcpr("[BDI] " + this.getName() + " has dropped " + detached.getName());
		}
	}

	this.getSprite().SetZ(0.0f);
}

bool canBePickedUp(CBlob@ this, CBlob@ byBlob)
{
	return byBlob !is this && (this.hasTag("migrant") || this.hasTag("dead"));
}

bool isInventoryAccessible(CBlob@ this, CBlob@ forBlob)
{
	return (forBlob !is this) && ((getKnocked(this) > 0) || (this.get_f32("babbyed") > 0) || this.hasTag("dead") 
		|| ((this.isKeyPressed(key_down) || this.getPlayer() is null) && forBlob.getTeamNum() == this.getTeamNum()));
}
