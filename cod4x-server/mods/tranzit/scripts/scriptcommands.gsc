#include scripts\_include;

init()
{
	precacheShader("waypoint_kill");

	/* debug functions */
	addScriptCommand("botpos", 1);
	//addScriptCommand("bottarget", 1);
	//addScriptCommand("botkick", 1);
	addScriptCommand("botkill", 1);
	//addScriptCommand("setwave", 1);
	addScriptCommand("givemoney", 1);
	//addScriptCommand("respawndebug", 1);
	addScriptCommand("botlive", 1);
		
	/* player commands */
	addScriptCommand("myguid", 1);
		
	/* player extra settings */
	addScriptCommand("fov", 1);
	addScriptCommand("fps", 1);
	addScriptCommand("thirdperson", 1);
}

Callback_ScriptCommand(command, arguments)
{
	waittillframeend;

	//if self is defined it was called by a player (chat) -  else with rcon
	if(!isDefined(self))
		return;
		
	switch(command)
	{
		//debug functions
		case "botpos":
			if(isDefined(self))
			{
				level.bot_move_debug = true;
				consolePrint("//" + self.name + " at " + self.origin + "\n");
				self thread TargetMarkers();
			}
			break;
			
		case "botlive":
			logZombieLives();
			break;
			
		case "botkick":
			removeAllTestClients();
			break;
			
		case "botkill":
			killAllZombies();
			break;
			
		case "bottarget":
			self thread BotMoveInfo(arguments);
			break;
		
		case "givemoney":;
			self thread scripts\money::gainMoney(int(arguments));
			break;
			
		case "myguid":
			exec("tell " + self.name + " Your GUID: " + self.guid);
			break;
		
		case "setwave":
			game["tranzit"].wave = int(arguments);
			break;
			
		case "respawndebug":
			spawnPoints = level.teamSpawnPoints[self.pers["team"]];
			spawnPoint = scripts\spawnlogic::getSpawnpoint_NearTeam(spawnPoints);
			self setOrigin(spawnpoint.origin);
			self setPlayerAngles(spawnpoint.angles);
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
		
		default: break;
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

killAllZombies()
{
	for(i=0;i<level.players.size;i++)
	{
		if(level.players[i] isAZombie())
			level.players[i] FinishPlayerDamage(level.players[i], level.players[i], level.players[i].health, 0, "MOD_RIFLE_BULLET", "none", self.origin, VectorToAngles(self.origin - self.origin), "head", 0);
	}
}

logZombieLives()
{
	consolePrint("//" + "level.zombiesTotalForWave: " + level.zombiesTotalForWave + "\n");
	consolePrint("//" + "level.zombiesLeftInWave: " + level.zombiesLeftInWave + "\n");
	consolePrint("//" + "level.zombiesSpawned: " + level.zombiesSpawned + "\n");
	consolePrint("//" + "level.dwarfsLeft: " + level.dwarfsLeft + "\n");
	consolePrint("//" + "\n");

	for(i=0;i<level.players.size;i++)
	{
		if(level.players[i] isAZombie())
			consolePrint("//" + level.players[i].name + ": " + level.players[i].pers["lives"] + "\n");
	}
}

BotMoveInfo(botClientIdentifier)
{
	self endon("death");
	self endon("disconnect");
	
	bot = getPlayer(botClientIdentifier);
	
	if(!isDefined(bot))
		return;

	bot.debugMyPath = true;
	
	consolePrint("botPos: " + bot.origin + " loc: " + bot.myAreaLocation + " wp: " + getNearestWp(bot.origin, bot.myAreaLocation) + "\n");
	
	if(isDefined(bot.myMoveTarget.myAreaLocation))
		consolePrint("botTargetPos: " + bot.myMoveTarget.origin + " loc: " + bot.myMoveTarget.myAreaLocation + " wp: " + getNearestWp(bot.myMoveTarget.origin, bot.myMoveTarget.myAreaLocation) + "\n");
	else
		consolePrint("botTargetPos: " + bot.myMoveTarget.origin + " loc: undefined wp: " + getNearestWp(bot.myMoveTarget.origin, 0) + "\n");
	
	consolePrint("playerPos: " + self.origin + " loc: " + self.myAreaLocation + " wp: " + getNearestWp(self.origin, self.myAreaLocation) + "\n");
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