// A script by TFlippy

#include "Requirements.as";
#include "ShopCommon.as";
#include "Descriptions.as";
#include "CheckSpam.as";
#include "CTFShopCommon.as";
#include "MakeMat.as";
#include "MinableMatsCommon.as";

Random traderRandom(Time());

void onInit(CBlob@ this)
{
	// this.set_TileType("background tile", CMap::tile_castle_back);

	// if (isServer()) this.server_setTeamNum(-1);

	this.getSprite().SetZ(-50); //background
	this.getShape().getConsts().mapCollisions = false;

	this.Tag("builder always hit");

	HarvestBlobMat[] mats = {};
	mats.push_back(HarvestBlobMat(150.0f, "mat_wood"));
	this.set("minableMats", mats);	

	AddIconToken("$icon_faultymine$", "FaultyMine.png", Vec2f(16, 16), 1, 7);

	this.set_Vec2f("shop offset", Vec2f(4, 0));
	this.set_Vec2f("shop menu size", Vec2f(4, 5));
	this.set_string("shop description", "Rat's Den");
	this.set_u8("shop icon", 25);

	{
		ShopItem@ s = addShopItem(this, "Tasty Rat Burger", "$ratburger$", "ratburger", "I always ate this as a kid.");
		AddRequirement(s.requirements, "coin", "", "Coins", 31);
		s.spawnNothing = true;
	}
	{
		ShopItem@ s = addShopItem(this, "Very Fresh Rat", "$ratfood$", "ratfood", "I caught this rat myself.");
		AddRequirement(s.requirements, "coin", "", "Coins", 17);
		s.spawnNothing = true;
	}
	{
		ShopItem@ s = addShopItem(this, "Lite Pistal", "$icon_banditpistol$", "banditpistol", "My grandma made this pistol.");
		AddRequirement(s.requirements, "coin", "", "Coins", 70);
		s.spawnNothing = true;
	}
	{
		ShopItem@ s = addShopItem(this, "Timbr Grindr", "$icon_banditrifle$", "banditrifle", "I jammed two pipes in this and it kills people and works it's good.");
		AddRequirement(s.requirements, "coin", "", "Coins", 190);
		s.spawnNothing = true;
	}
	{
		ShopItem@ s = addShopItem(this, "Kill Pebles (5)", "$icon_banditammo$", "mat_banditammo-5", "My grandpa made these.");
		AddRequirement(s.requirements, "coin", "", "Coins", 21);
		s.spawnNothing = true;
	}
	{
		ShopItem@ s = addShopItem(this, "A Working Mine", "$icon_faultymine$", "faultymine", "You should buy this.");
		AddRequirement(s.requirements, "coin", "", "Coins", 33);
		s.spawnNothing = true;
	}
	{
		ShopItem@ s = addShopItem(this, "Bandit Music", "$musicdisc$", "disc-18", "Plays a bandit music!");
		AddRequirement(s.requirements, "coin", "", "Coins", 150);
		s.spawnNothing = true;
	}
	{
		ShopItem@ s = addShopItem(this, "Soviet Anthem", "$musicdisc$", "disc-29", "Plays USSR anthem!");
		AddRequirement(s.requirements, "coin", "", "Coins", 150);
		s.spawnNothing = true;
	}
	{
		ShopItem@ s = addShopItem(this, "Ebic Music", "$musicdisc$", "disc-28", "Plays an ebic music!");
		AddRequirement(s.requirements, "coin", "", "Coins", 150);
		s.spawnNothing = true;
	}
	{
		ShopItem@ s = addShopItem(this, "TC Anthem", "$musicdisc$", "disc-30", "Plays the TC Anthem!");
		AddRequirement(s.requirements, "coin", "", "Coins", 150);
		s.spawnNothing = true;
	}
	{
		ShopItem@ s = addShopItem(this, "Katyusha Катюша", "$musicdisc$", "disc-31", "Plays Katyusha Катюша!");
		AddRequirement(s.requirements, "coin", "", "Coins", 150);
		s.spawnNothing = true;
	}
	{
		ShopItem@ s = addShopItem(this, "Steins Gate: The Last Game", "$musicdisc$", "disc-32", "Plays Steins Gate: The Last Game!");
		AddRequirement(s.requirements, "coin", "", "Coins", 150);
		s.spawnNothing = true;
	}
	{
		ShopItem@ s = addShopItem(this, "Moonsong", "$musicdisc$", "disc-33", "Plays Moonsong!");
		AddRequirement(s.requirements, "coin", "", "Coins", 150);
		s.spawnNothing = true;
	}
	{
		ShopItem@ s = addShopItem(this, "Preparing for War", "$musicdisc$", "disc-34", "Plays Preparing for War!");
		AddRequirement(s.requirements, "coin", "", "Coins", 150);
		s.spawnNothing = true;
	}
}

void GetButtonsFor(CBlob@ this, CBlob@ caller)
{
	this.set_bool("shop available", this.isOverlapping(caller));
}

void onCommand(CBlob@ this, u8 cmd, CBitStream @params)
{
	if (cmd == this.getCommandID("shop made item"))
	{
		this.getSprite().PlaySound("MigrantHmm");
		this.getSprite().PlaySound("ChaChing");

		u16 caller, item;

		if(!params.saferead_netid(caller) || !params.saferead_netid(item))
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
			else if (spl[0] == "disc")
			{
				CBlob@ disc = server_CreateBlobNoInit("musicdisc");
				disc.setPosition(this.getPosition());
				disc.set_u8("track_id", parseInt(spl[1]));
				disc.server_setTeamNum(-1);
				disc.Init();

				if (disc is null) return;

				if (!disc.canBePutInInventory(callerBlob))
				{
					callerBlob.server_Pickup(disc);
				}
				else if (callerBlob.getInventory() !is null && !callerBlob.getInventory().isFull())
				{
					callerBlob.server_PutInInventory(disc);
				}
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

				if (blob is null && callerBlob is null) return;
  
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
}
