#include scripts\_include;

init()
{
	add_effect("wallweapon_location_light", "tranzit/misc/wallweapon_light");

	add_sound("weapon_show", "weap_wall");

	//mp_forsaken_world has 4 mapareas
	// Pistols
	addWallweapon( "beretta", 50, 1);
	addWallweapon( "colt45", 50, 1);
	addWallweapon( "deserteagle", 100, 2);
	addWallweapon( "usp", 50, 1);

	// Semi Auto
	addWallweapon( "g3", 200, 2);
	addWallweapon( "m14", 600, 2);
	addWallweapon( "m16", 600, 2);

	// Grenades
	addWallweapon( "c4", 250, 2);
	addWallweapon( "claymore", 250, 2);
	addWallweapon( "frag_grenade", 250, 2);

	// Scoped
	addWallweapon( "barrett", 750, 4);
	addWallweapon( "dragunov", 750, 3);
	addWallweapon( "m21", 750, 2);
	addWallweapon( "m40a3", 750, 3);
	addWallweapon( "remington700", 750, 3);

	// Full Auto (SMGs)
	addWallweapon( "ak74u", 500, 2);
	addWallweapon( "mp5", 500, 2);
	addWallweapon( "p90", 500, 2);
	addWallweapon( "skorpion", 500, 2);
	addWallweapon( "uzi", 500, 2);

	// Full Auto (Rifles)
	addWallweapon( "ak47", 1000, 3);
	addWallweapon( "g36c", 1000, 3);
	addWallweapon( "m4", 1000, 3);
	addWallweapon( "mp44", 1000, 2);

	// Shotguns
	addWallweapon( "m1014", 1200, 2);
	addWallweapon( "winchester1200", 1200, 2);

	// Heavy Machineguns
	addWallweapon( "m60e4", 3000, 4);
	addWallweapon( "rpd", 3000, 4);
	addWallweapon( "saw", 3000, 4);

	// Rocket Launchers
	addWallweapon( "rpg", 2000, 3);

	thread loadWallweapons();
}

addWallweapon(weaponName, cost, area)
{
	if(!isDefined(level.zombieWallweapons))
		level.zombieWallweapons = [];

	if(getSubStr(weaponName, weaponName.size - 3, weaponName.size) == "_mp")
		weaponName = getSubStr(weaponName, 0, weaponName.size - 3);
	
	PrecacheItem(weaponName + "_mp");

	cost = roundUpToTen(int(cost));
	ammocost = roundUpToTen(int(cost/2));
	
	if(cost > 0) cost *= -1;
	if(ammocost > 0) ammocost *= -1;
	
	game["tranzit"].score["wallweapon_" + weaponName] = cost;
	game["tranzit"].score["wallweapon_" + weaponName + "_ammo"] = ammocost;
	
	curEntry = level.zombieWallweapons.size;
	level.zombieWallweapons[curEntry] = spawnStruct();
	level.zombieWallweapons[curEntry].area = area;
	level.zombieWallweapons[curEntry].weaponName = weaponName;
	level.zombieWallweapons[curEntry].ammohint = "WALLWEAPON_BUY_AMMO";
	level.zombieWallweapons[curEntry].weaponhint = "WALLWEAPON_BUY_WEAPON";
}

getZombieWallweapon()
{
	desiredWeapon = self.target;

	if(isDefined(desiredWeapon))
	{
		if(getSubStr(desiredWeapon, desiredWeapon.size - 3, desiredWeapon.size) == "_mp")
			desiredWeapon = getSubStr(desiredWeapon, 0, desiredWeapon.size - 3);

		//check if the weapon is in the array
		for(i=0;i<level.zombieWallweapons.size;i++)
		{
			if(desiredWeapon == level.zombieWallweapons[i].weaponName)
			{
				self.weapon = level.zombieWallweapons[i];
				return;
			}
		}
	}

	randomWeapon = undefined;
	area = scripts\maparea::getClosestMapArea(self.origin);
	
	if(!isDefined(area))
		randomWeapon = level.zombieWallweapons[randomInt(level.zombieWallweapons.size)];
	else
	{
		possibleWeapons = [];
		for(i=0;i<level.zombieWallweapons.size;i++)
		{
			if(level.zombieWallweapons[i].area <= area.spawner_id)
				possibleWeapons[possibleWeapons.size] = level.zombieWallweapons[i];
		}
		
		if(!possibleWeapons.size)
			randomWeapon = level.zombieWallweapons[randomInt(level.zombieWallweapons.size)];
		else
			randomWeapon = possibleWeapons[randomInt(possibleWeapons.size)];
	}

	self.weapon = randomWeapon;
	self setModel(getWeaponModel(randomWeapon.weaponName + "_mp", 0));
	self hide();
}

