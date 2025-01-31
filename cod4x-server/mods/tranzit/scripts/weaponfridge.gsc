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
		
		if(player UseButtonPressed())
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
	self getFridgedWeapon();
	self swapWeapons();
	self.fridging = undefined;
}

getFridgedWeapon()
{
	if(!isDefined(self.fridgedWeapon))
		self.fridgedWeapon = spawnStruct();

	self.fridgedWeapon.weapon = undefined;

	fridge = "player_storages/fridge/" + self.guid + ".csv";
	
	if(fs_testFile(fridge))
	{
		file = openFile(fridge, "read");
		
		if(file > 0)
		{
			self.inFridge = [];
			while(1)
			{
				line = fReadLn(file);
					
				if(!isDefined(line) || isEmptyString(line))
					break;
					
				line = CaesarShiftCipher(line, "decrypt");
				line = strToK(line, ",");

				curEntry = self.inFridge.size;
				self.inFridge[curEntry] = spawnStruct();
				self.inFridge[curEntry].weapon = undefined;
				self.inFridge[curEntry].weaponAmmoClip = 0;
				self.inFridge[curEntry].weaponAmmoStock = 0;
				self.inFridge[curEntry].map = "";

				if(isDefined(line[0]))
					self.inFridge[curEntry].weapon = line[0];
			
				if(isDefined(line[1]))
					self.inFridge[curEntry].weaponAmmoClip = int(line[1]);
			
				if(isDefined(line[2]))
					self.inFridge[curEntry].weaponAmmoStock = int(line[2]);
				
				//if the weapon was stored in this map set the var
				if(isDefined(line[3]))
				{
					self.inFridge[curEntry].map = line[3];
				
					if(line[3] == level.script)
					{
						if(isDefined(self.inFridge[curEntry].weapon))
						{
							self.fridgedWeapon.weapon = self.inFridge[curEntry].weapon;
							self.fridgedWeapon.weaponAmmoClip = self.inFridge[curEntry].weaponAmmoClip;
							self.fridgedWeapon.weaponAmmoStock = self.inFridge[curEntry].weaponAmmoStock;
						}
					}
				}
			}
		
			closeFile(file);
		}
	}
}

swapWeapons()
{
	self endon("disconnect");
	self endon("death");

	fridge = "player_storages/fridge/" + self.guid + ".csv";
	file = openFile(fridge, "write");
	
	toFridge = spawnStruct();
	toFridge.map = level.script;
	toFridge.weapon = self getCurrentWeapon();
	if(toFridge.weapon == "none")
		return;
	
	if(file > 0)
	{
		toFridge.weaponAmmoClip = self getWeaponAmmoClip(toFridge.weapon);
		if(!isDefined(toFridge.weaponAmmoClip))
			toFridge.weaponAmmoClip = 0;
			
		toFridge.weaponAmmoStock = self getWeaponAmmoStock(toFridge.weapon);
		if(!isDefined(toFridge.weaponAmmoStock))
			toFridge.weaponAmmoStock = 0;
			
		self takeCurrentWeapon();
	
		//if this is defined then there is a weapon inside
		if(isDefined(self.fridgedWeapon.weapon))
		{
			self giveNewWeapon(self.fridgedWeapon.weapon, false, false, self.fridgedWeapon.weaponAmmoClip, self.fridgedWeapon.weaponAmmoStock);
			
			if(isDefined(self getEmptyWeaponSlot()) && !self hasWeapon(game["tranzit"].player_empty_hands))
				self giveNewWeapon(game["tranzit"].player_empty_hands, true);
		}
		else
		{
			if(isDefined(self getEmptyWeaponSlot()) && !self hasWeapon(game["tranzit"].player_empty_hands))
				self giveNewWeapon(game["tranzit"].player_empty_hands);
		}

		if(toFridge.weapon == game["tranzit"].player_empty_hands)
			toFridge.weapon = undefined;

		for(i=0;i<self.inFridge.size;i++)
		{
			if(self.inFridge[i].map == toFridge.map)
				continue;
		
			string = self.inFridge[i].weapon + "," + self.inFridge[i].weaponAmmoClip + "," + self.inFridge[i].weaponAmmoStock + "," + self.inFridge[i].map;
			fPrintLn(file, CaesarShiftCipher(string, "encrypt"));
		}
		
		if(isDefined(toFridge.weapon))
		{
			string = toFridge.weapon + "," + toFridge.weaponAmmoClip + "," + toFridge.weaponAmmoStock + "," + toFridge.map;
			fPrintLn(file, CaesarShiftCipher(string, "encrypt"));
		}
		
		closeFile(file);
	}
}