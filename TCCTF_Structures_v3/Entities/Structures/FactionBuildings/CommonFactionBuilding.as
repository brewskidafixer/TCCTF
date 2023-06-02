#include "Survival_Structs.as";
#include "Survival_Icons.as";
#include "Hitters.as";
#include "Logging.as";

const string raid_tag = "under raid";
const u32[] teamcolours = {0xff0000ff, 0xffff0000, 0xff00ff00, 0xffff00ff, 0xffff6600, 0xff00ffff, 0xff6600ff, 0xff647160};

void onInit(CBlob@ this)
{
	this.Tag("faction_base");

	this.addCommandID("faction_captured");
	this.addCommandID("faction_destroyed");
	this.addCommandID("faction_menu_button");
	this.addCommandID("faction_player_button");
	this.addCommandID("button_join");
	this.addCommandID("sv_toggle");
	this.addCommandID("cl_toggle");

	this.addCommandID("rename_base");
	this.addCommandID("rename_faction");

	this.set_string("initial_base_name", this.getInventoryName());
	string base_name = this.get_string("base_name");
	if (base_name != "") this.setInventoryName(this.getInventoryName() + " \"" + base_name + "\"");

	this.set_bool("base_demolition", false);
	this.set_bool("base_alarm", false);
	this.set_bool("base_alarm_manual", false);
	this.set_bool("isActive", true);

	AddIconToken("$faction_become_leader$", "FactionIcons.png", Vec2f(16, 16), 0);
	AddIconToken("$faction_resign_leader$", "FactionIcons.png", Vec2f(16, 16), 1);
	AddIconToken("$faction_remove$", "FactionIcons.png", Vec2f(16, 16), 2);
	AddIconToken("$faction_enslave$", "FactionIcons.png", Vec2f(16, 16), 3);

	AddIconToken("$faction_bed_true$", "FactionIcons.png", Vec2f(16, 16), 4);
	AddIconToken("$faction_bed_false$", "FactionIcons.png", Vec2f(16, 16), 5);

	AddIconToken("$faction_lock_true$", "FactionIcons.png", Vec2f(16, 16), 6);
	AddIconToken("$faction_lock_false$", "FactionIcons.png", Vec2f(16, 16), 7);

	AddIconToken("$faction_coin_true$", "FactionIcons.png", Vec2f(16, 16), 8);
	AddIconToken("$faction_coin_false$", "FactionIcons.png", Vec2f(16, 16), 9);

	AddIconToken("$faction_crate_true$", "FactionIcons.png", Vec2f(16, 16), 10);
	AddIconToken("$faction_crate_false$", "FactionIcons.png", Vec2f(16, 16), 11);

	AddIconToken("$faction_f2p_true$", "FactionIcons.png", Vec2f(16, 16), 12);
	AddIconToken("$faction_f2p_false$", "FactionIcons.png", Vec2f(16, 16), 13);

	AddIconToken("$faction_slavery_true$", "FactionIcons.png", Vec2f(16, 16), 14);
	AddIconToken("$faction_slavery_false$", "FactionIcons.png", Vec2f(16, 16), 15);

	AddIconToken("$faction_reserved1_true$", "FactionIcons.png", Vec2f(16, 16), 16);
	AddIconToken("$faction_reserved1_false$", "FactionIcons.png", Vec2f(16, 16), 17);

	AddIconToken("$faction_reserved2_true$", "FactionIcons.png", Vec2f(16, 16), 18);
	AddIconToken("$faction_reserved2_false$", "FactionIcons.png", Vec2f(16, 16), 19);

	AddIconToken("$faction_alarm_true$", "FactionIcons.png", Vec2f(16, 16), 20);
	AddIconToken("$faction_alarm_false$", "FactionIcons.png", Vec2f(16, 16), 21);
}

void onTick(CBlob@ this)
{
	SetMinimap(this);   //needed for under raid check
	if (this.get_bool("base_alarm_manual") || this.hasTag(raid_tag))
	{	
		if (this.get_bool("base_allow_alarm") && !this.get_bool("base_alarm"))
		{
			SetAlarm(this, true);
		}
	}
	else if (this.get_bool("base_alarm"))
	{
		this.set_bool("base_alarm", false);
		this.SetLight(this.get_bool("isActive"));

		if (this.getName() == "fortress")
		{
			this.SetLightRadius(128.0f);
			this.SetLightColor(SColor(255, 255, 200, 128));
		}
		else if (this.getName() == "stronghold")
		{
			this.SetLightRadius(192.0f);
			this.SetLightColor(SColor(255, 255, 240, 171));
		}
		else if (this.getName() == "citadel" || this.getName() == "convent")
		{
			this.SetLightRadius(256.0f);
			this.SetLightColor(SColor(255, 255, 240, 210));
		}
	}
}

