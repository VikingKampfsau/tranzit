#include scripts\_include;

init()
{
	precacheModel("perkmachines");
	precacheModel("zombie_vending_ammo");

	precacheShader("perk_quickrevive");
	precacheShader("perk_tombstone");
	precacheShader("specialty_fastreload");
	precacheShader("specialty_rof");
	precacheShader("specialty_armorvest");
	
	add_effect("light_on_blue", "tranzit/perksacola/light_on_blue");
	add_effect("light_on_green", "tranzit/perksacola/light_on_green");
	add_effect("light_on_red", "tranzit/perksacola/light_on_red");
	add_effect("light_on_white", "tranzit/perksacola/light_on_white");
	add_effect("light_on_yellow", "tranzit/perksacola/light_on_yellow");
	
	add_sound("jingle_doubletap", "jingle_doubletap");
	add_sound("jingle_juggernaut", "jingle_juggernaut");
	add_sound("jingle_quickrevive", "jingle_quickrevive");
	add_sound("jingle_fastreload", "jingle_fastreload");
	add_sound("perks_power_on", "perks_power_on");

	add_weapon("perksacola", "smoke_grenade_mp");
	
	thread initZombiePerks();
	thread initDefaultPerks();
	thread loadVendingMachines();
}

initZombiePerks()
{
	level.zombie_perks = [];
	level.zombie_perks[level.zombie_perks.size] = "perk_quickrevive";
	level.zombie_perks[level.zombie_perks.size] = "perk_tombstone";
}

initDefaultPerks()
{
	level.default_perks = [];
	level.default_perks[level.default_perks.size] = "specialty_specialgrenade";
	level.default_perks[level.default_perks.size] = "specialty_fraggrenade";
	level.default_perks[level.default_perks.size] = "specialty_extraammo";
	level.default_perks[level.default_perks.size] = "specialty_detectexplosive";
	level.default_perks[level.default_perks.size] = "specialty_bulletdamage";
	level.default_perks[level.default_perks.size] = "specialty_armorvest";
	level.default_perks[level.default_perks.size] = "specialty_fastreload";
	level.default_perks[level.default_perks.size] = "specialty_rof";
	level.default_perks[level.default_perks.size] = "specialty_twoprimaries";
	level.default_perks[level.default_perks.size] = "specialty_gpsjammer";
	level.default_perks[level.default_perks.size] = "specialty_explosivedamage";
	level.default_perks[level.default_perks.size] = "specialty_longersprint";
	level.default_perks[level.default_perks.size] = "specialty_bulletaccuracy";
	level.default_perks[level.default_perks.size] = "specialty_pistoldeath";
	level.default_perks[level.default_perks.size] = "specialty_grenadepulldeath";
	level.default_perks[level.default_perks.size] = "specialty_bulletpenetration";
	level.default_perks[level.default_perks.size] = "specialty_holdbreath";
	level.default_perks[level.default_perks.size] = "specialty_quieter";
	level.default_perks[level.default_perks.size] = "specialty_parabolic";
	
	//following perks are no perks per se (i can not check them)
	//the game replaces them with weapons
	//level.default_perks[level.default_perks.size] = "specialty_weapon_c4";
	//level.default_perks[level.default_perks.size] = "specialty_weapon_rpg";
	//level.default_perks[level.default_perks.size] = "specialty_weapon_claymore";
}

perkAllowedToAppearOnHud(perk)
{
	switch(perk)
	{
		case "perk_quickrevive":
		case "perk_tombstone":
		case "specialty_fastreload":
		case "specialty_rof":
		case "specialty_armorvest":
			return true;
		
		default: return false;
	}
}

getDefaultPerkOfZombiePerk(name)
{
	if(isDefaultPerk(name))
		return name;

	if(name == "perk_doubletap")
		return "specialty_rof";
	else if(name == "perk_fastreload")
		return "specialty_fastreload";

	return name;
}

isDefaultPerk(name)
{
	for(i=0;i<level.default_perks.size;i++)
	{
		if(name == level.default_perks[i])
			return true;
	}
	
	return false;
}

