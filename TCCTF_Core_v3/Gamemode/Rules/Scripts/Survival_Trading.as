#include "TradingCommon.as";
#include "Descriptions.as"
#include "GameplayEvents.as"
#include "Survival_Structs.as";
#include "CustomBlocks.as";

#define SERVER_ONLY

const int coinsOnDamageAdd = 5;
const int coinsOnKillAdd = 50;
const int coinsOnDeathLose = 10;
const int min_coins = 50;

const int coinsOnDeathLosePercent = 10;
const int coinsOnTKLose = 25;

const int coinsOnRestartAdd = 2500;
const bool keepCoinsOnRestart = false;

const int coinsOnHitSiege = 5;
const int coinsOnKillSiege = 100;

const int coinsOnCapFlag = 100;

const int coinsOnBuild = 4;
const int coinsOnBuildWood = 1;
const int coinsOnBuildWorkshop = 20;

const int warmupFactor = 3;

const u32 MAX_COINS = 30000;

string[] names;

bool kill_traders_and_shops = false;

void GiveRestartCoins(CPlayer@ p)
{
	if (keepCoinsOnRestart)
		p.server_setCoins(p.getCoins() + coinsOnRestartAdd);
	else
		p.server_setCoins(coinsOnRestartAdd);
}

void GiveRestartCoinsIfNeeded(CPlayer@ player)
{
	const string s = player.getUsername();
	for (uint i = 0; i < names.length; ++i)
	{
		if (names[i] == s)
		{
			return;
		}
	}

	names.push_back(s);
	if (player.getCoins() < coinsOnRestartAdd) GiveRestartCoins(player);
}

//extra coins on start to prevent stagnant round start
void Reset(CRules@ this)
{
	names.clear();

	uint count = getPlayerCount();
	for (uint p_step = 0; p_step < count; ++p_step)
	{
		CPlayer@ p = getPlayer(p_step);
		GiveRestartCoins(p);
		names.push_back(p.getUsername());
	}
}

void onRestart(CRules@ this)
{
	Reset(this);
}

void onInit(CRules@ this)
{
	Reset(this);
}

//also given when plugging player -> on first spawn
void onSetPlayer(CRules@ this, CBlob@ blob, CPlayer@ player)
{
	if (player !is null)
	{
		GiveRestartCoinsIfNeeded(player);
	}
}

void onBlobCreated(CRules@ this, CBlob@ blob)
{
	if (blob.getName() == "tradingpost")
	{
		if (kill_traders_and_shops)
		{
			blob.server_Die();
			KillTradingPosts();
		}
		else
		{
			MakeTradeMenu(blob);
		}
	}
}

TradeItem@ addItemForCoin(CBlob@ this, const string &in name, int cost, const bool instantShipping, const string &in iconName, const string &in configFilename, const string &in description)
{
	TradeItem@ item = addTradeItem(this, name, 0, instantShipping, iconName, configFilename, description);
	if (item !is null && cost > 0)
	{
		AddRequirement(item.reqs, "coin", "", "Coins", cost);
		item.buyIntoInventory = true;
	}
	return item;
}

void MakeTradeMenu(CBlob@ trader)
{
	//load config

	s32 menu_width = 3;
	s32 menu_height = 4;

	// build menu
	CreateTradeMenu(trader, Vec2f(menu_width, menu_height), "Buy goods");

	//
	addTradeSeparatorItem(trader, "$MENU_GENERIC$", Vec2f(3, 1));

	addItemForCoin(trader, "Bomb", 25, true, "$mat_bombs$", "mat_bombs", descriptions[1]);
	addItemForCoin(trader, "Working Mine", 60, true, "$mine$", "faultymine", "A completely unsafe and working mine.");
	addItemForCoin(trader, "Arrows", 10, true, "$mat_arrows$", "mat_arrows", descriptions[2]);

	addItemForCoin(trader, "Drill", 100, true, "$drill$", "drill", descriptions[43]);
	addItemForCoin(trader, "Bucket", 5, true, "$bucket$", "bucket", "A bucket for storing water.");
	addItemForCoin(trader, "Lantern", 5, true, "$lantern$", "lantern", "A lantern for lighting up the dark");
	
	addItemForCoin(trader, "Wood", 25, true, "$mat_wood$", "mat_wood", "Woody timber.");
	addItemForCoin(trader, "Stone", 50, true, "$mat_stone$", "mat_stone", "Rocky stone.");

}

// load coins amount

void KillTradingPosts()
{
	CBlob@[] tradingposts;
	bool found = false;
	if (getBlobsByName("tradingpost", @tradingposts))
	{
		for (uint i = 0; i < tradingposts.length; i++)
		{
			CBlob @b = tradingposts[i];
			b.server_Die();
		}
	}
}

// give coins for killing

void onPlayerDie(CRules@ this, CPlayer@ victim, CPlayer@ killer, u8 customData)
{
	if (victim !is null)
	{
		if (!this.isWarmup())	//only reduce coins if the round is on.
		{
			s32 lost = victim.getCoins() * (coinsOnDeathLosePercent * 0.01f);

			victim.server_setCoins(victim.getCoins() - lost);

			CBlob@ blob = victim.getBlob();

			if (killer !is null)
			{
				if (killer !is victim && killer.getTeamNum() != victim.getTeamNum())
				{
					killer.server_setCoins(killer.getCoins() + coinsOnKillAdd + lost*0.5f);
				}
				if (blob !is null)
					server_DropCoins(blob.getPosition(), lost*0.5f);
			}
			else if (blob !is null)
				server_DropCoins(blob.getPosition(), lost);
		}
	}
}

// give coins for damage

f32 onPlayerTakeDamage(CRules@ this, CPlayer@ victim, CPlayer@ attacker, f32 DamageScale)
{
	if (attacker !is null && attacker !is victim && attacker.getTeamNum() != victim.getTeamNum())
	{
        CBlob@ v = victim.getBlob();
        f32 health = 0.0f;
        if(v !is null)
            health = v.getHealth();
        f32 dmg = DamageScale;
        dmg = Maths::Min(health, dmg);

		attacker.server_setCoins(attacker.getCoins() + dmg * coinsOnDamageAdd / this.attackdamage_modifier);
	}

	return DamageScale;
}

void onCommand(CRules@ this, u8 cmd, CBitStream @params)
{
	if (isServer())
	{
		if (cmd == getGameplayEventID(this))
		{
			GameplayEvent g(params);

			CPlayer@ p = g.getPlayer();
			if (p !is null)
			{
				u32 coins = 0;

				switch (g.getType())
				{
					case GE_built_block:
					{
						g.params.ResetBitIndex();
						u16 tile = g.params.read_u16();
						
						switch (tile)
						{
							case CMap::tile_wood_back:
							case CMap::tile_castle_back: coins = 2; break;

							case CMap::tile_wood:
							case CMap::tile_ground:
							case CMap::tile_bconcrete:
							case CMap::tile_biron: coins = 4; break;
							
							case CMap::tile_bplasteel:
							case CMap::tile_castle:
							case CMap::tile_concrete: coins = 6; break;
							
							case CMap::tile_iron: coins = 10; break;
							
							case CMap::tile_reinforcedconcrete: coins = 12; break;
							
							case CMap::tile_plasteel: coins = 16; break;
						}
					}
					break;

					case GE_built_blob:
					{
						g.params.ResetBitIndex();
						string name = g.params.read_string();

						coins = coinsOnBuild;
					}
					break;
				}

				if (coins > 0)
				{
					p.server_setCoins(p.getCoins() + coins);
				}
			}
		}
	}
}