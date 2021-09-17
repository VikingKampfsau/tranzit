//Cleaned rotu file to make rotu maps compatible

setGameMode(mode)
{
}

setPlayerSpawns(targetname)
{
}

setWorldVision(vision, transitiontime)
{
}

buildParachutePickup(targetname)
{
}

buildWeaponPickup(targetname, itemtext, weapon, type)
{
}

buildAmmoStock(targetname, loadtime)
{
	boxType = getDvar("rotu_ammobox_type");
	
	if(boxType == "ammo")
		level.rotuAmmoBoxName = targetname;
	else
		level.rotuMisteryBoxName = targetname;
}

setWeaponHandling(id)
{
}

setSpawnWeapons(primary, secondary)
{
}

// ONSLAUGHT MODE
beginZomSpawning()
{
}

//SURVIVAL MODE
buildSurvSpawn(targetname, priority) // Loading spawns for survival mode (incoming waves)
{
}

//SURVIVAL MODE
removeSurvSpawn(targetname) // Removing spawns for survival mode (incoming waves)
{
}

buildSurvSpawnByClassname(classname, priority)
{
}

prepareMap()
{
}

buildWeaponUpgrade(targetname) // Weaponshop actually
{
	level.rotuVendingMachineName = targetname;
}

startSurvWaves() 
{
}

waittillStart()
{
}

buildBarricade(targetname, parts, health, deathFx, buildFx, dropAll)
{
	level.rotuBarricade = [];
	level.rotuBarricade["Name"] = targetname;
}
