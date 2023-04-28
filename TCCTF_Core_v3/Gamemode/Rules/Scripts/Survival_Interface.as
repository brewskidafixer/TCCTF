#define CLIENT_ONLY

//#include "TDM_Structs.as";
#include "ScoreboardCommon.as";
#include "Survival_Structs.as";
#include "UI.as";

//skin
// #include "MainButtonRender.as"
// #include "MainTextInputRender.as"
// #include "MainToggleRender.as"
// #include "MainOptionRender.as"
// #include "MainSliderRender.as"
//controls
// #include "UIButton.as"
// #include "UITextInput.as"
// #include "UIToggle.as"
// #include "UIOption.as"
// #include "UISlider.as"

// #include "UILabel.as"


//Const
const SColor red = SColor(255,255,50,50);//RED
const SColor lBlack = SColor(255,64,64,64);
const SColor black = SColor(255,0,0,0);
const SColor white = SColor(255,255,255,255);
const SColor grey = SColor(255,220,220,220);
const SColor grey2 = SColor(255, 191, 191, 191);
const string serverName = "Territory Control";
const SColor[] teamColourArray = {SColor(255, 102, 102, 255), SColor(255, 255, 102, 102), SColor(255, 51, 102, 13),
      SColor(255, 98, 26, 131), SColor(255, 132, 71, 21), SColor(255, 43, 83, 83), SColor(255, 42, 48, 132), SColor(255, 100, 113, 96)};

//Non const
string serverIP = "";
string mapName = "";

int hovered_age = -1;
int hovered_tier = -1;
bool draw_age = false;
bool draw_tier = false;

void onInit(CRules@ this)
{
	onRestart(this);
}

void onRestart(CRules@ this)
{
	CNet@ net = getNet();
	CMap@ map = getMap();
	serverIP = net.joined_ip;

	mapName = map is null ? "Error: Blame KAG" : map.getMapName();
}

