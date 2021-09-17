#include maps\mp\_utility;
#include scripts\_include;

Callback_StartGameType()
{
	setDvar("scr_game_playerwaittime", 0);
	setDvar("scr_game_matchstarttime", 0);
	setDvar("scr_game_onlyheadshots", 0);
	setDvar("scr_game_allowkillcam", 0);
	setDvar("scr_game_spectatetype", 1);
	setDvar("scr_team_fftype", 0);

	level.splitscreen = 0;
	level.xenon = 0;
	level.ps3 = 0;
	level.console = 0;
	level.oldschool = 0;
	level.onlineGame = false;
	level.rankedMatch = false;

	level.prematchPeriod = 0;
	level.prematchPeriodEnd = 0;
	
	level.intermission = false;
	
	if ( !isDefined( game["gamestarted"] ) )
	{
		// defaults if not defined in level script
		game["allies"] = "marines";
		game["axis"] = "russian";
		
		game["attackers"] = "axis";
		game["defenders"] = "allies";

		if(!isDefined(game["state"]))
			game["state"] = "playing";
	
		precacheStatusIcon( "hud_status_dead" );
		//precacheStatusIcon( "hud_status_connecting" );
		
		precacheRumble( "damage_heavy" );

		precacheShader( "white" );
		precacheShader( "black" );
		
		makeDvarServerInfo( "scr_allies", "usmc" );
		makeDvarServerInfo( "scr_axis", "arab" );

		game["strings"]["press_to_spawn"] = &"PLATFORM_PRESS_TO_SPAWN";
		game["strings"]["waiting_for_teams"] = &"MP_WAITING_FOR_PLAYERS";
		game["strings"]["opponent_forfeiting_in"] = &"MP_OPPONENT_FORFEITING_IN";
		game["strings"]["match_starting_in"] = &"MP_MATCH_STARTING_IN";
		game["strings"]["spawn_next_round"] = &"MP_SPAWN_NEXT_ROUND";
		game["strings"]["waiting_to_spawn"] = &"MP_WAITING_TO_SPAWN";
		game["strings"]["match_starting"] = &"MP_MATCH_STARTING";
		game["strings"]["change_class"] = &"MP_CHANGE_CLASS_NEXT_SPAWN";
		game["strings"]["last_stand"] = &"MPUI_LAST_STAND";
		
		game["strings"]["cowards_way"] = &"PLATFORM_COWARDS_WAY_OUT";
		
		game["strings"]["tie"] = &"MP_MATCH_TIE";
		game["strings"]["round_draw"] = &"MP_ROUND_DRAW";

		game["strings"]["enemies_eliminated"] = &"MP_ENEMIES_ELIMINATED";
		game["strings"]["score_limit_reached"] = &"MP_SCORE_LIMIT_REACHED";
		game["strings"]["round_limit_reached"] = &"MP_ROUND_LIMIT_REACHED";
		game["strings"]["time_limit_reached"] = &"MP_TIME_LIMIT_REACHED";
		game["strings"]["players_forfeited"] = &"MP_PLAYERS_FORFEITED";

		game["strings"]["allies_win"] = &"MP_MARINES_WIN_MATCH";
		game["strings"]["allies_win_round"] = &"MP_MARINES_WIN_ROUND";
		game["strings"]["allies_mission_accomplished"] = &"MP_MARINES_MISSION_ACCOMPLISHED";
		game["strings"]["allies_eliminated"] = &"MP_MARINES_ELIMINATED";
		game["strings"]["allies_forfeited"] = &"MP_MARINES_FORFEITED";
		game["strings"]["allies_name"] = &"MP_MARINES_NAME";
		
		game["music"]["spawn_allies"] = "mp_spawn_usa";
		game["music"]["victory_allies"] = "mp_victory_usa";
		game["icons"]["allies"] = "faction_128_usmc";
		game["colors"]["allies"] = (0,0,0);
		game["voice"]["allies"] = "US_1mc_";
		setDvar( "scr_allies", "usmc" );
		
		game["strings"]["axis_win"] = &"MP_SPETSNAZ_WIN_MATCH";
		game["strings"]["axis_win_round"] = &"MP_SPETSNAZ_WIN_ROUND";
		game["strings"]["axis_mission_accomplished"] = &"MP_SPETSNAZ_MISSION_ACCOMPLISHED";
		game["strings"]["axis_eliminated"] = &"MP_SPETSNAZ_ELIMINATED";
		game["strings"]["axis_forfeited"] = &"MP_SPETSNAZ_FORFEITED";
		game["strings"]["axis_name"] = &"MP_SPETSNAZ_NAME";
		
		game["music"]["spawn_axis"] = "mp_spawn_soviet";
		game["music"]["victory_axis"] = "mp_victory_soviet";
		game["icons"]["axis"] = "faction_128_ussr";
		game["colors"]["axis"] = (0.52,0.28,0.28);
		game["voice"]["axis"] = "RU_1mc_";
		setDvar( "scr_axis", "ussr" );

		game["music"]["defeat"] = "mp_defeat";
		game["music"]["victory_spectator"] = "mp_defeat";
		game["music"]["winning"] = "mp_time_running_out_winning";
		game["music"]["losing"] = "mp_time_running_out_losing";
		game["music"]["victory_tie"] = "mp_defeat";
		
		game["music"]["suspense"] = [];
		game["music"]["suspense"][game["music"]["suspense"].size] = "mp_suspense_01";
		game["music"]["suspense"][game["music"]["suspense"].size] = "mp_suspense_02";
		game["music"]["suspense"][game["music"]["suspense"].size] = "mp_suspense_03";
		game["music"]["suspense"][game["music"]["suspense"].size] = "mp_suspense_04";
		game["music"]["suspense"][game["music"]["suspense"].size] = "mp_suspense_05";
		game["music"]["suspense"][game["music"]["suspense"].size] = "mp_suspense_06";
		
		game["dialog"]["mission_success"] = "mission_success";
		game["dialog"]["mission_failure"] = "mission_fail";
		game["dialog"]["mission_draw"] = "draw";

		game["dialog"]["round_success"] = "encourage_win";
		game["dialog"]["round_failure"] = "encourage_lost";
		game["dialog"]["round_draw"] = "draw";
		
		// status
		game["dialog"]["timesup"] = "timesup";
		game["dialog"]["winning"] = "winning";
		game["dialog"]["losing"] = "losing";
		game["dialog"]["lead_lost"] = "lead_lost";
		game["dialog"]["lead_tied"] = "tied";
		game["dialog"]["lead_taken"] = "lead_taken";
		game["dialog"]["last_alive"] = "lastalive";

		game["dialog"]["boost"] = "boost";

		if ( !isDefined( game["dialog"]["offense_obj"] ) )
			game["dialog"]["offense_obj"] = "boost";
		if ( !isDefined( game["dialog"]["defense_obj"] ) )
			game["dialog"]["defense_obj"] = "boost";
		
		game["dialog"]["hardcore"] = "hardcore";
		game["dialog"]["oldschool"] = "oldschool";
		game["dialog"]["highspeed"] = "highspeed";
		game["dialog"]["tactical"] = "tactical";

		game["dialog"]["challenge"] = "challengecomplete";
		game["dialog"]["promotion"] = "promotion";

		game["dialog"]["bomb_taken"] = "bomb_taken";
		game["dialog"]["bomb_lost"] = "bomb_lost";
		game["dialog"]["bomb_defused"] = "bomb_defused";
		game["dialog"]["bomb_planted"] = "bomb_planted";

		game["dialog"]["obj_taken"] = "securedobj";
		game["dialog"]["obj_lost"] = "lostobj";

		game["dialog"]["obj_defend"] = "obj_defend";
		game["dialog"]["obj_destroy"] = "obj_destroy";
		game["dialog"]["obj_capture"] = "capture_obj";
		game["dialog"]["objs_capture"] = "capture_objs";

		game["dialog"]["hq_located"] = "hq_located";
		game["dialog"]["hq_enemy_captured"] = "hq_captured";
		game["dialog"]["hq_enemy_destroyed"] = "hq_destroyed";
		game["dialog"]["hq_secured"] = "hq_secured";
		game["dialog"]["hq_offline"] = "hq_offline";
		game["dialog"]["hq_online"] = "hq_online";

		game["dialog"]["move_to_new"] = "new_positions";

		game["dialog"]["attack"] = "attack";
		game["dialog"]["defend"] = "defend";
		game["dialog"]["offense"] = "offense";
		game["dialog"]["defense"] = "defense";

		game["dialog"]["halftime"] = "halftime";
		game["dialog"]["overtime"] = "overtime";
		game["dialog"]["side_switch"] = "switching";

		game["dialog"]["flag_taken"] = "ourflag";
		game["dialog"]["flag_dropped"] = "ourflag_drop";
		game["dialog"]["flag_returned"] = "ourflag_return";
		game["dialog"]["flag_captured"] = "ourflag_capt";
		game["dialog"]["enemy_flag_taken"] = "enemyflag";
		game["dialog"]["enemy_flag_dropped"] = "enemyflag_drop";
		game["dialog"]["enemy_flag_returned"] = "enemyflag_return";
		game["dialog"]["enemy_flag_captured"] = "enemyflag_capt";

		game["dialog"]["capturing_a"] = "capturing_a";
		game["dialog"]["capturing_b"] = "capturing_b";
		game["dialog"]["capturing_c"] = "capturing_c";
		game["dialog"]["captured_a"] = "capture_a";
		game["dialog"]["captured_b"] = "capture_c";
		game["dialog"]["captured_c"] = "capture_b";

		game["dialog"]["securing_a"] = "securing_a";
		game["dialog"]["securing_b"] = "securing_b";
		game["dialog"]["securing_c"] = "securing_c";
		game["dialog"]["secured_a"] = "secure_a";
		game["dialog"]["secured_b"] = "secure_b";
		game["dialog"]["secured_c"] = "secure_c";

		game["dialog"]["losing_a"] = "losing_a";
		game["dialog"]["losing_b"] = "losing_b";
		game["dialog"]["losing_c"] = "losing_c";
		game["dialog"]["lost_a"] = "lost_a";
		game["dialog"]["lost_b"] = "lost_b";
		game["dialog"]["lost_c"] = "lost_c";

		game["dialog"]["enemy_taking_a"] = "enemy_take_a";
		game["dialog"]["enemy_taking_b"] = "enemy_take_b";
		game["dialog"]["enemy_taking_c"] = "enemy_take_c";
		game["dialog"]["enemy_has_a"] = "enemy_has_a";
		game["dialog"]["enemy_has_b"] = "enemy_has_b";
		game["dialog"]["enemy_has_c"] = "enemy_has_c";

		game["dialog"]["lost_all"] = "take_positions";
		game["dialog"]["secure_all"] = "positions_lock";

		[[level.onPrecacheGameType]]();

		game["gamestarted"] = true;
		
		game["teamScores"]["allies"] = 0;
		game["teamScores"]["axis"] = 0;
	}
	
	if(!isdefined(game["timepassed"]))
		game["timepassed"] = 0;

	if(!isdefined(game["roundsplayed"]))
		game["roundsplayed"] = 0;
	
	level.skipVote = false;
	level.gameEnded = false;
	level.teamSpawnPoints["axis"] = [];
	level.teamSpawnPoints["allies"] = [];

	level.objIDStart = 0;
	level.forcedEnd = false;
	level.hostForcedEnd = false;

	level.hardcoreMode = 0;

	// this gets set to false when someone takes damage or a gametype-specific event happens.
	level.useStartSpawns = true;
	
	// set to 0 to disable
	setdvar("scr_teamKillPunishCount", "0");
	level.minimumAllowedTeamKills = getdvarint("scr_teamKillPunishCount") - 1; // punishment starts at the next one
	
	if( getdvar( "r_reflectionProbeGenerate" ) == "1" )
		level waittill( "eternity" );

	//zombie map development stuff
	//before we load any scripts and waste variables and memory
	//we should make sure that the host does not just want to
	//build navmesh and spawn csv files
	scripts\maparea::init();
	scripts\debug\navmeshtool::init();
	scripts\debug\weaponupgradetool::init();
	thread scripts\debug\weaponindex::init();

	thread maps\mp\gametypes\_rank::init();
	thread maps\mp\gametypes\_menus::init();
	thread maps\mp\gametypes\_hud::init();
	thread maps\mp\gametypes\_serversettings::init();
	thread maps\mp\gametypes\_clientids::init();
	thread maps\mp\gametypes\_teams::init();
	thread maps\mp\gametypes\_weapons::init();
	thread maps\mp\gametypes\_shellshock::init();
	thread maps\mp\gametypes\_deathicons::init();
	thread maps\mp\gametypes\_damagefeedback::init();
	thread maps\mp\gametypes\_healthoverlay::init();
	thread maps\mp\gametypes\_spectating::init();
	thread maps\mp\gametypes\_objpoints::init();
	thread maps\mp\gametypes\_gameobjects::init();
	thread maps\mp\gametypes\_oldschool::deletePickups();
	thread maps\mp\gametypes\_battlechatter_mp::init();
	thread maps\mp\gametypes\_hud_message::init();
	//thread maps\mp\gametypes\_hardpoints::init();

	//thread maps\mp\gametypes\_spawnlogic::init();
	thread scripts\spawnlogic::init();

	stringNames = getArrayKeys( game["strings"] );
	for ( index = 0; index < stringNames.size; index++ )
		precacheString( game["strings"][stringNames[index]] );

	level.maxPlayerCount = 0;
	level.playerCount["allies"] = 0;
	level.playerCount["axis"] = 0;
	level.aliveCount["allies"] = 0;
	level.aliveCount["axis"] = 0;
	level.playerLives["allies"] = 0;
	level.playerLives["axis"] = 0;
	level.lastAliveCount["allies"] = 0;
	level.lastAliveCount["axis"] = 0;
	level.everExisted["allies"] = false;
	level.everExisted["axis"] = false;
	level.waveDelay["allies"] = 0;
	level.waveDelay["axis"] = 0;
	level.lastWave["allies"] = 0;
	level.lastWave["axis"] = 0;
	level.wavePlayerSpawnIndex["allies"] = 0;
	level.wavePlayerSpawnIndex["axis"] = 0;
	level.alivePlayers["allies"] = [];
	level.alivePlayers["axis"] = [];
	level.activePlayers = [];

	//disable early map ends
	level.timeLimit = 0;
	level.scoreLimit = 0;
	level.roundLimit = 0;

	makeDvarServerInfo( "ui_scorelimit" );
	makeDvarServerInfo( "ui_timelimit" );
	makeDvarServerInfo( "ui_allow_classchange", 0 );
	makeDvarServerInfo( "ui_allow_teamchange", 0 );
	
	setdvar( "g_deadChat", 1 );
	
	level.inPrematchPeriod = false;
	level.gracePeriod = 0;
	level.inGracePeriod = false;
	level.roundEndDelay = 5;
	level.halftimeRoundEndDelay = 3;
	
	maps\mp\gametypes\_globallogic::updateTeamScores( "axis", "allies" );
	
	[[level.onStartGameType]]();
	
	//zombie stuff
	//--->
	game["tranzit"] = spawnStruct();

	thread scripts\debug\random_tests::init();
	thread scripts\debug\testclients::init();
	thread scripts\navmesh::init();

	thread scripts\weapons::init();

	thread scripts\airstrike::init();
	thread scripts\ambient::init();
	thread scripts\ammoboxes::init();
	thread scripts\barricades::init();
	thread scripts\battlechatter::init();
	thread scripts\carepackage::init();
	thread scripts\craftables::init();
	thread scripts\generator::init();
	thread scripts\gore::init();
	thread scripts\introscreen::init();
	thread scripts\misterybox::init();
	thread scripts\money::init();
	thread scripts\menus::init();
	thread scripts\monkeybomb::init();
	thread scripts\perks::init();
	thread scripts\packapunch::init();
	thread scripts\power::init();
	thread scripts\rank::init();
	thread scripts\readyup::init();
	thread scripts\revive::init();
	thread scripts\riotshield::init();
	thread scripts\scriptcommands::init();
	thread scripts\scoreboard::init();
	thread scripts\sentrygun::init();
	thread scripts\survivors::init();
	thread scripts\teleporter::init();
	thread scripts\vehicle::init();
	thread scripts\wallweapons::init();
	thread scripts\waves::init();
	thread scripts\weaponfridge::init();
	thread scripts\zombie_drops::init();
	thread scripts\zombies::init();

	level.killcam = false;
	level.teamBalance = 0;
	level.endGameOnTimeLimit = false;
	level.endGameOnScoreLimit = false;
	level.teamLimit = game["tranzit"].zombie_max_ai;
	level.lowerTextFontSize = 1.6; //play a bit with this. default: 2
	//<--- zombie stuff
	
	thread maps\mp\gametypes\_globallogic::startGame();
	
	//we have no round, score or timeLimit, so there is no need to update them
	//level thread maps\mp\gametypes\_globallogic::updateGameTypeDvars();
}

