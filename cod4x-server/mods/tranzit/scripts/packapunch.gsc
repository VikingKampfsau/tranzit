#include maps\mp\_utility;
#include scripts\_include;

init()
{
	precacheModel("zombie_vending_packapunch");
	
	add_weapon("at4", "at4_mp", true);
	
	add_sound("packa_loop", "packa_loop");
	add_sound("packa_sting", "packa_sting");
	add_sound("packa_upgrade_weap", "packa_upgrade_weap");
	add_sound("packa_weap_ready", "packa_weap_ready");
	
	add_effect("pap_working_fx", "tranzit/packapunch/pap_working_fx");
		
	if(game["tranzit"].mapType == "tranzit")
		level.packapunchMachines = getEntArray("packapunch", "targetname");
	else if(game["tranzit"].mapType == "rotu")
	{
		//rotu has only two additional entities in map
		//so when there are multiple shops/misteryBoxes we use the last one for packapunch
		wait 2; //give the misteryBox script some time to grab the misteryBoxes and define packapunch
	}
	else
	{
		level.packapunchMachines = getEntArray("sd_bomb", "targetname");
	}
	
	if(!isDefined(level.packapunchMachines) || !level.packapunchMachines.size)
	{
		consolePrint("^1Map has no spawnpoints for packapunchMachines\n");
		return;
	}
	
	for(i=0;i<level.packapunchMachines.size;i++)
		level.packapunchMachines[i] thread initPackapunchMachine();
}

initPackapunchMachine()
{
	if(self.model != "zombie_vending_packapunch")
		self setModel("zombie_vending_packapunch");

	if(game["tranzit"].mapType == "default")
		self.angles += (0,180,0);

	if(!isDefined(self.roller))
	{
		self.roller = spawn("script_model", self.origin);
		self.roller setModel("zombie_vending_packapunch");
	}
	
	self.roller.origin = self getTagOrigin("tag_roller");
	self.roller.angles = self.angles;

	self.roller show();
	self.roller hidePart("tag_machine", self.roller.model);
	self.roller unlink();
	
	self show();
	self hidePart("tag_wheels", self.model);
	
	self.power = false;
	self.booting = false;
	self.isInUse = false;
	
	while(!isDefined(game["tranzit"].powerEnabled) || !game["tranzit"].powerEnabled)
		wait .05;
		
	if(!self.power)
		self thread activatePackAPunchMachine(false);		
}

activatePackAPunchMachine(localPowerSupply, delay)
{
	self endon("death");

	if(self.booting || self.power)
		return;

	self.booting = true;

	if(isDefined(delay))
		wait delay;

	if(!isDefined(localPowerSupply) || !localPowerSupply)
	{
		self PlaySoundRef("perks_power_on");
		wait 7;
	}

	self.booting = false;

	if(self.power)
		return;

	self.power = true;
	self.isInUse = false;
	self.trigger = spawn("trigger_radius", self.origin, 0, 50, 50);
	
	self thread switchOnPowerLight(level._effect["revive_light"]);
	self thread PlayLoopVendingSound("packa_sting", 8);
	
	while(self.power)
	{
		self.trigger waittill("trigger", player);

		if(!self.power)
			continue;

		if(self.isInUse)
			continue;

		if(!player isReadyToUse())
			continue;

		player thread showTriggerUseHintMessage(self.trigger, player getLocTextString("PACKAPUNCH_USE_PRESS_BUTTON"), scripts\money::getPrice("packapunch"));

		if(!player scripts\money::hasEnoughMoney("packapunch"))
			continue;

		if(player UseButtonPressed())
		{
			self.isInUse = true;
			player thread usePackapunchMachine(self, player);
		}
	}
	
	self notify("stop_vending_sound");
}

switchOnPowerLight(fx)
{
	self endon("death");

	self.fxEnt = spawnFx(fx, self.origin, AnglesToForward(self.angles), AnglesToUp(self.angles));

	//delay 1 is important, else we need a wait before this
	triggerFx(self.fxEnt, 1);
	
	while(self.power)
		wait 1;
		
	self.fxEnt delete();
}