void SetMinimap(CBlob@ this)
{
	bool raid = this.hasTag(raid_tag);

	if (raid || this.get_bool("base_alarm"))
	{
		this.SetMinimapOutsideBehaviour(CBlob::minimap_snap);
		this.SetMinimapVars("GUI/Minimap/MinimapIcons.png", 1, Vec2f(16, 16));
	}
	else
	{
		this.SetMinimapOutsideBehaviour(CBlob::minimap_arrow);

		if (this.hasTag("minimap_large")) this.SetMinimapVars("GUI/Minimap/MinimapIcons.png", this.get_u8("minimap_index"), Vec2f(16, 8));
		else if (this.hasTag("minimap_small")) this.SetMinimapVars("GUI/Minimap/MinimapIcons.png", this.get_u8("minimap_index"), Vec2f(8, 8));
	}

	this.SetMinimapRenderAlways(true);
}

void onChangeTeam(CBlob@ this, const int oldTeam)
{
	if (oldTeam > 1) return;
	CBlob@[] forts;
	getBlobsByTag("faction_base", @forts);

	int newTeam = this.getTeamNum();
	int totalFortCount = forts.length;
	int oldTeamForts = 0;
	int newTeamForts = 0;

	CRules@ rules = getRules();

	SetNearbyBlobsToTeam(this, oldTeam, newTeam);

	for (uint i = 0; i < totalFortCount; i++)
	{
		int fortTeamNum = forts[i].getTeamNum();

		if (fortTeamNum == newTeam)
		{
			newTeamForts++;
		}
		else if (fortTeamNum == oldTeam)
		{
			oldTeamForts++;
		}
	}

	if (oldTeamForts <= 0 || this.get_string("base_name") != "")
	{
		if (isServer())
		{
			CBitStream bt;
			bt.write_s32(newTeam);
			bt.write_s32(oldTeam);
			bt.write_bool(oldTeamForts == 0);

			this.SendCommand(this.getCommandID("faction_captured"), bt);

			// for(u8 i = 0; i < getPlayerCount(); i++)
			// {
				// CPlayer@ p = getPlayer(i);
				// if(p !is null && p.getTeamNum() == oldTeam)
				// {
					// p.server_setTeamNum(XORRandom(100)+100);
					// CBlob@ b = p.getBlob();
					// if(b !is null)
					// {
						// b.server_Die();
					// }
				// }
			// }
		}
	}
	CheckTeamWon();
}

void SetNearbyBlobsToTeam(CBlob@ this, const int oldTeam, const int newTeam)
{
	CBlob@[] teamBlobs;
	this.getMap().getBlobsInRadius(this.getPosition(), 128.0f, @teamBlobs);

	for (uint i = 0; i < teamBlobs.length; i++)
	{
		CBlob@ b = teamBlobs[i];
		if (b.getName() != this.getName() && b.hasTag("change team on fort capture") && (b.getTeamNum() == oldTeam || b.getTeamNum() > 7))
		{
			b.server_setTeamNum(newTeam);
		}
	}
}

void onDie(CBlob@ this)
{
	if (this.hasTag("upgrading")) return;

	CBlob@[] forts;
	getBlobsByTag("faction_base", @forts);

	CRules@ rules = getRules();
	int teamForts = 0; // Current fort is being faction_destroyed
	u8 team = this.getTeamNum();

	for (uint i = 0; i < forts.length; i++)
	{
		if (forts[i].getTeamNum() == team) teamForts++;
	}

	if (isServer() && (teamForts <= 0 || this.get_string("base_name") != ""))
	{
		CBitStream bt;
		bt.write_s32(team);
		bt.write_bool(teamForts <= 0);

		this.SendCommand(this.getCommandID("faction_destroyed"), bt);
	}
	CheckTeamWon();
}

