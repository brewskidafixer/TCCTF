#include "Hitters.as";

void Splash(CBlob@ this, const uint splash_halfwidth, const uint splash_halfheight,
            const f32 splash_offset, const bool shouldStun = true)
{
	//extinguish fire
	CMap@ map = this.getMap();
	Sound::Play("SplashSlow.ogg", this.getPosition(), 3.0f);


    //bool raycast = this.hasTag("splash ray cast");

	if (map !is null)
	{
		bool is_server = isServer();
		Vec2f pos = this.getPosition() +
		            Vec2f(this.isFacingLeft() ?
		                  -splash_halfwidth * map.tilesize*splash_offset :
		                  splash_halfwidth * map.tilesize * splash_offset,
		                  0);

		for (int x_step = -splash_halfwidth - 2; x_step < splash_halfwidth + 2; ++x_step)
		{
			for (int y_step = -splash_halfheight - 2; y_step < splash_halfheight + 2; ++y_step)
			{
				Vec2f wpos = pos + Vec2f(x_step * map.tilesize, y_step * map.tilesize);
				Vec2f outpos;

				//extinguish the fire at this pos
				if (is_server)
				{
					map.server_setFireWorldspace(wpos, false);
				}

				//make a splash!
				if (!v_fastrender)
				{
					bool random_fact = ((x_step + y_step + getGameTime() + 125678) % 7 > 3);

					if (x_step >= -splash_halfwidth && x_step < splash_halfwidth &&
					        y_step >= -splash_halfheight && y_step < splash_halfheight &&
					        (random_fact || y_step == 0 || x_step == 0))
					{
						map.SplashEffect(wpos, Vec2f(0, 10), 8.0f);
					}
				}
			}
		}

		const f32 radius = Maths::Max(splash_halfwidth * map.tilesize + map.tilesize, splash_halfheight * map.tilesize + map.tilesize);

		u8 hitter = shouldStun ? Hitters::water_stun : Hitters::water;

		Vec2f offset = Vec2f(splash_halfwidth * map.tilesize + map.tilesize, splash_halfheight * map.tilesize + map.tilesize);
		Vec2f tl = pos - offset * 0.5f;
		Vec2f br = pos + offset * 0.5f;
		if (is_server)
		{
			CBlob@ ownerBlob;
			CPlayer@ damagePlayer = this.getDamageOwnerPlayer();
			if (damagePlayer !is null && damagePlayer.getBlob() !is null)
			{
				@ownerBlob = damagePlayer.getBlob();
			}

			CBlob@[] blobs;
			map.getBlobsInBox(tl, br, @blobs);
			for (uint i = 0; i < blobs.length; i++)
			{
				CBlob@ blob = blobs[i];

				if (blob is null) { continue;}
                /*if(raycast
                    && blob.getPlayer() !is null
                    && map.rayCastSolidNoBlobs(this.getPosition(), blob.getPosition()))
                {
                    continue;

                }*/


				bool hitHard = (blob.getTeamNum()!=this.getTeamNum() || (this.getTeamNum()<0 || this.getTeamNum()>=7)) || ownerBlob is blob;

				Vec2f hit_blob_pos = blob.getPosition();
				Vec2f bombforce = getBombForce(radius, hit_blob_pos, pos, blob.getMass(), 0);

				if (shouldStun && (ownerBlob is blob || (this.isOverlapping(blob) && hitHard)))
				{
					this.server_Hit(blob, pos, bombforce, 0.0f, Hitters::water_stun_force, true);
				}

				if (hitHard)
				{
					this.server_Hit(blob, pos, bombforce, 0.0f, hitter, true);
				}
				else //still have to hit teamies so we can put them out!
				{
					this.server_Hit(blob, pos, bombforce, 0.0f, Hitters::water, true);
				}
			}
		}
	}
}

// copied from Explosion.as ...... should be in bombcommon?
Vec2f getBombForce(f32 radius, Vec2f hit_blob_pos, Vec2f pos, f32 hit_blob_mass, f32 &out scale)
{
	Vec2f offset = hit_blob_pos - pos;
	f32 distance = offset.Length();
	//set the scale (2 step)
	scale = (distance > (radius * 0.7)) ? 0.5f : 1.0f;
	//the force, copy across
	Vec2f bombforce = offset;
	bombforce.Normalize();
	bombforce *= 2.0f;
	bombforce.y -= 0.2f; // push up for greater cinematic effect
	bombforce.x = Maths::Round(bombforce.x);
	bombforce.y = Maths::Round(bombforce.y);
	bombforce /= 2.0f;
	bombforce *= hit_blob_mass * (3.0f) * scale;
	return bombforce;
}