Callback_PlayerConnect()
{
	thread maps\mp\gametypes\_globallogic::notifyConnecting();

	self setRank(0,1); //fake a prestige to hide the rank on scoreboard

	//self.statusicon = "hud_status_connecting";
	self waittill( "begin" );
	waittillframeend;
	self.statusicon = "";

	level notify( "connected", self );
	
	// only print that we connected if we haven't connected in a previous round
	if( !level.splitscreen && !isdefined( self.pers["score"] ) )
	{
		if(!isDefined(self.pers["isBot"]) || !self.pers["isBot"])
			iPrintLn(&"MP_CONNECTED", self);
			
		self thread scripts\rank::calcPlayerRank();
	}

	lpselfnum = self getEntityNumber();
	self.guid = self GetUniquePlayerID();
	
	logPrint("J;" + self.guid + ";" + lpselfnum + ";" + self.name + "\n");

	self setClientDvars( "toggle_tranzit_scoreboard", "0",
						 "cg_drawSpectatorMessages", 1,
						 "ui_hud_hardcore", getDvar( "ui_hud_hardcore" ),
						 "player_sprintTime", getDvar( "scr_player_sprinttime" ),
						 "ui_uav_client", getDvar( "ui_uav_client" ) );

	self setClientDvars( "cg_drawCrosshair", 1,
						 "cg_drawCrosshairNames", 0,
						 "cg_scoreboardRankFontScale", 0,
						 "cg_overheadIconSize", 0,
						 "cg_overheadRankSize", 0);

	self setClientDvars("cg_hudGrenadeIconHeight", "25", 
						"cg_hudGrenadeIconWidth", "25", 
						"cg_hudGrenadeIconOffset", "50", 
						"cg_hudGrenadePointerHeight", "12", 
						"cg_hudGrenadePointerWidth", "25", 
						"cg_hudGrenadePointerPivot", "12 27", 
						"cg_hudGrenadeIconMaxRangeFrag", 0,
						"cg_fovscale", "1");
	
	self maps\mp\gametypes\_globallogic::initPersStat( "score" );
	self maps\mp\gametypes\_globallogic::initPersStat( "deaths" );
	self maps\mp\gametypes\_globallogic::initPersStat( "suicides" );
	self maps\mp\gametypes\_globallogic::initPersStat( "kills" );
	self maps\mp\gametypes\_globallogic::initPersStat( "headshots" );
	self maps\mp\gametypes\_globallogic::initPersStat( "assists" );
	self maps\mp\gametypes\_globallogic::initPersStat( "teamkills" );

	self.score = self.pers["score"];
	self.deaths = self maps\mp\gametypes\_globallogic::getPersStat( "deaths" );
	self.suicides = self maps\mp\gametypes\_globallogic::getPersStat( "suicides" );
	self.kills = self maps\mp\gametypes\_globallogic::getPersStat( "kills" );
	self.headshots = self maps\mp\gametypes\_globallogic::getPersStat( "headshots" );
	self.assists = self maps\mp\gametypes\_globallogic::getPersStat( "assists" );
	
	self.teamKillPunish = false;
	
	if( getdvar( "r_reflectionProbeGenerate" ) == "1" )
		level waittill( "eternity" );

	self.killedPlayers = [];
	self.killedPlayersCurrent = [];
	self.killedBy = [];
	
	self.leaderDialogQueue = [];
	self.leaderDialogActive = false;
	self.leaderDialogGroups = [];
	self.leaderDialogGroup = "";

	self.cur_kill_streak = 0;
	self.cur_death_streak = 0;
	self.death_streak = self maps\mp\gametypes\_persistence::statGet( "death_streak" );
	self.kill_streak = self maps\mp\gametypes\_persistence::statGet( "kill_streak" );
	self.lastGrenadeSuicideTime = -1;

	self.teamkillsThisRound = 0;
	
	self.pers["lives"] = level.numLives;
	self.pers["downs"] = 0;
	self.pers["revives"] = 0;
	
	self setStat(2401, 0); //self.pers["kills"]
	self setStat(2402, 0); //self.pers["downs"]
	self setStat(2403, 0); //self.pers["revives"]
	self setStat(2404, 0); //self.pers["headshots"]
	
	self.hasSpawned = false;
	self.waitingToSpawn = false;
	self.deathCount = 0;

	self.afkWaves = 0;
	self.isReady = false;
	self.zombiePerks = [];
	self.zombiePerksDisabled = [];
	self.waitingToRespawn = false;
	self.wasAliveAtMatchStart = false;
	
	self thread scripts\scriptcommands::resetPlayerSettings();
	
	self setClientDvars("r_filmTweakInvert", 0,
						"r_filmTweakBrightness", 0,
						"r_filmtweakLighttint", "0.8 0.8 1",
						"r_filmTweakContrast", 1.2,
						"r_filmTweakDesaturation", 0,
						"r_filmTweakDarkTint", "1.8 1.8 2",
						"r_filmTweakenable", 1,
						"r_filmusetweaks", 1);
	
	self thread maps\mp\_flashgrenades::monitorFlash();
	
	self setClientDvars("cg_deadChatWithDead", 0,
							"cg_deadChatWithTeam", 1,
							"cg_deadHearTeamLiving", 1,
							"cg_deadHearAllLiving", 0,
							"cg_everyoneHearsEveryone", 0 );
	
	level.players[level.players.size] = self;
	
	if ( level.teambased )
		self updateScores();
	
	// When joining a game in progress, if the game is at the post game state (scoreboard) the connecting player should spawn into intermission
	if ( game["state"] == "postgame" )
	{
		self.pers["team"] = "spectator";
		self.team = "spectator";

		self setClientDvars( "ui_hud_hardcore", 1,
							   "cg_drawSpectatorMessages", 0 );
		
		[[level.spawnIntermission]]();
		self closeMenu();
		self closeInGameMenu();
		return;
	}

	maps\mp\gametypes\_globallogic::updateLossStats( self );

	level endon( "game_ended" );

	if ( isDefined( self.pers["team"] ) )
		self.team = self.pers["team"];

	if ( isDefined( self.pers["class"] ) )
		self.class = self.pers["class"];
	
	if ( !isDefined( self.pers["team"] ) )
	{
		// Don't set .sessionteam until we've gotten the assigned team from code,
		// because it overrides the assigned team.
		self.pers["team"] = "spectator";
		self.team = "spectator";
		self.sessionstate = "dead";
		
		//self updateObjectiveText();
		
		[[level.spawnSpectator]]();
		
		self setclientdvar( "g_scriptMainMenu", game["menu_team"] );
		self openMenu( game["menu_team"] );
		
		if ( self.pers["team"] == "spectator" )
			self.sessionteam = "spectator";
		
		if ( level.teamBased )
		{
			// set team and spectate permissions so the map shows waypoint info on connect
			self.sessionteam = self.pers["team"];
			if ( !isAlive( self ) )
				self.statusicon = "hud_status_dead";
			self thread maps\mp\gametypes\_spectating::setSpectatePermissions();
		}
	}
	else if ( self.pers["team"] == "spectator" )
	{
		self setclientdvar( "g_scriptMainMenu", game["menu_team"] );
		self.sessionteam = "spectator";
		self.sessionstate = "spectator";
		[[level.spawnSpectator]]();
	}
	else
	{
		self.sessionteam = self.pers["team"];
		self.sessionstate = "dead";
		
		//self updateObjectiveText();
		
		[[level.spawnSpectator]]();
		
		self thread [[level.spawnClient]]();					
		self thread maps\mp\gametypes\_spectating::setSpectatePermissions();
	}
	
	if ( isDefined( self.pers["isBot"] ) )
		return;
		
	self.pers["language"] = getPlayerLanguage();
		
	for( i=0; i<5; i++ )
	{
		if( !level.onlinegame )
			return;
			
		if( self getstat( 205+(i*10) ) == 0 )
		{
			kick( self getentitynumber() );
			return;
		}
	}
}

