#define SERVER_ONLY

void onInit(CRules@ this)
{
	u32 time = getGameTime();
	this.set_u32("lastMeteor", time);
	this.set_u32("lastWreckage", time);
	this.set_bool("meteorrain", false);
}

void onRestart(CRules@ this)
{
	u32 time = getGameTime();
	this.set_u32("lastMeteor", time);
	this.set_u32("lastWreckage",time);
	this.set_bool("meteorrain", false);
}

void onTick(CRules@ this)
{
    if (getGameTime() % 30 == 0)
    {
		CMap@ map = getMap();
		
		u32 lastMeteor = this.get_u32("lastMeteor");
		u32 lastWreckage = this.get_u32("lastWreckage");
		
		u32 time = getGameTime();
		u32 timeSinceMeteor = time - lastMeteor;
		u32 timeSinceWreckage = time - lastWreckage;
		u32 meteorTime = 4000;
		if (this.get_bool("meteorrain")) meteorTime = 1000;

        if (timeSinceMeteor > meteorTime && XORRandom(Maths::Max(25000 - timeSinceMeteor, 0)) == 0) // Meteor strike
        {
			tcpr("[RGE] Random event: Meteor");
            server_CreateBlob("meteor", -1, Vec2f(XORRandom(map.tilemapwidth) * map.tilesize, 0.0f));
			
			this.set_u32("lastMeteor", time);
        }
		
		if (timeSinceWreckage > 20000 && XORRandom(Maths::Max(150000 - timeSinceWreckage, 0)) == 0) // Wreckage
        {
            tcpr("[RGE] Random event: Wreckage");
            server_CreateBlob(XORRandom(100) > 50 ? "ancientship" : "poisonship", -1, Vec2f(XORRandom(map.tilemapwidth) * map.tilesize, 0.0f));
			
			this.set_u32("lastWreckage", time);
    	}
    }
}
