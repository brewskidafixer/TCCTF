// A script by TFlippy

#include "Requirements.as";
#include "ShopCommon.as";
#include "Descriptions.as";
#include "CheckSpam.as";
#include "CTFShopCommon.as";
#include "MakeMat.as";
#include "MakeCrate.as";

Random traderRandom(Time());

void onInit(CBlob@ this)
{
	// this.set_TileType("background tile", CMap::tile_castle_back);

	this.getSprite().SetZ(500); //background
	this.getShape().getConsts().mapCollisions = false;

	this.Tag("builder always hit");
		
	this.getCurrentScript().tickFrequency = 300;
			
	this.getShape().SetOffset(Vec2f(0, 4));
	
	AddIconToken("$ratburger$", "RatBurger.png", Vec2f(16, 16), 0);
	AddIconToken("$ratfood$", "Rat.png", Vec2f(16, 16), 0);
	AddIconToken("$faultymine$", "FaultyMine.png", Vec2f(16, 16), 0);
	AddIconToken("$badger$", "Badger.png", Vec2f(32, 16), 0);
	AddIconToken("$icon_banditpistol$", "BanditPistol.png", Vec2f(16, 8), 0);
	
	this.set_Vec2f("shop offset", Vec2f(0, 0));
	this.set_Vec2f("shop menu size", Vec2f(3, 1));
	this.set_string("shop description", "Badger Den");
	this.set_u8("shop icon", 25);

	/*
	{
		ShopItem@ s = addShopItem(this, "raise a badger", "$steak$", "badger", "Groo. <3");
		AddRequirement(s.requirements, "blob", "steak", "Steak", 1);
		
		s.spawnNothing = true;
	}
	*/
	{
		ShopItem@ s = addShopItem(this, "butcher a badger", "$badger$", "butcher", "Groo. <3");
		AddRequirement(s.requirements, "blob", "badger", "dead badger", 1);
		
		s.spawnNothing = true;
	}
	{
		ShopItem@ s = addShopItem(this, "Buy a Friend (1)", "$heart$", "friend", "bison. >:(");
		//AddRequirement(s.requirements, "coin", "", "Coins", 6666);
		AddRequirement(s.requirements, "blob", "steak", "Steak", 3);
		AddRequirement(s.requirements, "blob", "heart", "Heart", 1);
		AddRequirement(s.requirements, "blob", "food", "Burger",3);
		s.spawnNothing = true;
	}
}

void onTick(CBlob@ this)
{
	if (isServer())
	{
		if (XORRandom(100) > 5) return;
	
		// getMap().getBlobsInBox(this.getPosition() + Vec2f(96, -96), this.getPosition() + Vec2f(-64, 64), @blobs);
	
		CBlob@[] blobs;
		getBlobsByTag("badger", @blobs);
		
		if (blobs.length < 10) server_CreateBlob("badger", this.getTeamNum(), this.getPosition() + getRandomVelocity(0, XORRandom(16), 360));
	}
}

void GetButtonsFor(CBlob@ this, CBlob@ caller)
{
	// print("" + (caller.getPosition() - this.getPosition()).Length());
	this.set_bool("shop available", (caller.getPosition() - this.getPosition()).Length() < 40.0f);
}

bool doesCollideWithBlob(CBlob@ this, CBlob@ blob)
{
	return false;
}

void onCommand(CBlob@ this, u8 cmd, CBitStream @params)
{
	if(cmd == this.getCommandID("shop made item"))
	{
		this.getSprite().PlaySound("badger_growl" + (XORRandom(6) + 1) + ".ogg");
		
		u16 caller, item;
		
		if(!params.saferead_netid(caller) || !params.saferead_netid(item))
			return;
		
		string name = params.read_string();
		CBlob@ callerBlob = getBlobByNetworkID(caller);
		
		if (callerBlob is null) return;
		
		if (isServer())
		{
			string[] spl = name.split("-");
			
			/*if (spl[0] == "coin")
			{
				CPlayer@ callerPlayer = callerBlob.getPlayer();
				if (callerPlayer is null) return;
				
				callerPlayer.server_setCoins(callerPlayer.getCoins() +  parseInt(spl[1]));
			}*/
			if (spl[0] == "butcher"){
				CBlob@ steak = server_CreateBlob("steak", -1, this.getPosition());
				if (steak !is null)
				{
					steak.server_SetQuantity(3*this.getQuantity());
					if (!callerBlob.server_PutInInventory(steak))
					{
						steak.setPosition(callerBlob.getPosition());
					}
				}
				CBlob@ heart = server_CreateBlob("heart", -1, this.getPosition());
				if (heart !is null)
				{
					if (!callerBlob.server_PutInInventory(heart))
					{
						heart.setPosition(callerBlob.getPosition());
					}
				}
			}
			else if (spl[0] == "friend")
			{
				string friend = "bison"; //spl[0].replace("rien", "sche").replace("f", "").replace("ch", "cy").replace("d", "er").replace("ee", "the");
				//CBlob@ blob = server_CreateBlob(friend, callerBlob.getTeamNum(), this.getPosition());
				server_MakeCrate(friend, friend, 0, this.getTeamNum(), this.getPosition(), true, 1);
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