onPlayerDisconnect()
{
	if(isDefined(self.actionSlotItem))
		thread scripts\craftables::reactivateCraftedWeaponPickup(self.actionSlotItem);
		
	level thread maps\mp\gametypes\_globallogic::updateTeamStatus();
}

//basically a copy from _globallogic - but removed all the crap we don't need
onPlayerDamage(eInflictor, eAttacker, iDamage, iDFlags, sMeansOfDeath, sWeapon, vPoint, vDir, sHitLoc, psOffsetTime)
{
	// create a class specialty checks; CAC:bulletdamage, CAC:armorvest
	iDamage = maps\mp\gametypes\_class::cac_modified_damage(self, eAttacker, iDamage, sMeansOfDeath);
	self.iDFlags = iDFlags;
	self.iDFlagsTime = getTime();
	
	if(isDefined(self.godmode) && self.godmode)
		return;
		
	if(game["tranzit"].wave == 0)
		return;
	
	if(game["state"] == "postgame")
		return;
	
	if(self.sessionteam == "spectator")
		return;
	
	if(isDefined(self.canDoCombat) && !self.canDoCombat)
	{
		if(game["tranzit"].wave >= 1)
			self.canDoCombat = true;
		else
			return;
	}
	
	if(isDefined(eAttacker) && isPlayer(eAttacker) && isDefined(eAttacker.canDoCombat) && !eAttacker.canDoCombat)
		return;
	
	usingRiotShield = false;
	if(isPlayer(eAttacker))
	{
		if(self getCurrentWeapon() == getWeaponFromCustomName("riotshield"))
			usingRiotShield = true;
		
		if(eAttacker != self && usingRiotShield)
		{
			if(self scripts\riotshield::attackerIsDamagingRiotShield(eInflictor, eAttacker, vPoint, vDir, sMeansOfDeath))
			{
				if(self.riotShieldHealth <= 0)
					return;
			
				self.riotShieldHealth -= int(iDamage / 3);
					
				if(self.riotShieldHealth > 0)
					return;
					
				iDamage = abs(int(self.riotShieldHealth));
				
				self takeCurrentWeapon();
			}
		}
	}

	if(self isAZombie())
	{
		//doubled damage for breast shots with a bolt sniper
		if(isSubStr(sHitLoc, "torso") && scripts\weapons::isSniper(sWeapon))
			iDamage *= 2;

		if(isDefined(sMeansOfDeath))
		{
			if(sMeansOfDeath == "MOD_MELEE")
			{
				switch(self.zombieType)
				{
					case "avagadro":
					case "dwarf":
						break;
					
					default:
					{
						if(game["tranzit"].wave <= 1)
							iDamage = self.health;
						else
							iDamage = int(self.maxhealth / game["tranzit"].wave) + 1;

						break;
					}
				}

				if(sWeapon == getWeaponFromCustomName("knife"))
					iDamage *= 3;
				else if(sWeapon == getWeaponFromCustomName("katana"))
					iDamage = int(iDamage * 5.5);
			}
			else if(isSubStr(sMeansOfDeath, "BULLET"))
			{
				if(self.zombieType == "avagadro")
					iDamage = int(iDamage / 2);
			}
			else
			{
				//increase the damage of a grenade or projectile
				if((isSubStr(sMeansOfDeath, "MOD_GRENADE") || isSubStr(sMeansOfDeath, "MOD_EXPLOSIVE") || isSubStr(sMeansOfDeath, "MOD_PROJECTILE")) && isDefined(eInflictor))
					iDamage *= int(self.maxhealth * 1/4);
			}
		}
	}

	prof_begin("Callback_PlayerDamage flags/tweaks");
	
	// Don't do knockback if the damage direction was not specified
	if(!isDefined(vDir))
		iDFlags |= level.iDFLAGS_NO_KNOCKBACK;

	if ( (level.teamBased && (self.health == self.maxhealth)) || !isDefined( self.attackers ) )
	{
		self.attackers = [];
		self.attackerData = [];
	}
	
	if(isHeadShot(sWeapon, sHitLoc, sMeansOfDeath))
		sMeansOfDeath = "MOD_HEAD_SHOT";
	
	// explosive barrel/car detection
	sWeapon = isExplosiveObjectInflictor(eInflictor, sWeapon);

	prof_end("Callback_PlayerDamage flags/tweaks");

	// check for completely getting out of the damage
	if(!(iDFlags & level.iDFLAGS_NO_PROTECTION))
	{
		if(isExplosiveDamage(sMeansOfDeath) && isDefined(eInflictor))
		{
			self.explosiveInfo = [];
			self.explosiveInfo["damageTime"] = getTime();
			self.explosiveInfo["damageId"] = eInflictor getEntityNumber();
			self.explosiveInfo["returnToSender"] = false;
			self.explosiveInfo["counterKill"] = false;
			self.explosiveInfo["chainKill"] = false;
			self.explosiveInfo["cookedKill"] = false;
			self.explosiveInfo["throwbackKill"] = false;
			self.explosiveInfo["weapon"] = sWeapon;
			
			isFrag = isSubStr(sWeapon, "frag_");

			if(eAttacker != self)
			{
				if((isSubStr(sWeapon, "c4_") || isSubStr(sWeapon, "claymore_")) && isDefined(eAttacker) && isDefined(eInflictor.owner))
				{
					self.explosiveInfo["returnToSender"] = (eInflictor.owner == self);
					self.explosiveInfo["counterKill"] = isDefined(eInflictor.wasDamaged);
					self.explosiveInfo["chainKill"] = isDefined(eInflictor.wasChained);
					self.explosiveInfo["bulletPenetrationKill"] = isDefined(eInflictor.wasDamagedFromBulletPenetration);
					self.explosiveInfo["cookedKill"] = false;
				}

				self.explosiveInfo["suicideGrenadeKill"] = false;
				if(isDefined(eAttacker.lastGrenadeSuicideTime) && eAttacker.lastGrenadeSuicideTime >= gettime() - 50 && isFrag)
					self.explosiveInfo["suicideGrenadeKill"] = true;
			}
			
			if(isFrag)
			{
				self.explosiveInfo["cookedKill"] = isDefined(eInflictor.isCooked);
				self.explosiveInfo["throwbackKill"] = isDefined(eInflictor.threwBack);
			}
		}

		if(isPlayer(eAttacker))
			eAttacker.pers["participation"]++;
		
		// return if friendly fire
		if(level.teamBased && isPlayer(eAttacker) && (self != eAttacker) && (self.pers["team"] == eAttacker.pers["team"]))
		{
			prof_begin("Callback_PlayerDamage player");

			//do sth cool
			
			prof_end("Callback_PlayerDamage player");
			
			return;
		}
		else
		{
			prof_begin("Callback_PlayerDamage world");
			
			if(isdefined(eAttacker) && isPlayer(eAttacker) && eAttacker == self)
				return;
			
			// Make sure at least one point of damage is done
			if(iDamage < 1)
				iDamage = 1;

			if(isDefined(eAttacker) && isPlayer(eAttacker) && eAttacker != self)
			{
				if(eAttacker isAZombie())
					iDamage = eAttacker.damagePoints;
				else
				{
					eAttacker thread [[level.onXPEvent]]("damage");
			
					if(game["powerup_instakill"])
					{
						if(self.zombieType != "avagadro")
							iDamage = self.health;
					}
				}
			}

			if(isdefined(eAttacker) && isPlayer(eAttacker) && isDefined(sWeapon))
				eAttacker maps\mp\gametypes\_weapons::checkHit(sWeapon);

			if ( level.teamBased && isDefined( eAttacker ) && isPlayer( eAttacker ) )
			{
				if ( !isdefined( self.attackerData[eAttacker.clientid] ) )
				{
					self.attackers[ self.attackers.size ] = eAttacker;
					// we keep an array of attackers by their client ID so we can easily tell
					// if they're already one of the existing attackers in the above if().
					// we store in this array data that is useful for other things, like challenges
					self.attackerData[eAttacker.clientid] = false;
				}

				self.attackerData[eAttacker.clientid] = true;
			}

			//no idea what this is for - maybe for the challenges (VIKING)
			self.wasCooked = undefined;
			if(issubstr(sMeansOfDeath, "MOD_GRENADE") && isDefined(eInflictor.isCooked))
				self.wasCooked = getTime();
			
			self maps\mp\gametypes\_globallogic::finishPlayerDamageWrapper(eInflictor, eAttacker, iDamage, iDFlags, sMeansOfDeath, sWeapon, vPoint, vDir, sHitLoc, psOffsetTime);

			if(self isAZombie())
				self thread scripts\gore::onZombieDamaged(sWeapon, sMeansOfDeath, sHitLoc, vPoint, eAttacker, eInflictor);
			else if(self isASurvivor())
				self thread scripts\gore::onSurvivorDamaged(sWeapon, sMeansOfDeath, sHitLoc, vPoint, eAttacker, eInflictor);

			prof_end("Callback_PlayerDamage world");
		}

		self.hasDoneCombat = true;

		if(isdefined(eAttacker) && eAttacker != self)
		{
			hasBodyArmor = false;
			if(self scripts\perks::hasZombiePerk("specialty_armorvest"))
				hasBodyArmor = true;

			if(iDamage > 0)
				eAttacker thread maps\mp\gametypes\_damagefeedback::updateDamageFeedback(hasBodyArmor);
		}
	}

	if(isdefined(eAttacker) && eAttacker != self)
		level.useStartSpawns = false;

	prof_begin("Callback_PlayerDamage log");

	if(self.sessionstate != "dead")
	{
		lpselfnum = self getEntityNumber();
		lpselfname = self.name;
		lpselfteam = self.pers["team"];
		lpselfGuid = self getGuid();
		lpattackerteam = "";

		if(isPlayer(eAttacker))
		{
			lpattacknum = eAttacker getEntityNumber();
			lpattackGuid = eAttacker getGuid();
			lpattackname = eAttacker.name;
			lpattackerteam = eAttacker.pers["team"];
		}
		else
		{
			lpattacknum = -1;
			lpattackGuid = "";
			lpattackname = "";
			lpattackerteam = "world";
		}

		logPrint("D;" + lpselfGuid + ";" + lpselfnum + ";" + lpselfteam + ";" + lpselfname + ";" + lpattackGuid + ";" + lpattacknum + ";" + lpattackerteam + ";" + lpattackname + ";" + sWeapon + ";" + iDamage + ";" + sMeansOfDeath + ";" + sHitLoc + "\n");
	}
	
	prof_end("Callback_PlayerDamage log");
}

