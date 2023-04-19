// A script by TFlippy
#include "GramophoneCommon.as";

void onInit(CBlob@ this)
{
	if (!this.exists("track_id")) 
	{
		Random@ rand = Random(this.getNetworkID());
		this.set_u8("track_id", rand.NextRanged(records.length));
	}
	const u8 track_id = this.get_u8("track_id");
	const u8 track_sprite = Maths::Min(track_id, 27);
	
	// print("" + track_id);
	
	if (track_id < records.length)
	{
		GramophoneRecord record = records[track_id];
		if (record !is null)
		{
			this.setInventoryName("Gramophone Record\n(" + record.name + ")");
			
			CSprite@ sprite = this.getSprite();
			Animation@ anim = sprite.addAnimation("disc_" + track_sprite, 0, false);
			anim.AddFrame(track_sprite);
			
			sprite.SetAnimation(anim);
		}
	}
}