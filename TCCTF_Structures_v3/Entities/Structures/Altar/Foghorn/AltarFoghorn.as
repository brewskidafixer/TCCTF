#include "Requirements.as";
#include "Requirements_Tech.as";
#include "ShopCommon.as";
#include "DeityCommon.as";
#include "MakeSeed.as";

void onInit(CBlob@ this)
{
	this.set_u8("deity_id", Deity::foghorn);
	this.set_Vec2f("shop menu size", Vec2f(3, 3));
	this.getCurrentScript().tickFrequency = 90;
	this.set_string("classtype", "scoutchicken");
	
	CSprite@ sprite = this.getSprite();
	sprite.SetEmitSound("ChickenMarch.ogg");
	sprite.SetEmitSoundVolume(0.40f);
	sprite.SetEmitSoundSpeed(1.00f);
	sprite.SetEmitSoundPaused(false);
	
	this.SetLight(true);
	this.SetLightRadius(48.0f);
	this.SetLightColor(SColor(255, 170, 255, 61));
	
	{
		ShopItem@ s = addShopItem(this, "Upgrade Altar", "$phone$", "offering_phone", "Upgrade Altar by sacrificing your iPhone XXX.");
		AddRequirement(s.requirements, "blob", "phone", "iPhone XXX", 1);
		s.customButton = true;
		s.buttonwidth = 1;	
		s.buttonheight = 1;
		
		s.spawnNothing = true;
	}
	{
		ShopItem@ s = addShopItem(this, "Offer Scrub's Chow", "$foodcan$", "offering_scrubs", "Sacrifice Scrub's chow in return for power.");
		AddRequirement(s.requirements, "blob", "foodcan", "Scrub's Chow", 20);
		s.customButton = true;
		s.buttonwidth = 1;	
		s.buttonheight = 1;
		
		s.spawnNothing = true;
	}
	{
		ShopItem@ s = addShopItem(this, "Chicken's Outfit", "$chickentools$", "chickentools", "Morph into a chicken using chickentools.", true);
		AddRequirement(s.requirements, "blob", "chicken", "Chicken", 1);
		AddRequirement(s.requirements, "coin", "", "Coins", 1250);

		s.spawnNothing = true;
	}
	{
		ShopItem@ s = addShopItem(this, "Recruit a UPF Scout", "$scoutchicken$", "offering_summon-1", "Enlist a UPF Chicken Scout.", true);
		AddRequirement(s.requirements, "blob", "egg", "Egg", 1);
		AddRequirement(s.requirements, "blob", "lighthelmet", "Light Helmet", 1);
		AddRequirement(s.requirements, "blob", "lightvest", "Light Vest", 1);
		AddRequirement(s.requirements, "coin", "", "Coins", 1500);
		s.customButton = true;
		s.buttonwidth = 1;
		s.buttonheight = 1;

		s.spawnNothing = true;
	}
	{
		ShopItem@ s = addShopItem(this, "Recruit a UPF Soldier", "$soldierchicken$", "offering_summon-2", "Enlist a UPF Chicken Soldier.", true);
		AddRequirement(s.requirements, "blob", "egg", "Egg", 1);
		AddRequirement(s.requirements, "blob", "mediumhelmet", "Medium Helmet", 1);
		AddRequirement(s.requirements, "blob", "mediumvest", "Medium Vest", 1);
		AddRequirement(s.requirements, "coin", "", "Coins", 3500);
		s.customButton = true;
		s.buttonwidth = 1;
		s.buttonheight = 1;

		s.spawnNothing = true;
	}
	{
		ShopItem@ s = addShopItem(this, "Recruit a UPF Heavy", "$heavychicken$", "offering_summon-3", "Enlist a UPF Chicken Heavy.", true);
		AddRequirement(s.requirements, "blob", "egg", "Egg", 1);
		AddRequirement(s.requirements, "blob", "heavyhelmet", "Heavy Helmet", 1);
		AddRequirement(s.requirements, "blob", "heavyvest", "Heavy Vest", 1);
		AddRequirement(s.requirements, "coin", "", "Coins", 7500);
		s.customButton = true;
		s.buttonwidth = 1;
		s.buttonheight = 1;

		s.spawnNothing = true;
	}
	{
		ShopItem@ s = addShopItem(this, "Recruit a UPF Commander", "$commanderchicken$", "offering_summon-4", "Enlist a UPF Chicken Commander.", true);
		AddRequirement(s.requirements, "blob", "egg", "Egg", 1);
		AddRequirement(s.requirements, "blob", "lighthelmet", "Light Helmet", 1);
		AddRequirement(s.requirements, "blob", "mediumvest", "Medium Vest", 1);
		AddRequirement(s.requirements, "coin", "", "Coins", 5000);
		s.customButton = true;
		s.buttonwidth = 1;
		s.buttonheight = 1;

		s.spawnNothing = true;
	}
	
	this.set_f32("deity_power", 250);
}

