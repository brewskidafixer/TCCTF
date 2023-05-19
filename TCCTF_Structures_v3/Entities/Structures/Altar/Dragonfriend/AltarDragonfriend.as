#include "Requirements.as";
#include "Requirements_Tech.as";
#include "ShopCommon.as";
#include "DeityCommon.as";
#include "MakeMat.as";
#include "Explosion.as";

void onInit(CBlob@ this)
{
	Random@ rand = Random(this.getNetworkID());

	this.set_u8("deity_id", Deity::dragonfriend);
	this.set_Vec2f("shop menu size", Vec2f(4, 2));
	this.getCurrentScript().tickFrequency = 30;
	
	// CSprite@ sprite = this.getSprite();
	// sprite.SetEmitSound("AltarDragonfriend_Music.ogg");
	// sprite.SetEmitSoundVolume(0.40f);
	// sprite.SetEmitSoundSpeed(1.00f);
	// sprite.SetEmitSoundPaused(false);
	
	this.SetLight(true);
	this.SetLightRadius(48.0f);
	this.SetLightColor(SColor(255, 170, 255, 61));
	
	AddIconToken("$icon_dragonfriend_follower$", "InteractionIcons.png", Vec2f(32, 32), 11);
	{
		ShopItem@ s = addShopItem(this, "Rite of Greed", "$icon_dragonfriend_follower$", "follower", "Gain a Premium Dragon Membership by paying 1499 coins.\n\nThe Dragon disapproves anyone with a poor credit rating.");
		AddRequirement(s.requirements, "coin", "", "Coins", 1499);
		s.customButton = true;
		s.buttonwidth = 2;	
		s.buttonheight = 2;
		
		s.spawnNothing = true;
	}
	
	AddIconToken("$icon_dragonfriend_offering_0$", "AltarDragonfriend_Icons.png", Vec2f(24, 24), 0);
	{
		ShopItem@ s = addShopItem(this, "Offering of Stonks", "$icon_dragonfriend_offering_0$", "offering_stonks", "Turn in some purchased Stonks in exchange for dragon powers.");
		AddRequirement(s.requirements, "blob", "mat_stonks", "Stonks", 1);
		s.customButton = true;
		s.buttonwidth = 1;	
		s.buttonheight = 1;
		
		s.spawnNothing = true;
	}
	
	AddIconToken("$icon_dragonfriend_offering_1$", "AltarDragonfriend_Icons.png", Vec2f(24, 24), 1);
	{
		ShopItem@ s = addShopItem(this, "Offering of the Meteor", "$icon_dragonfriend_offering_1$", "offering_meteor", "Offer 10000 coins to summon a meteor.");
		AddRequirement(s.requirements, "blob", "mat_goldingot", "Gold Ingot", 100);
		s.customButton = true;
		s.buttonwidth = 1;	
		s.buttonheight = 1;
		
		s.spawnNothing = true;
	}
	
	AddIconToken("$icon_dragonfriend_offering_2$", "Material_Stonks.png", Vec2f(16, 16), 3);
	{
		ShopItem@ s = addShopItem(this, "Manipulate Market", "$icon_dragonfriend_offering_2$", "Manipulate_Market", "uses all stonks in inventory to stonk price");
		AddRequirement(s.requirements, "blob", "mat_stonks", "Stonks", 1);
		s.customButton = true;
		s.buttonwidth = 1;	
		s.buttonheight = 1;
		s.spawnNothing = true;
	}
	
	
	// AddIconToken("$icon_dragonfriend_offering_2$", "AltarDragonfriend_Icons.png", Vec2f(24, 24), 2);
	// {
		// ShopItem@ s = addShopItem(this, "Offering of Doritos", "$icon_dragonfriend_offering_2$", "offering_doritos", "Sacrifice some money to buy Doritos from the built-in vending machine.");
		// AddRequirement(s.requirements, "coin", "", "Coins", 50);
		// s.customButton = true;
		// s.buttonwidth = 1;	
		// s.buttonheight = 1;
		
		// s.spawnNothing = true;
	// }
	
	this.set_f32("stonks_volatility", 0.20f);
	this.set_f32("stonks_growth", 0.01f);
	this.set_f32("stonks_value", rand.NextRanged(stonks_base_value_max));

	this.addCommandID("stonks_update");
	this.addCommandID("stonks_trade");
	this.addCommandID("stonks_menu");

	u8 teamnum = this.getTeamNum();
	AddIconToken("$icon_stonks1$", "Material_Stonks.png", Vec2f(16, 16), 0, teamnum);
	AddIconToken("$icon_stonks10$", "Material_Stonks.png", Vec2f(16, 16), 1, teamnum);
	AddIconToken("$icon_stonks100$", "Material_Stonks.png", Vec2f(16, 16), 2, teamnum);
	AddIconToken("$icon_stonks1000$", "Material_Stonks.png", Vec2f(16, 16), 3, teamnum);
}