void onRenderScoreboard(CRules@ this)
{
	//sort players
	CPlayer@[] sortedplayers;
	for (u8 i = 0; i < getPlayersCount(); i++)
	{
		CPlayer@ p = getPlayer(i);
		const int team = p.getTeamNum();
		bool inserted = false;
		for (u8 j = 0; j < sortedplayers.length; j++)
		{
			if (sortedplayers[j].getTeamNum() < team)
			{
				sortedplayers.insert(j, p);
				inserted = true;
				break;
			}
		}
		if (!inserted)
		{
			sortedplayers.push_back(p);
		}
	}

	f32 y_offset = 0;

	// Server Info
	{
		f32 width = 200;
		f32 height = 120;

		GUI::SetFont("menu");

		string title =  "";
		string mapname = "";

		Vec2f dim;
		GUI::GetTextDimensions(serverName, dim);
		if (dim.x + 15 > width) width = dim.x + 25;

		GUI::GetTextDimensions(mapName, dim);
		if (dim.x + 15 > width) width = dim.x + 25;

		const Vec2f tl = Vec2f(100, 60);
		const Vec2f br = Vec2f(width, height) + tl;
		Vec2f mid = Vec2f(width * 0.50f, 0) + tl;

		y_offset = tl.x + width;//required otherwise the rules tab overlaps us

		GUI::DrawFramedPane(tl, br);

		mid.y += 20;
		GUI::DrawTextCentered(serverName, mid, white);
		mid.y += 20;
		GUI::DrawTextCentered("Capture The Faction", mid, white);
		mid.y += 40;
		GUI::DrawTextCentered(mapName, mid, white);
		mid.y += 20;
		GUI::DrawTextCentered(getTranslatedString("Match time: {TIME}").replace("{TIME}", "" + timestamp((getRules().exists("match_time") ? getRules().get_u32("match_time") : getGameTime())/getTicksASecond())), mid, white);
	}

	const f32 stepheight = 20;
	const f32 playerList_yOffset = (sortedplayers.length + 3.5) * stepheight;

	// Server rules
	{
		const f32 width = getScreenWidth() - 100 - y_offset - 10;
		const f32 height = 120;
		const Vec2f tl = Vec2f(y_offset + 10, 60);
		const Vec2f br = Vec2f(width, height) + tl;
		const f32 mid = tl.x + width * 0.50f;
		const f32 tO = y_offset + 20;//text offset
		GUI::DrawFramedPane(tl, br);

		GUI::SetFont("menu");
		GUI::DrawText("General Rules and Notes", Vec2f(mid- 100,tl.y + 10), red);
		GUI::DrawText("- Do not grief or sabotage your team, such as by wasting resources or stealing the leadership or kicking everyone out.", Vec2f(tO, tl.y + 30), white);
		GUI::DrawText("- Intentionally crashing the server will result in a lengthy ban.", Vec2f(tO, tl.y + 45), white);
		//GUI::DrawText("- Try not hoard too many slaves, general rule of thumb is to only slave people either for being a murderhobo or annoying.", Vec2f(tO, tl.y + 75), white);
		GUI::DrawText("- Do not spam. Do not hack. Do not be extremely toxic.", Vec2f(tO,tl.y + 60), white);
	}

	// player scoreboard
	{

		Vec2f topleft(100, 190);
		Vec2f bottomright(getScreenWidth() - 100, topleft.y + playerList_yOffset);

		GUI::DrawFramedPane(topleft, bottomright);

		y_offset = bottomright.y;

		//offset border

		topleft.x += stepheight;
		bottomright.x -= stepheight;
		topleft.y += stepheight;

		GUI::SetFont("menu");

		//draw player table header

		if (getScreenWidth() < 1461)//Compact
		{

			GUI::DrawText("Character Name", Vec2f(topleft.x, topleft.y), white);
			GUI::DrawText("User Name", Vec2f(topleft.x + 200, topleft.y), white);
			GUI::DrawText("Accolades", Vec2f(bottomright.x - 700, topleft.y), white);
			// GUI::DrawText("Clan", Vec2f(bottomright.x - 510, topleft.y), white);
			GUI::DrawText("Wealth", Vec2f(bottomright.x - 420, topleft.y), white);
			GUI::DrawText("Ping", Vec2f(bottomright.x - 330, topleft.y), white);
			GUI::DrawText("Kills", Vec2f(bottomright.x - 270, topleft.y), white);
			GUI::DrawText("Deaths", Vec2f(bottomright.x - 220, topleft.y), white);
			GUI::DrawText("Title", Vec2f(bottomright.x - 150, topleft.y), white);
		}
		else
		{
			GUI::DrawText("Character Name", Vec2f(topleft.x, topleft.y), white);
			GUI::DrawText("User Name", Vec2f(topleft.x + 250, topleft.y), white);
			GUI::DrawText("Accolades", Vec2f(bottomright.x - 850, topleft.y), white);
			//GUI::DrawText("Clan", Vec2f(bottomright.x - 850, topleft.y), white);
			// GUI::DrawText("Team Status", Vec2f(bottomright.x - 550, topleft.y), SColor(0xffffffff));
			GUI::DrawText("Wealth", Vec2f(bottomright.x - 550, topleft.y), white);
			GUI::DrawText("Ping", Vec2f(bottomright.x - 450, topleft.y), white);
			GUI::DrawText("Kills", Vec2f(bottomright.x - 350, topleft.y), white);
			GUI::DrawText("Deaths", Vec2f(bottomright.x - 250, topleft.y), white);
			GUI::DrawText("Title", Vec2f(bottomright.x - 150, topleft.y), white);
		}

		topleft.y += stepheight * 0.5f;

		CControls@ controls = getControls();
		const Vec2f mousePos = controls.getMouseScreenPos();

		//draw players
		for (u8 i = 0; i < sortedplayers.length; i++)
		{
			CPlayer@ p = sortedplayers[i];
			if (p is null) continue;

			bool playerHover = mousePos.y > topleft.y + 20 && mousePos.y < topleft.y + 40;

			topleft.y += stepheight;
			bottomright.y = topleft.y + stepheight;
			const Vec2f lineoffset = Vec2f(0, -2);

			//Player stuff
			SColor tempGrey = grey;
			SColor customCol = grey;
			const s32 ping_in_ms = s32(p.getPing() * 1000.0f / 30.0f);
			const u16 coins = p.getCoins();
			const string lowUsername = p.getUsername().toLower();
			const string rank = getRank(lowUsername, customCol, p);
			//const string clan = this.exists("clanData"+lowUsername) ? this.get_string("clanData"+lowUsername) : "";
			const string characterName = (p.getClantag().length > 0 ? p.getClantag() + " " : "") + p.getCharacterName();
			SColor playercolour = teamColourArray[p.getTeamNum() % teamColourArray.length];

			if (p.getTeamNum() >= 100)
			{
				playercolour = grey2;
			}

			if (playerHover)
			{
				customCol = white;
				playercolour = white;
				tempGrey = white;
			}
			//End

			//Fancy under line
			GUI::DrawLine2D(Vec2f(topleft.x, bottomright.y + 1) + lineoffset, Vec2f(bottomright.x, bottomright.y + 1) + lineoffset, lBlack);
			GUI::DrawLine2D(Vec2f(topleft.x, bottomright.y) + lineoffset, bottomright + lineoffset, SColor(playercolour));
			//End

			//Icon
			string tex = "";
			u16 frame = 0;
			Vec2f framesize;
			if (p.isMyPlayer())
			{
				tex = "ScoreboardIcons.png";
				frame = 4;
				framesize.Set(16, 16);
			}
			else
			{
				tex = p.getScoreboardTexture();
				frame = p.getScoreboardFrame();
				framesize = p.getScoreboardFrameSize();
			}
			if (tex != "") GUI::DrawIcon(tex, frame, framesize, topleft, 0.5f, p.getTeamNum());
			//End

			if (getScreenWidth() < 1461)
			{
				GUI::DrawText(characterName      , topleft + Vec2f(20, 0)               , playercolour);//CharacterName
				GUI::DrawText(p.getUsername()    , topleft + Vec2f(200, 0)              , tempGrey);//Username
				GUI::DrawText(coins + " coins"   , Vec2f(bottomright.x - 420, topleft.y), tempGrey);//Coins
				GUI::DrawText(ping_in_ms + " ms" , Vec2f(bottomright.x - 330, topleft.y), tempGrey);//Ping
				GUI::DrawText("" + p.getKills()  , Vec2f(bottomright.x - 270, topleft.y), tempGrey);//Kills
				GUI::DrawText("" + p.getDeaths() , Vec2f(bottomright.x - 220, topleft.y), tempGrey);//Deaths
				if(rank != "") GUI::DrawText(rank, Vec2f(bottomright.x - 150, topleft.y), customCol);//Rank
			}
			else
			{
				GUI::DrawText(characterName      , topleft + Vec2f(20, 0)               , playercolour);//PlayerColour

				GUI::DrawText(p.getUsername()    , topleft + Vec2f(250, 0)              , tempGrey);
				//GUI::DrawText(clan               , Vec2f(bottomright.x - 850, topleft.y), tempGrey);
				//if (clan != "") GUI::DrawIcon(clan + "_icon.png", 0, Vec2f(16,16), Vec2f(bottomright.x - 875, topleft.y), 0.5f, p.getTeamNum());
				GUI::DrawText(coins + " coins"   , Vec2f(bottomright.x - 550, topleft.y), tempGrey);
				GUI::DrawText(ping_in_ms + " ms" , Vec2f(bottomright.x - 450, topleft.y), tempGrey);
				GUI::DrawText("" + p.getKills()  , Vec2f(bottomright.x - 350, topleft.y), tempGrey);
				GUI::DrawText("" + p.getDeaths() , Vec2f(bottomright.x - 250, topleft.y), tempGrey);
				if(rank != "") GUI::DrawText(rank, Vec2f(bottomright.x - 150, topleft.y), customCol);
			}
		}
	}

	// team scoreboard
	{
		TeamData[]@ team_list;
		this.get("team_list", @team_list);

		if (team_list !is null)
		{
			u8 maxTeams = team_list.length;
			u8 team_len = 0;
			for (u8 i = 0; i < team_list.length; i++)
			{
				if (team_list[i].player_count > 0) team_len++;
			}

			if (team_len > 0)
			{
				const f32 stepheight = 20;
				const f32 base_offset = 850;

				Vec2f topleft(100, 200 + playerList_yOffset);
				Vec2f bottomright(getScreenWidth() - 100, topleft.y + ((team_len + 3.5) * stepheight));
				GUI::DrawFramedPane(topleft, bottomright);

				y_offset = bottomright.y;

				//offset border
				topleft.x += stepheight;
				bottomright.x -= stepheight;
				topleft.y += stepheight;

				GUI::SetFont("menu");

				//draw player table header
				if (getScreenWidth() < 1461)
				{
					GUI::DrawText("Team Name", Vec2f(topleft.x, topleft.y), white);
					GUI::DrawText("Leader", Vec2f(topleft.x + 100, topleft.y), white);
					GUI::DrawText("Members", Vec2f(bottomright.x    - 650, topleft.y), white);
					GUI::DrawText("Upkeep", Vec2f(bottomright.x     - 560, topleft.y), white);
					GUI::DrawText("Wealth", Vec2f(bottomright.x     - 490, topleft.y), white);
					GUI::DrawText("Recruiting", Vec2f(bottomright.x - 400, topleft.y), white);
					GUI::DrawText("Murder Tax", Vec2f(bottomright.x - 320, topleft.y), white);
					GUI::DrawText("Lockdown", Vec2f(bottomright.x   - 230, topleft.y), white);
					GUI::DrawText("Land Owned", Vec2f(bottomright.x - 150, topleft.y), white);
				}
				else
				{
					GUI::DrawText("Team Name", Vec2f(topleft.x, topleft.y), white);
					GUI::DrawText("Leader", Vec2f(topleft.x + 250, topleft.y), white);
					GUI::DrawText("Members", Vec2f(bottomright.x        - base_offset, topleft.y), white);
					GUI::DrawText("Upkeep", Vec2f(bottomright.x         - base_offset + 100, topleft.y), white);
					GUI::DrawText("Wealth", Vec2f(bottomright.x         - base_offset + 200, topleft.y), white);
					GUI::DrawText("Recruitment", Vec2f(bottomright.x    - base_offset + 300, topleft.y), white);
					GUI::DrawText("Murder Tax", Vec2f(bottomright.x     - base_offset + 450, topleft.y), white);
					//GUI::DrawText("Slavery", Vec2f(bottomright.x      - base_offset + 550, topleft.y), white);
					GUI::DrawText("Lockdown", Vec2f(bottomright.x       - base_offset + 550, topleft.y), white);
					GUI::DrawText("Land Owned", Vec2f(bottomright.x     - base_offset + 650, topleft.y), white);
				}

				topleft.y += stepheight * 0.5f;

				CControls@ controls = getControls();
				Vec2f mousePos = controls.getMouseScreenPos();

				const u16 total_capturables = this.get_u16("total_capturables");

				for (u32 i = 0; i < team_list.length; i++)
				{
					TeamData@ team = team_list[i];
					if (team.player_count == 0) continue;

					CTeam@ cTeam = this.getTeam(i);

					if (team is null) continue;

					bool hover = mousePos.y > topleft.y + 20 && mousePos.y < topleft.y + 40;

					topleft.y += stepheight;
					bottomright.y = topleft.y + stepheight;

					const Vec2f lineoffset = Vec2f(0, -2);

					SColor tempGrey = grey;
					SColor color = teamColourArray[i];

					if (hover)
					{
						tempGrey = white;
						color = white;
					}

					GUI::DrawLine2D(Vec2f(topleft.x, bottomright.y + 1) + lineoffset, Vec2f(bottomright.x, bottomright.y + 1) + lineoffset, lBlack);
					GUI::DrawLine2D(Vec2f(topleft.x, bottomright.y) + lineoffset, bottomright + lineoffset, color);

					const string teamName = team.team_name == "" ? cTeam.getName() : team.team_name;
					const string leaderName = team.leader_name == "" ? "N/A" : team.leader_name;
					const string upkeep = team.upkeep + " / " + team.upkeep_cap;
					const string recOn = team.recruitment_enabled ? "Yes" : "No";
					const string taxOn = team.tax_enabled ?         "Yes" : "No";
					const string slaOn = team.slavery_enabled ?     "Yes" : "No";
					const string lockOn = team.lockdown_enabled ?   "Yes" : "No";

					if (getScreenWidth() < 1461)
					{
						GUI::DrawText(teamName              , topleft, color);
						GUI::DrawText(leaderName            , topleft + Vec2f(100, 0), tempGrey);
						GUI::DrawText(team.player_count + "", Vec2f(bottomright.x - 650, topleft.y), tempGrey);
						GUI::DrawText(upkeep                , Vec2f(bottomright.x - 560, topleft.y), tempGrey);
						GUI::DrawText(team.wealth + " coins", Vec2f(bottomright.x - 490, topleft.y), tempGrey);
						GUI::DrawText(recOn                 , Vec2f(bottomright.x - 400, topleft.y), tempGrey);
						GUI::DrawText(taxOn                 , Vec2f(bottomright.x - 320, topleft.y), tempGrey);
						GUI::DrawText(lockOn                , Vec2f(bottomright.x - 230, topleft.y), tempGrey);

						GUI::DrawText(Maths::Round((f32(team.controlled_count) / f32(total_capturables)) * 100.00f) + "%", Vec2f(bottomright.x - 150, topleft.y), tempGrey);
					}
					else
					{
						GUI::DrawText(teamName              , topleft, color);
						GUI::DrawText(leaderName            , topleft + Vec2f(250, 0), tempGrey);
						GUI::DrawText(team.player_count + "", Vec2f(bottomright.x - base_offset + 000, topleft.y), tempGrey);
						GUI::DrawText(upkeep                ,Vec2f(bottomright.x - base_offset  + 100, topleft.y), tempGrey);
						GUI::DrawText(team.wealth + " coins", Vec2f(bottomright.x - base_offset + 200, topleft.y), tempGrey);
						GUI::DrawText(recOn                 , Vec2f(bottomright.x - base_offset + 300, topleft.y), tempGrey);
						GUI::DrawText(taxOn                 , Vec2f(bottomright.x - base_offset + 450, topleft.y), tempGrey);
						//GUI::DrawText(slaOn               , Vec2f(bottomright.x - base_offset + 550, topleft.y), tempGrey);
						GUI::DrawText(lockOn                , Vec2f(bottomright.x - base_offset + 550, topleft.y), tempGrey);
						GUI::DrawText(Maths::Round((f32(team.controlled_count) / f32(total_capturables)) * 100.00f) + "%", Vec2f(bottomright.x - base_offset + 650, topleft.y), tempGrey);
					}
				}
			}
		}
	}

	// Discord Button
	{
		f32 width = 100;
		f32 height = 40;

		const string text = "Go to Dark's Discord Server";

		Vec2f dim;
		GUI::GetTextDimensions(text, dim);

		width = dim.x + 20;

		Vec2f tl = Vec2f(getScreenWidth() - 100 - width, y_offset + 10);
		Vec2f br = Vec2f(getScreenWidth() - 100, tl.y + height);

		CControls@ controls = getControls();
		Vec2f mousePos = controls.getMouseScreenPos();

		bool hover = mousePos.x > tl.x && mousePos.x < br.x && mousePos.y > tl.y && mousePos.y < br.y;

		if (hover)
		{
			GUI::DrawButton(tl, br);

			if (controls.isKeyJustPressed(KEY_LBUTTON))
			{
				Sound::Play("option");

				OpenWebsite("https://discord.gg/ssVRhV6bsU");
				// Engine::AcceptWebsiteOpen(true);
				// Menu::CloseAllMenus();
			}
		}
		else
		{
			GUI::DrawPane(tl, br, 0xffcfcfcf);
		}

		GUI::DrawTextCentered(text, Vec2f(tl.x + (width * 0.50f), tl.y + (height * 0.50f)), 0xffffffff);
	}

	// Blog Button
	{
		f32 width = 100;
		f32 height = 40;

		const string text = "TFlippy's Patreon";

		Vec2f dim;
		GUI::GetTextDimensions(text, dim);

		width = dim.x + 20;

		Vec2f tl = Vec2f(getScreenWidth() - 340 - width, y_offset + 10);
		Vec2f br = Vec2f(getScreenWidth() - 340, tl.y + height);

		CControls@ controls = getControls();
		Vec2f mousePos = controls.getMouseScreenPos();

		bool hover = mousePos.x > tl.x && mousePos.x < br.x && mousePos.y > tl.y && mousePos.y < br.y;

		if (hover)
		{
			GUI::DrawButton(tl, br);

			if (controls.isKeyJustPressed(KEY_LBUTTON))
			{
				Sound::Play("option");

				OpenWebsite("https://www.patreon.com/tflippy");
				// Engine::AcceptWebsiteOpen(true);
				// Menu::CloseAllMenus();
			}
		}
		else
		{
			GUI::DrawPane(tl, br, 0xffcfcfcf);
		}

		GUI::DrawTextCentered(text, Vec2f(tl.x + (width * 0.50f), tl.y + (height * 0.50f)), 0xffffffff);
	}

	// GitHub Button
	{
		f32 width = 100;
		f32 height = 40;

		const string text = "GitHub Repository";

		Vec2f dim;
		GUI::GetTextDimensions(text, dim);

		width = dim.x + 20;

		Vec2f tl = Vec2f(getScreenWidth() - 500 - width, y_offset + 10);
		Vec2f br = Vec2f(getScreenWidth() - 500, tl.y + height);

		CControls@ controls = getControls();
		Vec2f mousePos = controls.getMouseScreenPos();

		bool hover = mousePos.x > tl.x && mousePos.x < br.x && mousePos.y > tl.y && mousePos.y < br.y;

		if (hover)
		{
			GUI::DrawButton(tl, br);

			if (controls.isKeyJustPressed(KEY_LBUTTON))
			{
				Sound::Play("option");
				OpenWebsite("https://github.com/brewskidafixer/TCCTF");
				//OpenWebsite("https://github.com/TFlippy/kag_territorycontrol");
				// Engine::AcceptWebsiteOpen(true);
				// Menu::CloseAllMenus();
			}
		}
		else
		{
			GUI::DrawPane(tl, br, 0xffcfcfcf);
		}

		GUI::DrawTextCentered(text, Vec2f(tl.x + (width * 0.50f), tl.y + (height * 0.50f)), 0xffffffff);
	}

	// Change log Button
	{
		f32 width = 100;
		f32 height = 40;

		const string text = "Change log";

		Vec2f dim;
		GUI::GetTextDimensions(text, dim);

		width = dim.x + 20;

		Vec2f tl = Vec2f(getScreenWidth() - 670 - width, y_offset + 10);
		Vec2f br = Vec2f(getScreenWidth() - 670, tl.y + height);

		CControls@ controls = getControls();
		Vec2f mousePos = controls.getMouseScreenPos();

		bool hover = mousePos.x > tl.x && mousePos.x < br.x && mousePos.y > tl.y && mousePos.y < br.y;

		if (hover)
		{
			GUI::DrawButton(tl, br);

			if (controls.isKeyJustPressed(KEY_LBUTTON))
			{
				Sound::Play("option");
				OpenWebsite("https://github.com/brewskidafixer/TCCTF/commits/main");
				//OpenWebsite("https://change.vamist.dev/tc/");
				// Engine::AcceptWebsiteOpen(true);
				// Menu::CloseAllMenus();
			}
		}
		else
		{
			GUI::DrawPane(tl, br, 0xffcfcfcf);
		}

		GUI::DrawTextCentered(text, Vec2f(tl.x + (width * 0.50f), tl.y + (height * 0.50f)), 0xffffffff);
	}

	CControls@ controls = getControls();
	Vec2f mousePos = controls.getMouseScreenPos();

}

