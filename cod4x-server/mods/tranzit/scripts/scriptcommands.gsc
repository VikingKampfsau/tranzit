#include scripts\_include;

init()
{
	precacheShader("waypoint_kill");

	/* player commands */
	addScriptCommand("myguid", 1);
	addScriptCommand("calladmin", 1);
		
	/* player extra settings */
	addScriptCommand("fov", 1);
	addScriptCommand("fps", 1);
	addScriptCommand("thirdperson", 1);
	
	/* bug reports & feedback */
	addScriptCommand("bug", 1);
	addScriptCommand("bugs", 1);
	addScriptCommand("idea", 1);
	addScriptCommand("feature", 1);
	addScriptCommand("suggest", 1);
	addScriptCommand("suggestion", 1);
}

Callback_ScriptCommand(command, arguments)
{
	waittillframeend;

	//if self is defined it was called by a player (chat) -  else with rcon
	if(!isDefined(self) || !isPlayer(self))
		return;
	
	//mod included commands
	switch(command)
	{
		// player commands
		case "myguid":
			exec("tell " + self.name + " Your GUID: " + self.guid);
			break;
		
		case "calladmin":			
		case "bug":
		case "bugs":
		case "idea":
		case "feature":
		case "suggest":
		case "suggestion":
			sendDiscordMessage(self, command, arguments);
			break;
		
		//player extra settings
		case "fov":
			self.playerSetting[command] += 0.125;
			
			if(self.playerSetting[command] > 1.25)
				self.playerSetting[command] = 1;
			
			self setClientDvar("cg_fovScale", self.playerSetting[command]);
			self iPrintlnBold("FoV Scale: ^1" + self.playerSetting[command]);
			break;
			
		case "fps":
			self.playerSetting[command] = !self.playerSetting[command];
			self setClientDvar("cg_drawfps", self.playerSetting[command]);
			break;
		
		case "thirdperson":
			self.playerSetting[command] = !self.playerSetting[command];
			self setClientDvar("cg_thirdperson", self.playerSetting[command]);
			break;
		
		default:
			exec("tell " + self.name + " ^1Unknown command!");
			break;
	}
}

resetPlayerSettings()
{
	self.playerSetting["fov"] = 1;
	self.playerSetting["fps"] = false;
	self.playerSetting["thirdperson"] = false;
	
	self setClientDvars("cg_fovScale", self.playerSetting["fov"],
						"cg_drawfps", self.playerSetting["fps"],
						"cg_thirdperson", self.playerSetting["thirdperson"]);
}

TargetMarkers()
{
	self endon("death");
	self endon("disconnect");

	self setClientDvars("waypointiconheight", 20,
						"waypointiconwidth", 20);

	self.targetMarkers = [];

	for(i=0;i<level.alivePlayers[game["attackers"]].size;i++)
	{
		enemy = level.alivePlayers[game["attackers"]][i];
		
		if(isDefined(self.targetMarkers[i]))
			self.targetMarkers[i] delete();
	
		self.targetMarkers[i] = newClientHudElem(self);
		self.targetMarkers[i].x = enemy.origin[0];
		self.targetMarkers[i].y = enemy.origin[1];
		self.targetMarkers[i].z = enemy.origin[2];
		self.targetMarkers[i].isFlashing = false;
		self.targetMarkers[i].isShown = true;
		self.targetMarkers[i].baseAlpha = 0;
		self.targetMarkers[i].alpha = 0;
		self.targetMarkers[i].owner = self;
		self.targetMarkers[i].team = self.pers["team"];
		self.targetMarkers[i].target = enemy;
		self.targetMarkers[i] setShader("waypoint_kill", 15, 15);
		self.targetMarkers[i] setWayPoint(true, "waypoint_kill");
		self.targetMarkers[i] setTargetEnt(enemy);
		
		self.targetMarkers[i] thread monitorMarkerVisibility();
	}
}

monitorMarkerVisibility()
{
	self endon("death");
	
	if(isDefined(self.owner) && isDefined(self.target) && self.owner == self.target)
		return;
	
	while(1)
	{
		wait .05;
		
		if(!isDefined(self))
			break;
			
		if(!isDefined(self.owner) || !isPlayer(self.owner) || !isAlive(self.owner))
			break;
			
		if(!isDefined(self.target) || !isPlayer(self.target) || !isDefined(self.target getEntityNumber()))
			break;

		if(!isAlive(self.target) || self.target.sessionstate != "playing")
			break;

		if(self.target.pers["team"] == self.team)
			break;
	
		self.baseAlpha = 1;
		self.alpha = 1;
	}

	if(isDefined(self))
	{
		self clearTargetEnt();
		self destroy();
	}
}

