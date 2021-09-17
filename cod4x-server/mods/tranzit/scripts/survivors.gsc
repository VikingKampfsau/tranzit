#include scripts\_include;

init()
{
	precacheShader("hud_overlay_claws_00");
	precacheShader("hud_overlay_claws_01");
	precacheShader("hud_overlay_claws_02");

	precacheModel("viewmodel_hands_bare");

	level.surviormodels = [];
	
	initSurvivorModel("body_complete_mp_russian_farmer", "");
	initSurvivorModel("body_complete_mp_zakhaev", "");
	initSurvivorModel("body_complete_mp_zakhaevs_son_coup", "");
	initSurvivorModel("body_complete_mp_vip", "");
	initSurvivorModel("body_mp_vip_pres", "head_mp_usmc_zack");
}

initSurvivorModel(body, head)
{
	precacheModel(body);
	
	if(head != body && head != "")
		precacheModel(head);
	
	curEntry = level.surviormodels.size;
	level.surviormodels[curEntry] = spawnStruct();
	level.surviormodels[curEntry].entry = curEntry;
	level.surviormodels[curEntry].body = body;
	level.surviormodels[curEntry].head = head;
}

spawnSurvivor()
{
	self endon("disconnect");

	self.maxhealth = 100;
	self.health = self.maxhealth;

	if(game["tranzit"].wave > 0)
		self.pers["lives"] = 0;

	if(game["tranzit"].wave > 6)
		self.pers["score"] = game["tranzit"].score_latejoiner;
	else
		self.pers["score"] = game["tranzit"].score_start;
			
	self.score = self.pers["score"];
	self setStat(2400, self.score);

	self.godmode = false;

	self.perk_hud = [];
	self.headicon = "";
	self.banking = false;
	self.isDrinkingSoda = false;
	self.mantleInVehicle = false;
	self.underDwarfAttack = false;
	self.dwarfOnShoulders = undefined;
	
	self.buyingWallweapon = false;
	
	self.actionSlotItem = undefined;
	self.actionSlotWeapon = undefined;
	self.actionSlotHardpoint = undefined;

	self.moveSpeedScale = 1.0;

	if(isDefined(self.bleedOverlay))
		self.bleedOverlay destroy();

	//not necessary - we detachAll right before the playermodel is set
	//self detachOldWeaponModels();
	
	self setSurvivorModel();
	self giveLoadout();

	self SetMoveSpeedScale(self.moveSpeedScale);

	self thread monitorSpeed();
	//self thread watchForElevator(); //to much false positives
	self thread monitorDiveToProne();
	self thread createClawDamageHud();
	self thread scripts\maparea::monitorMovementInMap();
	
	self scripts\perks::setZombiePerk("specialty_pistoldeath");
	
	self setClientDvar("ui_showStockScoreboard", 1); //remove this lince once there is a hook to hide the default scoreboard
}

detachOldWeaponModels()
{
	if(self hasAttached("worldmodel_riot_shield_iw5"))
		self detach("worldmodel_riot_shield_iw5", "tag_weapon_left");

	if(self hasAttached("worldmodel_knife"))
		self detach("worldmodel_knife", "tag_weapon_left");
}

getFreeSurvivorModel()
{
	curID = 0;
	for(i=0;i<level.players.size;i++)
	{
		if(self == level.players[i])
			continue;
			
		if(!isDefined(level.players[i].curModelID))
			continue;
		
		if(level.players[i].curModelID == curID)
		{
			curID++;
			i = -1;
		}
	}

	if(curID <= level.surviormodels.size)
		return curID;
	
	return randomInt(level.surviormodels.size);
}

