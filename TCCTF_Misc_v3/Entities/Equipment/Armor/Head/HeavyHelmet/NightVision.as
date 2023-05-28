void nightVision(CBlob@ this)
{
    u8 team = this.getTeamNum();
    /*
    SColor[] colors =
    {
        SColor(255, 50, 20, 255), // Blue
        SColor(255, 255, 50, 20), // Red
        SColor(255, 50, 255, 20), // Green
        SColor(255, 255, 20, 255), // Magenta
        SColor(255, 255, 128, 20), // Orange
        SColor(255, 20, 255, 255), // Cyan
        SColor(255, 128, 128, 255), // Violet
    };

    this.SetLight(true);
    this.SetLightRadius(128.0f);
    this.SetLightColor(team < colors.length ? colors[team] : SColor(255, 200, 200, 200));
    */

    if (isClient() && this.isMyPlayer())
    {
        switch (team)
        {
            case 0:     getMap().CreateSkyGradient("nightvision_blue.png"); break;
            case 1:     getMap().CreateSkyGradient("nightvision_red.png"); break;
            case 2:     getMap().CreateSkyGradient("nightvision_green.png"); break;
            case 3:     getMap().CreateSkyGradient("nightvision_violet.png"); break;
            case 4:     getMap().CreateSkyGradient("nightvision_orange.png"); break;
            case 5:     getMap().CreateSkyGradient("nightvision_cyan.png"); break;
            case 6:     getMap().CreateSkyGradient("nightvision_indigo.png"); break;
            default:    getMap().CreateSkyGradient("nightvision_grey.png"); break;
        }
    }
}