const f32 power_fire_immunity_max = 100000.00f;

// const u32 stonks_update_frequency = 30 * 5;
const u32 stonks_update_frequency = 2;
// const u32 stonks_update_frequency = 3;
const f32 stonks_base_value_min = 100.00f;
const f32 stonks_base_value_max = 2000.00f;

f32[] graph = {0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0};
int graph_index = 0;

void onTick(CBlob@ this)
{
	const bool server = isServer();
	const bool client = isClient();

	if (client)
	{
		buy_pressed = false;	
		sell_pressed = false;	
	
		const f32 power = this.get_f32("deity_power");
	
		const f32 stonks_volatility = this.get_f32("stonks_volatility");
		const f32 stonks_growth = this.get_f32("stonks_growth");
		const f32 stonks_value = this.get_f32("stonks_value");
		
		string volatility_text;
		if (stonks_volatility > 0.90f) volatility_text = "extremely high";
		else if (stonks_volatility > 0.80f) volatility_text = "very high";
		else if (stonks_volatility > 0.60f) volatility_text = "high";
		else if (stonks_volatility > 0.40f) volatility_text = "medium";
		else if (stonks_volatility > 0.20f) volatility_text = "low";
		else volatility_text = "very low";
		
		string text = "Altar of the Dragon\n";
		text += "\nDragon Power: " + power;
		text += "\nFire Resistance: " + Maths::Min(power / power_fire_immunity_max * 100.00f, 100.00f) + "%";
		text += "\nMaximum Stonks Value: " + Maths::Ceil(stonks_base_value_max + (power / 100.00f)) + " coins";
		text += "\nFireball Power: " + Maths::Round((1.00f + Maths::Sqrt(power * 0.00002f)) * 100.00f) + "%";
		// text += "\n\nStonks:";
		text += "\nVolatility: " + volatility_text;
		// text += "\nGrowth: " + (stonks_growth >= 0 ? "+" : "-") + (Maths::Abs(s32(stonks_growth * 10000.00f) * 0.01f)) + "%";
		// text += "\n";
		// text += "\nSell Price: " + Maths::Ceil(stonks_value) + " coins";
		// text += "\nBuy Price: " + Maths::Ceil(stonks_value * 0.98f) + " coins";
		this.setInventoryName(text);
		
		const f32 radius = 64.00f + ((power / 100.00f) * 8.00f);
		this.SetLightRadius(radius);
	}
	
	if (isServer())
	{
		updateStonks(this);
	}
}

void updateStonks(CBlob@ this)
{
	// print("updating stonks");

	const f32 power = this.get_f32("deity_power");

	f32 stonks_volatility = this.get_f32("stonks_volatility");
	f32 stonks_growth = this.get_f32("stonks_growth");
	f32 stonks_value = this.get_f32("stonks_value");

	f32 stonks_value_max = stonks_base_value_max + (power / 100.00f);

	if (stonks_value == stonks_base_value_min || stonks_value == stonks_value_max) stonks_growth *= -Maths::Min(0.30f + stonks_volatility, 0.80f);
	if ((XORRandom(100) * 0.01f) < Maths::Pow(stonks_volatility, 2.00f)) stonks_growth *= -stonks_volatility * 1.40f;
	if ((XORRandom(100) * 0.01f) > Maths::Pow(stonks_volatility, 2.00f)) stonks_growth *= 0.80f;
	if ((XORRandom(100) * 0.01f) > Maths::Pow(stonks_volatility, 3.00f)) stonks_growth *= 1.25f;

	f32 stonks_volatility_new = (XORRandom(100) < 10) ? Maths::Pow(XORRandom(100) * 0.01f, 1.50f) : (stonks_volatility);
	f32 stonks_growth_new = stonks_growth + (((1000 - XORRandom(2000)) / 1000.00f) * (stonks_volatility_new * stonks_volatility_new * 0.15f));
	f32 stonks_value_new = Maths::Clamp(stonks_value * (1.00f + stonks_growth_new), stonks_base_value_min, stonks_value_max);

	CBitStream stream;
	
	stream.write_f32(stonks_volatility_new);
	stream.write_f32(stonks_growth_new);
	stream.write_f32(stonks_value_new);
	
	this.SendCommand(this.getCommandID("stonks_update"), stream);
}

