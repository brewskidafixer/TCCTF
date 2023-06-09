﻿#include "MakeMat.as";
#include "MakeCrate.as";
#include "Requirements.as";
#include "CustomBlocks.as";

void onInit(CSprite@ this)
{
	// Building
	this.SetZ(-50);

	this.SetEmitSound("ChickenAssembler_Loop.ogg");
	this.SetEmitSoundVolume(0.3f);
	this.SetEmitSoundSpeed(0.9f);
	this.SetEmitSoundPaused(false);
}

class AssemblerItem
{
	string resultname;
	u32 resultcount;
	string title;
	CBitStream reqs;

	AssemblerItem(string resultname, u32 resultcount, string title)
	{
		this.resultname = resultname;
		this.resultcount = resultcount;
		this.title = title;
	}
}

void onInit(CBlob@ this)
{
	AssemblerItem[] items;
	{
		AssemblerItem i("assaultrifle", 2, "UPF Assault Rifle (2)");
		AddRequirement(i.reqs, "blob", "mat_steelingot", "Steel Ingot", 16);
		AddRequirement(i.reqs, "blob", "mat_ironingot", "Iron Ingot", 8);
		items.push_back(i);
	}
	{
		AssemblerItem i("autoshotgun", 2, "UPF Assault Shotgun (2)");
		AddRequirement(i.reqs, "blob", "mat_steelingot", "Steel Ingot", 20);
		AddRequirement(i.reqs, "blob", "mat_ironingot", "Iron Ingot", 8);
		items.push_back(i);
	}
	{
		AssemblerItem i("sniper", 1, "UPF Sniper Rifle (1)");
		AddRequirement(i.reqs, "blob", "mat_steelingot", "Steel Ingot", 12);
		AddRequirement(i.reqs, "blob", "mat_ironingot", "Iron Ingot", 4);
		items.push_back(i);
	}
	{
		AssemblerItem i("uzi", 4, "UPF Submachine Gun (4)");
		AddRequirement(i.reqs, "blob", "mat_steelingot", "Steel Ingot", 24);
		AddRequirement(i.reqs, "blob", "mat_ironingot", "Iron Ingot", 8);
		items.push_back(i);
	}
	{
		AssemblerItem i("sar", 2, "UPF Semiautomatic Rifle (2)");
		AddRequirement(i.reqs, "blob", "mat_steelingot", "Steel Ingot", 13);
		AddRequirement(i.reqs, "blob", "mat_ironingot", "Iron Ingot", 12);
		items.push_back(i);
	}
	{
		AssemblerItem i("silencedrifle", 2, "UPF Suppressed Rifle (2)");
		AddRequirement(i.reqs, "blob", "mat_steelingot", "Steel Ingot", 20);
		AddRequirement(i.reqs, "blob", "mat_ironingot", "Iron Ingot", 10);
		items.push_back(i);
	}
	{
		AssemblerItem i("mat_battery", 250, "Voltron Battery Plus (250)");
		AddRequirement(i.reqs, "blob", "mat_ironingot", "Iron Ingot", 2);
		AddRequirement(i.reqs, "blob", "mat_copperingot", "Copper Ingot", 1);
		AddRequirement(i.reqs, "blob", "mat_mithril", "Mithril", 25);
		AddRequirement(i.reqs, "blob", "mat_sulphur", "Sulphur", 25);
		items.push_back(i);
	}
	{
		AssemblerItem i("mat_sammissile", 16, "SAM Missile (16)");
		AddRequirement(i.reqs, "blob", "mat_ironingot", "Iron Ingot", 8);
		AddRequirement(i.reqs, "blob", "mat_methane", "Methane", 50);
		items.push_back(i);
	}
	{
		AssemblerItem i("guidedmissile", 2, "Guided Missile (2)");
		AddRequirement(i.reqs, "blob", "mat_ironingot", "Iron Ingot", 6);
		AddRequirement(i.reqs, "blob", "mat_methane", "Methane", 50);
		AddRequirement(i.reqs, "blob", "mat_sulphur", "Sulphur", 25);
		items.push_back(i);
	}
	{
		AssemblerItem i("cruisemissile", 1, "Cruise Missile (1)");
		AddRequirement(i.reqs, "blob", "mat_ironingot", "Iron Ingot", 12);
		AddRequirement(i.reqs, "blob", "mat_methane", "Methane", 50);
		AddRequirement(i.reqs, "blob", "mat_sulphur", "Sulphur", 25);
		items.push_back(i);
	}
	{
		AssemblerItem i("pdw", 2, "UPF PDW (2)");
		AddRequirement(i.reqs, "blob", "mat_steelingot", "Steel Ingot", 10);
		AddRequirement(i.reqs, "blob", "mat_ironingot", "Iron Ingot", 6);
		items.push_back(i);
	}
	{
		AssemblerItem i("carbine", 2, "UPF Carbine (2)");
		AddRequirement(i.reqs, "blob", "mat_steelingot", "Steel Ingot", 12);
		AddRequirement(i.reqs, "blob", "mat_ironingot", "Iron Ingot", 8);
		items.push_back(i);
	}

	this.set("items", items);

	this.set_TileType("background tile", CMap::tile_biron);
	this.getShape().getConsts().mapCollisions = false;
	this.getCurrentScript().tickFrequency = 150;

	this.Tag("builder always hit");
	this.Tag("change team on fort capture");
	this.set_bool("state", true);

	this.addCommandID("set");
	this.addCommandID("state");

	this.set_u8("crafting", 0);

	this.Tag("ignore extractor");
}