void GetButtonsFor(CBlob@ this, CBlob@ caller)
{
	this.set_bool("shop available", this.isOverlapping(caller) && caller.getTeamNum() == this.getTeamNum());
	if (caller.isOverlapping(this))
	{
		if (caller.getTeamNum() == this.getTeamNum())
		{
			CBitStream params_menu;
			params_menu.write_u16(caller.getNetworkID());
			// CButton@ button_menu = caller.CreateGenericButton(11, Vec2f(14, 5), this, this.getCommandID("faction_menu"), "Faction Management", params_menu);

			CBlob@ carried = caller.getCarriedBlob();
			if (carried !is null && carried.getName() == "paper")
			{
				CBitStream params_menu;
				params_menu.write_u16(caller.getNetworkID());
				params_menu.write_u16(carried.getNetworkID());

				caller.CreateGenericButton("$icon_paper$", Vec2f(7, -8), this, this.getCommandID("rename_base"), "Rename the base", params_menu);
			}
			if (this.getName() != "camp")
			{
				CBitStream params;
				CButton@ buttonEject = caller.CreateGenericButton((this.get_bool("isActive") ? 27 : 23), Vec2f(0, -8), 
					this, this.getCommandID("sv_toggle"), (this.get_bool("isActive") ? "Turn Off" : "Turn On"), params);
			}
		}
	}
}

void SetAlarm(CBlob@ this, bool inState)
{
	if (inState == this.get_bool("base_alarm")) return;

	this.set_bool("base_alarm", true);
	if (isServer()) this.Sync("base_alarm", true);

	this.SetLight(true);
	this.SetLightRadius(256.0f);
	this.SetLightColor(SColor(255, 255, 0, 0));
}

void Faction_Menu(CBlob@ this, CBlob@ caller)
{
	CPlayer@ myPly = caller.getPlayer();
	if (myPly !is null && caller.isMyPlayer())
	{
		TeamData@ team_data;
		GetTeamData(this.getTeamNum(), @team_data);

		const bool isLeader = team_data.leader_name == myPly.getUsername();

		const bool recruitment_enabled = team_data.recruitment_enabled;
		const bool tax_enabled = team_data.tax_enabled;
		const bool storage_enabled = team_data.storage_enabled;
		const bool lockdown_enabled = team_data.lockdown_enabled;
		const bool f2p_enabled = team_data.f2p_enabled;
		const bool slavery_enabled = team_data.slavery_enabled;
		const bool reserved_1_enabled = team_data.lockdown_enabled;
		const bool reserved_2_enabled = team_data.lockdown_enabled;

		const bool base_demolition = this.get_bool("base_demolition");
		const bool base_alarm = this.get_bool("base_alarm");

		CBlob@[] forts;
		getBlobsByTag("faction_base", @forts);
		int teamForts = 0;

		for(uint i = 0; i < forts.length; i++)
		{
			int fortTeamNum = forts[i].getTeamNum();
			if (fortTeamNum == this.getTeamNum()) teamForts++;
		}
		const bool canDestroy = teamForts != 1;
	}
}