onPlayerLastStand(eInflictor, attacker, iDamage, sMeansOfDeath, sWeapon, vDir, sHitLoc, psOffsetTime, deathAnimDuration)
{
	self thread scripts\revive::putInLastStand(eInflictor, attacker, iDamage, sMeansOfDeath, sWeapon, vDir, sHitLoc, psOffsetTime, deathAnimDuration);
	
	if(isDefined(self.actionSlotItem))
	{
		thread scripts\craftables::reactivateCraftedWeaponPickup(self.actionSlotItem);
		self takeActionSlotWeapon("craftable");
	}
}

Callback_PlayerKilled(eInflictor, attacker, iDamage, sMeansOfDeath, sWeapon, vDir, sHitLoc, psOffsetTime, deathAnimDuration)
{
	self endon("spawned");
	self notify("killed_player");

	if(self.sessionteam == "spectator")
		return;
	
	if(game["state"] == "postgame")
		return;
	
	prof_begin("PlayerKilled pre constants");
	
	deathTimeOffset = 0;
	if(isdefined(self.useLastStandParams))
	{
		self.useLastStandParams = undefined;
		
		assert(isdefined(self.lastStandParams));
		
		eInflictor = self.lastStandParams.eInflictor;
		attacker = self.lastStandParams.attacker;
		iDamage = self.lastStandParams.iDamage;
		sMeansOfDeath = self.lastStandParams.sMeansOfDeath;
		sWeapon = self.lastStandParams.sWeapon;
		vDir = self.lastStandParams.vDir;
		sHitLoc = self.lastStandParams.sHitLoc;
		
		deathTimeOffset = (gettime() - self.lastStandParams.lastStandStartTime) / 1000;
		
		self.lastStandParams = undefined;
	}

	sMeansOfDeathOld = "";
	if(isHeadShot(sWeapon, sHitLoc, sMeansOfDeath))
	{
		sMeansOfDeath = "MOD_HEAD_SHOT";
		
		if(isDefined(sWeapon))
		{
			switch(WeaponClass(sWeapon))
			{
				case "mg":
				case "rifle":
				case "spread":
					sMeansOfDeathOld = "MOD_RIFLE_BULLET";
					break;
			
				case "pistol":
				case "smg":
				default: break;
			}
		}
	}
	
	if(attacker.classname == "script_vehicle" && isDefined(attacker.owner))
		attacker = attacker.owner;

	if(getDvarInt("developer") > 0)
	{
		// send out an obituary message to all clients about the kill
		if(level.teamBased && isDefined(attacker.pers) && self.team == attacker.team && sMeansOfDeath == "MOD_GRENADE" && level.friendlyfire == 0)
			obituary(self, self, sWeapon, sMeansOfDeath);
		else
			obituary(self, attacker, sWeapon, sMeansOfDeath);
	}

	riotDeathModel = undefined;
	if(self getCurrentWeapon() == getWeaponFromCustomName("riotshield"))
	{
		if(self hasAttached("worldmodel_riot_shield_iw5"))
		{
			self detach("worldmodel_riot_shield_iw5", "tag_weapon_left");
	
			riotDeathModel = spawn("script_model", self getTagOrigin("tag_weapon_left"));
			riotDeathModel.angles = self getTagAngles("tag_weapon_left");
			riotDeathModel setModel("worldmodel_riot_shield_iw5");
			riotDeathModel PhysicsLaunch();
		}
	}
	
	self.sessionstate = "dead";
	self.statusicon = "hud_status_dead";

	self.pers["weapon"] = undefined;
	
	self.killedPlayersCurrent = [];
	
	self.deathCount++;

	if(!isDefined(self.switching_teams))
	{
		self maps\mp\gametypes\_globallogic::incPersStat("deaths", 1);
		self.deaths = self.pers["deaths"];	
		self maps\mp\gametypes\_globallogic::updatePersRatio("kdratio", "kills", "deaths");
			
		self.cur_kill_streak = 0;
		self.cur_death_streak++;
			
		if(self.cur_death_streak > self.death_streak)
		{
			self maps\mp\gametypes\_persistence::statSet("death_streak", self.cur_death_streak);
			self.death_streak = self.cur_death_streak;
		}
	}
	
	lpselfnum = self getEntityNumber();
	lpselfname = self.name;
	lpattackGuid = "";
	lpattackname = "";
	lpselfteam = "";
	lpselfguid = self getGuid();
	lpattackerteam = "";
	lpattacknum = -1;

	prof_end("PlayerKilled pre constants");

	if(isPlayer(attacker))
	{
		lpattackGuid = attacker getGuid();
		lpattackname = attacker.name;

		if(attacker == self) // killed himself
		{
			// switching teams
			if(!isDefined(self.switching_teams))
			{
				self maps\mp\gametypes\_globallogic::incPersStat("suicides", 1);
				self.suicides = self .pers["suicides"];
				self thread [[level.onXPEvent]]("suicide");

				if(sMeansOfDeath == "MOD_SUICIDE" && sHitLoc == "none" && self.throwingGrenade)
					self.lastGrenadeSuicideTime = gettime();
			}
		}
		else
		{
			prof_begin("PlayerKilled attacker");

			lpattacknum = attacker getEntityNumber();

			prof_begin("pks1");

			if(sMeansOfDeath == "MOD_MELEE")
				attacker thread [[level.onXPEvent]]("melee");
			else if(sMeansOfDeath == "MOD_HEAD_SHOT")
			{
				attacker maps\mp\gametypes\_globallogic::incPersStat("headshots", 1);
				attacker setStat(2404, attacker.pers["headshots"]);
				attacker.headshots = attacker.pers["headshots"];

				attacker thread [[level.onXPEvent]]("headshot");
			}

			attacker maps\mp\gametypes\_globallogic::incPersStat("kills", 1);
			attacker setStat(2401, attacker.pers["kills"]);
			attacker.kills = attacker.pers["kills"];
			attacker maps\mp\gametypes\_globallogic::updatePersRatio("kdratio", "kills", "deaths");
			attacker thread [[level.onXPEvent]]("kill");

			if(isAlive(attacker))
			{
				if(!isDefined(eInflictor) || !isDefined(eInflictor.requiredDeathCount) || attacker.deathCount == eInflictor.requiredDeathCount)
					attacker.cur_kill_streak++;
			}
			
			attacker.cur_death_streak = 0;
			
			if(attacker.cur_kill_streak > attacker.kill_streak)
			{
				attacker maps\mp\gametypes\_persistence::statSet("kill_streak", attacker.cur_kill_streak);
				attacker.kill_streak = attacker.cur_kill_streak;
			}

			// to prevent spectator gain score for team-spectator after throwing a granade and killing someone before he switched
			if(level.teamBased && attacker.pers["team"] != "spectator")
				maps\mp\gametypes\_globallogic::giveTeamScore("kill", attacker.pers["team"],  attacker, self);

			//no idea what this is doing - can't remember the game is playing a sound when i killed someone
			level thread maps\mp\gametypes\_battlechatter_mp::sayLocalSoundDelayed(attacker, "kill", 0.75);

			prof_end("pks1");
			
			if(level.teamBased)
			{
				prof_begin("PlayerKilled assists");

				if(isdefined(self.attackers))
				{
					/* maybe we need the assist in future
					for(j = 0; j < self.attackers.size; j++)
					{
						player = self.attackers[j];
						
						if(!isDefined(player))
							continue;
						
						if(player == attacker)
							continue;
						
						player thread processAssist(self);
					}*/

					self.attackers = [];
				}
				
				prof_end("PlayerKilled assists");
			}
			
			prof_end("PlayerKilled attacker");
		}
	}
	else
	{
		killedByEnemy = false;

		lpattacknum = -1;
		lpattackguid = "";
		lpattackname = "";
		lpattackerteam = "world";

		// even if the attacker isn't a player, it might be on a team
		if(isDefined(attacker) && isDefined(attacker.team) && (attacker.team == "axis" || attacker.team == "allies"))
		{
			if(attacker.team != self.pers["team"]) 
			{
				killedByEnemy = true;
				if(level.teamBased)
					maps\mp\gametypes\_globallogic::giveTeamScore("kill", attacker.team, attacker, self);
			}
		}
	}			
			
	prof_begin("PlayerKilled post constants");

	logPrint("K;" + lpselfguid + ";" + lpselfnum + ";" + lpselfteam + ";" + lpselfname + ";" + lpattackguid + ";" + lpattacknum + ";" + lpattackerteam + ";" + lpattackname + ";" + sWeapon + ";" + iDamage + ";" + sMeansOfDeath + ";" + sHitLoc + "\n");

	attackerString = "none";
	if(isPlayer(attacker)) // attacker can be the worldspawn if it's not a player
		attackerString = attacker getXuid() + "(" + lpattackname + ")";
	self logstring("d " + sMeansOfDeath + "(" + sWeapon + ") a:" + attackerString + " d:" + iDamage + " l:" + sHitLoc + " @ " + int(self.origin[0]) + " " + int(self.origin[1]) + " " + int(self.origin[2]));

	level thread maps\mp\gametypes\_globallogic::updateTeamStatus();

	self maps\mp\gametypes\_gameobjects::detachUseModels(); // want them detached before we create our corpse
	
	self.switching_teams = undefined;
	self.joining_team = undefined;
	self.leaving_team = undefined;

	self thread [[level.onPlayerKilled]](eInflictor, attacker, iDamage, sMeansOfDeath, sMeansOfDeathOld, sWeapon, vDir, sHitLoc, psOffsetTime, deathAnimDuration);
	self thread scripts\gore::spawnCorpse(eInflictor, attacker, iDamage, sMeansOfDeath, sMeansOfDeathOld, sWeapon, vDir, sHitLoc, psOffsetTime, deathAnimDuration);
	
	self.deathTime = getTime();
	
	// let the player watch themselves die
	wait(0.25);
	self.cancelKillcam = true;
	self notify("death_delay_finished");
	
	if(game["state"] != "playing")
		return;
	
	respawnTimerStartTime = gettime();
	
	prof_end("PlayerKilled post constants");
	
	if(game["state"] != "playing")
	{
		self.sessionstate = "dead";
		self.spectatorclient = -1;
		self.killcamentity = -1;
		self.archivetime = 0;
		self.psoffsettime = 0;
		return;
	}
	
	timePassed = (gettime() - respawnTimerStartTime) / 1000;
	self thread [[level.spawnClient]](timePassed);
}