void onTick(CBlob@ this)
{
	if (!isClient()) return;

	const f32 power = this.get_f32("deity_power");
	CBlob@[] chickens;
	getBlobsByTag("combat chicken", chickens);
	this.set_u8("maxChickens", Maths::FastSqrt(Maths::FastSqrt(power))*2);
	this.setInventoryName("Altar of Foghorn\n\nUPF Power: "+power
		+"\nChicken Morph Type: "+this.get_string("classtype")
		+"\nMax Chickens: "+this.get_u8("maxChickens"));
}

void onCommand(CBlob@ this, u8 cmd, CBitStream @params)
{
	if (cmd == this.getCommandID("shop made item"))
	{
		u16 caller, item;
		if (params.saferead_netid(caller) && params.saferead_netid(item))
		{
			string data = params.read_string();
			CBlob@ callerBlob = getBlobByNetworkID(caller);
			if (callerBlob !is null)
			{
				CPlayer@ callerPlayer = callerBlob.getPlayer();
				if (callerPlayer !is null)
				{
					string[] spl = data.split("-");
					if (data == "offering_scrubs")
					{
						this.add_f32("deity_power", 125);
						if (isServer()) this.Sync("deity_power", false);
					}
					else if (spl[0] == "offering_summon")
					{
						this.set_u8("maxChickens", Maths::FastSqrt(Maths::FastSqrt(this.get_f32("deity_power")))*2);
						string chickenType = "scoutchicken";
						u8 maxChickens = this.get_u8("maxChickens");
						switch (parseInt(spl[1]))
						{
							case 1:
								chickenType = "scoutchicken";
								break;
							case 2:
								chickenType = "soldierchicken";
								break;
							case 3:
								chickenType = "heavychicken";
								break;
							case 4:
								chickenType = "commanderchicken";
								break;
							default:
								chickenType = "scoutchicken";
								break;
						}
						CBlob@[] chickens;
						getBlobsByTag("chicken", chickens);
						u8 chickenCount = 0;
						u8 team = this.getTeamNum();
						for (u8 i = 0; i < chickens.length; i++)
							if (chickens[i] !is null && chickens[i].getTeamNum() == team && !chickens[i].hasTag("dead"))
								chickenCount++;
								
						if (chickenCount < this.get_u8("maxChickens"))
						{
							if (isServer())
							{
								CBlob@ blob = server_CreateBlob(chickenType, this.getTeamNum(), this.getPosition());
								callerBlob.server_Pickup(blob);
							}
						}
						else if (callerBlob.isMyPlayer()) Sound::Play("NoAmmo.ogg");
					}
					else if (data == "offering_phone")
					{
						this.add_f32("deity_power", 2500);
						if (isServer()) this.Sync("deity_power", false);
						this.set_u8("maxChickens", Maths::FastSqrt(Maths::FastSqrt(this.get_f32("deity_power")))*2);
						CBlob@[] chickens;
						getBlobsByTag("combat chicken", chickens);

						if (this.get_f32("deity_power") > 7500)
						{
							this.set_string("classtype", "heavychicken");
						}
						else if (this.get_f32("deity_power") > 1500)
						{
							this.set_string("classtype", "soldierchicken");
						}
					}
					else if (isServer() && data == "chickentools")
					{
						if (this.get_f32("deity_power") > 7500)
						{
							this.set_string("classtype", "heavychicken");
						}
						else if (this.get_f32("deity_power") > 1500)
						{
							this.set_string("classtype", "soldierchicken");
						}
						CBlob@ blob = server_CreateBlobNoInit("chickentools");
						blob.set_string("classtype", this.get_string("classtype"));
						blob.setPosition(this.getPosition());
						blob.Init();

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
	}
}

void onDie(CBlob@ this)
{
	if (isServer()) server_CreateBlob(this.get_string("classtype"), this.getTeamNum(), this.getPosition());
}