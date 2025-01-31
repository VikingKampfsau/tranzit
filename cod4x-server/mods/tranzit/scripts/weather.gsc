#include scripts\_include;

init()
{
	//add_effect("rain", "tranzit/weather/rain");
	add_effect("rain_0", "weather/rain_0");
	add_effect("rain_1", "weather/rain_1");	
	add_effect("rain_2", "weather/rain_2");
	add_effect("rain_3", "weather/rain_3");
	add_effect("rain_4", "weather/rain_4");
	add_effect("rain_5", "weather/rain_5");
	add_effect("rain_6", "weather/rain_6");
	add_effect("rain_7", "weather/rain_7");
	add_effect("rain_8", "weather/rain_8");
	add_effect("rain_9", "weather/rain_9");
	add_effect("rain_10", "weather/rain_heavy");
	add_effect("rain_heavy_cloudtype", "weather/rain_heavy_cloudtype");
	add_effect("thunderstorm", "tranzit/weather/thunderstorm");
	
	add_sound("rain_heavy", "ambient_cargoshipmp_ext_sur");
	add_sound("rain_light", "ambient_farm_sur");
	
	//need a cod4x plugin to access that data from map worldspawn
	//or to read it from any client dvar (what i want to avoid)
	game["map_worldspawn"] = getWorldspawn(); //plugin ;)
	
	//force the values from mp_forsaken_world
	//since i replaced all other sky textures with the one used in this map
	//Values of mp_forsaken_world:
	//"sunlight" ".85"
	//"suncolor" "0.5 0.6 1"
	game["map_worldspawn"]["sunColor"] = "0.5 0.6 1";
	game["map_worldspawn"]["sunLight"] = ".85";
	
	//controls the temperment of the weather
	thread rainInit();
}

rainInit()
{
	level.rainLevel = 0;
	prevRainLevel = level.rainLevel;
	
	thread fogChange();
	thread thunderstormInit();
	thread rainLevelChangerInit();
	
	while(1)
	{
		if(prevRainLevel != getDvarInt("weather_rainlevel"))
		{
			prevRainLevel = getDvarInt("weather_rainlevel");
			
			if(prevRainLevel > 10)
			{
				prevRainLevel = 10;
				setDvar("weather_rainlevel", prevRainLevel);
			}
			
			thread rainChange(prevRainLevel);
		}
		
		wait 5;
	}
}

thunderstormInit()
{
	skyheight = GetSkyHeight()[0];

	while(1)
	{
		if(level.rainLevel >= 9)
		{
			setSunLight("1 1 1", randomFloatRange(2,4));
			playFx(level._effect["thunderstorm"], (int(randomFloatRange(level.spawnMins[0], level.spawnMaxs[0])), int(randomFloatRange(level.spawnMins[1], level.spawnMaxs[1])), int(randomFloatRange(skyheight - 50, skyheight))));
			wait randomFloatRange(0.07, 0.19);
			resetSunLight();
		}
		
		wait randomFloatRange(0.66, 6.79);
	}
}

rainLevelChangerInit()
{
	level endon("game_ended");

	while(1)
	{
		setDvar("weather_rainlevel", randomInt(11));
		wait 300+randomIntRange(0, 300);
	}
}
	
rainChange(newLvl)
{
	transition = randomFloatRange(0.5, 10.5);
	
	level thread rainEffectChange(newLvl, transition);

	wait (transition*0.5);
	
	if(newLvl == 0)
		level.ambient_modifier = "rain_off";
	else if(newLvl >= 1 && newLvl <= 6)
		level.ambient_modifier = "rain_light";
	else
		level.ambient_modifier = "rain_heavy";
		
	thread fogChange();
	
	scripts\ambient::setAmbient(level.ambient_modifier, transition, transition);
	
	wait (transition*0.5);
}

fogChange()
{
	if(!isDefined(game["tranzit"].waveStarted) || !game["tranzit"].waveStarted)
	{
		SetExpFog(350, 12000, 0, 0, 0, 2);
		return;
	}
		
	if(level.ambient_modifier == "rain_off")
		SetExpFog(350, 850, 0, 0, 0, 5);
	else if(level.ambient_modifier == "rain_light")
		SetExpFog(320, 750, 0, 0, 0, 5);
	else if(level.ambient_modifier == "rain_heavy")
		SetExpFog(260, 550, 0, 0, 0, 5);
}

rainEffectChange(change, transition)
{
	level notify("rain_level_change");
	level endon("rain_level_change");
	
	/*
	if(change == 0)
		iPrintLnBold("Rain fades out over " + transition + " seconds");
	else
		iPrintLnBold("Rain becomes lvl " + change + " over " + transition + " seconds");
	*/
	
	if(level.rainLevel > change)
	{
		dif = level.rainLevel - change;
		transition /= dif;
		for(i=0;i<dif;i++)
		{
			wait(transition);
			level.rainLevel--;
			level._effect["rain_drops"] = level._effect["rain_" + level.rainLevel];
		}
		assert(level.rainLevel == change);
	}
	if(level.rainLevel < change)
	{
		dif = change - level.rainLevel;
		transition /= dif;
		for(i=0;i<dif;i++)
		{
			wait(transition);
			level.rainLevel++;
			level._effect["rain_drops"] = level._effect["rain_" + level.rainLevel];
		}
		assert(level.rainLevel == change);
	}
}

setSunLight(color, brightness, transition)
{
	if(!isDefined(transition))
		transition = 0;

	for(i=0;i<level.players.size;i++)
	{
		if(level.players[i] isASurvivor())
		{
			if(!isDefined(brightness))
				level.players[i] setClientDvar("r_lightTweakSunColor", color + " 1");
			else
			{
				level.players[i] setClientDvars(
					"r_lightTweakSunColor", color + " 1",
					"r_lightTweakSunLight", brightness);
			}
		}
	}
}

resetSunLight(transition)
{
	if(!isDefined(transition))
		transition = 0;

	setSunLight(game["map_worldspawn"]["sunColor"], game["map_worldspawn"]["sunLight"], transition);
}

playerWeather()
{
	self endon("disconnect");
	self endon("spawned"); //this notify triggers on beginning of the spawn function. spawned_player fires at the end of the spawn function

	//one function at a time - this is just a fail save
	self notify("playerWeather_fx_loop");
	self endon("playerWeather_fx_loop");

	while(1)
	{
		if(level.rainLevel > 0)
		{
			playFx(level._effect["rain_drops"], self.origin + (0,0,650), self.origin + (0,0,680));
			
			//on very heavy rain add a rain cloud
			if(level.rainLevel >= 8)
				playFx(level._effect["rain_heavy_cloudtype"], self.origin + (0,0,650));
		}
		
		wait (0.3);
	}
}

overwriteMapSunlight()
{
	self setClientDvars(
		"r_lightTweakSunColor", game["map_worldspawn"]["sunColor"] + " 1",
		"r_lightTweakSunLight", game["map_worldspawn"]["sunLight"]);
}