// A script by TFlippy

#include "Requirements.as";
#include "ShopCommon.as";
#include "Descriptions.as";
#include "CheckSpam.as";
#include "CTFShopCommon.as";
#include "MakeMat.as";

Random traderRandom(Time());
const string[] upgrade = {
	"You can upgrade lab with copper ingots - hold ingots in hand.",
	"You can upgrade lab with steel ingots - hold ingots in hand.",
	"You can upgrade reactor with mithril ingots - hold ingots in hand.",
	"You can upgrade reactor with steel ingots - hold ingots in hand."
};

const string[] armor = {
	"Armor has durability! Repair armor in armories if badly damaged.",
	"Helmets can absorb up to 25 hearts.",
	"Bulletproof Vests can absorb up to 30 hearts.",
	"Armor from armories aren't the only equipment that offers protection when worn. e.g. bucket/keg/scuba",
	"Armor can be durability can be restored by storing it inside an armory's smart storage",
	"The more damaged your armor, the less effective it is."
};

const string[] drug = {
	"You can make acid and methane by adding meat to druglab, and when the heat is greater than 300, press react!",
	"Druglabs explode when the pressure goes over its limit.",
	"Stim Recipe: 25,000 pressure, 400 heat; 50 acid, 50 sulphur.",
	"Gooby Recipe: 25,000 pressure, 1000 heat; 45 High Grade Meat(HG meat).",
	"Explodium Recipe: Less than 300 heat; 15 High Grade Meat(HG meat)."
};

const string[] rando = {
	"You could get enriched mithril while making domino in older versions of tc!",
	"Coal mines produce more resources when captured and hooked up to a silo.",
	"`The only cure is death.` - TFlippy",
	"`Vamist finally caught participating in illegal activities` - TFlippy",
	"TFlippy left TC to make TC2 :kag_cry:",
	"You can make pumpkin/grain farms and sell your crops for coins at the Merchant.",
	"South Africa is a country and not a region mind blowing",
	"Vamist once carried crates for a living. L moment",
	"Firework Kungfu will one day return",
	"JimTheSmith paid $50 for a blue role on discord... bruh",
	"Dark will one day make TC CTF... prob 2050||edit: omg I did it already lol",
	"TC2 will one day replace the current TC",
	"In TC, there was a Great Clan War back in 2018, involving the clans: DARK and USSR",
	"Mithrios may one day return...",
	"Mithrios, DarkSlayer, and Gingerbeard once formed a pact prior to USSR",
	"You can get TC2 right now, go to: www.patreon.com/tflippy",
	"Rajang has a history of spawning 50+ firewaves in TC...",
	"gog is the best player in TC",
	"There once existed a man named advan who created a clan named Ivan, and now has an altar called Ivan Altar.",
	"There once was a man/devil named Mithrios who brought havoc to TC, so he was nerfed, as his power was too great, which had brought unbalance to TC.",
	"Magic was banned in TC due to the great wizard wars back then",
	"Back then, guns did not exist in TC, so nor did UPF"
};

