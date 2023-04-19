
//gib into steak blob(s) on death

void onInit(CBlob@ this)
{
	if (!this.exists("number of steaks"))
		this.set_u8("number of steaks", 1);
}

void onDie(CBlob@ this)
{
	if (isServer() && this.getHealth() < 0.0f)
	{
		u8 steaks = this.get_u8("number of steaks");

		CBlob@ steak = server_CreateBlob("steak", -1, this.getPosition());
		if (steak !is null)
		{
			steak.server_SetQuantity(this.get_u8("number of steaks")*this.getQuantity());
		}
	}
	this.getCurrentScript().runFlags |= Script::remove_after_this;
}
