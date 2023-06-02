// show menu that only allows to join spectator

#include "SwitchFromSpec.as"

const int BUTTON_SIZE = 2;
const string[] iconName = {
	"$BLUE_TEAM$",
	"$RED_TEAM$",
	"$GREEN_TEAM$",
	"$PURPLE_TEAM$",
	"$ORANGE_TEAM$",
	"$CYAN_TEAM$",
	"$INDIGO_TEAM$"
};
const string[] teamName = {
	"Blue Team",
	"Red Team",
	"Green Team",
	"Purple Team",
	"Orange Team",
	"Cyan Team",
	"Indigo Team"
};

void onInit(CRules@ this)
{
	this.addCommandID("pick teams");
	this.addCommandID("pick none");

	AddIconToken("$TEAMGENERIC$", "Grandpa.png", Vec2f(16, 24), 0);
	AddIconToken("$BLUE_TEAM$", "HeavyChicken.png", Vec2f(32, 16), 0, 0);
	AddIconToken("$RED_TEAM$", "HeavyChicken.png", Vec2f(32, 16), 0, 1);
	AddIconToken("$GREEN_TEAM$", "HeavyChicken.png", Vec2f(32, 16), 0, 2);
	AddIconToken("$PURPLE_TEAM$", "HeavyChicken.png", Vec2f(32, 16), 0, 3);
	AddIconToken("$ORANGE_TEAM$", "HeavyChicken.png", Vec2f(32, 16), 0, 4);
	AddIconToken("$CYAN_TEAM$", "HeavyChicken.png", Vec2f(32, 16), 0, 5);
	AddIconToken("$INDIGO_TEAM$", "HeavyChicken.png", Vec2f(32, 16), 0, 6);
}

void ShowTeamMenu(CRules@ this)
{
	CPlayer@ player = getLocalPlayer();
	if (player is null)
	{
		return;
	}
	bool admin = false;
	u8 teamCount = 2;
	if (getSecurity().checkAccess_Feature(player, "silent_rcon")) admin = true;
	if (admin) teamCount = this.getTeamsCount();

	getHUD().ClearMenus(true);

	CGridMenu@ menu = CreateGridMenu(getDriver().getScreenCenterPos(), null, Vec2f((teamCount + 0.5f) * BUTTON_SIZE, BUTTON_SIZE), "Change team");

	if (menu !is null)
	{
		CBitStream exitParams;
		menu.AddKeyCommand(KEY_ESCAPE, this.getCommandID("pick none"), exitParams);
		menu.SetDefaultCommand(this.getCommandID("pick none"), exitParams);

		string icon, name;
		{
			CBitStream params;
			params.write_u16(player.getNetworkID());
			params.write_u8(this.getSpectatorTeamNum());
			CGridButton@ button2 = menu.AddButton("$TEAMGENERIC$", getTranslatedString("Spectator"), this.getCommandID("pick teams"), Vec2f(BUTTON_SIZE / 2, BUTTON_SIZE), params);
		}
		for (int i = 0; i < teamCount; i++)
		{
			CBitStream params;
			params.write_u16(player.getNetworkID());
			params.write_u8(i);

			icon = iconName[i];
			name = teamName[i];


			CGridButton@ button =  menu.AddButton(icon, getTranslatedString(name), this.getCommandID("pick teams"), Vec2f(BUTTON_SIZE, BUTTON_SIZE), params);
		}
	}
}

// the actual team changing is done in the player management script -> onPlayerRequestTeamChange()

void ReadChangeTeam(CRules@ this, CBitStream @params)
{
	CPlayer@ player = getPlayerByNetworkId(params.read_u16());
	u8 team = params.read_u8();

	if (player is getLocalPlayer())
	{
		if (CanSwitchFromSpec(this, player, team))
		{
			ChangeTeam(player, team);
		}
		else
		{
			client_AddToChat("Game is currently full. Please wait for a new slot before switching teams.", ConsoleColour::GAME);
			Sound::Play("NoAmmo.ogg");
		}
	}
}

void ChangeTeam(CPlayer@ player, u8 team)
{
	player.client_ChangeTeam(team);
	getHUD().ClearMenus();
}

void onCommand(CRules@ this, u8 cmd, CBitStream @params)
{
	if (cmd == this.getCommandID("pick teams"))
	{
		ReadChangeTeam(this, params);
	}
	else if (cmd == this.getCommandID("pick none"))
	{
		getHUD().ClearMenus();
	}
}