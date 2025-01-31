#include common_scripts\utility;
#include maps\mp\_utility;

#include scripts\_include;

init()
{
	add_weapon("weapondrop", "weapondrop_mp", true);
	
	game["tranzit"].weaponDrop = [];
	game["tranzit"].weaponDrop["curdrops"] = 0;
	game["tranzit"].weaponDrop["maxdrops"] = 10;
	game["tranzit"].weaponDrop["livetime"] = 300;
}

dropWeaponOnDeath()
{
	//drop the "best" weapon on death
	//what is the "best" weapon? strongest?
	//but isn't an auto rifle better than a sniper rifle?
	//for now drop the last used weapon
	weapon = self.lastUsedWeapon;
	if(!isDefined(weapon) || !self hasWeapon(weapon))
		weapon = self getCurrentWeapon();

	if(!isDropableWeapon(weapon))
		return;
	
	if(!self hasWeapon(weapon))
		return;
	
	if(!self AnyAmmoForWeaponModes(weapon))
		return;
	
	clipAmmo = self GetWeaponAmmoClip(weapon);
	if(clipAmmo <= 0)
		return;

	stockAmmo = self GetWeaponAmmoStock(weapon);
	stockMax = WeaponMaxAmmo(weapon);
	if(stockAmmo > stockMax)
		stockAmmo = stockMax;

	item = self dropItem(weapon);

	item ItemWeaponSetAmmo(clipAmmo, stockAmmo);
	//item maps\mp\gametypes\_weapons::itemRemoveAmmoFromAltModes();
	
	item.owner = self;
	
	item thread maps\mp\gametypes\_weapons::watchPickup();
	item thread deletePickupAfterAWhile();
}

dropWeaponOnResponse()
{
	if(game["tranzit"].weaponDrop["curdrops"] >= game["tranzit"].weaponDrop["maxdrops"])
		return;

	if(isDefined(self.isDroppingWeapon))
		return;

	//drop the strongest weapon on death only
	weapon = self getCurrentWeapon();

	if(!isDropableWeapon(weapon))
		return;

	self thread monitorWeaponThrow(weapon);
	self giveWeapon("weapondrop_mp");
	self setSpawnWeapon("weapondrop_mp");
}

monitorWeaponThrow(weapon)
{
	self endon("disconnect");
	self endon("death");

	self waittill("weapon_change", newWeapon);

	if(newWeapon == "weapondrop_mp")
	{
		while(self getCurrentWeapon() != newWeapon)
			wait .05;

		self.isDroppingWeapon = weapon;

		self execClientCommand("attack"); //frag might work too - depends on the weaponfile
		self waittill("grenade_fire", grenade, weaponName);
		
		self takeWeapon("weapondrop_mp");
		self.weapons = self getweaponslist();
		if(isDefined(self.weapons[0]))
			self switchToWeapon(self.weapons[0]);
		
		self.isDroppingWeapon = undefined;

		if(!self AnyAmmoForWeaponModes(weapon))
		{
			if(isDefined(grenade))
				grenade delete();
			
			return;
		}
		
		clipAmmo = self GetWeaponAmmoClip(weapon);
		if(clipAmmo <= 0)
		{
			if(isDefined(grenade))
				grenade delete();
			
			return;
		}

		stockAmmo = self GetWeaponAmmoStock(weapon);
		stockMax = WeaponMaxAmmo(weapon);
		if(stockAmmo > stockMax)
			stockAmmo = stockMax;
		
		item = self dropItem(weapon);
		item ItemWeaponSetAmmo(clipAmmo, stockAmmo);
		//item maps\mp\gametypes\_weapons::itemRemoveAmmoFromAltModes();
		
		item.origin -= (0,0,100000);
		
		item thread createFakeModel(grenade, getWeaponModel(weapon, 0));
		item thread deletePickupAfterAWhile();
		
		game["tranzit"].weaponDrop["curdrops"]++;
	}
}

createFakeModel(grenade, weaponModel)
{
	self endon("death");

	//the model of the grenade is not changable so spawn a fakeModel
	fakeModel = spawn("script_model", grenade.origin);
	fakeModel setModel(weaponModel);
	fakeModel.angles = grenade.angles;
	fakeModel linkTo(grenade);
		
	grenade hide();
	grenade maps\mp\gametypes\_weapons::waitTillNotMoving();
	
	if(!isDefined(grenade))
	{
		game["tranzit"].weaponDrop["curdrops"]--;
		
		fakeModel delete();
		self delete();
	}
	else
	{
		self.origin = grenade.origin;
		self thread maps\mp\gametypes\_weapons::watchPickup();
		
		grenade delete();
		fakeModel delete();
	}
}

deletePickupAfterAWhile()
{
	self endon("death");
	
	wait game["tranzit"].weaponDrop["livetime"];

	if(!isDefined(self))
		return;

	game["tranzit"].weaponDrop["curdrops"]--;

	self delete();
}