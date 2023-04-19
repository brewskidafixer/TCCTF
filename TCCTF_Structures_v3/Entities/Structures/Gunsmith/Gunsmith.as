// A script by TFlippy

#include "Requirements.as";
#include "ShopCommon.as";
#include "Descriptions.as";
#include "CheckSpam.as";
#include "CTFShopCommon.as";
#include "MakeMat.as";

const string[] resources =
{
	"mat_pistolammo",
	"mat_rifleammo",
	"mat_shotgunammo",
	"mat_gatlingammo"
};

const u8[] resourceYields =
{
	100,
	75,
	50,
	200
};

void onInit(CBlob@ this)
{
	this.set_TileType("background tile", CMap::tile_castle_back);

	//this.Tag("upkeep building");
	//this.set_u8("upkeep cap increase", 0);
	//this.set_u8("upkeep cost", 5);

	this.getSprite().SetZ(-50); //background
	this.getShape().getConsts().mapCollisions = false;

	this.Tag("builder always hit");
	this.Tag("change team on fort capture");

	this.getCurrentScript().tickFrequency = 1800;
	this.inventoryButtonPos = Vec2f(-8, 0);

	this.set_Vec2f("shop offset", Vec2f(0,0));
	this.set_Vec2f("shop menu size", Vec2f(4, 7));
	this.set_string("shop description", "Gunsmith's Workshop");
	this.set_u8("shop icon", 15);

	{
		ShopItem@ s = addShopItem(this, "Low Caliber Ammunition (40)", "$icon_pistolammo$", "mat_pistolammo-40", "Bullets for pistols and SMGs.");
		AddRequirement(s.requirements, "coin", "", "Coins", 80);

		s.spawnNothing = true;
	}
	{
		ShopItem@ s = addShopItem(this, "High Caliber Ammunition (30)", "$icon_rifleammo$", "mat_rifleammo-30", "Bullets for rifles. Effective against armored targets.");
		AddRequirement(s.requirements, "coin", "", "Coins", 120);

		s.spawnNothing = true;
	}
	{
		ShopItem@ s = addShopItem(this, "Shotgun Shells (8)", "$icon_shotgunammo$", "mat_shotgunammo-8", "Shotgun Shells for... Shotguns.");
		AddRequirement(s.requirements, "coin", "", "Coins", 120);

		s.spawnNothing = true;
	}
	{
		ShopItem@ s = addShopItem(this, "Machine Gun Ammunition (50)", "$icon_gatlingammo$", "mat_gatlingammo-50", "Ammunition used by the machine gun.");
		AddRequirement(s.requirements, "coin", "", "Coins", 100);

		s.spawnNothing = true;
	}
	{
		ShopItem@ s = addShopItem(this, "Revolver", "$revolver$", "revolver", "A compact firearm for those with small pockets.\n\nUses Low Caliber Ammunition.\n$icon_pistolammo$");
		AddRequirement(s.requirements, "coin", "", "Coins", 125);

		s.customButton = true;
		s.buttonwidth = 1;
		s.buttonheight = 1;

		s.spawnNothing = true;
	}
	{
		ShopItem@ s = addShopItem(this, "Bobby Gun", "$smg$", "smg", "A submachine gun.\n\nUses Low Caliber Ammunition.\n$icon_pistolammo$");
		AddRequirement(s.requirements, "coin", "", "Coins", 150);

		s.customButton = true;
		s.buttonwidth = 1;
		s.buttonheight = 1;

		s.spawnNothing = true;
	}
	{
		ShopItem@ s = addShopItem(this, "Bolt Action Rifle", "$rifle$", "rifle", "A handy bolt action rifle.\n\nUses High Caliber Ammunition.\n$icon_rifleammo$");
		AddRequirement(s.requirements, "coin", "", "Coins", 175);

		s.customButton = true;
		s.buttonwidth = 1;
		s.buttonheight = 1;

		s.spawnNothing = true;
	}
	{
		ShopItem@ s = addShopItem(this, "Lever Action Rifle", "$leverrifle$", "leverrifle", "A speedy lever action rifle.\n\nUses High Caliber Ammunition.\n$icon_rifleammo$");
		AddRequirement(s.requirements, "coin", "", "Coins", 200);

		s.customButton = true;
		s.buttonwidth = 1;
		s.buttonheight = 1;

		s.spawnNothing = true;
	}
	{
		ShopItem@ s = addShopItem(this, "Fuger", "$fuger$", "fuger", "A UPF Fuger Pistol.\n\nUses Low Caliber Ammunition.\n$icon_pistolammo$");
		AddRequirement(s.requirements, "coin", "", "Coins", 350);

		s.customButton = true;
		s.buttonwidth = 1;
		s.buttonheight = 1;

		s.spawnNothing = true;
	}
	{
		ShopItem@ s = addShopItem(this, "Uzi", "$uzi$", "uzi", "A UPF Uzi.\n\nUses Low Caliber Ammunition.\n$icon_pistolammo$");
		AddRequirement(s.requirements, "coin", "", "Coins", 500);

		s.customButton = true;
		s.buttonwidth = 1;
		s.buttonheight = 1;

		s.spawnNothing = true;
	}
	{
		ShopItem@ s = addShopItem(this, "PDW", "$pdw$", "pdw", "A UPF PDW.\n\nUses Low Caliber Ammunition.\n$icon_pistolammo$");
		AddRequirement(s.requirements, "coin", "", "Coins", 750);

		s.customButton = true;
		s.buttonwidth = 1;
		s.buttonheight = 1;

		s.spawnNothing = true;
	}
	{
		ShopItem@ s = addShopItem(this, "Carbine", "$carbine$", "carbine", "A UPF Carbine.\n\nUses High Caliber Ammunition.\n$icon_rifleammo$");
		AddRequirement(s.requirements, "coin", "", "Coins", 850);

		s.customButton = true;
		s.buttonwidth = 1;
		s.buttonheight = 1;

		s.spawnNothing = true;
	}
	{
		ShopItem@ s = addShopItem(this, "Semi Automatic Rifle", "$sar$", "sar", "A UPF Semi Automatic Rifle.\n\nUses High Caliber Ammunition.\n$icon_rifleammo$");
		AddRequirement(s.requirements, "coin", "", "Coins", 1350);

		s.customButton = true;
		s.buttonwidth = 2;
		s.buttonheight = 1;

		s.spawnNothing = true;
	}
	{
		ShopItem@ s = addShopItem(this, "Assault Rifle", "$assaultrifle$", "assaultrifle", "A UPF Assault Rifle.\n\nUses High Caliber Ammunition.\n$icon_rifleammo$");
		AddRequirement(s.requirements, "coin", "", "Coins", 1750);

		s.customButton = true;
		s.buttonwidth = 2;
		s.buttonheight = 1;

		s.spawnNothing = true;
	}
	{
		ShopItem@ s = addShopItem(this, "Suppressed Rifle", "$silencedrifle$", "silencedrifle", "A UPF Suppressed Rifle.\n\nUses High Caliber Ammunition.\n$icon_rifleammo$");
		AddRequirement(s.requirements, "coin", "", "Coins", 1850);

		s.customButton = true;
		s.buttonwidth = 2;
		s.buttonheight = 1;

		s.spawnNothing = true;
	}
	{
		ShopItem@ s = addShopItem(this, "Auto Shotgun", "$autoshotgun$", "autoshotgun", "A UPF Auto Shotgun.\n\nUses Shotgun Shells.\n$icon_shotgunammo$");
		AddRequirement(s.requirements, "coin", "", "Coins", 3250);

		s.customButton = true;
		s.buttonwidth = 2;
		s.buttonheight = 1;

		s.spawnNothing = true;
	}
	{
		ShopItem@ s = addShopItem(this, "Bazooka", "$icon_bazooka$", "bazooka", "A long tube capable of shooting rockets. Make sure nobody is standing behind it.\n\nUses Small Rockets.");
		AddRequirement(s.requirements, "coin", "", "Coins", 500);

		s.customButton = true;
		s.buttonwidth = 2;
		s.buttonheight = 1;

		s.spawnNothing = true;
	}
	{
		ShopItem@ s = addShopItem(this, "Shotgun", "$icon_shotgun$", "shotgun", "A short-ranged weapon that deals devastating damage.\n\nUses Shotgun Shells.\n$icon_shotgunammo$");
		AddRequirement(s.requirements, "coin", "", "Coins", 300);

		s.customButton = true;
		s.buttonwidth = 2;
		s.buttonheight = 1;

		s.spawnNothing = true;
	}
	{
		ShopItem@ s = addShopItem(this, "RPG", "$rpg$", "rpg", "A UPF RPG.\n\nUses Grenades as Ammunition.");
		AddRequirement(s.requirements, "coin", "", "Coins", 3500);

		s.customButton = true;
		s.buttonwidth = 2;
		s.buttonheight = 1;

		s.spawnNothing = true;
	}
	{
		ShopItem@ s = addShopItem(this, "Grenade Launcher", "$icon_grenadelauncher$", "grenadelauncher", "A short-ranged weapon that launches grenades.\n\nUses Grenades.");
		AddRequirement(s.requirements, "blob", "mat_steelingot", "Steel Ingot", 5);
		AddRequirement(s.requirements, "blob", "mat_wood", "Wood", 100);
		AddRequirement(s.requirements, "coin", "", "Coins", 4000);

		s.customButton = true;
		s.buttonwidth = 2;
		s.buttonheight = 1;

		s.spawnNothing = true;
	}
}

