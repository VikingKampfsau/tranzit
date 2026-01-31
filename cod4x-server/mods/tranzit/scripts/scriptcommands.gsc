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
	embed.sender_avatar = getDvar("webhook_url_avatar");
	embed.title = StrColorStrip(getDvar("sv_hostname")) + " (IP: " + getDvar("net_ip") + ":" + getDvar("net_port") + ")";
	embed.message = subMessage;
	embed.color = "";
	
	if(command == "calladmin")
	{
		webhook.url = getDvar("webhook_url_calladmin");

		embed.color = 16711680; //www.spycolor.com -> decimal value!
	}
	else if(isSubStr(command, "bug"))
	{
		webhook.url = getDvar("webhook_url_bug");
	
		embed.color = 16711680; //www.spycolor.com -> decimal value!
	}
	else if(isSubStr(command, "suggest") || command == "feature" || command == "idea")
	{
		webhook.url = getDvar("webhook_url_feature");
	
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
	
	//consolePrint("GSC: " + jsonPostMsg + "\n");
	
	httppostjson(webhook.url, jsonPostMsg, ::httppostjsonCallback, author);
}

httppostjsonCallback(handle)
{
	exec("tell " + self.name + " Failed to send your message - JSON POST failed!");
	
	// release the plugin internal json data
	jsonreleaseobject(handle);
}