void onInit(CBlob@ this)
{
	this.set_TileType("background tile", CMap::tile_castle_back);

	// this.Tag("upkeep building");
	// this.set_u8("upkeep cap increase", 0);
	// this.set_u8("upkeep cost", 5);

	this.getSprite().SetZ(-50); //background
	this.getShape().getConsts().mapCollisions = false;

	this.Tag("builder always hit");
	this.Tag("change team on fort capture");

	// getMap().server_SetTile(this.getPosition(), CMap::tile_wood_back);

	AddIconToken("$filled_bucket$", "bucket.png", Vec2f(16, 16), 1);

	this.set_Vec2f("shop offset", Vec2f(0,0));
	this.set_Vec2f("shop menu size", Vec2f(3, 5));
	this.set_string("shop description", "Bookworm's Lair");
	this.set_u8("shop icon", 15);

	this.addCommandID("upgrade");

	{
		ShopItem@ s = addShopItem(this, "Chemistry Blueprint", "$bp_chemistry$", "bp_chemistry", "The blueprint for the automated druglab.", true);
		AddRequirement(s.requirements, "coin", "", "Coins", 5000);

		s.spawnNothing = true;
	}
	{
		ShopItem@ s = addShopItem(this, "Adv Automation Blueprint", "$bp_automation_advanced$", "bp_automation_advanced", "The blueprint for the automated chicken assembler.", true);
		AddRequirement(s.requirements, "coin", "", "Coins", 3000);

		s.spawnNothing = true;
	}
	{
		ShopItem@ s = addShopItem(this, "Energetics Blueprint", "$bp_energetics$", "bp_energetics", "The blueprint for the beam tower.", true);
		AddRequirement(s.requirements, "coin", "", "Coins", 7500);

		s.spawnNothing = true;
	}
	{
		ShopItem@ s = addShopItem(this, "Sell Chemistry", "$COIN$", "coin-2000", "Sell blueprint for 2000 coins.");
		AddRequirement(s.requirements, "blob", "bp_chemistry", "Chemistry Blueprint", 1);
		s.spawnNothing = true;
	}
	{
		ShopItem@ s = addShopItem(this, "Sell Adv Automation", "$COIN$", "coin-1500", "Sell blueprint for 1500 coins.");
		AddRequirement(s.requirements, "blob", "bp_automation_advanced", "Adv Automation Blueprint", 1);
		s.spawnNothing = true;
	}
	{
		ShopItem@ s = addShopItem(this, "Sell Energetics", "$COIN$", "coin-1000", "Sell blueprint for 1000 coins.");
		AddRequirement(s.requirements, "blob", "bp_energetics", "Energetics Blueprint", 1);
		s.spawnNothing = true;
	}
	{
		ShopItem@ s = addShopItem(this, "Upgrading", "$paper$", "paper-upgrade", "Learn an interesting fact about upgrading laboratories");
		AddRequirement(s.requirements, "coin", "", "Coins", 10000);
		s.spawnNothing = true;
	}
	{
		ShopItem@ s = addShopItem(this, "Armor", "$paper$", "paper-armor", "Learn an interesting fact about armor and equipment.");
		AddRequirement(s.requirements, "coin", "", "Coins", 1000);
		s.spawnNothing = true;
	}
	{
		ShopItem@ s = addShopItem(this, "Drug Information", "$paper$", "paper-drug", "Learn an interesting fact about creating drugs.");
		AddRequirement(s.requirements, "coin", "", "Coins", 2000);
		s.spawnNothing = true;
	}
	{
		ShopItem@ s = addShopItem(this, "Random Facts", "$paper$", "paper-random", "Want to learn a random fact eh?");
		AddRequirement(s.requirements, "coin", "", "Coins", 500);
		s.spawnNothing = true;
	}
	if (this.hasTag("juggernauthammer"))
	{
		ShopItem@ s = addShopItem(this, "Construct Juggernaut Hammer", "$juggernauthammer$", "juggernauthammer", "Create a Juggernaut Hammer");
		AddRequirement(s.requirements, "blob", "mat_steelingot", "Steel Ingot", 10);
		AddRequirement(s.requirements, "blob", "mat_ironingot", "Iron Ingot", 20);
		AddRequirement(s.requirements, "blob", "foof", "Foof Juice", 2);
		AddRequirement(s.requirements, "blob", "fiks", "Fiks", 5);
		AddRequirement(s.requirements, "coin", "", "Coins", 1750);
		s.spawnNothing = true;
	}
	if (this.hasTag("ninjascroll"))
	{
		ShopItem@ s = addShopItem(this, "Purchase Ninja Scroll", "$ninjascroll$", "ninjascroll", "Purchase a ninja scroll replica.");
		AddRequirement(s.requirements, "blob", "nightstick", "Wooden Stick", 1);
		AddRequirement(s.requirements, "coin", "", "Coins", 850);
		s.spawnNothing = true;
	}
	if (this.hasTag("gyromat"))
	{
		ShopItem@ s = addShopItem(this, "Construct Gyromat", "$gyromat$", "gyromat", "Construct a gyromat.");
		AddRequirement(s.requirements, "blob", "mat_ironingot", "Iron Ingot", 10);
		AddRequirement(s.requirements, "blob", "mat_copperingot", "Copper Ingot", 5);
		AddRequirement(s.requirements, "blob", "mat_copperwire", "Copper Wire", 20);
		AddRequirement(s.requirements, "coin", "", "Coins", 850);
		s.spawnNothing = true;
	}
	if (this.hasTag("mat_mithril") && this.hasTag("mat_mithrilingot"))
	{
		ShopItem@ s = addShopItem(this, "Construct Mithril Ingot", "$mat_mithrilingot$", "mat_mithrilingot-10", "Synthesize Mithril Ingots.");
		AddRequirement(s.requirements, "blob", "mat_mithril", "Mithril", 100);
		AddRequirement(s.requirements, "coin", "", "Coins", 175);
		s.spawnNothing = true;
	}
}

