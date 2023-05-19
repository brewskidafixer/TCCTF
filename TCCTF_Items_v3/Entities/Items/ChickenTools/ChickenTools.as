const string[] classType = {
	"scoutchicken",
	"soldierchicken",
	"heavychicken",
	"commanderchicken"
};

void onInit(CBlob@ this)
{
	if (!this.exists("classtype")) this.set_string("classtype", "soldierchicken");
	string className = this.get_string("classtype");
	this.set_string("required class", className);
	this.set_Vec2f("class offset", Vec2f(0, 0));
	
	this.Tag("kill on use");
	this.Tag("dangerous");
	CSprite@ head = this.getSprite();
	if (head !is null)
	{
		for (u8 i = 0; i < classType.length; i++)
		{
			if (className == classType[i])
			{
				head.SetFrameIndex(i);
				this.setInventoryName(classType[i] + "'s Outfit");
				return;
			}
		}
	}
}

void GetButtonsFor(CBlob@ this, CBlob@ caller)
{
	bool canChangeClass = caller.getName() == this.get_string("required class");

	if(canChangeClass)
	{
		this.Untag("class button disabled");
	}
	else
	{
		this.Tag("class button disabled");
	}
}