loadWallweapons()
{
	level.wallweaponSpots = getEntArray("wallweapon", "targetname");
	for(i=0;i<level.wallweaponSpots.size;i++)
		level.wallweaponSpots[i] thread initWallweaponSpot();
}

initWallweaponSpot()
{
	self endon("death");
	
	self.active = false;
	self getZombieWallweapon();

	//find the wall
	trace = BulletTrace(self.origin - AnglesToRight(self.angles)*10, self.origin + AnglesToRight(self.angles)*10, false, self);
	
	if(trace["fraction"] >= 1)
	{
		//iPrintLnBold("no wall found in first step");
		trace = BulletTrace(self.origin + AnglesToRight(self.angles)*10, self.origin - AnglesToRight(self.angles)*10, false, self);
	}

	if(trace["fraction"] >= 1)
	{
		//iPrintLnBold("no wall found in second step");
		self.finalPos = self.origin;
	}
	else
	{
		//iPrintLnBold("wall found in second step");
		self.finalPos = self.origin;
		self.origin = self.origin + AnglesToForward(VectorToAngles(trace["position"] - self.origin)) * (Distance(trace["position"], self.origin) + 10);
	}
	
	self.trigger = spawn("trigger_radius", self.origin - (0,0,25), 0, 50, 50);
	
	self thread createWallweaponLight();
	
	while(1)
	{
		self.trigger waittill("trigger", player);
		
		if(!player isReadyToUse())
			continue;
		
		if(isDefined(player.buyingWallweapon) && player.buyingWallweapon)
			continue;
		
		if(!player isLookingAt(self))
			continue;
		
		if(player hasWeapon(self.weapon.weaponName + "_mp"))
		{
			player thread showTriggerUseHintMessage(self.trigger, player getLocTextString(self.weapon.ammohint), scripts\money::getPrice("wallweapon_" + self.weapon.weaponName + "_ammo"));
		
			if(!player scripts\money::hasEnoughMoney("wallweapon_" + self.weapon.weaponName + "_ammo"))
				continue;
		}
		else
		{
			player thread showTriggerUseHintMessage(self.trigger, player getLocTextString(self.weapon.weaponhint), scripts\money::getPrice("wallweapon_" + self.weapon.weaponName));
		
			if(!player scripts\money::hasEnoughMoney("wallweapon_" + self.weapon.weaponName))
				continue;
		}
		
		if(player UseButtonPressed())
		{
			if(!self.active)
				self thread activateWallweapon();

			player thread grabWallWeapon(self.weapon);
		}
	}
}

createWallweaponLight(lightPos)
{
	self endon("death");

	self.location_light = spawnFx(level._effect["wallweapon_location_light"], self.finalPos);
	triggerFx(self.location_light, 0.1);
	
	while(isDefined(self.trigger))
		wait .1;
	
	self.location_light delete();
}

activateWallweapon()
{
	self endon("death");
	
	if(self.active)
		return;
	
	self show();
	self.active = true;

	dist = Distance(self.origin, self.finalPos);
	speed = 5;
	time = dist / speed;
	
	if(time <= 0.05)
		time = 0.05;
	
	self playSoundRef("weapon_show");
	self moveTo(self.finalPos, time);
}

grabWallWeapon(wallWeapon)
{
	self endon("disconnect");
	self endon("death");
	
	self.buyingWallweapon = true;
	
	while(self UseButtonPressed())
		wait .05;

	newWeapon = wallWeapon.weaponName;

	if(getSubStr(wallWeapon.weaponName, wallWeapon.weaponName.size - 3, wallWeapon.weaponName.size) != "_mp")
		newWeapon = wallWeapon.weaponName + "_mp";

	if(isOtherExplosive(newWeapon) && self hasActionSlotWeapon("weapon"))
	{
		if(self.actionSlotWeapon != newWeapon)
			return;
	}
	
	if(isHardpointWeapon(newWeapon) && self hasActionSlotWeapon("hardpoint"))
	{
		if(self.actionSlotHardpoint != newWeapon)
			return;
	}

	if(self hasWeapon(newWeapon))
	{
		self giveMaxAmmo(newWeapon);
		self thread [[level.onXPEvent]]("wallweapon_" + wallWeapon.weaponName + "_ammo");
	}
	else
	{
		self thread [[level.onXPEvent]]("wallweapon_" + wallWeapon.weaponName);
	
		self giveNewWeapon(newWeapon);
	}
	
	self.buyingWallweapon = false;
}