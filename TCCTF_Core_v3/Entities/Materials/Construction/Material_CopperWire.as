void onInit(CBlob@ this)
{	
	this.maxQuantity = 5000;
	this.getCurrentScript().runFlags |= Script::remove_after_this;
}