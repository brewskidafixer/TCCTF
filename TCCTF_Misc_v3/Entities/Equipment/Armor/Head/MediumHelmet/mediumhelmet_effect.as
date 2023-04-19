#include "PixelOffsets.as"
#include "RunnerTextures.as"
#include "RunnerCommon.as"
#include "NightVision.as"

void onInit(CBlob@ this)
{
    if (this.get_string("reload_script") != "mediumhelmet")
        UpdateScript(this);
}

void UpdateScript(CBlob@ this) // the same as onInit, works one time when get equiped
{
    CSpriteLayer@ milhelmet = this.getSprite().addSpriteLayer("mediumhelmet", "MediumHelmet.png", 16, 16);
   
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
    if (this.get_string("reload_script") == "mediumhelmet")
    {
        UpdateScript(this);
        this.set_string("reload_script", "");
    }
 
    CSpriteLayer@ milhelmet = this.getSprite().getSpriteLayer("mediumhelmet");
    
   
    if (milhelmet !is null)
    {
        Vec2f headoffset(this.getSprite().getFrameWidth() / 2, -this.getSprite().getFrameHeight() / 2);
        Vec2f head_offset = getHeadOffset(this, -1, 0);
       
        headoffset += this.getSprite().getOffset();
        headoffset += Vec2f(-head_offset.x, head_offset.y);
        headoffset += Vec2f(0, -1);
        milhelmet.SetOffset(headoffset);
        milhelmet.SetFrameIndex(Maths::Floor(this.get_f32("mediumhelmet_health") / 10.01f));

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

    RunnerMoveVars@ moveVars;
    if (this.get("moveVars", @moveVars))
    {
        moveVars.walkFactor *= 0.95f;
    }
   
    if (this.get_f32("mediumhelmet_health") >= 40.0f)
    {
        this.getSprite().PlaySound("ricochet_" + XORRandom(3));
        this.set_string("equipment_head", "");
        this.set_f32("mediumhelmet_health", 39.9f);
        if (milhelmet !is null)
        {
            this.getSprite().RemoveSpriteLayer("mediumhelmet");
        }
        this.RemoveScript("mediumhelmet_effect.as");
    }
    
    // print("helmet: "+this.get_f32("mh_health"));
}
 
void onDie(CBlob@ this)
{
    if (isServer())
    {
        CBlob@ item = server_CreateBlob("mediumhelmet", this.getTeamNum(), this.getPosition());
        if (item !is null)
        {
            if (this.hasTag("bushy")) item.Tag("bushy");
            if (this.hasTag("nightGoggles")) item.Tag("nightGoggles");
            item.set_f32("health", this.get_f32("mediumhelmet_health"));
            item.Sync("health", true);
        }
    }
    
    if (this.getSprite().getSpriteLayer("bushy") !is null) this.getSprite().RemoveSpriteLayer("bushy");
    if (this.getSprite().getSpriteLayer("nightGoggles") !is null) this.getSprite().RemoveSpriteLayer("nightGoggles");
    if (this.getSprite().getSpriteLayer("mediumhelmet") !is null) this.getSprite().RemoveSpriteLayer("mediumhelmet");
    this.RemoveScript("mediumhelmet_effect.as");
}