PlayLoopVendingSound(sound, length)
{
	self endon("death");
	
	self notify("stop_vending_sound");
	self endon("stop_vending_sound");

	while(self.power)
	{
		self PlaySoundRef(sound);
		wait (length + 5);
	}
}

getUpgradeForWeapon(weapon)
{
	file = "packapunch/weaponupgrades.csv";
	return TableLookupInFile(file, 0, weapon, 1, false);
}

usePackapunchMachine(box, player)
{
	curWeapon = player getCurrentWeapon();
	upgradedWeapon = getUpgradeForWeapon(curWeapon);

	if(!isDefined(upgradedWeapon))
	{
		player iPrintLnBold(player getLocTextString("PACKAPUNCH_FAIL_BAD_WEAPON"));
		box.isInUse = false;
		return;
	}

	player thread [[level.onXPEvent]]("packapunch");
	player takeCurrentWeapon();

	box rotateRoller("in");

	weaponModel = spawn("script_model", box getTagOrigin("tag_input"));
	weaponModel.angles = box.angles + (0,90,0);
	weaponModel setModel(getWeaponModel(curWeapon, 0));
		
	wait .5;
	
	weaponModel moveTo(box getTagOrigin("tag_work"), 0.5);
	
	wait .35;
	
	weaponModel hide();
	playSoundAtPosition("packa_upgrade_weap", box.origin);
	PlayFXOnTag(level._effect["pap_working_fx"], box, "tag_work");
	
	wait 3;

	playSoundAtPosition("packa_weap_ready", box.origin);

	weaponModel show();
	weaponModel setModel(getWeaponModel(upgradedWeapon, 0));
	weaponModel moveTo(box getTagOrigin("tag_input"), 0.5);
	
	box rotateRoller("out");
	
	wait .5;
	
	thread makeUpgradedWeaponGrabable(player, weaponModel, upgradedWeapon);
	weaponModel thread deleteOverTime(7, box getTagOrigin("tag_work"));
	
	while(isDefined(weaponModel))
		wait .05;
		
	box.isInUse = false;
}

makeUpgradedWeaponGrabable(grabber, weaponModel, upgradedWeapon)
{
	weaponModel endon("death");
	
	weaponModel.trigger = spawn("trigger_radius", weaponModel.origin, 0, 50, 50);
	
	while(isDefined(weaponModel.trigger))
	{
		weaponModel.trigger waittill("trigger", player);

		if(!player isReadyToUse())
			continue;

		if(!isDefined(grabber) || !isPlayer(grabber))
			return;

		if(player != grabber)
			continue;

		if(player UseButtonPressed())
		{
			while(player UseButtonPressed())
				wait .05;
		
			randomShout = randomInt(8);
			if(randomShout == 0)
				player playSoundRef("gen_weappick");
			else if(randomShout == 1)
			{
				switch(WeaponClass(upgradedWeapon))
				{
					case "mg":		player playSoundRef("weappick_mg");			break;
					case "spread":	player playSoundRef("weappick_shotgun");	break;
					case "rifle":	player playSoundRef("weappick_sniper");		break;
					case "grenade":	player playSoundRef("weappick_sticky");		break;
					case "pistol":
					default:		player playSoundRef("weappick_crappy");		break;
				}
			}

			result = self giveNewWeapon(upgradedWeapon);
			
			if(result)
				break;
		}
	}
	
	weaponModel playSoundRef("buy_item");
	weaponModel hide();
	wait .1;
	weaponModel delete();
}

deleteOverTime(time, target)
{
	self endon("death");
	
	wait (time - 2);
	self moveTo(target, 2);	
	wait 2;
	
	self delete();
}

rotateRoller(direction)
{
	rollTime = 1.5;

	if(direction == "out")
		rollAngle = 360;
	else
		rollAngle = -360;

	self.roller RotatePitch(rollAngle, rollTime, (rollTime * 0.5));
}