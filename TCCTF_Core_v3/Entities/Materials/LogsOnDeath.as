//tree making logs on death script

#include "TreeCommon.as"

void onDie(CBlob@ this)
{
	if (this.hasTag("no drop")) return;
	
	Vec2f pos = this.getPosition();
	pos.y -= 4.0f; // TODO: fix logs spawning in ground
	f32 fall_angle = 0.0f;

	if (this.exists("tree_fall_angle"))
	{
		fall_angle = this.get_f32("tree_fall_angle");
	}

	TreeSegment[]@ segments;
	this.get("TreeSegments", @segments);
	if (segments is null)
		return;

	if (isServer())
	{
		if (this.hasTag("burning"))
		{
			CBlob@ coal = server_CreateBlob("mat_coal", this.getTeamNum(), pos);
			if (coal !is null) coal.server_SetQuantity(3*segments.length);
		}
		else
		{
			CBlob@ log = server_CreateBlob("log", this.getTeamNum(), pos);
			if (log !is null)
			{
				log.server_SetQuantity(segments.length);
				log.setAngleDegrees(fall_angle);
			}
		}
	}

	//TODO LEAVES PARTICLES
	//ParticleAnimated( "Entities/Effects/leaves", pos, Vec2f(0,-0.5f), 0.0f, 1.0f, 2+XORRandom(4), 0.2f, false );
	//for (int i = 0; i < this.getSprite().getSpriteLayerCount(); i++) { // crashes
	//    ParticlesFromSprite( this.getSprite().getSpriteLayer(i) );
	//}
	// effects
	Sound::Play("Sounds/branches" + (XORRandom(2) + 1) + ".ogg", this.getPosition());
}
