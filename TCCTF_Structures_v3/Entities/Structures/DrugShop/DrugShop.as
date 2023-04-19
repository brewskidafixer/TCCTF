// A script by DarkSlayer

#include "Requirements.as";
#include "ShopCommon.as";
#include "Descriptions.as";
#include "CheckSpam.as";
#include "CTFShopCommon.as";
#include "MakeMat.as";

void onInit(CBlob@ this)
{
	this.set_TileType("background tile", CMap::tile_castle_back);

	this.getSprite().SetZ(-50); //background
	this.getShape().getConsts().mapCollisions = false;

	this.Tag("builder always hit");
	this.Tag("change team on fort capture");

	this.set_Vec2f("shop offset", Vec2f(0, 0));
	this.set_Vec2f("shop menu size", Vec2f(4, 4));
	this.set_string("shop description", "Chemist's Workshop");
	this.set_u8("shop icon", 15);

	{
		ShopItem@ s = addShopItem(this, "Acid(25)", "$mat_acid$", "mat_acid-25", "Acid:\nA foundation material for drug creation");
		AddRequirement(s.requirements, "blob", "mat_meat", "Meat", 25);
		AddRequirement(s.requirements, "coin", "", "", 350);

		s.spawnNothing = true;
	}
	{
		ShopItem@ s = addShopItem(this, "Methane(25)", "$mat_methane$", "mat_methane-25", "Methane: CH4\nA highly flammable gas");
		AddRequirement(s.requirements, "blob", "mat_meat", "Meat", 25);
		AddRequirement(s.requirements, "coin", "", "", 250);

		s.spawnNothing = true;
	}
	{
		ShopItem@ s = addShopItem(this, "Oil(25)", "$mat_oil$", "mat_oil-25", "Oil:\nAmerica's Most Sought Resource");
		AddRequirement(s.requirements, "blob", "mat_coal", "mat_coal", 50);
		AddRequirement(s.requirements, "coin", "", "", 350);

		s.spawnNothing = true;
	}
	{
		ShopItem@ s = addShopItem(this, "Fuel(25)", "$mat_fuel$", "mat_fuel-25", "Fuel:\nJet Fuel");
		AddRequirement(s.requirements, "blob", "mat_oil", "Oil", 25);
		AddRequirement(s.requirements, "blob", "mat_methane", "Methane", 25);
		AddRequirement(s.requirements, "coin", "", "", 750);

		s.spawnNothing = true;
	}
	{
		ShopItem@ s = addShopItem(this, "Domino(1)", "$domino$", "domino-1", "Domino:\n+Max HP\n+Passive HP Regen\n+Mobility\nWithdrawal");
		AddRequirement(s.requirements, "blob", "mat_acid", "Acid", 10);
		AddRequirement(s.requirements, "blob", "mat_mithril", "Mithril", 5);
		AddRequirement(s.requirements, "coin", "", "", 500);

		s.spawnNothing = true;
	}
	{
		ShopItem@ s = addShopItem(this, "Fiks(2)", "$fiks$", "fiks-2", "Fiks:\n+Max HP\n+High HP Regen");
		AddRequirement(s.requirements, "blob", "mat_acid", "Acid", 10);
		AddRequirement(s.requirements, "blob", "mat_mithril", "Mithril", 5);
		AddRequirement(s.requirements, "coin", "", "", 500);

		s.spawnNothing = true;
	}
	{
		ShopItem@ s = addShopItem(this, "Crak(1)", "$crak$", "crak-1", "Crak:\n+Mobility\nDig/Place Speed\nWithdrawal");
		AddRequirement(s.requirements, "blob", "fiks", "fiks", 1);
		AddRequirement(s.requirements, "coin", "", "", 500);

		s.spawnNothing = true;
	}
	{
		ShopItem@ s = addShopItem(this, "Bobongo(1)", "$bobongo$", "bobongo-1", "Bobongo:\n+Mining Yield");
		AddRequirement(s.requirements, "blob", "mat_dirt", "Dirt", 25);
		AddRequirement(s.requirements, "blob", "mat_meat", "Meat", 5);
		AddRequirement(s.requirements, "blob", "mat_acid", "Acid", 10);
		AddRequirement(s.requirements, "coin", "", "", 350);

		s.spawnNothing = true;
	}
	{
		ShopItem@ s = addShopItem(this, "Stim(1)", "$stim$", "stim-1", "Stim:\n+Mobility");
		AddRequirement(s.requirements, "blob", "mat_acid", "Acid", 25);
		AddRequirement(s.requirements, "blob", "mat_sulphur", "Sulphur", 25);
		AddRequirement(s.requirements, "coin", "", "", 500);

		s.spawnNothing = true;
	}
	{
		ShopItem@ s = addShopItem(this, "Rippio(1)", "$rippio$", "rippio-1", "Rippio:\nPoison");
		AddRequirement(s.requirements, "blob", "stim", "stim", 1);
		AddRequirement(s.requirements, "blob", "mat_oil", "Oil", 25);
		AddRequirement(s.requirements, "coin", "", "", 350);

		s.spawnNothing = true;
	}
	{
		ShopItem@ s = addShopItem(this, "Paxilon(1)", "$paxilon$", "paxilon-1", "Paxilon:\nSleep Drug");
		AddRequirement(s.requirements, "blob", "vodka", "Vodka", 1);
		AddRequirement(s.requirements, "blob", "mat_oil", "Oil", 25);
		AddRequirement(s.requirements, "coin", "", "", 250);

		s.spawnNothing = true;
	}
	{
		ShopItem@ s = addShopItem(this, "Gooby(1)", "$gooby$", "gooby-1", "Gooby:\nSuper Soldier drug\n+Massive HP bonus/regen\nWithdrawal");
		AddRequirement(s.requirements, "blob", "rippio", "Rippio", 1);
		AddRequirement(s.requirements, "blob", "fiks", "Fiks", 1);
		AddRequirement(s.requirements, "blob", "mat_dangerousmeat", "High Grade Meat", 20);
		AddRequirement(s.requirements, "coin", "", "", 1250);

		s.spawnNothing = true;
	}
	{
		ShopItem@ s = addShopItem(this, "Bobomax(1)", "$bobomax$", "bobomax-1", "Bobomax:\nTrippy");
		AddRequirement(s.requirements, "blob", "mat_oil", "Oil", 25);
		AddRequirement(s.requirements, "blob", "mat_mithril", "Mithril", 10);
		AddRequirement(s.requirements, "coin", "", "", 350);

		s.spawnNothing = true;
	}
	{
		ShopItem@ s = addShopItem(this, "Babby (1)", "$babby$", "babby-1", "Babby:\nPacifier drug, makes them unable to shoot guns, etc.");
		AddRequirement(s.requirements, "blob", "mat_acid", "Acid", 15);
		AddRequirement(s.requirements, "blob", "mat_coal", "Coal", 10);
		AddRequirement(s.requirements, "coin", "", "", 500);

		s.spawnNothing = true;
	}
	{
		ShopItem@ s = addShopItem(this, "Propesko(1)", "$propesko$", "propesko-1", "Propesko:\nExplode on Death");
		AddRequirement(s.requirements, "blob", "mat_acid", "Acid", 50);
		AddRequirement(s.requirements, "blob", "mat_coal", "Coal", 50);
		AddRequirement(s.requirements, "blob", "mat_sulphur", "Sulphur", 50);
		AddRequirement(s.requirements, "coin", "", "", 1250);

		s.spawnNothing = true;
	}
	{
		ShopItem@ s = addShopItem(this, "Fumes(1)", "$fumes$", "fumes-1", "Fumes:\nWings");
		AddRequirement(s.requirements, "blob", "mat_acid", "Acid", 25);
		AddRequirement(s.requirements, "blob", "mat_coal", "Coal", 25);
		AddRequirement(s.requirements, "blob", "mat_fuel", "Fuel", 25);
		AddRequirement(s.requirements, "coin", "", "", 2500);

		s.spawnNothing = true;
	}
}

