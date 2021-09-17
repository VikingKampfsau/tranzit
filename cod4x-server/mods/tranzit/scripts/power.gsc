#include scripts\_include;

init()
{
	add_sound("switch_flip", "switch_flip");
	add_sound("power_up", "power_up");
	add_sound("power_turn_on", "power_turn_on");
	add_sound("power_down", "power_down");
	
	thread initPowerSwitch();
}

initPowerSwitch()
{
	game["tranzit"].powerEnabled = false;

	powerSwitch = getEnt("powerswitch", "targetname");

	level waittill("connected", player);

	if(!isDefined(powerSwitch))
	{
		wait 10;
		game["tranzit"].powerEnabled = true;
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
	
	wait 1;
	self delete();
}