isZombiePerk(name)
{
	for(i=0;i<level.zombie_perks.size;i++)
	{
		if(name == level.zombie_perks[i])
			return true;
	}
	
	return false;
}

setZombiePerk(name)
{
	name = getDefaultPerkOfZombiePerk(name);

	if(isDefaultPerk(name))
		self setPerk(name);
	else if(isZombiePerk(name))
		self.zombiePerks[self.zombiePerks.size] = name;
		
	self addPerkToHud(name);
}

hasZombiePerk(name)
{
	self endon("disconnect");

	name = getDefaultPerkOfZombiePerk(name);

	if(isDefaultPerk(name))
		return self hasPerk(name);

	if(!self.zombiePerks.size)
		return false;

	for(i=0;i<self.zombiePerks.size;i++)
	{
		if(name == self.zombiePerks[i])
			return true;
	}
	
	return false;
}

unsetZombiePerk(name, keepHud)
{
	self endon("disconnect");

	if(!isDefined(keepHud))
		keepHud = false;

	name = getDefaultPerkOfZombiePerk(name);
	
	if(!keepHud)
		self removePerkFromHud(name, true);
	else
		self disablePerkOnHud(name);

	if(isDefaultPerk(name))
		self unsetPerk(name);

	if(keepHud)
		self.zombiePerksDisabled[self.zombiePerksDisabled.size] = name;

	if(!self.zombiePerks.size)
		return;

	for(i=0;i<self.zombiePerks.size;i++)
	{
		if(name == self.zombiePerks[i])
		{		
			self.zombiePerks[i] = undefined;
			break;
		}
	}

	self.zombiePerks = RemoveUndefinedEntriesFromArray(self.zombiePerks);
}

clearZombiePerks()
{
	self endon("disconnect");

	for(i=0;i<level.default_perks.size;i++)
	{
		//do not take this perk
		if(level.default_perks[i] == "specialty_pistoldeath")
			continue;
	
		if(self hasPerk(level.default_perks[i]))
			self removePerkFromHud(level.default_perks[i], false);
	}

	self clearPerks();

	if(!self.zombiePerks.size)
		return;

	for(i=0;i<self.zombiePerks.size;i++)
	{
		self removePerkFromHud(self.zombiePerks[i], false);
		self.zombiePerks[i] = undefined;
	}

	self.zombiePerks = RemoveUndefinedEntriesFromArray(self.zombiePerks);
}

loadVendingMachines()
{
	level.vendingMachines = getEntArray("vendingmachine", "targetname");

	//no vendingMachines found - check for rotu map
	if(!isDefined(level.vendingMachines) || !level.vendingMachines.size)
	{
		wait 2;
		
		if(isDefined(level.rotuVendingMachineName))
			level.vendingMachines = getEntArray(level.rotuVendingMachineName, "targetname");
	}

	//nothing found - return
	if(!isDefined(level.vendingMachines) || !level.vendingMachines.size)
		return;

	for(i=0;i<level.vendingMachines.size;i++)
		level.vendingMachines[i] thread initVendingMachine();
}

initVendingMachine()
{
	self endon("death");

	self.power = false;
	self.booting = false;
	self.isInUse = false;
	self.content = self.target;

	if(!isDefined(self.content)) //rotu
		self.content = "rotu_shop";
	else
	{
		self setModel("perkmachines");
		self hidePerkMachineParts();
	}
	
	while(!isDefined(game["tranzit"].powerEnabled) || !game["tranzit"].powerEnabled)
		wait .05;
		
	if(!self.power)
		self thread activateVendingMachine(false);
}

hidePerkMachineParts()
{
	if(self.content != "specialty_rof")
		self hidePart("tag_doubletap", self.model);

	if(self.content != "specialty_armorvest")
		self hidePart("tag_juggernaut", self.model);
			
	if(self.content != "perk_quickrevive")
		self hidePart("tag_quickrevive", self.model);

	if(self.content != "specialty_fastreload")
		self hidePart("tag_fastreload", self.model);
}

