#include scripts\_include;

init()
{
	add_sound("switch_flip", "switch_flip");
	add_sound("power_up", "power_up");
	add_sound("power_turn_on", "power_turn_on");
	add_sound("power_down", "power_down");
	
	game["tranzit"].powerEnabled = false;

	initScriptableLights();
	
	thread initPowerSwitch();
}

initScriptableLights()
{
	level.scriptableLight = getEntArray("light", "classname");
	
	if(level.scriptableLight.size <= 0)
		return;
	
	/* does not work as expected */
	/*for(i=0;i<level.scriptableLight.size;i++)
	{
		//store current values in a struct, just in case we modify the light and have to restore it's previous state
		level.scriptableLight[i].lightInfo = spawnStruct();
		level.scriptableLight[i].lightInfo.id = i;
		level.scriptableLight[i].lightInfo.entNo = level.scriptableLight[i] getEntityNumber();
		level.scriptableLight[i].lightInfo.color = level.scriptableLight[i] getLightColor();
		level.scriptableLight[i].lightInfo.radius = level.scriptableLight[i] getLightRadius();
		level.scriptableLight[i].lightInfo.intensity = level.scriptableLight[i] getLightIntensity();
		level.scriptableLight[i].lightInfo.defaultIntensity  = level.scriptableLight[i].script_burst;
		
		level.scriptableLight[i] thread monitorScriptableLight();
	}*/
}

initPowerSwitch()
{
	powerSwitch = getEnt("powerswitch", "targetname");

	if(!isDefined(powerSwitch))
	{
		game["tranzit"].powerEnabled = true;

		thread lightUpScriptableLights();
		return;
	}
	
	powerSwitch thread monitorSwitchTriggering();
}

monitorSwitchTriggering()
{
	self endon("death");
	
	self.trigger = spawn("trigger_radius", self.origin - (0,0,25), 0, 50, 50);
	
	while(1)
	{
		self.trigger waittill("trigger", player);
		
		if(!player isReadyToUse())
			continue;
		
		player thread showTriggerUseHintMessage(self.trigger, player getLocTextString("POWER_SWITCH_USE"));
		
		if(player UseButtonPressed())
			break;
	}
	
	self.trigger delete();
	
	self playSoundRef("switch_flip");
	self rotatePitch(-25, 0.3);
	wait 0.3;
	
	self playSoundRef("power_turn_on");
	wait 6;
	self playSoundRef("power_up");
	wait 5;
	game["tranzit"].avagadroReleased = true;
	wait 2;
	game["tranzit"].powerEnabled = true;
	
	thread lightUpScriptableLights();
	
	wait 1;
	self delete();
}

monitorScriptableLight()
{
	self endon("death");
	
	self.power = false;
	status = self.power;
	
	consolePrint("monitoring scriptable light: " + self.lightInfo.id + "\n");
	
	while(1)
	{
		if(status != self.power)
		{
			if(self.power)
			{
				self.lightInfo.intensity = self.lightInfo.defaultIntensity;
				self setLightIntensity(self.lightInfo.intensity);
			}
			else
			{
				self.lightInfo.intensity = 0.1;
				self setLightIntensity(self.lightInfo.intensity);
			}
			
			status = self.power;
		}
		
		wait .5;
	}
}

lightUpScriptableLights()
{
	if(level.scriptableLight.size <= 0)
		return;

	for(i=0;i<level.scriptableLight.size;i++)
		level.scriptableLight[i] thread lightUpScriptableLight();
}

lightUpScriptableLight()
{
	consolePrint("turning on scriptable light: " + self.lightInfo.id + "\n");
	self.power = true;
}

darkenScriptableLights()
{
	if(level.scriptableLight.size <= 0)
		return;

	for(i=0;i<level.scriptableLight.size;i++)
		level.scriptableLight[i] thread darkenScriptableLight();
}

darkenScriptableLight()
{
	self.power = false;
}