setSurvivorModel()
{
	if(!isDefined(self.curModelID))
		self.curModelID = getFreeSurvivorModel();
	
	self detachAll();
	self setModel(level.surviormodels[self.curModelID].body);
	self setViewModel("viewmodel_hands_bare");
	
	if(isDefined(level.surviormodels[self.curModelID].head) && level.surviormodels[self.curModelID].head != "")
		self attach(level.surviormodels[self.curModelID].head);
		
	//for debugging
	if(getDvar("debug_zom_anims") != "")
	{
		self.zombieTypeNo = 0;
		self.zombieType = getDvar("debug_zom_anims");
		self thread scripts\zombies::setZombieModel();
	}
}

giveLoadout()
{
	self TakeAllWeapons();
	self scripts\perks::clearZombiePerks();

	self GiveWeapon(game["tranzit"].player_start_weapon, 0);
	self GiveMaxAmmo(game["tranzit"].player_start_weapon);
	self SetSpawnWeapon(game["tranzit"].player_start_weapon);
	
	self GiveWeapon(game["tranzit"].player_empty_hands, 0);
	
	self.pers["primaryWeapon"] = game["tranzit"].player_start_weapon;
	self.pers["secondaryWeapon"] = game["tranzit"].player_empty_hands;
	
	//also give 0 grenades to prepare the secondaryOffhand slot
	self giveWeapon("frag_grenade_mp");
	self setWeaponAmmoClip("frag_grenade_mp", 0);
	self switchToOffhand("frag_grenade_mp");

	//clear the actionSlots
	self SetActionSlot(1, ""); //craftables (nightvision)
	self SetActionSlot(3, ""); //explosives (c4 etc slot)
	self SetActionSlot(4, ""); //hardpoints (air support slot)
	self.actionSlotItem = undefined;
	self.actionSlotWeapon = undefined;
	self.actionSlotHardpoint = undefined;

	self thread scripts\battlechatter::monitorPlayerAmmo();
	
//for debugging
//self giveActionslotWeapon("hardpoint", "carepackage");
}

diveFromSprinting()
{
	if(self getStance() == "stand")
		return false;
		
	if(!self isOnGround())
		return false;
		
	if(!self isReadyToUse())
		return false;

	velocity = self GetVelocity();
	vector = abs(sqr(velocity[0]) + sqr(velocity[1]) + sqr(velocity[2]));
	vector = sqrt(vector); 
	
	if(self scripts\perks::hasZombiePerk("specialty_longersprint"))
	{
		switch(WeaponClass(self GetCurrentWeapon()))
		{
			case "pistol":
				self.dive_speed = 270;
				break;
			case "mg":
				self.dive_speed = 210;
				break;
			case "rifle":
				self.dive_speed = 210;
				break;
			case "smg":
				self.dive_speed = 250;
				break;
			case "spread":
				self.dive_speed = 210;
				break;
			default:
				self.dive_speed = 260;
				break;
		}
	}
	else
	{
		switch(WeaponClass(self GetCurrentWeapon()))
		{
			case "pistol":
				self.dive_speed = 230;
				break;
			case "mg":
				self.dive_speed = 180;
				break;
			case "rifle":
				self.dive_speed = 190;
				break;
			case "smg":
				self.dive_speed = 220;
				break;
			case "spread":
				self.dive_speed = 190;
				break;
			default:
				self.dive_speed = 240;
				break;
		}
	}
	
	if(vector > self.dive_speed)
		return true;

	return false;
}

monitorDiveToProne()
{
	self endon("disconnect");
	self endon("death");
	
	while(1)
	{
		if(self diveFromSprinting())
		{
			self disableWeapons();
			self AllowAds(false);
			self AllowSprint(false);
			
			highest_point = self diveToProne();
			wait .05;

			while(!self isOnGround())
				wait .05;
			
			//damage other entities when falling down 90 or more units
			if((highest_point[2] - self.origin[2]) >= 90 && self getStance() == "prone")
				RadiusDamage(self.origin, 18, (highest_point[2] - self.origin[2])/4, (highest_point[2] - self.origin[2])/4, undefined, "MOD_FALLING");
			
			self enableWeapons();
			self AllowAds(true);
			self AllowSprint(true);
			
			wait .1;
		}
		
		wait .05;
	}
}

