void onInit(CBlob@ this)
{
	this.set_string("required class", "drone");
	this.set_Vec2f("class offset", Vec2f(0, 0));
	
	this.Tag("kill on use");
	this.Tag("dangerous");
}

void GetButtonsFor(CBlob@ this, CBlob@ caller)
{
	bool canChangeClass = caller.getName() != "drone";

	if(canChangeClass)
	{
		this.Untag("class button disabled");
	}
	else
	{
		this.Tag("class button disabled");
	}
}