main()
{
	maps\mp\mp_forsaken_world_fx::main();
	maps\createfx\mp_forsaken_world_fx::main();
	maps\mp\_load::main();

	//maps\mp\_compass::setupMiniMap("compass_map_mp_forsaken_world");

	game["allies"] = "marines";
	game["axis"] = "opfor";
	game["attackers"] = "axis";
	game["defenders"] = "allies";
	game["allies_soldiertype"] = "woodland";
	game["axis_soldiertype"] = "woodland";
	
	setdvar( "r_specularcolorscale", "2" );
	
	setdvar("compassmaxrange","1800");
	
	//used to lower the height for airstrikes and carepackages
	//calc is: height of skybrush - (514 * level.mapSkyHeightScale);
	level.mapSkyHeightScale = 3;

	//used to show a short intro message
	level.intro_linefeed_lines = [];
	level.intro_linefeed_lines[level.intro_linefeed_lines.size] = "Apocalypse";
	level.intro_linefeed_lines[level.intro_linefeed_lines.size] = "Altay Mountains, Russia";
	level.intro_linefeed_lines[level.intro_linefeed_lines.size] = "DAY-TIME";
}