//this is used to do some extra stuff
onPlayerKilled(eInflictor, attacker, iDamage, sMeansOfDeath, sMeansOfDeathOld, sWeapon, vDir, sHitLoc, psOffsetTime, deathAnimDuration)
{
	if(self isASurvivor())
	{
		if(isDefined(self.actionSlotItem))
			thread scripts\craftables::reactivateCraftedWeaponPickup(self.actionSlotItem);
			
		if(isDefined(self.minigun_huds))
			self thread scripts\weapons::removeMinigunHud();
			
		self scripts\perks::clearZombiePerks();
		return;
	}

	if(self isAZombie())
	{
		if(self.zombieType == "dwarf")
			level.dwarfsLeft--;
		else
		{
			level.zombiesLeftInWave--;
			
			if(self.zombieType == "human")
				self thread scripts\zombie_drops::dropZombiePowerUp();
		}
	
		self thread scripts\gore::onZombieKilled(attacker, sMeansOfDeath, sMeansOfDeathOld);

		wait 4;
		if(isDefined(self.myTarget))
		{
			if(isDefined(self.myTarget.underDwarfAttack) && self.myTarget.underDwarfAttack)
			{
				self.myTarget.underDwarfAttack = false;
			}
		}

		return;
	}
}

onOneLeftEvent(team)
{
	if(team == game["attackers"])
	{
		if(level.zombiesSpawned < level.zombiesTotalForWave)
			return;
	
		for(i=0;i<level.players.size;i++)
		{
			if(isDefined(level.players[i].pers["team"]) && level.players[i].pers["team"] == game["attackers"])
			{
				if(isAlive(level.players[i]))
				{
					if(level.players[i].zombieType == "avagadro")
						thread scripts\waves::endWave();
				}
			}
		}
	}
	else
	{
		for(i=0;i<level.players.size;i++)
		{
			if(isDefined(level.players[i].pers["team"]) && level.players[i].pers["team"] == game["defenders"] && isDefined(level.players[i].pers["class"]))
			{
				if(level.players[i].sessionstate == "playing" && !level.players[i].afk)
					break;
			}
		}
		
		if(i == level.players.size)
			return;
		
		level.players[i] thread scripts\announcer::warnLastPlayer();
	}
}

