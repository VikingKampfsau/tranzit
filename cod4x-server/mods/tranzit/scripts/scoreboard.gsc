init()
{
	setdvar("g_TeamName_" + game["defenders"], "^2Humans");
	setdvar("g_TeamIcon_" + game["defenders"], "teamlogo_humans");
	setdvar("g_TeamColor_" + game["defenders"], "0 0.8 0");
	setdvar("g_ScoresColor_" + game["defenders"], "0.1 0.8 0.1");

	setdvar("g_TeamName_" + game["attackers"], "^1Undeads");
	setdvar("g_TeamIcon_" + game["attackers"], "teamlogo_zombies");
	setdvar("g_TeamColor_" + game["attackers"], "0.8 0 0");
	setdvar("g_ScoresColor_" + game["attackers"], "0.8 0.1 0.1");
	
	setdvar("g_ScoresColor_Spectator", ".25 .25 .25");
	setdvar("g_ScoresColor_Free", ".76 .78 .10");
	setdvar("g_teamColor_MyTeam", ".6 .8 .6" );
	setdvar("g_teamColor_EnemyTeam", "1 .45 .5" );
}