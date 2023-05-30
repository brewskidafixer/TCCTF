// Princess brain

#include "BrainCommon.as"
#include "Hitters.as";
#include "Explosion.as";
#include "FireParticle.as"
#include "FireCommon.as";
//#include "LoaderUtilities.as";
#include "CustomBlocks.as";
#include "RunnerCommon.as";
#include "HittersTC.as";
#include "NightVision.as";

string[] particles = 
{
	"LargeSmoke",
	"Explosion.png",
	"LargeFire.png",
	"FireFlash.png",
};

void onInit( CBrain@ this )
{
	if (isServer())
	{
		InitBrain( this );
		this.server_SetActive( true ); // always running
	}
}

void onInit(CBlob@ this)
{
	this.set_u32("next sound", 0.0f);

	this.SetLight(true);
	this.SetLightRadius(32.0f);
	this.SetLightColor(SColor(255, 255, 20, 0));

	this.set_string("custom_explosion_sound", "MithrilBomb_Explode.ogg");
	this.set_string("custom name", this.getInventoryName());
	this.set_bool("map_damage_raycast", true);
	this.set_Vec2f("explosion_offset", Vec2f(0, 0));

	this.set_f32("bomb angle", 90);
	this.Tag("map_damage_dirt");
	this.Tag("auto_turret");
	this.Tag("canlink");

	this.set_u16("controller_blob_netid", 0);
	this.set_u16("controller_player_netid", 0);
	this.set_u16("remote_id", 0);

	this.addCommandID("offblast");
	this.addCommandID("link");
	this.addCommandID("resetplayer");
	this.addCommandID("explode");

	this.set_u32("nextAttack", 0);

	this.set_f32("minDistance", 96);
	this.set_f32("chaseDistance", 512);
	this.set_f32("maxDistance", 1200);

	this.set_f32("inaccuracy", 0.00f);
	this.set_u8("reactionTime", 0);
	this.set_u8("attackDelay", 0);

	this.set_bool("raider", true);

	this.SetDamageOwnerPlayer(null);

	this.Tag("npc");
	this.Tag("player");

	this.getCurrentScript().tickFrequency = 30;

	if (isClient())
	{
		this.getSprite().PlaySound("scyther-intro.ogg");
	}

	if (isServer())
	{
		CBlob@ ammo = server_CreateBlob("mat_mithril", this.getTeamNum(), this.getPosition());
		ammo.server_SetQuantity(250);
		this.server_PutInInventory(ammo);

		CBlob@ gun = server_CreateBlob("chargeblaster", this.getTeamNum(), this.getPosition());
		if(gun !is null)
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

void onTick(CBlob@ this)
{
	if (this.get_bool("offblast") && this.getHealth() <= 7.0f) // lost connection with scyther since low health
	{
		ResetPlayer(this);
		CBlob@ remote = getBlobByNetworkID(this.get_u16("remote_id"));
		if (remote !is null)
		{
			CBitStream params;
			params.write_u16(this.getNetworkID());
			remote.SendCommand(remote.getCommandID("unlink"), params);
		}
		return;
	}
	if (!this.hasTag("temp"))
	{
		nightVision(this);
		this.Tag("temp");
	}
	RunnerMoveVars@ moveVars;
	if (this.get("moveVars", @moveVars))
	{
		moveVars.walkFactor *= 0.90f;
		moveVars.jumpFactor *= 1.20f;
		moveVars.wallclimbing = true;
		moveVars.wallsliding = true;
	}

	if (isClient())
	{
		if (getGameTime() > this.get_u32("next sound"))
		{
			this.getSprite().PlaySound("/scyther-laugh" + XORRandom(2) + ".ogg");
			this.set_u32("next sound", getGameTime() + 100);
		}
	}
}

void onTick(CBrain@ this)
{
	if (!isServer()) return;

	CBlob@ blob = this.getBlob();

	if (blob.getPlayer() !is null) return;

	const f32 chaseDistance = blob.get_f32("chaseDistance");
	const f32 maxDistance = blob.get_f32("maxDistance");

	CBlob@ target = this.getTarget();

	// print("" + target.getConfig());

	if (target is null)
	{
		this.SetTarget(FindTarget(this, maxDistance));
		this.getCurrentScript().tickFrequency = 15;
	}
	
	if (target !is null && target !is blob)
	{
		// print("" + target.getConfig());

		this.getCurrentScript().tickFrequency = 1;

		// print("" + this.lowLevelMaxSteps);

		const f32 distance = (target.getPosition() - blob.getPosition()).Length();
		const f32 minDistance = blob.get_f32("minDistance");

		const bool visibleTarget = isVisible(blob, target);
		const bool stuck = this.getState() == 4;
		const bool target_attackable = target !is null && !(target.getTeamNum() == blob.getTeamNum() || target.hasTag("material"));
		const bool lose = distance > maxDistance;
		const bool chase = target_attackable && distance > minDistance;
		const bool retreat = !target_attackable || ((distance < minDistance) && visibleTarget);

		// print("" + stuck);

		if (lose)
		{
			this.SetTarget(null);
			this.getCurrentScript().tickFrequency = 15;
			return;
		}

		blob.setAimPos(target.getPosition());

		if (blob.get_u32("nextAttack") < getGameTime() && (stuck || (visibleTarget ? true : distance <= chaseDistance * 0.50f)))
		{
			blob.setKeyPressed(key_action1, true);
			blob.set_bool("should_do_attack_hack", true);
		}
		else
		{
			blob.setKeyPressed(key_action1, false);
		}

		if (target_attackable && chase)
		{
			if (blob.getTickSinceCreated() % 90 == 0) this.SetPathTo(target.getPosition(), false);
			// if (getGameTime() % 45 == 0) this.SetHighLevelPath(blob.getPosition(), target.getPosition());
			// Move(this, blob, this.getNextPathPosition());
			// print("chase")

			Vec2f dir = this.getNextPathPosition() - blob.getPosition();
			dir.Normalize();

			if (distance > 256)
			{
				Move(this, blob, blob.getPosition() + dir * 24);
			}
			else 
			{
				Move(this, blob, target.getPosition());
			}
		}
		else if (retreat)
		{
			DefaultRetreatBlob( blob, target );
		}

		// if (distance > chaseDistance)
		// {
			// this.SetTarget(FindTarget(this, maxDistance * 100.00f));
		// }

		if (target.hasTag("dead") || target.hasTag("weapon"))
		{
			CPlayer@ targetPlayer = target.getPlayer();

			this.SetTarget(null);
			this.getCurrentScript().tickFrequency = 30;
			return;
		}
	}
	else
	{
		if (XORRandom(2) == 0) RandomTurn(blob);
	}

	FloatInWater(blob); 
} 

CBlob@ FindTarget(CBrain@ this, f32 maxDistance)
{
	CBlob@ blob = this.getBlob();
	const Vec2f pos = blob.getPosition();

	CBlob@[] blobs;
	// getMap().getBlobsInRadius(blob.getPosition(), maxDistance, @blobs);

	getBlobsByTag("flesh", @blobs);
	getBlobsByTag("auto_turret", @blobs);
	const u8 myTeam = blob.getTeamNum();

	f32 distance = maxDistance;
	u16 net_id = 0;

	for (int i = 0; i < blobs.length; i++)
	{
		CBlob@ b = blobs[i];
		Vec2f bp = b.getPosition() - pos;
		f32 d = bp.Length();

		if (d < distance && b.getTeamNum() != myTeam && !b.hasTag("dead") && !b.hasTag("passive") && !b.hasTag("invincible"))
		{
			distance = d;
			net_id = b.getNetworkID();
		}
	}

	return getBlobByNetworkID(net_id);
}

void Move(CBrain@ this, CBlob@ blob, Vec2f pos)
{
	Vec2f dir =  blob.getPosition() - pos;
	dir.Normalize();

	// print("DIR: x: " + dir.x + "; y: " + dir.y);

	blob.setKeyPressed(key_left, dir.x > 0);
	blob.setKeyPressed(key_right, dir.x < 0);
	blob.setKeyPressed(key_up, dir.y > 0);
	blob.setKeyPressed(key_down, dir.y < 0);
}

f32 onHit(CBlob@ this, Vec2f worldPoint, Vec2f velocity, f32 damage, CBlob@ hitterBlob, u8 customData)
{
	switch (customData)
	{
		case Hitters::stab:
		case Hitters::sword:
		case Hitters::fall:
			damage *= 0.50f;
			break;

		case Hitters::arrow:
			damage *= 0.45f; 
			break;

		case Hitters::burn:
		case Hitters::fire:
		case HittersTC::radiation:
			damage = 0.00f;
			break;

		case HittersTC::electric:
			damage = 5.00f;
			break;
	}

	if (isClient())
	{
		if (getGameTime() > this.get_u32("next sound") - 50)
		{
			this.getSprite().PlaySound("/scyther-screech" + XORRandom(7) + ".ogg");
			this.set_u32("next sound", getGameTime() + 100);
		}
	}

	if (isServer())
	{
		CBrain@ brain = this.getBrain();

		if (brain !is null && hitterBlob !is null)
		{
			if (hitterBlob.getTeamNum() != this.getTeamNum())
			{
				if (hitterBlob.hasTag("weapon"))
				{
					AttachmentPoint@ point = hitterBlob.getAttachments().getAttachmentPointByName("PICKUP");
					if (point !is null)
					{
						CBlob@ holder = point.getOccupied();
						if (holder !is null) brain.SetTarget(holder);
					}
				}
				else brain.SetTarget(hitterBlob);
			}
		}
	}

	return damage;
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
	CRules@ rules = getRules();
	if (!shouldExplode(this, rules))
	{
		addToNextTick(this, rules, DoExplosion);
		return;
	}

	if (!this.hasTag("exploded"))
	{
		DoExplosion(this);
	}

	if (isServer())
	{
		for (int i = 0; i < 3; i++)
		{
			CBlob@ gib = server_CreateBlob("scythergib", this.getTeamNum(), this.getPosition());

			switch(i)
			{
				case 0: 
					gib.getSprite().SetAnimation("head");
					break;

				case 1: 
					gib.getSprite().SetAnimation("blade");
					break;

				case 2: 
					gib.getSprite().SetAnimation("torso");
					break;

				default:
					gib.getSprite().SetAnimation("misc");
					break;
			}
		}

		for (int i = 0; i < 3; i++)
		{
			CBlob@ plasteel = server_CreateBlob("mat_plasteel", this.getTeamNum(), this.getPosition());
			plasteel.server_SetQuantity(10 + XORRandom(3));
		}
	}
	if (isClient() && this.isMyPlayer()) getMap().CreateSkyGradient("skygradient.png");
}

void DoExplosion(CBlob@ this)
{
	this.Tag("exploded");

	f32 random = XORRandom(16);
	f32 modifier = 1 + Maths::Log(this.getQuantity());
	f32 angle = -this.get_f32("bomb angle");
	f32 vellen = this.getVelocity().Length();

	// print("Modifier: " + modifier + "; Quantity: " + this.getQuantity());

	this.set_f32("map_damage_radius", (64.0f + random) * modifier);
	this.set_f32("map_damage_ratio", 0.25f);

	Explode(this, 64.0f + random, 100.0f);

	Vec2f pos = this.getPosition();
	CMap@ map = getMap();

	if (isServer())
	{
		for (int i = 0; i < 5; i++)
		{
			CBlob@ blob = server_CreateBlob("mat_mithril", this.getTeamNum(), this.getPosition());
			blob.server_SetQuantity(25 + XORRandom(40));
			blob.setVelocity(Vec2f(4 - XORRandom(8), -2 - XORRandom(5)) * (0.5f));
		}
	}
}

void ResetPlayer(CBlob@ this)
{
	CPlayer@ ply = getPlayerByNetworkId(this.get_u16("controller_player_netid"));
	CBlob@ blob = getBlobByNetworkID(this.get_u16("controller_blob_netid"));
	if (blob !is null && ply !is null && !blob.hasTag("dead"))
	{
		this.set_bool("offblast", false);
		this.set_u16("controller_blob_netid", 0);
		this.set_u16("controller_player_netid", 0);

		if (isServer()) blob.server_SetPlayer(ply);
	}
	else if (isServer()) this.server_Die();
}

void MakeParticle(CBlob@ this, const Vec2f pos, const Vec2f vel, const string filename = "SmallSteam")
{
	ParticleAnimated(filename, this.getPosition() + pos, vel, float(XORRandom(360)), 1.8f + XORRandom(100) * 0.01f, 2 + XORRandom(6), XORRandom(100) * -0.00005f, true);
}

void onCreateInventoryMenu(CBlob@ this, CBlob@ forBlob, CGridMenu @gridmenu)
{
	if (!this.isMyPlayer()) return;
	Vec2f ul = gridmenu.getUpperLeftPosition();
	Vec2f lr = gridmenu.getLowerRightPosition();

	this.ClearGridMenusExceptInventory();
	const int inv_posx = this.getInventory().getInventorySlots().x;
	const int inv_posy = this.getInventory().getInventorySlots().y;
	Vec2f pos = Vec2f(lr.x, ul.y) + Vec2f(-24*inv_posx, 66*inv_posy);

	CGridMenu@ menu = CreateGridMenu(pos, this, Vec2f(inv_posx, 1), "Functions");

	this.set_Vec2f("InventoryPos",pos);

	AddIconToken("$explode$", "SmallExplosion1.png", Vec2f(24, 20), 1);
	AddIconToken("$controller_icon$", "EngineerMale.png", Vec2f(32, 28), 0);

	if (menu !is null)
	{
		menu.deleteAfterClick = true;

		{
			CGridButton@ button = menu.AddButton("$controller_icon$", "Exit Control", this.getCommandID("resetplayer"), Vec2f(1, 1));
			if (button !is null)
			{
				button.SetEnabled(!this.hasTag("canlink"));
				button.selectOneOnClick = false;
			}
		}
		{
			CGridButton@ button = menu.AddButton("$explode$", "Explode", this.getCommandID("explode"));
			if (button !is null)
			{
				button.SetEnabled(true);
				button.selectOneOnClick = false;
			}
		}
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
		if (ply is null || caller is null) return;

		this.set_bool("offblast", true);
		this.set_u16("controller_blob_netid", caller_netid);
		this.set_u16("controller_player_netid", player_netid);

		if (isServer())
		{
			this.server_SetPlayer(ply);
		}

		if (isClient() && ply.isMyPlayer()) this.getSprite().PlaySound("scyther-intro.ogg");
		this.getCurrentScript().tickFrequency = 1;
	}
	else if (cmd == this.getCommandID("resetplayer"))
	{
		ResetPlayer(this);
	}
	else if (cmd == this.getCommandID("explode"))
	{
		if (isServer())
		{
			this.server_Die();
			ResetPlayer(this);
		}
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