activateVendingMachine(localPowerSupply, delay)
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

	self.power = true;
	self.booting = false;
	self.isInUse = false;
	self.trigger = spawn("trigger_radius", self.origin - (0,0,25), 0, 50, 50);
	
	if(self.content == "rotu_shop")
		self thread randomPowerLightAndVendingSound();
	else
	{
		fxData = getVendingEffectDataForPerk(self.content);
	
		self thread switchOnPowerLight(fxData["lightFX"], fxData["lightFXTag"]);
		self thread PlayVendingSound(fxData["sound"], true, fxData["soundLength"]);
	}

	while(self.power)
	{
		self.trigger waittill("trigger", player);
		
		if(!self.power)
			break;
		
		if(self.isInUse)
			continue;
		
		if(!player isReadyToUse())
			continue;
		
		if(self.content == "rotu_shop")
		{
			player thread showTriggerUseHintMessage(self.trigger, player getLocTextString("PERK_VENDING_BUY_SODA"), undefined, " ");
		
			if(player UseButtonPressed())
			{
				while(player UseButtonPressed())
					wait .05;
			
				player closeMenu();
				player closeInGameMenu();
				player openMenu(game["menu_rotu_shop"]);
			}
		}
		else
		{
			if(player hasZombiePerk(self.content))
				continue;
			
			player thread showTriggerUseHintMessage(self.trigger, player getLocTextString("PERK_VENDING_BUY_SODA"), scripts\money::getPrice(self.content));

			if(!player scripts\money::hasEnoughMoney(self.content))
				continue;
			
			if(player UseButtonPressed())
			{
				self.isInUse = true;
			
				player thread useVendingMachine(self.content);
			
				self.isInUse = false;
			}
		}
	}
}

getVendingEffectDataForPerk(perk)
{
	data = [];
	switch(perk)
	{
		case "specialty_rof":
			data["lightFX"] = level._effect["light_on_yellow"];
			data["lightFXTag"] = "tag_doubletap_light";
			data["sound"] = "jingle_doubletap";
			data["soundLength"] = 5;
			break;
			
		case "specialty_armorvest":
			data["lightFX"] = level._effect["light_on_red"];
			data["lightFXTag"] = "tag_juggernaut_light";
			data["sound"] = "jingle_juggernaut";
			data["soundLength"] = 4;
			break;
			
		case "perk_quickrevive":
			data["lightFX"] = level._effect["light_on_blue"];
			data["lightFXTag"] = "tag_quickrevive_light";
			data["sound"] = "jingle_quickrevive";
			data["soundLength"] = 6;
			break;
			
		case "specialty_fastreload":
			data["lightFX"] = level._effect["light_on_green"];
			data["lightFXTag"] = "tag_fastreload_light";
			data["sound"] = "jingle_fastreload";
			data["soundLength"] = 4;
			break;
	}
	
	return data;
}

randomPowerLightAndVendingSound()
{
	self endon("death");
	
	perks = "specialty_rof,specialty_armorvest,perk_quickrevive,specialty_fastreload";
	perks = strToK(perks, ",");
	
	while(self.power)
	{
		fxData = getVendingEffectDataForPerk(perks[randomInt(perks.size)]);
	
		self thread switchOnPowerLight(fxData["lightFX"]);
		self PlayVendingSound(fxData["sound"], false, fxData["soundLength"]);
		
		wait .1;
	}
}

switchOnPowerLight(fx, tag)
{
	self endon("death");

	if(isDefined(self.fxEnt))
		self.fxEnt delete();

	if(isDefined(tag))
		self.fxEnt = spawnFx(fx, self getTagOrigin(tag));
	else
		self.fxEnt = spawnFx(fx, self.origin + (0,0,45) + AnglesToForward(self.angles)*10);

	//delay 1 is important, else we need a wait before this
	triggerFx(self.fxEnt, 1);
	
	//power on (again) - activate perk when bought earlier
	for(i=0;i<level.players.size;i++)
	{
		if(isDefined(level.players[i].zombiePerksDisabled))
		{
			for(j=0;j<level.players[i].zombiePerksDisabled.size;j++)
			{
				if(level.players[i].zombiePerksDisabled[j] == self.content)
					level.players[i] setZombiePerk(self.content);
			}
		}
	}
	
	while(self.power)
		wait 1;
		
	self.fxEnt delete();
	
	//no power - no perks
	for(i=0;i<level.players.size;i++)
		level.players[i] unsetZombiePerk(self.content, true);
}

