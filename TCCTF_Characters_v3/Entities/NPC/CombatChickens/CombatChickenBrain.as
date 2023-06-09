#include "BrainCommon.as"
#include "Hitters.as";
#include "RunnerCommon.as";
#include "DeityCommon.as";
#include "Knocked.as";

const f32 cursor_lerp_speed = 0.50f;

void onInit(CBrain@ this)
{
	if (isServer())
	{
		InitBrain( this );
		this.server_SetActive( true ); // always running
		
		CBlob@ blob = this.getBlob();
		
		blob.set_u32("next_repath", 0);
		blob.set_u32("next_search", 0);
		// blob.set_bool("awaiting_repath", true);
		
		// this.failtime_end = 15;
		this.plannerSearchSteps = 25;
		this.lowLevelSteps = 25;
	}
}

void onTick(CBrain@ this)
{
	if (!isServer()) return;
	
	CBlob@ blob = this.getBlob();
	if (getKnocked(blob) > 0) return;
	
	if (blob.getPlayer() !is null) return;
	
	// SearchTarget(this, false, true);
	
	CBlob@ target = this.getTarget();
	
	const f32 chaseDistance = blob.get_f32("chaseDistance");
	
	const u32 next_repath = blob.get_u32("next_repath");
	const u32 next_search = blob.get_u32("next_search");
	const bool has_path = this.getHighPathSize() > 0;
	
	const bool can_repath = getGameTime() >= next_repath;
	const bool can_search = getGameTime() >= next_search && target is null;
	const f32 maxDistance = blob.get_f32("maxDistance");

	bool stuck = false;
	
	if (this.getState() == 4)
	{
		blob.set_bool("stuck", true);
		stuck = true;
	}
	else
	{
		stuck = false;
	}
	
	// print("" + (target == null));
	
	// print("" + stuck);
	
	// print("" + this.getCurrentScript().tickFrequency);
	
	// this.failtime_end = 15;
	// this.plannerSearchSteps = 25;
	// this.lowLevelSteps = 25;
	
	
	
	// CBlob@ t = getLocalPlayerBlob();
	// CBlob@ t = getBlobByName("camp");
	// if (t !is null && getGameTime() % 30 == 0) 
	// {	
		// this.SetHighLevelPath(blob.getPosition(), t.getPosition());
		// // this.SetLowLevelPath(blob.getPosition(), t.getPosition());
		// // this.SetPathTo(t.getPosition(), false);
	// }
	
	// print("" + this.plannerSearchSteps);
	
	// print("" + next_search + "; " + getGameTime());
	
	if (target is null)
	{
		const bool raider = blob.get_bool("raider");
		const Vec2f pos = blob.getPosition();
	
		if (can_search)
		{
			this.getCurrentScript().tickFrequency = 30;
			
			// print("search");
			
			CBlob@[] blobs;
			getMap().getBlobsInRadius(blob.getPosition(), chaseDistance, @blobs);
			
			// getBlobsByTag("human", @blobs);
			const u8 myTeam = blob.getTeamNum();
			int hold = 0;
			int totalTargets = blobs.length;
			bool targetFound = false;
			f32 closestDistance = chaseDistance;
			for (int i = 0; i < totalTargets; i++)
			{
				CBlob@ b = blobs[i];
				f32 d = blob.getDistanceTo(b);
				if (b.getTeamNum() != myTeam && d <= chaseDistance && !b.hasTag("dead") && 
					(b.hasTag("flesh") || b.hasTag("auto_turret")) && !b.hasTag("passive") && 
					!b.hasTag("invincible") && (isVisible(blob, b) || d < 48))
				{
					if (d > closestDistance) continue;
					closestDistance = d;
					targetFound = true;
					hold = i;
				}
			}
			if (targetFound)
			{
				this.SetTarget(blobs[hold]);
				blob.set_u32("nextAttack", getGameTime() + blob.get_u8("reactionTime"));
				this.getCurrentScript().tickFrequency = 1;
				return;
			}
			
			blob.set_u32("next_search", getGameTime() + XORRandom(90));
		}
		if (!blob.exists("raidcooldown")) blob.set_f32("raidcooldown", 0);
		if (raider && blob.get_f32("raidcooldown") < getGameTime())
		{
			CBlob@ raid_target = getBlobByNetworkID(blob.get_u16("raid target"));
			if (raid_target !is null)
			{
				const f32 distance = raid_target.getDistanceTo(blob);
				if (!blob.isOverlapping(raid_target))
				{
					const bool reached_path_end = this.getPathPositionAtIndex(100) == this.getNextPathPosition();
					Vec2f dir;
					
					if (can_repath) 
					{
						this.SetPathTo(raid_target.getPosition(), false);
						blob.set_u32("next_repath", getGameTime() + 60 + XORRandom(60));
					}
					
					if (has_path && !reached_path_end)
					{
						dir = this.getNextPathPosition() - blob.getPosition();
						dir.Normalize();
						
						blob.set_Vec2f("target_dir", dir);
					}
					else
					{
						dir = blob.get_Vec2f("target_dir");
						dir.Normalize();
					}
				
					if (stuck)
					{
						if (blob.get_f32("timeToRaid") < getGameTime())
						{
							blob.set_f32("raidcooldown", getGameTime() + 30*90);
							blob.set_u16("raid target", 0);
						}
						Move(this, blob, blob.getPosition() + Vec2f(XORRandom(48) - 24, -(8 + XORRandom(16))));
						const f32 minDistance = blob.get_f32("minDistance");
						const f32 maxDistance = blob.get_f32("maxDistance");
					
						if (distance > minDistance && distance < maxDistance)
							Attack(this, raid_target, false);
						if (XORRandom(20) == 0) findRaid(blob);
					}
					else Move(this, blob, raid_target.getPosition());
					this.getCurrentScript().tickFrequency = 1;
				}
				if (raid_target.getTeamNum() == blob.getTeamNum())
				{
					blob.set_u16("raid target", 0);
				}
			}
			else
			{
				findRaid(blob);
				blob.set_f32("timeToRaid", getGameTime() + 30*30);
			}
		}
		else this.getCurrentScript().tickFrequency = 15;
	}
	else if (target !is blob)
	{
		// print("" + target.getName());
	
		this.getCurrentScript().tickFrequency = 1;
		
		// print("" + this.lowLevelMaxSteps);
		
		const f32 distance = target.getDistanceTo(blob);
		const f32 minDistance = blob.get_f32("minDistance");
		
		const bool visibleTarget = isVisible(blob, target);
		
		const bool target_attackable = !(target.getTeamNum() == blob.getTeamNum() || target.hasTag("material"));
		const bool lose = distance > maxDistance;
		const bool chase = target_attackable && (distance > chaseDistance || !visibleTarget);
		const bool retreat = !target_attackable || ((distance < minDistance) && visibleTarget);
		
		if (lose)
		{
			ResetTarget(this);
			this.getCurrentScript().tickFrequency = 15;
			return;
		}
		
		if (target_attackable)
		{
			if (visibleTarget) 
			{
				Attack(this, target, true);
			}
			else if (stuck || distance < 64)
			{
				Attack(this, target, false);
			}
		}
		
		if (target_attackable && chase)
		{
			if (can_repath) 
			{	
				this.SetPathTo(target.getPosition(), false);
				blob.set_u32("next_repath", getGameTime() + 60 + XORRandom(30));
			}
	
			Vec2f dir = this.getNextPathPosition() - blob.getPosition();
			dir.Normalize();
			
			if (!visibleTarget)
			{
				Move(this, blob, blob.getPosition() + dir * 24);
			}
			else 
			{
				Move(this, blob, target.getPosition());
			}
			
			// Move(this, blob, blob.getPosition() + dir * 16);
		}
		else if (retreat)
		{
			DefaultRetreatBlob(blob, target);
			// print("retreat");
		}

		if (target.hasTag("dead"))
		{
			CPlayer@ targetPlayer = target.getPlayer();
		
			ResetTarget(this);
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

void findRaid(CBlob@ this)
{
	CBlob@[] bases;
	getBlobsByTag("upkeep building", @bases);
	bool foundBase = false;
	u8 hold = 0;

	if (bases.length > 0) 
	{
		f32 closestDistance = 2000.0f;
		f32 posy = this.getPosition().y;
		f32 smallestydif = 0.0f;
		for (u8 j = 0; j < bases.length; j++)
		{
			if (bases[j].getTeamNum() != this.getTeamNum())
			{
				f32 distance = this.getDistanceTo(bases[j]);
				f32 ydif = Maths::Abs(posy - bases[j].getPosition().y);
				bool isFactionBase = bases[j].hasTag("faction_base");
				if (isFactionBase) distance *= 0.7f; // priority
				if (distance + ydif*2 < closestDistance + smallestydif*2)
				{
					closestDistance = distance;
					smallestydif = ydif;
					hold = j;
					foundBase = true;
				}
			}
		}
	}
	if (!foundBase)
	{
		if (XORRandom(2) == 0) RandomTurn(this);
		this.getCurrentScript().tickFrequency = 15;
	}
	else this.set_u16("raid target", bases[hold].getNetworkID());
}

void ResetTarget(CBrain@ this)
{
	CBlob@ blob = this.getBlob();

	this.SetTarget(null);
	blob.set_bool("stuck", false);
	
	this.getCurrentScript().tickFrequency = 30;
	
	// print("search");
	
	const f32 chaseDistance = blob.get_f32("chaseDistance");
	const Vec2f pos = blob.getPosition();
	CBlob@[] blobs;
	getMap().getBlobsInRadius(blob.getPosition(), chaseDistance, @blobs);
	
	// getBlobsByTag("human", @blobs);
	const u8 myTeam = blob.getTeamNum();
	int hold = 0;
	int totalTargets = blobs.length;
	bool targetFound = false;
	f32 closestDistance = chaseDistance;
	for (int i = 0; i < totalTargets; i++)
	{
		CBlob@ b = blobs[i];
		f32 d = blob.getDistanceTo(b);
		if (b.getTeamNum() != myTeam && d <= chaseDistance && !b.hasTag("dead") && 
			(b.hasTag("flesh") || b.hasTag("auto_turret")) && !b.hasTag("passive") && 
			!b.hasTag("invincible") && (isVisible(blob, b) || d < 48))
		{
			if (d > closestDistance) continue;
			closestDistance = d;
			targetFound = true;
			hold = i;
		}
	}
	if (targetFound)
	{
		this.SetTarget(blobs[hold]);
		blob.set_u32("nextAttack", getGameTime() + blob.get_u8("reactionTime"));
		this.getCurrentScript().tickFrequency = 1;
		return;
	}
	
	blob.set_u32("next_search", getGameTime() + XORRandom(10));
}

void Attack(CBrain@ this, CBlob@ target, bool useBombs)
{
	CBlob@ blob = this.getBlob();

	// blob.setAimPos(target.getPosition());
	// const f32 reactionTime = blob.get_f32("reactionTime");

	
	f32 dist = (target.getPosition() - blob.getPosition()).Length();
	f32 jitter = blob.get_f32("inaccuracy") * Maths::Sqrt(dist);
	Vec2f randomness = getRandomVelocity(0, (XORRandom(1000) * 0.001f) * jitter * 20.00f, 360);	
	blob.setAimPos(Vec2f_lerp(blob.getAimPos(), target.getPosition() + randomness, 0.20f));
	
	if (blob.get_u32("nextAttack") < getGameTime())
	{
		AttachmentPoint@ point = blob.getAttachments().getAttachmentPointByName("PICKUP");
		
		if (point !is null) 
		{
			CBlob@ gun = point.getOccupied();
			if (gun !is null) 
			{
				if (blob.get_u32("nextAttack") < getGameTime())
				{							
					// f32 dist = (target.getPosition() - blob.getPosition()).Length();
					// f32 jitter = blob.get_f32("inaccuracy") * Maths::Sqrt(dist);
					
					// print("jitter " + Maths::Sqrt(dist));
					
					// Vec2f randomness = Vec2f((100 - XORRandom(200)) * jitter, (100 - XORRandom(200)) * jitter);
					// Vec2f randomness = getRandomVelocity(0, (XORRandom(1000) * 0.001f) * jitter * 20.00f, 360);	
				
					// Vec2f currentCursorPos = this.getAimPos();
					// Vec2f targetCursorPos = target.getPosition() + randomness;
					
					// targetPos = Vec2f(lerp(currentCursorPos.x, targetCursorPos.x, le)
				
					// Vec2f currentCursorPos = blob.getAimPos();
					// Vec2f targetCursorPos = target.getPosition() + randomness;
					
					// targetCursorPos = Vec2f(lerp(currentCursorPos.x, targetCursorPos.x, cursor_lerp_speed), lerp(currentCursorPos.y, targetCursorPos.y, cursor_lerp_speed));
				
					// blob.setAimPos(targetCursorPos);
				
					
					blob.setKeyPressed(key_action1, true);
					blob.set_bool("should_do_attack_hack", true);
					blob.set_u32("nextAttack", getGameTime() + blob.get_u8("attackDelay"));
				}
				else
				{
					blob.setKeyPressed(key_action1, false);
					blob.set_bool("should_do_attack_hack", false);
				}
			}
		}
	}
}

void Move(CBrain@ this, CBlob@ blob, Vec2f pos)
{
	Vec2f dir = blob.getPosition() - pos;

	blob.setKeyPressed(key_left, dir.x > 0);
	blob.setKeyPressed(key_right, dir.x < 0);
	blob.setKeyPressed(key_up, dir.y > 0);
	blob.setKeyPressed(key_down, dir.y < 0);
}

f32 Lerp(f32 v0, f32 v1, f32 t) 
{
	return v0 + t * (v1 - v0);
}