void onCommand(CBlob@ this, u8 cmd, CBitStream@ inParams)
{
	if (cmd == this.getCommandID("rename_base") || cmd == this.getCommandID("rename_faction"))
	{
		CBlob @caller = getBlobByNetworkID(inParams.read_u16());
		CBlob @carried = getBlobByNetworkID(inParams.read_u16());

		if (caller !is null && carried !is null)
		{
			string new_name = carried.get_string("text");
			string old_name;

			if (cmd == this.getCommandID("rename_base"))
			{
				old_name = this.getInventoryName();
				this.setInventoryName(new_name);
			}
			else
			{
				TeamData@ team_data;
				GetTeamData(this.getTeamNum(), @team_data);
				if (team_data !is null)
				{
					old_name = GetTeamName(this.getTeamNum());
					team_data.team_name = new_name;
				}
			}

			string renamer_name = "Someone";
			SColor message_color(255, 128, 128, 128);

			CPlayer@ player = caller.getPlayer();
			if (player !is null)
			{
				renamer_name = player.getUsername();
				CRules @rules = getRules();
				if (rules !is null)
				{
					CTeam@ team = rules.getTeam(player.getTeamNum());
					if (team !is null)
					{
						message_color = player.getTeamNum() < 7 ? team.color : SColor(255, 128, 128, 128);
					}
				}
			}
			client_AddToChat(renamer_name + " has renamed " + old_name + " to " + new_name, message_color);

			carried.server_Die();
		}
	}

	if (isServer())
	{
		if (cmd == this.getCommandID("faction_captured") || cmd == this.getCommandID("faction_destroyed"))
		{
			int team = inParams.read_s32();
			if (cmd == this.getCommandID("faction_captured"))
			{
				team = inParams.read_s32();
			}

			bool defeat = inParams.read_bool();
			bool self_destroy = this.get_bool("base_demolition");
		}
		else if (cmd == this.getCommandID("sv_toggle"))
		{
			this.set_bool("isActive", !this.get_bool("isActive"));
			this.Sync("isActive", true);
			bool isActive = this.get_bool("isActive");
			this.SetLight(this.get_bool("isActive"));

			CBitStream stream;
			stream.write_bool(isActive);
			this.SendCommand(this.getCommandID("cl_toggle"), stream);
		}
	}

	if (isClient())
	{
		if (cmd == this.getCommandID("cl_toggle"))
		{		
			this.getSprite().PlaySound("LeverToggle.ogg");
		}
		else if (cmd == this.getCommandID("faction_captured"))
		{
			CRules@ rules = getRules();

			int newTeam = inParams.read_s32();
			int oldTeam = inParams.read_s32();
			bool defeat = inParams.read_bool();

			if (rules is null) return;

			// if (!(oldTeam < getRules().getTeamsNum())) return;

			if (oldTeam < 7 && newTeam < 7)
			{
				string oldTeamName = GetTeamName(oldTeam);
				string newTeamName = GetTeamName(newTeam);

				client_AddToChat(oldTeamName + "'s "+this.getInventoryName()+" has been captured by the " + newTeamName + "!", SColor(0xff444444));
				if (defeat)
				{
					client_AddToChat(oldTeamName + " has been defeated by the " + newTeamName + "!", SColor(0xff444444));

					CPlayer@ ply = getLocalPlayer();
					int myTeam = ply.getTeamNum();

					if (oldTeam == myTeam)
					{
						Sound::Play("FanfareLose.ogg");
					}
					else
					{
						Sound::Play("flag_score.ogg");
					}
				}
			}
		}
		else if (cmd == this.getCommandID("faction_destroyed"))
		{
			CRules@ rules = getRules();

			int team = inParams.read_s32();
			bool defeat = inParams.read_bool();

			if (rules is null) return;

			if (team < 2) 
			{
				string teamName = GetTeamName(team);
				client_AddToChat(teamName + "'s "+this.getInventoryName()+" has been destroyed!", SColor(0xff444444));

				if (defeat) 
				{
					client_AddToChat(teamName + " has been defeated!", SColor(0xff444444));
					CPlayer@ ply = getLocalPlayer();
					int myTeam = ply.getTeamNum();

					if (team == myTeam)
					{
						Sound::Play("FanfareLose.ogg");
					}
					else
					{
						Sound::Play("flag_score.ogg");
					}
				}
			}
		}
	}
}

f32 onHit(CBlob@ this, Vec2f worldPoint, Vec2f velocity, f32 damage, CBlob@ hitterBlob, u8 customData)
{
	if (customData == Hitters::builder || customData == Hitters::drill)
	{
		return damage *= 3.0f;
	}

	return damage;
}

void CheckTeamWon()
{
	CRules@ rules = getRules();
	if (rules is null || !rules.isMatchRunning()) { return; }

	CBlob@[] flags;
	getBlobsByTag("faction_base", @flags);

	int winteamIndex = -1;
	s8 team_wins_on_end = -1;
	u8 aliveTeams = 0;

	for (uint team_num = 0; team_num < rules.getTeamsCount(); team_num++)
	{
		if (aliveTeams > 1) return;
		for (uint i = 0; i < flags.length; i++)
		{
			if (team_num == flags[i].getTeamNum())
			{
				flags.removeAt(i);
				aliveTeams++;
				winteamIndex = team_num;
				break;
			}
		}
	}
	if (aliveTeams == 0) return;

	rules.set_s8("team_wins_on_end", team_wins_on_end);

	if (winteamIndex >= 0 && winteamIndex < 8)
	{
		const string[] teamNames = {
			"Blue Team",
			"Red Team",
			"Elf Nation",
			"UPF Federation",
			"Dutch Republic",
			"Confederacy of the Space Union",
			"The Shadow Clan"
		};
		rules.SetTeamWon(winteamIndex);   //game over!
		rules.SetGlobalMessage(teamNames[winteamIndex] + " wins the game!");
		rules.SetCurrentState(GAME_OVER);
	}
}