void GetButtonsFor(CBlob@ this, CBlob@ caller)
{
	if (this.isOverlapping(caller))
	{
		CBitStream params;
		params.write_u16(caller.getNetworkID());
		
		CButton@ buttonEject = caller.CreateGenericButton(11, Vec2f(0, -8), this, this.getCommandID("stonks_menu"), "Stonks Menu", params);
	}
}

void onCommand(CBlob@ this, u8 cmd, CBitStream@ params)
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
					if (data == "follower")
					{
						if (callerBlob.getTeamNum() < 7)
						{
							this.add_f32("deity_power", 999);
							if (isServer()) this.Sync("deity_power", false);
							
							if (isClient())
							{
								// if (callerBlob.get_u8("deity_id") != Deity::dragonfriend)
								// {
									// client_AddToChat(callerPlayer.getCharacterName() + " has become a follower of Dragonfriend.", SColor(255, 255, 0, 0));
								// }
								
								CBlob@ localBlob = getLocalPlayerBlob();
								if (localBlob !is null)
								{
									if (this.getDistanceTo(localBlob) < 128)
									{
										this.getSprite().PlaySound("LotteryTicket_Kaching", 2.00f, 1.00f);
									}
								}
							}
							//if (isServer())	{
							callerPlayer.set_u8("deity_id", Deity::dragonfriend);
							callerBlob.set_u8("deity_id", Deity::dragonfriend);
							callerPlayer.Sync("deity_id", true);
							callerBlob.Sync("deity_id", true);
							//}
						}
						else
						{
							if (isClient())
							{
								callerBlob.getSprite().PlaySound("TraderScream.ogg", 2.00f, 1.00f);
								
								Explode(callerBlob, 32.0f, 0.2f);
								callerBlob.getSprite().Gib();
								
								ParticleBloodSplat(callerBlob.getPosition(), true);
							}
							
							if (isServer())
							{
								server_DropCoins(this.getPosition(), 1499);
								callerBlob.server_Die();
							}
						}
					}
					else
					{
						if (data == "offering_stonks")
						{							
							if (isServer())
							{	
								f32 stonks_value = this.get_f32("stonks_value");
							
								this.add_f32("deity_power", stonks_value * 0.95f);
								if (isServer()) this.Sync("deity_power", true);
							
								server_DropCoins(this.getPosition(), stonks_value * 0.05f);
							}
							
							if (isClient())
							{
								this.getSprite().PlaySound("LotteryTicket_Kaching", 2.00f, 1.00f);
							}
						}
						else if (data == "offering_meteor")
						{
							if (isServer())
							{
								this.add_f32("deity_power", 9999);
								if (isServer()) this.Sync("deity_power", true);
							
								f32 map_width = getMap().tilemapwidth * 8.00f;
								CBlob@ item = server_CreateBlob("meteor", this.getTeamNum(), Vec2f(XORRandom(map_width), 0));
								item.Tag("dragonfriend");
								item.set_f32("deity_power", this.get_f32("deity_power")/10000);
								
								server_DropCoins(this.getPosition(), XORRandom(100));
							}
							
							if (isClient())
							{
								this.getSprite().PlaySound("LotteryTicket_Kaching", 2.00f, 1.00f);
							}
						}
						else if (data == "Manipulate_Market")
						{
							//get stonk value
							f32 stonks_value = this.get_f32("stonks_value");
							//get stonk in inventory
							CInventory@ inv = callerBlob.getInventory();
							u16 stonkcount = inv.getCount("mat_stonks")+1;
							//remove stonks from inventory
							inv.server_RemoveItems("mat_stonks", stonkcount-1);
							
							
							//get sign from growth
							if(this.get_f32("stonks_growth") < 0){
									stonkcount = stonkcount * -1;
							}
							
							f32 power = this.get_f32("deity_power");
							f32 stonks_value_max = stonks_base_value_max + (power / 100.00f);
							this.set_f32("stonks_value", Maths::Clamp(stonks_value + (100 * stonkcount), stonks_base_value_min, stonks_value_max));
							this.Sync("stonks_value", true);
							
					
						
						}
					}
				}				
			}
		}
	}
	else if (cmd == this.getCommandID("stonks_menu"))
	{
		u16 caller;
		if (params.saferead_netid(caller))
		{
			CBlob@ callerBlob = getBlobByNetworkID(caller);
			if (callerBlob !is null && callerBlob.isMyPlayer())
			{
		    	CGridMenu@ menu = CreateGridMenu(getDriver().getScreenCenterPos() + Vec2f(0, -160), this, Vec2f(2, 3), "\nStonks Broker\n");
				if (menu !is null)
				{
					menu.deleteAfterClick = false;
				
					for (u8 i = 1; i <= 100; i*=10)
					{
						{
							CBitStream params;
							params.write_u16(callerBlob.getNetworkID());
							params.write_u8(0);
							params.write_u8(i);
							menu.AddButton("$icon_stonks"+i+"$", "\nBuy Stonks: ("+i+")\n", this.getCommandID("stonks_trade"), params);
						}
						{
							CBitStream params;
							params.write_u16(callerBlob.getNetworkID());
							params.write_u8(1);
							params.write_u8(i);
							menu.AddButton("$icon_stonks"+i+"$", "\nSell Stonks: ("+i+")\n", this.getCommandID("stonks_trade"), params);
						}
					}
				}
			}
		}
	}
	else if (cmd == this.getCommandID("stonks_update"))
	{
		if (isClient())
		{
			f32 stonks_volatility;
			f32 stonks_growth;
			f32 stonks_value;
			
			if (params.saferead_f32(stonks_volatility) && params.saferead_f32(stonks_growth) && params.saferead_f32(stonks_value))
			{
				const f32 power = this.get_f32("deity_power");
			
				f32 stonks_value_old = this.get_f32("stonks_value");
				//causes div zero error not used aswell
				//f32 stonks_value_delta = stonks_value / stonks_value_old;
				
				
				f32 stonks_value_max = stonks_base_value_max + (power / 100.00f);
				
				this.set_f32("stonks_volatility", stonks_volatility);
				this.set_f32("stonks_growth", stonks_growth);
				this.set_f32("stonks_value", Maths::Clamp(stonks_value, stonks_base_value_min, stonks_value_max));
				this.Sync("stonks_volatility", true);
				this.Sync("stonks_growth", true);
				this.Sync("stonks_value", true);
				
				graph[graph_index] = stonks_value;
				graph_index = Maths::FMod(graph_index + 1, graph.size());
			}
		}
	}
	else if (cmd == this.getCommandID("stonks_trade"))
	{
		u16 caller_netid;
		u8 action;
		u8 quantity;

		if (params.saferead_netid(caller_netid) && params.saferead_u8(action) && params.saferead_u8(quantity))
		{
			CBlob@ caller = getBlobByNetworkID(caller_netid);
			if (caller !is null && caller.get_u8("deity_id") == Deity::dragonfriend)
			{
				CPlayer@ callerPlayer = caller.getPlayer();
				if (callerPlayer !is null)
				{
					CBitStream reqs;
					CBitStream missing;
				
					f32 stonks_value = this.get_f32("stonks_value");
				
					s32 buy_price = Maths::Ceil(stonks_value * 1.02f);
					s32 sell_price = Maths::Ceil(stonks_value);
				
					switch (action)
					{
						case 0: // Buy
						{
							AddRequirement(reqs, "coin", "", "Coins", buy_price * quantity);
						}
						break;
						
						case 1: // Sell
						{
							AddRequirement(reqs, "blob", "mat_stonks", "Stonks", quantity);
						}
						break;
					}
					
					bool has_reqs = false;
					if (hasRequirements(caller.getInventory(), reqs, missing))
					{
						if (isServer())
						{
							server_TakeRequirements(caller.getInventory(), this.getInventory(), reqs);
						}
						
						has_reqs = true;
					}
					
					if (has_reqs)
					{
						switch (action)
						{
							case 0: // Buy
							{
								if (isServer())
								{
									MakeMat(caller, this.getPosition(), "mat_stonks", quantity);
									// this.set_f32("stonks_value", Maths::Clamp(stonks_value + (buy_price * 0.02f), stonks_base_value_min, stonks_base_value_max));
									// this.Sync("stonks_value", false);
								}
								
								if (isClient())
								{
									this.getSprite().PlaySound("/ChaChing.ogg");
								}
							}
							break;
							
							case 1: // Sell
							{
								if (isServer())
								{
									u16 totalCoins = callerPlayer.getCoins() + sell_price * quantity;
									if (totalCoins >  30000)
									{
										u8 goldIngots = (totalCoins - 30000)/100;
										if (goldIngots > 0)
										{
											totalCoins = totalCoins - (100 * goldIngots);
											callerPlayer.server_setCoins(totalCoins);
											CBlob@ mat = server_CreateBlob("mat_goldingot");
											if (mat !is null)
											{
												mat.Tag("do not set materials");
												mat.server_SetQuantity(goldIngots);
												if (!caller.server_PutInInventory(mat))
												{
													mat.setPosition(caller.getPosition());
												}
											}
										}
									}
									else callerPlayer.server_setCoins(totalCoins);
									// this.set_f32("stonks_value", Maths::Clamp(stonks_value - (sell_price * 0.02f), stonks_base_value_min, stonks_base_value_max));
									// this.Sync("stonks_value", false);
								}
								
								if (isClient())
								{
									this.getSprite().PlaySound("/ChaChing.ogg");
								}
							}
							break;
						}
					}
					
					
					// print("has reqs: " + has_reqs);
				}
			}
		}
	}
	
}

