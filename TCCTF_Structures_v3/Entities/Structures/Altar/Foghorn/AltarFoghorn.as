#include "Requirements.as";
#include "Requirements_Tech.as";
#include "ShopCommon.as";
#include "DeityCommon.as";
#include "MakeSeed.as";

void onInit(CBlob@ this)
{
	this.set_u8("deity_id", Deity::foghorn);
	this.set_Vec2f("shop menu size", Vec2f(5, 1));
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
		AddRequirement(s.requirements, "coin", "", "Coins", 1500);

		s.spawnNothing = true;
	}
	{
		ShopItem@ s = addShopItem(this, "Recruit a UPF Soldier", "$soldierchicken$", "offering_summon", "Enlist a UPF chicken soldier.", true);
		AddRequirement(s.requirements, "blob", "egg", "Egg", 1);
		AddRequirement(s.requirements, "coin", "", "Coins", 1750);

		s.spawnNothing = true;
	}
	
	this.set_f32("deity_power", 0);
}

void onTick(CBlob@ this)
{
	if (!isClient()) return;

	const f32 power = this.get_f32("deity_power");
	CBlob@[] chickens;
	getBlobsByTag("combat chicken", chickens);
	this.set_u8("maxChickens", Maths::FastSqrt(Maths::FastSqrt(power)));
	if (power > 7500)
	{
		this.set_string("classtype", "heavychicken");
		this.set_u8("maxChickens", this.get_u8("maxChickens"));
	}
	else if (power > 1500)
	{
		this.set_string("classtype", "soldierchicken");
		this.set_u8("maxChickens", this.get_u8("maxChickens"));
	}
	this.setInventoryName("Altar of Foghorn\n\nUPF Power: "+power
		+"\nChicken Morph Type: "+this.get_string("classtype")
		+"\nChicken Summon Type: "+this.get_string("classtype")
		+"\nMax Combat Chickens: "+this.get_u8("maxChickens"));
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
					if (data == "offering_scrubs")
					{
						this.add_f32("deity_power", 125);
						if (isServer()) this.Sync("deity_power", false);
					}
					else if (data == "offering_summon")
					{
						this.set_u8("maxChickens", Maths::FastSqrt(Maths::FastSqrt(this.get_f32("deity_power"))));
						CBlob@[] chickens;
						getBlobsByTag("combat chicken", chickens);

						if (this.get_f32("deity_power") > 7500)
						{
							this.set_string("classtype", "heavychicken");
							this.set_u8("maxChickens", this.get_u8("maxChickens"));
						}
						else if (this.get_f32("deity_power") > 1500)
						{
							this.set_string("classtype", "soldierchicken");
							this.set_u8("maxChickens", this.get_u8("maxChickens"));
						}
						if (chickens.length < this.get_u8("maxChickens"))
						{
							if (isServer())
							{
								CBlob@ blob = server_CreateBlob(this.get_string("classtype"), this.getTeamNum(), this.getPosition());
								callerBlob.server_Pickup(blob);
							}
						}
						else if (callerBlob.isMyPlayer()) Sound::Play("NoAmmo.ogg");
					}
					else if (data == "offering_phone")
					{
						this.add_f32("deity_power", 2500);
						if (isServer()) this.Sync("deity_power", false);
						this.set_u8("maxChickens", Maths::FastSqrt(Maths::FastSqrt(this.get_f32("deity_power"))));
						CBlob@[] chickens;
						getBlobsByTag("combat chicken", chickens);

						if (this.get_f32("deity_power") > 7500)
						{
							this.set_string("classtype", "heavychicken");
							this.set_u8("maxChickens", this.get_u8("maxChickens"));
						}
						else if (this.get_f32("deity_power") > 1500)
						{
							this.set_string("classtype", "soldierchicken");
							this.set_u8("maxChickens", this.get_u8("maxChickens"));
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