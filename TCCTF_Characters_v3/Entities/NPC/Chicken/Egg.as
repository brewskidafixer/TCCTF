
const int grow_time = 50 * getTicksASecond();

const int MAX_CHICKENS_TO_HATCH = 3;
const f32 CHICKEN_LIMIT_RADIUS = 120.0f;

void onInit(CBlob@ this)
{
	this.getCurrentScript().tickFrequency = 120;
	this.addCommandID("hatch");
	this.Tag("hopperable");
	this.set_f32("pickup_priority", 0.05f);

	this.maxQuantity = 64;
}

bool canBePickedUp(CBlob@ this, CBlob@ byBlob)
{
	return true;
}

void onTick(CBlob@ this)
{
	if (isServer() && this.getTickSinceCreated() > grow_time)
	{
		int chickenCount = 0;
		CBlob@[] blobs;
		getMap().getBlobsInRadius(this.getPosition(), CHICKEN_LIMIT_RADIUS, @blobs);
		for (uint step = 0; step < blobs.length; ++step)
		{
			CBlob@ other = blobs[step];
			if (other.getName() == "chicken")
			{
				chickenCount++;
				if (chickenCount >= MAX_CHICKENS_TO_HATCH) break;
			}
		}

		if (chickenCount < MAX_CHICKENS_TO_HATCH)
		{
			if (isServer())
			{
				this.server_SetHealth(-1);
				this.server_Die();
				u8 eggs = this.getQuantity();
				server_CreateBlob("chicken", -1, this.getPosition() + Vec2f(0, -5.0f)).server_SetQuantity(eggs);
			}
		}
	}
}

bool doesCollideWithBlob(CBlob@ this, CBlob@ blob)
{
	if (blob !is null)
	{
		string blobName = blob.getName();
		return blobName != "chicken" && blobName != "egg";
	}
	return false;
}