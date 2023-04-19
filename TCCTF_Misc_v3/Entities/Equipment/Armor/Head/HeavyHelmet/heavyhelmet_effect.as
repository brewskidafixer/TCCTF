#include "PixelOffsets.as"
#include "RunnerTextures.as"
#include "RunnerCommon.as"
#include "NightVision.as";

void onInit(CBlob@ this)
{
    if (this.get_string("reload_script") != "heavyhelmet")
        UpdateScript(this);
}

void UpdateScript(CBlob@ this) // the same as onInit, works one time when get equiped
{
    nightVision(this);
    CSpriteLayer@ milhelmet = this.getSprite().addSpriteLayer("heavyhelmet", "HeavyHelmet.png", 16, 16);
   
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
}

void onTick(CBlob@ this)
{
    if (this.get_string("reload_script") == "heavyhelmet")
    {
        UpdateScript(this);
        this.set_string("reload_script", "");
    }
 
    CSpriteLayer@ milhelmet = this.getSprite().getSpriteLayer("heavyhelmet");
    
   
    if (milhelmet !is null)
    {
        Vec2f headoffset(this.getSprite().getFrameWidth() / 2, -this.getSprite().getFrameHeight() / 2);
        Vec2f head_offset = getHeadOffset(this, -1, 0);
       
        headoffset += this.getSprite().getOffset();
        headoffset += Vec2f(-head_offset.x, head_offset.y);
        headoffset += Vec2f(0, -2);
        milhelmet.SetOffset(headoffset);
        milhelmet.SetFrameIndex(Maths::Floor(this.get_f32("heavyhelmet_health") / 17.51f));
    }

    RunnerMoveVars@ moveVars;
    if (this.get("moveVars", @moveVars))
    {
        moveVars.walkFactor *= 0.85f;
    }
   
    if (this.get_f32("heavyhelmet_health") >= 70.0f)
    {
        this.getSprite().PlaySound("ricochet_" + XORRandom(3));
        this.set_string("equipment_head", "");
        this.set_f32("heavyhelmet_health", 69.9f);
        if (milhelmet !is null)
        {
            this.getSprite().RemoveSpriteLayer("heavyhelmet");
        }
        this.RemoveScript("heavyhelmet_effect.as");
    }
    
    // print("helmet: "+this.get_f32("mh_health"));
}
 
void onDie(CBlob@ this)
{
    if (isServer())
    {
        CBlob@ item = server_CreateBlob("heavyhelmet", this.getTeamNum(), this.getPosition());
        if (item !is null)
        {
            item.set_f32("health", this.get_f32("heavyhelmet_health"));
            item.Sync("health", true);
        }
    }
    if (isClient() && this.isMyPlayer()) getMap().CreateSkyGradient("skygradient.png");

    if (this.getSprite().getSpriteLayer("heavyhelmet") !is null) this.getSprite().RemoveSpriteLayer("heavyhelmet");
    this.RemoveScript("heavyhelmet_effect.as");
}