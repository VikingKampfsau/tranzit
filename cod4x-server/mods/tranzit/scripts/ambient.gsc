#include scripts\_include;

init()
{
	add_effect("fog_amb", "tranzit/env/fog_amb");
	add_effect("grain_cloud", "tranzit/misc/grain_cloud");
	add_effect("fog_outter_area", "tranzit/env/fog_outter_area_2");

	add_sound("whisper", "whisper");
	add_sound("amb_spooky", "amb_spooky");
	add_sound("amb_spooky_2d", "amb_spooky_2d");
	
	//how far the players can see before the map is dark
	SetExpFog(250, 400, 0, 0, 0, 2);
	
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
		
	ambientStop(fadeOut);
	ambientPlay(sound, fadeIn);
}

stopAmbient(fadeOut)
{
	if(!isDefined(fadeOut))
		fadeOut = 7;

	ambientStop(fadeOut);
}

prepareFxEntry(origin)
{
	struct = spawnStruct();
	struct.origin = origin;
	struct.active = false;
	struct.fxEnt = undefined;
	
	return struct;
}

monitorAmbientFX()
{
	while(1)
	{
		for(i=0;i<level.fxOrigins.size;i++)
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
	self.fxEnt = spawnFx(level._effect["fog_outter_area"], self.origin);

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