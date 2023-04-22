#include "LootSystem.as";

// name, amount, bonus, weight
LootItem@[] c_items =
{
	LootItem("mat_stone", 25, 2000, 800),
	LootItem("mat_wood", 25, 2000, 700),
	LootItem("mat_gold", 25, 500, 400),
	LootItem("mat_sulphur", 20, 500, 550),
	LootItem("mat_coal", 10, 200, 600),
	LootItem("grain", 5, 15, 400),
	LootItem("pumpkin", 2, 7, 300),
	LootItem("mysterybox", 1, 3, 780),
	LootItem("egg", 1, 12, 750),
	LootItem("landfish", 1, 1, 450),
	LootItem("chicken", 1, 6, 125),
	LootItem("mat_mithril", 1, 100, 250),
	LootItem("bomb", 1, 2, 400),
	LootItem("mat_incendiarybomb", 1, 3, 103),
	LootItem("mat_smallbomb", 4, 16, 247),
	LootItem("badger", 1, 3, 200),
	LootItem("badgerbomb", 1, 3, 200),
	LootItem("mat_oil", 10, 50, 720),
	LootItem("mat_copperingot", 3, 25, 300),
	LootItem("mat_ironingot", 5, 25, 500),
	LootItem("mat_goldingot", 1, 25, 105),
	LootItem("mat_steelingot", 5, 25, 254),
	LootItem("mat_mithrilingot", 5, 25, 90),
	LootItem("badgerden", 1, 1, 154),
	LootItem("heart", 1, 5, 743),
	LootItem("ratburger", 1, 3, 300),
	LootItem("bucket", 1, 2, 242),
	LootItem("sponge", 1, 2, 227),
	LootItem("mat_rifleammo", 5, 20, 724),
	LootItem("mat_pistolammo", 10, 60, 754),
	LootItem("mat_smallrocket", 1, 10, 275),
	LootItem("bazooka", 1, 0, 164),
	LootItem("flamethrower", 0, 1, 179),
	LootItem("mat_shotgunammo", 4, 16, 674),
	//LootItem("scyther", 1, 0, 5), // lolz //too op had to remove
	LootItem("ninjascroll", 1, 1, 250),
	LootItem("puntgun", 1, 1, 225),
	LootItem("juggernauthammer", 1, 1, 90),
	LootItem("gyromat", 1, 1, 1200),
	LootItem("phone", 1, 1, 200),
	LootItem("bp_chemistry", 1, 1, 300),
	LootItem("cube", 1, 0, 1) //poggers
};

void onInit(CBlob@ this)
{
	this.addCommandID("box_unpack");
}

void GetButtonsFor(CBlob@ this, CBlob@ caller)
{
	if (caller !is null && this.getDistanceTo(caller) <= 48)
	{
		caller.CreateGenericButton(12, Vec2f(0, 0), this, this.getCommandID("box_unpack"), "Unpack");
	}
}

void onCommand(CBlob@ this, u8 cmd, CBitStream @params)
{
	if (cmd == this.getCommandID("box_unpack"))
	{
		if (isServer())
		{
			if (this.hasTag("unpacked")) return;

			// print(c_items[0].blobname);
			server_SpawnRandomItem(this, @c_items);

			this.server_Die();
		}

		this.Tag("unpacked");
	}
}