void GetButtonsFor( CBlob@ this, CBlob@ caller )
{
	if (!caller.isOverlapping(this)) return;
	{
		CBitStream params;
		params.write_u16(caller.getNetworkID());

		CButton@ button = caller.CreateGenericButton(15, Vec2f(0, -16), this, ChickenAssemblerMenu, "Set Item");
	}
	{
		bool state = this.get_bool("state");
		CBitStream params;
		params.write_bool(!state);
		caller.CreateGenericButton((state ? 27 : 23), Vec2f(12, -8), this, 
			this.getCommandID("state"), getTranslatedString(state ? "OFF" : "ON"), params);
	}
}

void ChickenAssemblerMenu(CBlob@ this, CBlob@ caller)
{
	if(caller.isMyPlayer())
	{
		CGridMenu@ menu = CreateGridMenu(getDriver().getScreenCenterPos() + Vec2f(0.0f, 0.0f), this, Vec2f(4, 6), "Set Assembly");
		if (menu !is null)
		{
			AssemblerItem[] items = getItems(this);
			for(uint i = 0; i < items.length; i += 1)
			{
				AssemblerItem item = items[i];

				CBitStream pack;
				pack.write_u8(i);

				int teamnum = this.getTeamNum();
				if (teamnum > 6) teamnum = 7;
				AddIconToken("$chicken_assembler_icon" + i + "$", "ChickenAssemblerIcons.png", Vec2f(32, 16), i, teamnum);

				string text = "Set to Assemble: " + item.title;
				if(this.get_u8("crafting") == i)
				{
					text = "Already Assembling: " + item.title;
				}

				CGridButton @butt = menu.AddButton("$chicken_assembler_icon" + i + "$", text, this.getCommandID("set"), pack);
				butt.hoverText = item.title + "\n" + getButtonRequirementsText(item.reqs, false);
				if(this.get_u8("crafting") == i)
				{
					butt.SetEnabled(false);
				}
			}
		}
	}
}

void onCommand( CBlob@ this, u8 cmd, CBitStream @params )
{
	if (cmd == this.getCommandID("set"))
	{
		u8 setting = params.read_u8();
		this.set_u8("crafting", setting);
	}
	else if (cmd == this.getCommandID("state"))
	{
		bool newState = params.read_bool();
		this.set_bool("state", newState);
		this.getSprite().SetEmitSoundPaused(!newState);
	}
}

void onTick(CBlob@ this)
{
	if (!this.get_bool("state")) return;
	int crafting = this.get_u8("crafting");

	AssemblerItem[]@ items = getItems(this);
	if (items.length == 0) return;

	AssemblerItem item = items[crafting];
	CInventory@ inv = this.getInventory();


	CBitStream missing;
	if (hasRequirements(inv, item.reqs, missing))
	{
		if (isServer())
		{
			// CBlob @mat = server_CreateBlob(item.resultname, this.getTeamNum(), this.getPosition());
			// mat.server_SetQuantity(item.resultcount);

			CBlob@ blob = server_MakeCrate(item.resultname, item.title, 0, this.getTeamNum(), this.getPosition(), true, item.resultcount);
			
			server_TakeRequirements(inv, item.reqs);
		}

		this.getSprite().PlaySound("ProduceSound.ogg");
		this.getSprite().PlaySound("BombMake.ogg");
	}
}

void onCollision(CBlob@ this, CBlob@ blob, bool solid)
{
	if (blob is null) return;

	int crafting = this.get_u8("crafting");

	bool isMat = false;

	AssemblerItem[]@ items = getItems(this);
	if (items.length == 0) return;

	AssemblerItem item = items[crafting];
	CBitStream bs = item.reqs;
	bs.ResetBitIndex();
	string text, requiredType, name, friendlyName;
	u16 quantity = 0;

	while (!bs.isBufferEnd())
	{
		ReadRequirement(bs, requiredType, name, friendlyName, quantity);

		if(blob.getName() == name)
		{
			isMat = true;
			break;
		}
	}

	if (isMat && !blob.isAttached() && blob.hasTag("material"))
	{
		if (isServer()) this.server_PutInInventory(blob);
		if (isClient()) this.getSprite().PlaySound("bridge_open.ogg");
	}
}

bool isInventoryAccessible(CBlob@ this, CBlob@ forBlob)
{
	return (this.getTeamNum() >= 100 ? true : (forBlob.getTeamNum() == this.getTeamNum())) && forBlob.isOverlapping(this);
}

AssemblerItem[] getItems(CBlob@ this)
{
	AssemblerItem[] items;
	this.get("items", items);
	return items;
}


void onAddToInventory( CBlob@ this, CBlob@ blob )
{
	if(blob.getName() != "gyromat") return;

	this.getCurrentScript().tickFrequency = 150 / (this.exists("gyromat_acceleration") ? this.get_f32("gyromat_acceleration") : 1);
}

void onRemoveFromInventory(CBlob@ this, CBlob@ blob)
{
	if(blob.getName() != "gyromat") return;

	this.getCurrentScript().tickFrequency = 150 / (this.exists("gyromat_acceleration") ? this.get_f32("gyromat_acceleration") : 1);
}
