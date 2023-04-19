void onInit(CBlob@ this)
{
	if (isServer())
	{
		this.set_u8('decay step', 6);
	}

	this.maxQuantity = 2500;
	this.set_u8("fuel_energy", 20);
}