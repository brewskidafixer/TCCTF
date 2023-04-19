//Ghost logic

#include "Hitters.as";
#include "Knocked.as";
#include "ThrowCommon.as";
#include "RunnerCommon.as";
#include "Help.as";
#include "Requirements.as"

void onInit(CBlob@ this)
{
	//this.Tag("noBubbles"); this is for disabling emoticons, we won't need that.
	this.Tag("notarget"); //makes AI never target us
	this.Tag("noCapturing");
	this.Tag("truesight");

	this.Tag("noUseMenu");
	this.set_f32("gib health", -3.0f);

	this.getShape().getConsts().mapCollisions = false;

	this.Tag("player");
	this.Tag("invincible");
	this.SetVisible(false);

	CShape@ shape = this.getShape();
	shape.SetRotationsAllowed(false);
	shape.getConsts().net_threshold_multiplier = 0.5f;

	this.set_Vec2f("inventory offset", Vec2f(0.0f, -152.0f));

	this.getCurrentScript().runFlags |= Script::tick_not_attached;
	this.getCurrentScript().removeIfTag = "dead";

	this.getSprite().SetAnimation(this.getSexNum() == 0 ? "male" : "female");

	if(!isClient()){return;}
	ParticleZombieLightning(this.getPosition());
	this.getSprite().PlaySound("MagicWand.ogg");

}

void onSetPlayer(CBlob@ this, CPlayer@ player)
{
	if (player !is null)
	{
		/*player.server_setTeamNum(-1);
		this.server_setTeamNum(-1);*/
		player.SetScoreboardVars("ScoreboardIcons.png", (this.getSexNum() == 0 ? 8 : 9), Vec2f(16, 16));
	}
}

void onDie(CBlob@ this)
{
	if(!isClient()){return;}
	ParticleZombieLightning(this.getPosition());
	this.getSprite().PlaySound("SuddenGib.ogg", 0.9f, 1.0f);
}

void onTick(CBlob@ this)
{
	if (this.isInInventory()) return;
}

f32 onHit(CBlob@ this, Vec2f worldPoint, Vec2f velocity, f32 damage, CBlob@ hitterBlob, u8 customData)
{
	return 0;
}
