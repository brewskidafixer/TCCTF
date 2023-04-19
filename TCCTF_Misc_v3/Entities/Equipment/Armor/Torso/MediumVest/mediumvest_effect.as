#include "RunnerCommon.as"

void onTick(CBlob@ this)
{
    if (this.get_string("reload_script") == "mediumvest")
		this.set_string("reload_script", "");
	
	//print("hp: "+this.get_f32("bpv_health"));
	RunnerMoveVars@ moveVars;
    if (this.get("moveVars", @moveVars))
    {
        moveVars.walkFactor *= 0.85f;
    }
	
	if (this.get_f32("mediumvest_health") >= 60.0f)
	{
		this.getSprite().PlaySound("ricochet_" + XORRandom(3));
		this.set_string("equipment_torso", "");
		this.set_f32("mediumvest_health", 59.9f);
		this.RemoveScript("mediumvest_effect.as");
	}
	// print("torso: "+this.get_f32("bpv_health"));
}
//all stuff for damage located in FleshHit.as