void GetButtonsFor(CBlob@ this, CBlob@ caller)
{
	this.set_bool("shop available", this.isOverlapping(caller));
}


// void GetButtonsFor(CBlob@ this, CBlob@ caller)
// {
	// bool canChangeClass = caller.getName() != "sapper";

	// if(canChangeClass)
	// {
		// this.Untag("class button disabled");
		// this.set_Vec2f("shop offset", Vec2f(4, 0));
		// this.set_bool("shop available", this.isOverlapping(caller));
	// }
	// else
	// {
		// this.Tag("class button disabled");
		// this.set_Vec2f("shop offset", Vec2f(0, 0));
		// this.set_bool("shop available", this.isOverlapping(caller));
	// }
// }

void onCommand(CBlob@ this, u8 cmd, CBitStream @params)
{
	if(cmd == this.getCommandID("shop made item"))
	{
		this.getSprite().PlaySound("ConstructShort");

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
			else if (name.findFirst("mat_") != -1)
			{
				CPlayer@ callerPlayer = callerBlob.getPlayer();
				if (callerPlayer is null) return;

				CBlob@ mat = server_CreateBlob(spl[0], callerBlob.getTeamNum(), this.getPosition());

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
				if (spl.length == 2) blob.server_SetQuantity(parseInt(spl[1]));
				if (callerBlob.getPlayer() !is null && name == "nuke")
				{
					blob.SetDamageOwnerPlayer(callerBlob.getPlayer());
				}

				if (!blob.hasTag("vehicle"))
				{
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
}