DeleteTargetMarkers()
{
	self endon("disconnect");

	if(!isDefined(self))
		return;
	
	self setClientDvars("waypointiconheight", 36,
						"waypointiconwidth", 36);
	
	if(!isDefined(self.targetMarkers))
		return;
	
	for(i=0;i<self.targetMarkers.size;i++)
	{
		if(isDefined(self.targetMarkers[i]))
		{
			self.targetMarkers[i] clearTargetEnt();
			self.targetMarkers[i] destroy();
		}
	}
}

sendDiscordMessage(author, command, subMessage)
{
	if(!isDefined(subMessage) || subMessage == "")
	{
		exec("tell " + self.name + " Please enter a reason/description to your message!");
		return;
	}
	
	if(subMessage.size <= 3 || isEmptyString(subMessage))
	{
		exec("tell " + self.name + " Please enter a valid reason/description to your message!");
		return;
	}

	webhook = spawnStruct();
	webhook.url = "";
	
	embed = spawnStruct();
	embed.sender = author.name + " (" + author.guid + ")";
	embed.sender_avatar ="https://crops.giga.de/14/93/35/043030a8262119459ad158a42e_YyAxMjc0eDcxNyszKzM4AnJlIDg0MCA0NzIDMTMwMGE2MTVkODI=.jpg";
	embed.title = StrColorStrip(getDvar("sv_hostname")) + " (IP: " + getDvar("net_ip") + ":" + getDvar("net_port") + ")";
	embed.message = subMessage;
	embed.color = "";
	
	if(command == "calladmin")
	{
		webhook.url = "https://discord.com/api/webhooks/420542354135449600/V_zA11Wx_ymsCz62lTzPUSWdEIdKMrnS8eF8TV4wvxzx1AXQXOTvqYmzbT6eXrR1QDhe";

		embed.color = 16711680; //www.spycolor.com -> decimal value!
	}
	else if(isSubStr(command, "bug"))
	{
		webhook.url = "https://discord.com/api/webhooks/958627045053722634/ERV00nMBUAFr50288_uoaZZ8_ddOSOZ-otK7gMxt7XqylvepEFuUa7oT7Us0qXOS75T4";
	
		embed.color = 16711680; //www.spycolor.com -> decimal value!
	}
	else if(isSubStr(command, "suggest") || command == "feature" || command == "idea")
	{
		webhook.url = "https://discord.com/api/webhooks/958627851060514856/76bqIDheNV-JZACLnhVLeC7AwGPPwykZudJTQ2qbQ8cY_grodrl6TFW7OO9qJ93C7xVM";
	
		embed.color = 16769280; //www.spycolor.com -> decimal value!
	}

	if(!isDefined(webhook.url) || webhook.url == "")
	{
		exec("tell " + self.name + " Failed to send your message - connection to discord failed!");
		return;
	}
	
	jsonPostMsg = ""+
		"{"+
			"\"embeds\":"+
			"["+
			"{"+
				"\"author\":"+
				"{"+
					"\"name\": \"" + embed.sender + "\","+
					"\"icon_url\": \"" + embed.sender_avatar + "\""+
				"},"+
				"\"title\": \"" + embed.title + "\","+
				"\"description\": \"" + embed.message + "\","+
				"\"color\": \"" + embed.color + "\""+
			"}"+
			"]"+
		"}";
	
	httppostjson(webhook.url, jsonPostMsg, ::httppostjsonCallback, author);
}

httppostjsonCallback(handle)
{
	exec("tell " + self.name + " Failed to send your message - JSON POST failed!");
	
	// release the plugin internal json data
	jsonreleaseobject(handle);
}

/*
NOTE: Somehow copy & paste does not work - typing the commands works!
Install the dlang compiler and dub build system (https://dlang.org/download.html); for ubuntu/debian:

sudo wget https://netcologne.dl.sourceforge.net/project/d-apt/files/d-apt.list -O /etc/apt/sources.list.d/d-apt.list﻿
sudo apt-get update --allow-unauthenticated --allow-insecure-repositories
sudo apt-get -y --allow-unauthenticated install --reinstall d-apt-keyring﻿
sudo apt-get up﻿date && sudo apt-get i﻿nstall dmd-co﻿mpile﻿r du﻿b﻿

you'll also need the phobos library

sudo apt install libphobos2-dev:i386﻿

clone the plugin repository

git clone https://github.com/callofduty4x/cod4x_plugin_http.git﻿
cd ~/cod4x_plugin_http

then compile the plugin with

dub --arch=x86 --build=release﻿

now you should have "libcod4x_http_plugin.so"
*/