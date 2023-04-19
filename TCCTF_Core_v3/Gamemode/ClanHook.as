//Made by vamist

//const string clan_configstr   = "../Cache/TC/ClanPlayerList.cfg";
Clans clan;

void onNewPlayerJoin( CRules@ this, CPlayer@ player )
{
    if(isServer())
    {
        if(player !is null)
        {
            clan.userClanCheck(this,player,player.getUsername().toLower());
        }
        for(int a = 0; a < getPlayerCount(); a++)
        {
            CPlayer@ p = getPlayer(a);
            if(p !is null)
            {
                if(this.exists("clanData"+p.getUsername().toLower()))
                {
                    this.SyncToPlayer("clanData"+p.getUsername().toLower(),player);
                }
            }
        }
    }
}

const string[] darkList = 
{
    "blackguy123",
    "sohkyo",
    "mithrios"
};

const string[] ussrList = 
{
    "mrhobo",
    "wanted6",
    "nutbergers"
};

const string[] buckList = 
{
    "crack_cocaine",
    "cbryant21"
};

class Clans
{
    //Clan init names

    Clans(){}

    //Clan if a player is in a clan, if so give them a property
    void userClanCheck(CRules@ this,CPlayer@ player, string userName)
    {

        if(darkList.find(userName) != -1)
        {
            this.set_string("clanData"+userName,"DARK");
            this.Sync("clanData"+userName,true);
        }
        else if(ussrList.find(userName) != -1)
        {
            this.set_string("clanData"+userName,"USSR");
            this.Sync("clanData"+userName,true);
        }
        else if(buckList.find(userName) != -1)
        {
            this.set_string("clanData"+userName,"Bucket Brotherhood");
            this.Sync("clanData"+userName,true);
        }
        /*
        else if(LuxList.find(userName) != -1)
        {
            this.set_string("clanData"+userName,"Metalon");
            this.Sync("clanData"+userName,true);
        }
        else if(TclfList.find(userName) != -1)
        {
            this.set_string("clanData"+userName,"TC Liberation Front");
            this.Sync("clanData"+userName,true);
        }
        else if(ivanList.find(userName) != -1)
        {
            this.set_string("clanData"+userName,"Invanists United");
            this.Sync("clanData"+userName,true);
        }
        else if(spekList.find(userName) != -1)
        {
            this.set_string("clanData"+userName,"Sepulka");
            this.Sync("clanData"+userName,true);
        }
        else if(scpList.find(userName) != -1)
        {
            this.set_string("clanData"+userName,"SCP");
            this.Sync("clanData"+userName,true);
        }
        */
    }
}