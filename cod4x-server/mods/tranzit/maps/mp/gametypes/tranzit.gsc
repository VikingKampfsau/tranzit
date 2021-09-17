#include maps\mp\_utility;
#include maps\mp\gametypes\_hud_util;

main()
{
	if(getdvar("mapname") == "mp_background")
		return;
	
	maps\mp\gametypes\_globallogic::init();
	maps\mp\gametypes\_callbacksetup::SetupCallbacks();
	maps\mp\gametypes\_globallogic::SetupCallbacks();
	
	maps\mp\gametypes\_globallogic::registerRoundSwitchDvar( level.gameType, 0, 0, 0 );
	maps\mp\gametypes\_globallogic::registerTimeLimitDvar( level.gameType, 0, 0, 0 );
	maps\mp\gametypes\_globallogic::registerScoreLimitDvar( level.gameType, 0, 0, 0 );
	maps\mp\gametypes\_globallogic::registerRoundLimitDvar( level.gameType, 0, 0, 0 );
	maps\mp\gametypes\_globallogic::registerNumLivesDvar( level.gameType, 1, 1, 1 );
	
	level.teamBased = true;
	level.onStartGameType = ::onStartGameType;
	
	level.spawnPlayer = scripts\spawnlogic::spawnPlayer;
	level.onSpawnPlayer = scripts\spawnlogic::doPlayerSpawning;
	level.spawnClient = scripts\spawnlogic::spawnClient;
	level.onPrecacheGameType = scripts\precache::init;
	level.onDeadEvent = scripts\callbacks::onDeadEvent;
	level.onOneLeftEvent = scripts\callbacks::onOneLeftEvent;
	level.onPlayerDisconnect = scripts\callbacks::onPlayerDisconnect;
	level.onPlayerKilled = scripts\callbacks::onPlayerKilled;
	level.callbackPlayerDamage = scripts\callbacks::onPlayerDamage;
	level.callbackPlayerKilled = scripts\callbacks::Callback_PlayerKilled;
	level.callbackPlayerLastStand = scripts\callbacks::onPlayerLastStand;
	level.callbackPlayerConnect = scripts\callbacks::Callback_PlayerConnect;
	level.callbackStartGameType = scripts\callbacks::Callback_StartGameType;
	level.onForfeit = scripts\callbacks::onForfeit;
	level.onXPEvent = scripts\money::onMoneyEvent;
	
	
	level.class = maps\mp\gametypes\_globallogic::blank;
	level.onTimeLimit = maps\mp\gametypes\_globallogic::blank;
	level.onScoreLimit = maps\mp\gametypes\_globallogic::blank;
	level.onTeamScore = maps\mp\gametypes\_globallogic::blank;
}

onStartGameType()
{
	game["attackers"] = "axis";
	game["defenders"] = "allies";
	
	setClientNameMode("auto_change");
	
	game["objectiveText_attackers"] = &"";
	game["objectiveText_defenders"] = &"";
	
	maps\mp\gametypes\_globallogic::setObjectiveText(game["attackers"], game["objectiveText_attackers"]);
	maps\mp\gametypes\_globallogic::setObjectiveText(game["defenders"], game["objectiveText_defenders"]);

	if ( level.splitscreen )
	{
		maps\mp\gametypes\_globallogic::setObjectiveScoreText( game["attackers"], game["objectiveText_attackers"]);
		maps\mp\gametypes\_globallogic::setObjectiveScoreText( game["defenders"], game["objectiveText_defenders"]);
	}
	else
	{
		maps\mp\gametypes\_globallogic::setObjectiveScoreText( game["attackers"], game["objectiveText_attackers"]);
		maps\mp\gametypes\_globallogic::setObjectiveScoreText( game["defenders"], game["objectiveText_defenders"]);
	}
	maps\mp\gametypes\_globallogic::setObjectiveHintText( game["attackers"], game["objectiveText_attackers"]);
	maps\mp\gametypes\_globallogic::setObjectiveHintText( game["defenders"], game["objectiveText_defenders"]);

	level.spawnMins = ( 0, 0, 0 );
	level.spawnMaxs = ( 0, 0, 0 );	
	maps\mp\gametypes\_spawnlogic::placeSpawnPoints( "mp_tdm_spawn_allies_start" );
	maps\mp\gametypes\_spawnlogic::placeSpawnPoints( "mp_tdm_spawn_axis_start" );
	
	//maps\mp\gametypes\_spawnlogic::addSpawnPoints( game["defenders"], "mp_tdm_spawn" );
	//maps\mp\gametypes\_spawnlogic::addSpawnPoints( game["attackers"], "mp_dm_spawn" );
	scripts\spawnlogic::initCharacterSpawns();
	
	level.mapCenter = scripts\spawnlogic::findBoxCenter( level.spawnMins, level.spawnMaxs );
	setMapCenter( level.mapCenter );
	
	allowed[0] = "war";
	allowed[1] = "dm";
	maps\mp\gametypes\_gameobjects::main(allowed);
	
	maps\mp\gametypes\_rank::registerScoreInfo( "kill", 5 );
	maps\mp\gametypes\_rank::registerScoreInfo( "headshot", 5 );
	maps\mp\gametypes\_rank::registerScoreInfo( "assist", 2 );
}