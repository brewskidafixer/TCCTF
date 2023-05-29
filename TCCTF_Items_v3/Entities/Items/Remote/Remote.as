const u8 maxlinks = 6;

void onInit(CBlob@ this)
{
	for (u8 i = 0; i < maxlinks; i++) this.set_u16("remote_blob_"+i, 0);
	this.set_u8("total_links", 0);
	this.addCommandID("remote_menu");
	this.addCommandID("offblast");
	this.addCommandID("link");
	this.addCommandID("unlink");
}

void onCommand(CBlob@ this, u8 cmd, CBitStream @params)
{
	if (cmd == this.getCommandID("remote_menu"))
	{
		u16 caller;
		if (params.saferead_netid(caller))
		{
			CBlob@ callerBlob = getBlobByNetworkID(caller);
			if (callerBlob !is null && callerBlob.isMyPlayer())
			{
		    	CGridMenu@ menu = CreateGridMenu(getDriver().getScreenCenterPos(), this, Vec2f(this.get_u8("total_links")*2, 4), "\nRemote Menu\n");
				if (menu !is null)
				{
					menu.deleteAfterClick = true;
				
					for (u8 i = 0; i < maxlinks; i++)
					{
						u16 remoteBlob = this.get_u16("remote_blob_"+i);
						if (remoteBlob != 0)
						{
							CBlob@ link = getBlobByNetworkID(remoteBlob);
							if (link is null) continue;
							CBitStream stream;
							stream.write_u16(caller);
							stream.write_u16(callerBlob.getPlayer().getNetworkID());
							stream.write_u16(remoteBlob);
							menu.AddButton("$"+link.getName()+"$", "Control: "+link.get_string("custom name"), this.getCommandID("offblast"), Vec2f(2, 2), stream);
						}
					}
					for (u8 i = 0; i < maxlinks; i++)
					{
						u16 remoteBlob = this.get_u16("remote_blob_"+i);
						if (remoteBlob != 0)
						{
							CBlob@ link = getBlobByNetworkID(remoteBlob);
							if (link is null) continue;
							CBitStream stream;
							stream.write_u16(remoteBlob);
							menu.AddButton("$bucket$", "Unlink: "+link.get_string("custom name"), this.getCommandID("unlink"), Vec2f(2, 2), stream);
						}
					}
				}
			}
		}
	}
	else if (cmd == this.getCommandID("offblast"))
	{
		u16 caller, ply, remoteBlob;
		if (params.saferead_netid(caller) && params.saferead_netid(ply) && params.saferead_netid(remoteBlob))
		{
			CBlob@ link = getBlobByNetworkID(remoteBlob);
			CBitStream stream;
			stream.write_u16(caller);
			stream.write_u16(ply);
			link.SendCommand(link.getCommandID("offblast"), stream);
		}
	}
	else if (cmd == this.getCommandID("link"))
	{
		u16 link;
		if (params.saferead_netid(link))
		{
			for (u8 i = 0; i < maxlinks; i++)
			{
				if (this.get_u16("remote_blob_"+i) == 0)
				{
					this.add_u8("total_links", 1);
					this.set_u16("remote_blob_"+i, link);
					break;
				}
			}
		}
	}
	else if (cmd == this.getCommandID("unlink"))
	{
		u16 link;
		if (params.saferead_netid(link))
		{
			for (u8 i = 0; i < maxlinks; i++)
			{
				if (this.get_u16("remote_blob_"+i) == link)
				{
					this.sub_u8("total_links", 1);
					this.set_u16("remote_blob_"+i, 0);
					break;
				}
			}
			CBlob@ linkBlob = getBlobByNetworkID(link);
			if (linkBlob !is null)
			{
				linkBlob.Tag("canlink");
				linkBlob.set_u16("remote_id", 0);
			}
		}
	}
}

void onAttach(CBlob@ this, CBlob@ attached, AttachmentPoint @ap)
{
	if (isClient()) this.getSprite().PlaySound("/ss_hello.ogg");
}

void GetButtonsFor(CBlob@ this, CBlob@ caller)
{
	if (this.isAttachedTo(caller))
	{
		if (this.get_u8("total_links") > 0)
		{
			CBitStream params;
			params.write_u16(caller.getNetworkID());
			CButton@ button = caller.CreateGenericButton(11, Vec2f(0,0), this, this.getCommandID("remote_menu"), "Open Control Panel", params);
		}
		if (this.get_u8("total_links") < maxlinks)
		{
			CBlob@[] links;
			getBlobsByTag("canlink", @links);
			for (u8 i = 0; i < links.length; i++)
			{
				CBlob@ link = links[i];
				if (link !is null && this.getDistanceTo(link) < 48)
				{
					CBitStream params;
					params.write_u16(this.getNetworkID());
					CButton@ button = caller.CreateGenericButton(0, (link.getName() == "uav") ? Vec2f(-8,-8) : Vec2f(0,0), link, link.getCommandID("link"), "Link", params);
				}
			}
		}
	}
}