void GetButtonsFor(CBlob@ this, CBlob@ caller)
{
	this.set_bool("shop available", this.isOverlapping(caller));

	if (this.isOverlapping(caller))
	{
		CBlob@ carried = caller.getCarriedBlob();

		if (carried != null && (carried.getName() == "juggernauthammer" || carried.getName() == "ninjascroll" || carried.getName() == "gyromat" || carried.getName() == "mat_mithrilingot" || carried.getName() == "mat_mithril"))
		{
			if (!this.hasTag(carried.getName()))
			{
				CBitStream params;
				params.write_u16(caller.getNetworkID());
				CButton@ button = caller.CreateGenericButton(23, Vec2f(0, -8), this, this.getCommandID("upgrade"), "Research Item", params);
			}
		}
	}
}

void onCommand(CBlob@ this, u8 cmd, CBitStream @params)
{
	if (cmd == this.getCommandID("shop made item"))
	{
		this.getSprite().PlaySound("ConstructShort");

		u16 caller, item;

		if (!params.saferead_netid(caller) || !params.saferead_netid(item))
			return;

		string name = params.read_string();
		CBlob@ callerBlob = getBlobByNetworkID(caller);

		if (callerBlob is null) return;

		if (isServer())
		{
			string[] spl = name.split("-");

			if (spl[0] == "coin")
			{
				CPlayer@ callerPlayer = callerBlob.getPlayer();
				if (callerPlayer is null) return;

				callerPlayer.server_setCoins(callerPlayer.getCoins() +  parseInt(spl[1]));
			}
			else if (spl[0] == "paper")
			{
				string text = "Nothing";
				if (spl[1] == "upgrade")
				{
					u8 index = XORRandom(upgrade.length);
					text = upgrade[index];
				}
				else if (spl[1] == "armor")
				{
					u8 index = XORRandom(armor.length);
					text = armor[index];
				}
				else if (spl[1] == "drug")
				{
					u8 index = XORRandom(drug.length);
					text = drug[index];
				}
				else if (spl[1] == "random")
				{
					u8 index = XORRandom(rando.length);
					text = rando[index];
				}

				CBlob@ paper = server_CreateBlobNoInit("paper");
				paper.setPosition(this.getPosition());
				paper.server_setTeamNum(this.getTeamNum());
				paper.set_string("text", text);
				paper.Init();
			}
			else if (name.findFirst("mat_") != -1)
			{
				CPlayer@ callerPlayer = callerBlob.getPlayer();
				if (callerPlayer is null) return;

				CBlob@ mat = server_CreateBlob(spl[0]);

				if (mat !is null)
				{
					mat.Tag("do not set materials");
					mat.server_SetQuantity(parseInt(spl[1]));
					if (!callerBlob.server_PutInInventory(mat))
					{
						mat.setPosition(callerBlob.getPosition());
					}
				}
			}
			else
			{
				CBlob@ blob = server_CreateBlob(spl[0], callerBlob.getTeamNum(), this.getPosition());

				if (blob is null) return;

				if (!blob.canBePutInInventory(callerBlob))
				{
					callerBlob.server_Pickup(blob);
				}
				else if (callerBlob.getInventory() !is null && !callerBlob.getInventory().isFull())
				{
					callerBlob.server_PutInInventory(blob);
				}
			}
		}
	}
	else if (cmd == this.getCommandID("upgrade"))
	{
		CBlob@ caller = getBlobByNetworkID(params.read_u16());
		if (caller !is null)
		{
			CBlob@ carried = caller.getCarriedBlob();
			if (carried !is null)
			{
				if (carried.getName() == "juggernauthammer" || carried.getName() == "ninjascroll" || carried.getName() == "gyromat")
				{
					if (carried.getName() == "juggernauthammer" && !this.hasTag("juggernauthammer"))
					{
						ShopItem@ s = addShopItem(this, "Construct Juggernaut Hammer", "$juggernauthammer$", "juggernauthammer", "Create a Juggernaut Hammer");
						AddRequirement(s.requirements, "blob", "mat_steelingot", "Steel Ingot", 10);
						AddRequirement(s.requirements, "blob", "mat_ironingot", "Iron Ingot", 20);
						AddRequirement(s.requirements, "blob", "foof", "Foof Juice", 2);
						AddRequirement(s.requirements, "blob", "fiks", "Fiks", 5);
						AddRequirement(s.requirements, "coin", "", "Coins", 1750);
						s.spawnNothing = true;
					}
					else if (carried.getName() == "ninjascroll" && !this.hasTag("ninjascroll"))
					{
						ShopItem@ s = addShopItem(this, "Purchase Ninja Scroll", "$ninjascroll$", "ninjascroll", "Purchase a ninja scroll replica.");
						AddRequirement(s.requirements, "blob", "nightstick", "Wooden Stick", 1);
						AddRequirement(s.requirements, "coin", "", "Coins", 850);
						s.spawnNothing = true;
					}
					else if (carried.getName() == "gyromat" && !this.hasTag("gyromat"))
					{
						ShopItem@ s = addShopItem(this, "Construct Gyromat", "$gyromat$", "gyromat", "Construct a gyromat.");
						AddRequirement(s.requirements, "blob", "mat_ironingot", "Iron Ingot", 10);
						AddRequirement(s.requirements, "blob", "mat_copperingot", "Copper Ingot", 5);
						AddRequirement(s.requirements, "blob", "mat_copperwire", "Copper Wire", 20);
						AddRequirement(s.requirements, "coin", "", "Coins", 850);
						s.spawnNothing = true;
					}
					this.Tag(carried.getName());
					carried.server_Die();
				}
				else if (!this.hasTag(carried.getName()) && (carried.getName() == "mat_mithrilingot" || carried.getName() == "mat_mithril"))
				{
					u8 cost = 100;
					if (carried.getName() == "mat_mithrilingot") cost = 10;
					if (carried.getQuantity() >= cost)
					{
						int remain = carried.getQuantity() - cost;
						if (remain > 0)
						{
							carried.server_SetQuantity(remain);
						}
						else
						{
							carried.Tag("dead");
							carried.server_Die();
						}
						this.Tag(carried.getName());
						if (this.hasTag("mat_mithril") && this.hasTag("mat_mithrilingot"))
						{
							ShopItem@ s = addShopItem(this, "Construct Mithril Ingot", "$mat_mithrilingot$", "mat_mithrilingot-10", "Synthesize Mithril Ingots.");
							AddRequirement(s.requirements, "blob", "mat_mithril", "Mithril", 100);
							AddRequirement(s.requirements, "coin", "", "Coins", 175);
							s.spawnNothing = true;
						}
					}
					else if (caller.isMyPlayer()) client_AddToChat("Not enough! Upgrade costs "+cost, SColor(0xff444444));
				}
			}
		}
	}
}
