void onInit(CBlob@ this)
{
	this.Tag("torso");

	string name = this.getName();
	
	if (name == "suicidevest" || name == "keg")
		this.Tag("explosive");
	else if (name == "lightvest" || name == "mediumvest" || name == "heavyvest")
		this.Tag("armor");
	else if (name == "jetpack")
		this.maxQuantity = 3;
}