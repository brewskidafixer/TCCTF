void onInit(CBlob@ this)
{
	this.Tag("head");

	string name = this.getName();

	if (name == "lighthelmet" || name == "mediumhelmet" || name == "heavyhelmet")
	{
		if (this.exists("health"))
		{
			CSprite@ sprite = this.getSprite();
			if (sprite !is null)
		    {
		        Animation@ animation = sprite.getAnimation("default");
		        if (animation !is null)
		        {
					f32 divider = 6.26f;
					if (name == "mediumhelmet") divider = 10.0f;
					else if (name == "heavyhelmet") divider = 17.51f;
					sprite.animation.frame = u8(Maths::Floor(this.get_f32("health") / divider));
				}
		    }
		}
		this.Tag("armor");
	}
}