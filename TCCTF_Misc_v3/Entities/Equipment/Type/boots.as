void onInit(CBlob@ this)
{
	this.getShape().SetRotationsAllowed(true);

	this.Tag("boots");

	if (this.getName() == "combatboots")
		this.Tag("armor");
	else if (this.getName() == "flippers")
		this.maxQuantity = 3;
}