#include scripts\_include;

init()
{
	add_effect("fog_amb", "tranzit/env/fog_amb");
	add_effect("grain_cloud", "tranzit/misc/grain_cloud");
	add_effect("fog_outter_area", "tranzit/env/fog_outter_area_2");

	add_sound("whisper", "whisper");
	add_sound("amb_spooky", "amb_spooky");
	add_sound("amb_spooky_2d", "amb_spooky_2d");
	
	level.ambient_modifier = "";
	
	if(game["debug"]["status"] && game["debug"]["noFog"])
		return;
	
	wait 5; //should be enough time to build the fx array in map gsc
	
	if(isDefined(level.fxOrigins) && level.fxOrigins.size > 0)
		thread monitorAmbientFX();
}

setAmbient(sound, fadeIn, fadeOut)
{
	if(!isDefined(fadeOut))
		fadeOut = 1;
	
	if(!isDefined(fadeIn))
		fadeIn = 5;

	//if there is an ambient change (e.g. weather) use this instead
	if(isDefined(level.ambient_modifier) && level.ambient_modifier != "")
	{
		if(!isDefined(sound) || sound != level.ambient_modifier)
			sound = getZombieSoundalias(level.ambient_modifier);
	}

	if(!isDefined(sound))
	{
		//play a random ambient sound
		random = randomInt(3);
			
		if(random == 3)
			sound = getZombieSoundalias("whisper");
		else if(random == 2)
			sound = getZombieSoundalias("amb_spooky");
		else
			sound = getZombieSoundalias("amb_spooky_2d");
	}
		
	ambientStop(fadeOut);
	ambientPlay(sound, fadeIn);
}

stopAmbient(fadeOut)
{
	if(!isDefined(fadeOut))
		fadeOut = 7;

	ambientStop(fadeOut);
}

prepareFxEntry(origin, fxAlias, hideWhenNoPlayerInRange)
{
	if(!isDefined(hideWhenNoPlayerInRange))
		hideWhenNoPlayerInRange = true;

	struct = spawnStruct();
	struct.origin = origin;
	struct.active = false;
	struct.fxAlias = fxAlias;
	struct.fxEnt = undefined;
	struct.hide = hideWhenNoPlayerInRange;
	
	return struct;
}

monitorAmbientFX()
{
	while(1)
	{
		for(i=0;i<level.fxOrigins.size;i++)
		{
			if(!level.fxOrigins[i].hide)
				shouldStartFx = true;
			else
			{
				shouldStartFx = false;
				for(j=0;j<level.alivePlayers[game["defenders"]].size;j++)
				{
					if(isDefined(level.alivePlayers[game["defenders"]][j]))
					{
						if(Distance(level.fxOrigins[i].origin, level.alivePlayers[game["defenders"]][j].origin) <= 3000)
						{
							shouldStartFx = true;
							break;
						}
					}
				}
			}
			
			if(shouldStartFx)
				level.fxOrigins[i] startAmbientFX();
			else
				level.fxOrigins[i] stopAmbientFx();
		}
		
		wait .75;
	}
}

startAmbientFX()
{
	if(self.active)
		return;

	self.active = true;
	self.fxEnt = spawnFx(self.fxAlias, self.origin);

	//delay 1 is important, else we need a wait before this
	triggerFx(self.fxEnt, 1);
}

stopAmbientFx()
{
	if(!self.active)
		return;

	self.active = false;
	self.fxEnt delete();
}