f32 axis_x = 200;
f32 axis_y = 90;

void onRender(CSprite@ this)
{
	CBlob@ localBlob = getLocalPlayerBlob();
	if (localBlob !is null)
	{
		if (localBlob.get_u8("deity_id") == Deity::dragonfriend)
		{
			CBlob@ blob = this.getBlob();
			Vec2f blobPos = blob.getPosition();
			Vec2f localPos = localBlob.getPosition();
			
			bool inRange = (blobPos - localPos).getLength() < 32.00f;
			if (inRange)
			{
				const f32 power = blob.get_f32("deity_power");
			
				f32 stonks_volatility = blob.get_f32("stonks_volatility");
				f32 stonks_growth = blob.get_f32("stonks_growth");
				f32 stonks_value = blob.get_f32("stonks_value");
				
				f32 stonks_value_max = stonks_base_value_max + (power / 100.00f);
				
				// string volatility_text;
				// if (stonks_volatility > 0.90f) volatility_text = "extremely high";
				// else if (stonks_volatility > 0.80f) volatility_text = "very high";
				// else if (stonks_volatility > 0.60f) volatility_text = "high";
				// else if (stonks_volatility > 0.40f) volatility_text = "medium";
				// else if (stonks_volatility > 0.20f) volatility_text = "low";
				// else volatility_text = "very low";
				
				Vec2f pos = blob.getScreenPos() + Vec2f(-axis_x * 0.50f, 250);

				GUI::DrawWindow(pos - Vec2f(8, axis_y + 8), pos + Vec2f(8 + axis_x, 8));
				GUI::DrawLine2D(pos, pos + Vec2f(0, -axis_y), SColor(255, 196, 135, 58));
				GUI::DrawLine2D(pos, pos + Vec2f(axis_x, 0), SColor(255, 196, 135, 58));
				
				string text;
				// text += "\nVolatility: " + volatility_text;
				text += "\nGrowth: " + (stonks_growth >= 0 ? "+" : "-") + (Maths::Abs(s32(stonks_growth * 10000.00f) * 0.01f)) + "%";
				text += "\n";
				text += "\nSell Price: " + Maths::Ceil(stonks_value) + " coins";
				text += "\nBuy Price: " + Maths::Ceil(stonks_value * 1.02f) + " coins";
				
				GUI::SetFont("menu");
				GUI::DrawText("Stonks Dashboard", pos + Vec2f(axis_x + 16, -axis_y - 8), SColor(255, 255, 255, 255));
				
				GUI::SetFont("");
				GUI::DrawText(text, pos + Vec2f(axis_x + 16, -axis_y - 0), SColor(255, 255, 255, 255));
				
				int size = graph.size();
				f32 step_x = axis_x / graph.size();
				for (int i = 0; i < size - 1; i++)
				{
					f32 value_a = (graph[Maths::FMod(i + graph_index, size)] / stonks_value_max);
					f32 value_b = (graph[Maths::FMod(i + graph_index + 1, size)] / stonks_value_max);
					
					Vec2f pos_a = Vec2f(4 + pos.x + ((i + 0) * step_x), pos.y - (value_a * axis_y));
					Vec2f pos_b = Vec2f(4 + pos.x + ((i + 1) * step_x), pos.y - (value_b * axis_y));
					
					GUI::DrawLine2D(pos_a + Vec2f(2, 2), pos_b + Vec2f(2, 2), SColor(255, 196, 135, 58));
					GUI::DrawLine2D(pos_a, pos_b, SColor(255, u8(Maths::Clamp((1.00f - value_b) * 500.00f, 0.00f, 255.00f)), u8(Maths::Clamp(value_b * 500.00f, 0.00f, 255.00f)), 0));
				}
			}
		}
	}
}

bool buy_pressed = false;
bool sell_pressed = false;