#include common_scripts\utility;
#include scripts\_include;

#using_animtree("multiplayer");
init()
{
	game["debug"] = [];
	game["debug"]["status"] = false;

	initDebugVar("vehicle_draw_loadingarea", false);
	initDebugVar("vehicle_draw_mantlespots", false);
	initDebugVar("playerAwakening", false);
	initDebugVar("playerValueHud", false);
	initDebugVar("playerAwakening", false);
	initDebugVar("playerDamaged", false);
	initDebugVar("playerRank", false);
	initDebugVar("riotshield_damageArea", false);
	initDebugVar("barricades_noDoors", true);
	initDebugVar("barricades_noPlanks", true);
	initDebugVar("barricades_noBlockers", true);
	initDebugVar("noFog", true);

	if(!game["debug"]["status"])
		return;
	
	while(!isDefined(level.players) || level.players.size < 1)
		wait 1;
		
	while(level.aliveCount["allies"] <= 0 && !game["tranzit"].playersReady)
		wait 1;
		
	wait 1;
	
	consolePrint("calling test functions\n");
}