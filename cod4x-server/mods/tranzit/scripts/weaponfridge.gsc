#include scripts\_include;

init()
{
	thread loadWeaponFridges();
}

loadWeaponFridges()
{
	level.weaponFridges = getEntArray("weaponfridge", "targetname");
		
	//loop through all weaponFridges and create the trigger
	for(i=0;i<level.weaponFridges.size;i++)
		level.weaponFridges[i] thread initWeaponFridge();
}

initWeaponFridge()
{
	self endon("death");
	
	self.trigger = spawn("trigger_radius", self.origin - (0,0,25), 0, 64, 128);
	
	while(1)
	{
		self.trigger waittill("trigger", player);
		
		if(!player isReadyToUse())
			continue;
		
		player thread showTriggerUseHintMessage(self.trigger, player getLocTextString("FRIDGE_GRAB_WEAPON"));
		
		if(player UseButtonPressed() && (!isDefined(player.fridging) || !player.fridging))
		{
			player thread openWeaponFridge();
			
			while(player UseButtonPressed())
				wait 1;
		}
	}
	
	self.trigger delete();
}

openWeaponFridge()
{
	self endon("disconnect");
	self endon("death");
	
	self.fridging = true;
	self.fridgedWeapon = self checkFridgedWeapon();
	self swapWeapons();
	self.fridging = false;
}

checkFridgedWeapon()
{
	fridge = "player_storages/fridge/" + self.guid + ".csv";
	weapon = undefined;
	
	if(fs_testFile(fridge))
	{
		file = openFile(fridge, "read");
		
		if(file > 0)
		{
			weapon = fReadLn(file);
				
			if(!isDefined(weapon) || weapon == "" || weapon == " ")
				weapon = undefined;
			else
				weapon = CaesarShiftCipher(weapon, "decrypt");
		
			closeFile(file);
		}
	}
	
	return weapon;
}

swapWeapons()
{
	self endon("disconnect");
	self endon("death");

	fridge = "player_storages/fridge/" + self.guid + ".csv";
	file = openFile(fridge, "write");
	
	toFridge = self getCurrentWeapon();
	if(toFridge == "none")
		return;
	
	if(file > 0)
	{
		self takeCurrentWeapon();
	
		//if this is defined then there is a weapon inside
		if(isDefined(self.fridgedWeapon))
		{
			self giveNewWeapon(self.fridgedWeapon);
			
			if(isDefined(self getEmptyWeaponSlot()) && !self hasWeapon(game["tranzit"].player_empty_hands))
				self giveNewWeapon(game["tranzit"].player_empty_hands, true);
		}
		else
		{
			if(isDefined(self getEmptyWeaponSlot()) && !self hasWeapon(game["tranzit"].player_empty_hands))
				self giveNewWeapon(game["tranzit"].player_empty_hands);
		}

		if(toFridge == game["tranzit"].player_empty_hands)
			toFridge = undefined;

		if(isDefined(toFridge))
		{
			fPrintLn(file, CaesarShiftCipher(toFridge, "encrypt"));
			closeFile(file);
		}
		else
		{
			closeFile(file);
			if(fs_testFile(fridge))
				fs_remove(fridge);
		}
	}
}