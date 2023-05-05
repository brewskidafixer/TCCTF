void onInit(CBlob@ this)
{	
	this.Tag("ammo");
	this.Tag("primable");

	this.maxQuantity = 8;
	this.getCurrentScript().runFlags |= Script::remove_after_this;
}