void onTick(CBlob@ this)
{
	if(isServer())
	{
		for (u8 i = 0;i<4;i++)
		{
			if (!this.getInventory().isFull())
			{
				MakeMat(this, this.getPosition(), resources[i], XORRandom(resourceYields[i]));
			}
		}
	}
}

bool isInventoryAccessible(CBlob@ this, CBlob@ forBlob)
{
	return forBlob.getName() == "extractor" || (forBlob.isOverlapping(this) && forBlob.getCarriedBlob() is null);
}

void GetButtonsFor(CBlob@ this, CBlob@ caller)
{
	CBlob@ carried = caller.getCarriedBlob();

	if (isInventoryAccessible(this, caller))
	{
		this.set_Vec2f("shop offset", Vec2f(4, 0));
		this.set_bool("shop available", this.isOverlapping(caller));
	}
	else
	{
		this.set_Vec2f("shop offset", Vec2f(0, 0));
		this.set_bool("shop available", this.isOverlapping(caller));
	}
}

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

				MakeMat(callerBlob, this.getPosition(), spl[0], parseInt(spl[1]));

				// CBlob@ mat = server_CreateBlob(spl[0]);

				// if (mat !is null)
				// {
					// mat.Tag("do not set materials");
					// mat.server_SetQuantity(parseInt(spl[1]));
					// if (!callerBlob.server_PutInInventory(mat))
					// {
						// mat.setPosition(callerBlob.getPosition());
					// }
				// }
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
}