PlayVendingSound(sound, looped, length)
{
	self endon("death");
	
	self notify("stop_vending_sound");
	self endon("stop_vending_sound");

	if(!isDefined(looped))
		looped = false;
		
	if(!isDefined(length))
		length = 0;

	while(self.power)
	{
		self PlaySoundRef(sound);
		wait (length + 5);
		
		if(!looped)
			break;
	}
	
	self notify("stop_vending_sound");
}

useVendingMachine(perk)
{
	self endon("disconnect");
	self endon("death");

	if(isDefined(self.isDrinkingSoda) && self.isDrinkingSoda)
		return;

	self.isDrinkingSoda = true;

	self thread [[level.onXPEvent]](perk);
	self GetInventory();
	
	self shoutOutPerk(perk);
	
	bottleWeapon = getWeaponFromCustomName("perksacola");
	self giveWeapon(bottleWeapon);
	self giveMaxAmmo(bottleWeapon);
	self switchToNewWeapon(bottleWeapon, .05);
	
	wait 2.2; //drink durating
	
	self setZombiePerk(perk);
	self takeWeapon(bottleWeapon);

	self GiveInventory();
	wait .1;
	self SwitchToPreviousWeapon();
	
	self.isDrinkingSoda = false;
}

shoutOutPerk(perk)
{
	switch(perk)
	{
		case "specialty_rof":
			self PlaySoundRef("gen_perk_dbltap");
			break;
			
		case "specialty_armorvest":
			self PlaySoundRef("gen_perk_jugga");
			break;
			
		case "perk_quickrevive":
			self PlaySoundRef("gen_perk_revive");
			break;
			
		case "specialty_fastreload":
			self PlaySoundRef("gen_perk_speed");
			break;
		
		default:
			break;
	}
}

addPerkToHud(perk)
{
	if(!perkAllowedToAppearOnHud(perk))
		return;

	if(!isDefined(self.perk_hud))
		self.perk_hud = [];
	
	//stop when it's just a disbaled perk
	for(i=0;i<self.perk_hud.size;i++)
	{
		if(self.perk_hud[i].perk == perk)
		{
			self.perk_hud[i].alpha = 1;
			return;
		}
	}
	
	hud = NewClientHudElem(self);
	hud.alignX = "left";
	hud.alignY = "bottom";
	hud.horzAlign = "left";
	hud.vertAlign = "bottom";
	hud.x = self.perk_hud.size * 30;
	hud.y = hud.y - 70;
	hud.sort = 1;
	hud.foreground = true;
	hud.hidewheninmenu = false;

	hud.perk = perk;
	hud SetShader(perk, 48, 48);

	hud.alpha = 0;
	hud scaleOverTime(0.5, 24, 24);
	hud fadeOverTime(0.5);
	hud.alpha = 1;
	
	self.perk_hud[self.perk_hud.size] = hud;
}

disablePerkOnHud(perk)
{
	if(!isDefined(self.perk_hud))
		return;

	for(i=0;i<self.perk_hud.size;i++)
	{
		if(self.perk_hud[i].perk == perk)
			self.perk_hud[i].alpha = 0.3;
		
	}
}

removePerkFromHud(perk, moveRemaining)
{
	tempArray = [];
	for(i=0;i<self.perk_hud.size;i++)
	{
		if(self.perk_hud[i].perk == perk)
			self.perk_hud[i] thread fadePerkHud(0.5);
		else
			tempArray[tempArray.size] = self.perk_hud[i];
		
	}
	
	self.perk_hud = tempArray;
	
	if(!isDefined(moveRemaining) || moveRemaining)
	{
		for(i=0;i<self.perk_hud.size;i++)
			self.perk_hud[i] movePerkHud(0+(i*30), self.perk_hud[i].y, 0.5);
	}
}

movePerkHud(x, y, time)
{
	self moveOverTime(time);
	self.x = x;
	self.y = y;
}

fadePerkHud(time)
{
	self fadeOverTime(time);
	self.alpha = 0;
	wait time;
	self destroy();
}