string getRank(string &in username, SColor &out col, CPlayer@ p)
{

	// Note for anybody in the future:
	// Usernames are lower case
	// To get the hash of your username, do:
	// print('username'.getHash()+''); in rcon locally

	switch(username.getHash())
	{
		case -739620667: // vamist
		{
			col = SColor(255, 102, 255, 147);
			return "Ex-Server Host";
		}
		break;

		case -1006374661: // tflippy
		{
			col = SColor(255, 247, 255, 102);
			return "TC Creator";
		}
		break;

		case 2037779103: // digga
		{
			col = SColor(255,255,100,100);
			return "Community Manager";
		}

		case 916202166: // pirate-rob
		{
			col = SColor(255, 117, 166, 244);
			return "RoS Creator";
		}

		case -1483665587: // zable
		{
			col = SColor(255, 102, 255, 147);
			return "Server Host";
		}
		break;

		case 926613433: // blackguy123
		{
			col = SColor(255, 56, 149, 244);
			return "TC CTF Creator";
		}
		break;

		case 1793967571: // merser433
		case -1980129081: // goldenguy
		case -1959624089: // koi_
		case 1002491121: // jammer312
		case -210526304: // mrhobo
		case -675232681: // wunarg
		{
			col = SColor(255, 95, 151, 239);
			return "TC Developer";
		}
		break;

		case -1913766845: // cesar0
		case -445244992: // sylw
		case 306188315: // sjd360
		case 494034411: // turtlecake
		case -608852120: // hobey
		case -1384627824: // oolmbalol
		case -803033509: // garodil
		case -1628567952: // betelgeuse0
		case -1012336410: // megawaffle2000
		{
			col = SColor(255, 247, 156, 44);
			return "TC Contributor";
		}
		break;

		case 498824156: // gokke
		case -1528101978: // ollimarrex
		case 1931891399: // sniper2001
		{
			col = SColor(255, 244, 122, 66);
			return "Super Administrator";
		}

		case -1913960806: // geti
		case 1613635087: // mm
		case -702206699: // flieslikeabrick
		case 1839286352: // furai
		case -1618040870: // jrgp
		case 745727592: // asu
		{
			col = SColor(255, 196, 86, 247);
			return "KAG Developer";
		}
		break;

		//Some patreon thing for the future maybe

		default:
		{
			if (p !is null)
			{
				CSecurity@ security = getSecurity();
				if (!(security.checkAccess_Feature(p, "patreon")))
				{
					return "";
				}
				else
				{
					col = SColor(255, 241, 196, 15);
					return "Patreon Supporter";
				}
			}
			return "";
		}
	}
	return "";
}
