#include scripts\_include;

init()
{
	//here ends stuff that has no own script or is used globaly

	setDvar("scr_game_spectatetype", 1);

	//Effects
	add_effect("emitter_rocks", "tranzit/entity/emitter_rocks");
	add_effect("enitity_appear_fire", "tranzit/entity/enitity_appear_fire");
	add_effect("entitiy_disappear", "tranzit/entity/entitiy_disappear2");
	add_effect("entitiy_disappear_small_clouds", "tranzit/entity/entitiy_disappear");
	
	//not sure yet what i need this for
	//add_effect("grain_cloud", "tranzit/misc/grain_cloud");
}