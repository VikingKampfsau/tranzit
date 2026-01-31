#include common_scripts\utility;
#include scripts\_include;

#using_animtree("multiplayer");
init()
{
	game["debug"] = [];
	game["debug"]["status"] = true;

	initDebugVar("vehicle_draw_loadingarea", false);
	initDebugVar("vehicle_draw_mantlespots", false);
	initDebugVar("playerAwakening", false);
	initDebugVar("playerDamaged", false);
	initDebugVar("playerRank", false);
	initDebugVar("playerValueHud", true);
	initDebugVar("globalValueHud", false);
	initDebugVar("riotshield_damageArea", false);
	initDebugVar("barricades_noDoors", true);
	initDebugVar("barricades_noPlanks", true);
	initDebugVar("barricades_noBlockers", true);
	initDebugVar("noFog", true);
	initDebugVar("climbSpotShow", true);
	initDebugVar("startZombieSurvival", true);

	if(!game["debug"]["status"])
		return;
	
	wait 5;

	while(!isDefined(level.players) || level.players.size < 1)
		wait 1;
		
	while(level.aliveCount["allies"] <= 0 && !game["tranzit"].playersReady)
		wait 1;

	wait 1;
	
	iPrintLnBold("[DEBUG MODE] calling test functions\n");
	consolePrint("[DEBUG MODE] calling test functions\n");
}