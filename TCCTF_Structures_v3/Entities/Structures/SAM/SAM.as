// Princess brain

#include "Hitters.as";
#include "HittersTC.as";
#include "Knocked.as";
#include "VehicleAttachmentCommon.as";
#include "TurretAmmo.as";

const f32 radius = 128.0f;
const f32 damage = 5.00f;
const u32 delay = 90;

void onInit(CBlob@ this)
{
	this.Tag("builder always hit");
	this.Tag("heavy weight");
	this.Tag("ignore extractor");

	this.set_f32("pickup_priority", 16.00f);
	this.getShape().SetRotationsAllowed(false);

	this.getCurrentScript().tickFrequency = 10;
	// this.getCurrentScript().runFlags |= Script::tick_not_ininventory;

	this.getSprite().SetZ(20);

	this.set_u16("target", 0);
	this.set_u32("next_launch", 0);

	this.set_u16("ammoCount", 0);
	this.set_u16("maxAmmo", 45);
	this.set_string("ammoName", "mat_sammissile");
	this.set_string("ammoInventoryName", "Sam Missiles");
	this.set_string("ammoIconName", "$mat_sammissile$");

	this.set_bool("security_state", true);
	Turret_onInit(this);
}

void onInit(CSprite@ this)
{
	// this.SetEmitSound("Zapper_Loop.ogg");
	// this.SetEmitSoundVolume(0.0f);
	// this.SetEmitSoundSpeed(0.0f);
	// this.SetEmitSoundPaused(false);

	CSpriteLayer@ head = this.addSpriteLayer("head", "SAM_Launcher.png", 32, 16);
	if (head !is null)
	{
		head.SetOffset(Vec2f(0.0f, -8.0f));
		head.SetRelativeZ(5);
	}
}

bool doesCollideWithBlob(CBlob@ this, CBlob@ blob)
{
	return blob.getShape().isStatic() && blob.isCollidable();
}

bool canBePickedUp(CBlob@ this, CBlob@ byBlob)
{
	return byBlob.getTeamNum() == this.getTeamNum() && this.get_u16("ammoCount") == 0;
}

void onTick(CBlob@ this)
{
	AttachmentPoint@ point = this.getAttachments().getAttachmentPointByName("PICKUP");
	CBlob@ attachedBlob = point.getOccupied();

	if (attachedBlob !is null && !attachedBlob.hasTag("vehicle")) return;

	if (this.get_bool("security_state"))
	{
		int ammo = this.get_u16("ammoCount");
		if (ammo == 0) return;
		CBlob@[] blobs;
		getBlobsByTag("aerial", @blobs);

		Vec2f pos = this.getPosition();
		CMap@ map = getMap();

		int index = -1;
		u8 myTeam = this.getTeamNum();

		for (int i = 0; i < blobs.length; i++)
		{
			CBlob@ b = blobs[i];
			u8 team = b.getTeamNum();
			if (team == myTeam || !isVisible(this, b)) continue;

			f32 dist = this.getDistanceTo(b);

			if (dist < 1000)
			{
				index = i;
			}
		}

		if (index != -1)
		{
			CBlob@ target = blobs[index];

			if (target !is null)
			{
				if (target.getNetworkID() != this.get_u16("target"))
				{
					this.getSprite().PlaySound("SAM_Found.ogg", 1.00f, 1.00f);
					this.set_u32("next_launch", getGameTime() + 30);
				}

				this.set_u16("target", target.getNetworkID());
			}
			CBlob@ t = getBlobByNetworkID(this.get_u16("target"));
			if (t !is null && getGameTime() >= this.get_u32("next_launch") && isVisible(this, t))
			{
				this.SetFacingLeft((t.getPosition().x - this.getPosition().x) < 0);

				if (ammo > 0)
				{
					if (isServer())
					{
						Vec2f dir = t.getPosition() - this.getPosition();
						dir.Normalize();
						dir.y = -Maths::Abs(dir.y) - 0.25f;

						CBlob@ m = server_CreateBlobNoInit("sammissile");
						m.setPosition(this.getPosition() + Vec2f(0, -12));
						m.set_Vec2f("direction", dir);
						m.set_u16("target", this.get_u16("target"));
						m.set_f32("velocity", 10.00f);
						m.server_setTeamNum(this.getTeamNum());
						m.Tag("self_destruct");
						m.Init();

						this.sub_u16("ammoCount", 1);
					}

					this.getSprite().PlaySound("Missile_Launch.ogg");
					this.set_u32("next_launch", getGameTime() + 60);
				}
			}
		}
	}
}

bool isVisible(CBlob@ blob, CBlob@ target)
{
	Vec2f col;
	return !getMap().rayCastSolidNoBlobs(blob.getPosition(), target.getPosition(), col);
}

void onTick(CSprite@ this)
{
	//this.SetFacingLeft(false);
	CBlob@ blob = this.getBlob();
	if (blob.get_bool("security_state"))
	{
		if (isClient())
		{
			CBlob@ target = getBlobByNetworkID(blob.get_u16("target"));
			if (target !is null)
			{
				AttachmentPoint@ point = blob.getAttachments().getAttachmentPointByName("PICKUP");
				CBlob@ attachedBlob = point.getOccupied();

				if (attachedBlob !is null && !attachedBlob.hasTag("vehicle")) return;

				//blob.SetFacingLeft((target.getPosition().x - blob.getPosition().x) < 0);

				CSpriteLayer@ head = blob.getSprite().getSpriteLayer("head");
				if (head !is null)
				{
					Vec2f dir = target.getPosition() - blob.getPosition();
					dir.Normalize();
					dir.y = -Maths::Abs(dir.y) - 0.25f;

					head.ResetTransform();
					head.SetFacingLeft((target.getPosition().x - blob.getPosition().x) < 0);
					head.RotateBy(-dir.Angle() + (this.isFacingLeft() ? 180 : 0), Vec2f());
				}
			}
			else
			{
				CSpriteLayer@ head = this.getSpriteLayer("head");
				if (head !is null)
				{
					head.ResetTransform();
					head.SetFacingLeft(blob.isFacingLeft());
					//head.RotateBy((Maths::Sin(blob.getTickSinceCreated() * 0.05f) * 20), Vec2f());
				}
			}
		}
	}
}

void GetButtonsFor(CBlob@ this, CBlob@ caller)
{
	if (caller.getTeamNum() == this.getTeamNum())
	{
		if (this.getDistanceTo(caller) <= 32)
		{
			Turret_AddButtons(this, caller);
		}
	}
}

void onCommand(CBlob@ this, u8 cmd, CBitStream @params)
{
	if (cmd == this.getCommandID("security_set_state"))
	{
		bool state = params.read_bool();

		CSprite@ head = this.getSprite();
		if (head !is null)
		{
			head.SetFrameIndex(state ? 0 : 1);
		}

		this.getSprite().PlaySound(state ? "Security_TurnOn" : "Security_TurnOff", 0.30f, 1.00f);
		this.set_bool("security_state", state);
	}
	else Turret_onCommand(this, cmd, params);
}

void onCollision(CBlob@ this, CBlob@ blob, bool solid)
{
	if (blob !is null)
	{
		TryToAttachVehicle(this, blob);
	}
}

void onDie(CBlob@ this)
{
	const u16 ammoCount = this.get_u16("ammoCount");
	if (ammoCount > 0 && isServer())
	{
		server_CreateBlob("mat_sammissile", -1, this.getPosition()).server_SetQuantity(ammoCount);
	}
}