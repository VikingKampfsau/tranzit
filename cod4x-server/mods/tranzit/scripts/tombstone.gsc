/* never tested - never used */

#include scripts\_include;

init()
{
	precacheModel("zombie_tombstone");
	
	game["tranzit"].tombstone["livetime"] = 90;
}

initTombstone()
{
	self endon("disconnect");
	
	if(isDefined(self.tombstone))
		return;
	
	self.tombstone = spawnStruct();
	self.tombstone.owner = self;
	self.tombstone.origin = self.origin;
	self.tombstone.perks = self.zombiePerks;
	
	self.tombstone.primaryWeapon = self.pers["primaryWeapon"];
	self.tombstone.primaryAmmoClip = 0;
	self.tombstone.primaryAmmoStock = 0;
	
	if(isDefined(self.pers["primaryWeapon"]) && self hasWeapon(self.pers["primaryWeapon"]))
	{
		self.tombstone.primaryAmmoClip = self getWeaponAmmoClip(self.pers["primaryWeapon"]);
		self.tombstone.primaryAmmoStock = self getWeaponAmmoStock(self.pers["primaryWeapon"]);
	}

	self.tombstone.secondaryWeapon = self.pers["secondaryWeapon"];
	self.tombstone.secondaryAmmoClip = 0;
	self.tombstone.secondaryAmmoStock = 0;
	
	if(isDefined(self.pers["secondaryWeapon"]) && self hasWeapon(self.pers["secondaryWeapon"]))
	{
		self.tombstone.secondaryAmmoClip = self getWeaponAmmoClip(self.pers["secondaryWeapon"]);
		self.tombstone.secondaryAmmoStock = self getWeaponAmmoStock(self.pers["secondaryWeapon"]);
	}
	
	self.tombstone thread spawnTombStone();
}

spawnTombStone()
{
	level waittill("round_chalk_done");

	self.visual = spawn("script_model", self.origin);
	self.visual setModel("zombie_tombstone");
	
	self.trigger = spawn("trigger_radius", self.origin - (0,0,25), 0, 50, 50);
	
	self thread scripts\zombie_drops::createPowerupLight();
	self.trigger monitorTombstonePick(self.owner);
	
	playFx(level._effect["powerup_grab"], self.origin);
	
	if(isDefined(self.trigger))
		self.trigger delete();
		
	if(isDefined(self.visual))
		self.visual delete();

	//self.owner takeAllWeapons();
	self.owner giveNewWeapon(self.primaryWeapon, false, true, self.tombstone.primaryAmmoClip, self.tombstone.primaryAmmoStock);
	self.owner giveNewWeapon(self.secondaryWeapon, false, false, self.tombstone.secondaryAmmoClip, self.tombstone.secondaryAmmoStock);
}

monitorTombstonePick(owner)
{
	self endon("death");
	
	self thread deleteTombstoneAfterAWhile();
	
	while(1)
	{
		self waittill("trigger", player);
		
		if(player == owner)
			break;
	}
}

deleteTombstoneAfterAWhile()
{
	self endon("death");
	
	wait game["tranzit"].tombstone["livetime"];

	if(!isDefined(self))
		return;

	self delete();
}