onDeadEvent(team)
{
	if(game["tranzit"].wave <= 0)
		return;
	
	if(team == game["attackers"])
	{
		thread scripts\waves::endWave();
		return;
	}

	logPrint("\ngame end callback - all dead\n");
	thread scripts\waves::endGame();
}

onForfeit(team)
{
	level notify("forfeit in progress"); //ends all other forfeit threads attempting to run
	level endon("forfeit in progress");	//end if another forfeit thread is running
	level endon("abort forfeit");			//end if the team is no longer in forfeit status
	
	//don't end if the zombies forfeit
	if(team == game["attackers"])
		return;
	
	//do not wait if there is no spectator who could join
	if(level.players.size > 0 && (level.players.size - level.playerCount["axis"] - level.playerCount["axis"]) > 0)
	{
		forfeit_delay = 20.0;
		announcement(game["strings"]["opponent_forfeiting_in"], forfeit_delay);
		wait (10.0);
		announcement(game["strings"]["opponent_forfeiting_in"], 10.0);
		wait (10.0);
	}
	
	//if we really end the game then let the zombies win
	//otherwise it wont go here anyways
	setDvar("ui_text_endreason", game["strings"]["allies_forfeited"]);
	endReason = game["strings"]["allies_forfeited"];
	winner = "axis";
	
	//exit game, last round, no matter if round limit reached or not
	level.forcedEnd = true;
	
	logString("forfeit, win: " + winner + ", allies: " + game["teamScores"]["allies"] + ", opfor: " + game["teamScores"]["axis"]);
	
	logPrint("\ngame end callback - human forfeit\n");
	thread scripts\waves::endGame();
}