diveToProne()
{
	self endon("disconnect");
	self endon("death");

	velocity_multiplier_fw = self.dive_speed;
	velocity_multiplier_up = (self.dive_speed/4)*2;
	self setStance("prone");
	
	wait .2;

	angles = self getPlayerAngles();
	angles = (0, angles[1], 0);
	origin_in_air = PlayerPhysicsTrace(self.origin + (0, 0, 2), self.origin + (0, 0, 60));
	self setOrigin(origin_in_air);
	self SetVelocity((anglesToUp(angles)*velocity_multiplier_up) + (AnglesToForward(angles)*velocity_multiplier_fw));
	
	return origin_in_air;
}

monitorSpeed()
{
	self endon("disconnect");
	self endon("death");
	
	self.moveSpeed = 0;
	
	while(1)
	{
		self.velocity = self getVelocity();
		self.moveSpeed = length(self.velocity);
		wait .05;
	}
	
	//result: sprint is 285
}

watchForElevator()
{
	self endon("disconnect");
	self endon("death");

	// 3 = best results so far
	//>3 = less false elevator detects but also less elevator detects in general
	//<3 = more false elevator detects but also more elevator detects in general
	offset = 3;
	detection = 0;
	curOrigin = self getOrigin();

	while(1)
	{
		prevpos = int(curOrigin[2]);
	
		wait .05;

		curOrigin = self getOrigin();

		if(self isOnGround() || self isOnLadder() || self isMantling())
			continue;
	
		if(self.velocity[2] == 0 && (prevpos > int(curOrigin[2]+offset) || prevpos < int(curOrigin[2]-offset)))
		{
			detection++;
		
			if(detection >= 3)
			{
				self iPrintLnBold(self getLocTextString("PUNISHMENT_ELEVATOR"));
				self suicide();
			}
			
			continue;
		}

		detection = 0;
	}
}

createClawDamageHud()
{
	self endon("disconnect");
	
	if(!isDefined(self.clawDmgHud))
		self.clawDmgHud = [];
		
	for(i=0;i<3;i++)
	{
		if(isDefined(self.clawDmgHud[i]))
			self.clawDmgHud[i] destroy();
	
		self.clawDmgHud[i] = NewClientHudElem(self);
		self.clawDmgHud[i].alignX = "left";
		self.clawDmgHud[i].alignY = "top";
		self.clawDmgHud[i].x = 0;
		self.clawDmgHud[i].y = 0;
		self.clawDmgHud[i].horzAlign = "fullscreen";
		self.clawDmgHud[i].vertAlign = "fullscreen";
		self.clawDmgHud[i].foreground = false;
		self.clawDmgHud[i].archived = true;
		self.clawDmgHud[i].sort = 0;
		self.clawDmgHud[i].alpha = 0;
		self.clawDmgHud[i] setShader("hud_overlay_claws_0" + i, 640, 480);
	}
}
	
updateClawDmgHud()
{
	self endon("disconnect");
	self endon("death");

	if(!isDefined(self.clawDmgHudUpdate))
		self.clawDmgHudUpdate = 0;

	if(self.clawDmgHudUpdate >= self.clawDmgHud.size)
		self.clawDmgHudUpdate = 0;

	self.clawDmgHud[self.clawDmgHudUpdate].alpha = 1;
	self.clawDmgHud[self.clawDmgHudUpdate] FadeOverTime(2);
	self.clawDmgHud[self.clawDmgHudUpdate].alpha = 0;

	self.clawDmgHudUpdate++;
}

destroyClawDmgHud()
{
	self endon("disconnect");
	self endon("spawned");

	if(!isDefined(self.clawDmgHud) || !self.clawDmgHud.size)
		return;
		
	for(i=0;i<3;i++)
	{
		if(isDefined(self.clawDmgHud[i]))
			self.clawDmgHud[i] destroy();
	}
}