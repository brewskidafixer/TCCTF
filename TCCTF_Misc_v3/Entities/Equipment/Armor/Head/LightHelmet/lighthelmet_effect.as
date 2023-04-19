#include "PixelOffsets.as"
#include "RunnerTextures.as"
#include "NightVision.as"

void onInit(CBlob@ this)
{
	if (this.hasTag("bushy")) this.Tag("disguised");
	if (this.get_string("reload_script") != "lighthelmet")
		UpdateScript(this);
}

void UpdateScript(CBlob@ this) // the same as onInit, works one time when get equiped
{
    CSpriteLayer@ milhelmet = this.getSprite().addSpriteLayer("lighthelmet", "LightHelmet.png", 16, 16);
   
    if (milhelmet !is null)
    {
        milhelmet.addAnimation("default", 0, true);
		int[] frames = {0, 1, 2, 3};
		milhelmet.animation.AddFrames(frames);
		//milhelmet.SetAnimation(anim);
		
		milhelmet.SetVisible(true);
        milhelmet.SetRelativeZ(200);
        if (this.getSprite().isFacingLeft())
            milhelmet.SetFacingLeft(true);
    }

    if (this.hasTag("nightGoggles"))
    {
    	nightVision(this);
	    CSpriteLayer@ goggles = this.getSprite().addSpriteLayer("nightGoggles", "NightGoggles.png", 16, 16);

		if (goggles !is null)
		{
			goggles.SetVisible(true);
			goggles.SetRelativeZ(200);
			if (this.getSprite().isFacingLeft())
				goggles.SetFacingLeft(true);
		}
	}

    if (this.hasTag("bushy"))
    {
	    CSpriteLayer@ bushy = this.getSprite().addSpriteLayer("bushy", "Bushes.png", 24, 24);

		if (bushy !is null)
		{
			milhelmet.SetVisible(false);
			bushy.SetVisible(true);
			bushy.SetRelativeZ(200);
			if (this.getSprite().isFacingLeft())
				bushy.SetFacingLeft(true);
		}
	}
}
 
void onTick(CBlob@ this)
{
    if (this.get_string("reload_script") == "lighthelmet")
    {
        UpdateScript(this);
        this.set_string("reload_script", "");
    }
 
    CSpriteLayer@ milhelmet = this.getSprite().getSpriteLayer("lighthelmet");
    
   
    if (milhelmet !is null)
    {
        Vec2f headoffset(this.getSprite().getFrameWidth() / 2, -this.getSprite().getFrameHeight() / 2);
        Vec2f head_offset = getHeadOffset(this, -1, 0);
       
        headoffset += this.getSprite().getOffset();
        headoffset += Vec2f(-head_offset.x, head_offset.y);
        headoffset += Vec2f(0, -1);
        milhelmet.SetOffset(headoffset);
        milhelmet.SetFrameIndex(Maths::Floor(this.get_f32("lighthelmet_health") / 6.26f));
		
        CSpriteLayer@ bushy = this.getSprite().getSpriteLayer("bushy");
        if (this.hasTag("bushy") && bushy !is null)
        {
        	bushy.SetOffset(headoffset + Vec2f(1, 1));
        }
		CSpriteLayer@ goggles = this.getSprite().getSpriteLayer("nightGoggles");
		if (this.hasTag("nightGoggles") && goggles !is null)
		{
			goggles.SetOffset(headoffset + Vec2f(0, -1));
		}
    }
   
    if (this.get_f32("lighthelmet_health") >= 25.0f)
    {
        this.getSprite().PlaySound("ricochet_" + XORRandom(3));
        this.set_string("equipment_head", "");
        this.set_f32("lighthelmet_health", 24.9f);
		if (milhelmet !is null)
		{
			this.getSprite().RemoveSpriteLayer("lighthelmet");
		}
        this.RemoveScript("lighthelmet_effect.as");
    }
    
	// print("helmet: "+this.get_f32("mh_health"));
}
 
void onDie(CBlob@ this)
{
	if (isServer())
	{
		CBlob@ item = server_CreateBlob("lighthelmet", this.getTeamNum(), this.getPosition());
		if (item !is null)
		{
			if (this.hasTag("bushy")) item.Tag("bushy");
			if (this.hasTag("nightGoggles")) item.Tag("nightGoggles");
			item.set_f32("health", this.get_f32("lighthelmet_health"));
			item.Sync("health", true);
		}
	}
	
	if (this.getSprite().getSpriteLayer("bushy") !is null) this.getSprite().RemoveSpriteLayer("bushy");
	if (this.getSprite().getSpriteLayer("nightGoggles") !is null) this.getSprite().RemoveSpriteLayer("nightGoggles");
	if (this.getSprite().getSpriteLayer("lighthelmet") !is null) this.getSprite().RemoveSpriteLayer("lighthelmet");
    this.RemoveScript("lighthelmet_effect.as");
}