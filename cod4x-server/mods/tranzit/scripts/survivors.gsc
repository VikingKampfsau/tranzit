#include scripts\_include;

init()
{
	precacheShader("waypoint_empty");

	precacheShader("hud_overlay_claws_00");
	precacheShader("hud_overlay_claws_01");
	precacheShader("hud_overlay_claws_02");

	precacheShader("hint_mantle");

	precacheModel("viewmodel_hands_bare");

	level.surviormodels = [];
	
	initSurvivorModel("body_complete_mp_russian_farmer", "", true);
	initSurvivorModel("body_complete_mp_zakhaev", "", true);
	initSurvivorModel("body_complete_mp_zakhaevs_son_coup", "", true);
	initSurvivorModel("body_complete_mp_vip", "", true);
	//initSurvivorModel("body_mp_vip_pres", "head_mp_usmc_zack", false);
	
	if(getDvar("scr_knife_assist_range") == "")
		setDvar("scr_knife_assist_range", 128);
		
	if(getDvar("scr_knife_assist_angle") == "")
		setDvar("scr_knife_assist_angle", 15);
	
	/*the tranzit_extrafunctions plugin adds this new functions:
	player printWeaponState(); -> returns the current weaponState integer
	player isSwitchingWeapons(); -> returns if the player cycles weapons
	player isFiring(); -> returns if the player shoots
	player isMeleeing(); -> returns if the player melees
	player isReloading(); -> returns if the player reloads his weapon
	player isThrowingGrenade(); -> returns if the player throws a greande
	player isSprinting(); -> returns if the player sprints
	*/
}

initSurvivorModel(body, head, hasSilhouette)
{
	precacheModel(body);
	
	if(head != body && head != "")
		precacheModel(head);
	
	curEntry = level.surviormodels.size;
	level.surviormodels[curEntry] = spawnStruct();
	level.surviormodels[curEntry].entry = curEntry;
	level.surviormodels[curEntry].body = body;
	level.surviormodels[curEntry].head = head;
	
	if(isDefined(hasSilhouette) && hasSilhouette)
	{
		level.surviormodels[curEntry].silhouette = body + "_silhouette";
		precacheModel(level.surviormodels[curEntry].silhouette);
	}
}

spawnSurvivor()
{
	self endon("disconnect");

	self.maxhealth = 100;
	self.health = self.maxhealth;

	if(game["tranzit"].wave > 0)
		self.pers["lives"] = 0;

	//if(!self.wasAliveAtMatchStart)
	{
		if(game["tranzit"].wave > 6)
		{
			if(self.pers["score"] < game["tranzit"].score_latejoiner)
				self.pers["score"] = game["tranzit"].score_latejoiner;
		}
		else
		{
			if(self.pers["score"] < game["tranzit"].score_start)
				self.pers["score"] = game["tranzit"].score_start;
		}
	}
			
	self.score = self.pers["score"];
	self setStat(2400, self.score);

	self.perk_hud = [];
	self.headicon = "";
	self.godmode = false;
	self.banking = false;
	self.isDrinkingSoda = false;
	self.mantleInVehicle = false;
	self.underDwarfAttack = false;
	self.isNapalmBurning = false;
	self.dwarfOnShoulders = undefined;
	
	self.buyingWallweapon = false;
	
	self.actionSlotItem = undefined;
	self.actionSlotWeapon = undefined;
	self.actionSlotHardpoint = undefined;

	self.moveSpeedScale = 1.0;

	if(isDefined(self.bleedOverlay))
		self.bleedOverlay destroy();
		
	if(isDefined(self.mantleHintHud))
		self.mantleHintHud destroy();

	//not necessary - we detachAll right before the playermodel is set
	//self detachOldWeaponModels();
	
	self setSurvivorModel();
	self giveLoadout();

	self SetMoveSpeedScale(self.moveSpeedScale);

	self thread monitorSpeed();
	//self thread monitorMelee();
	self thread checkVehicle();
	//self thread watchForElevator(); //to much false positives
	self thread damagePlayerInFog();
	self thread monitorDiveToProne();
	self thread createClawDamageHud();
	self thread createPositionHudForTeam();
	
	//taken out
	//the silhouette is only visible when the player is in the same portal of the map
	//it's also not possible to show it to single players only
	//self thread createSilhouetteWhenNooneCanSeeHim();
	
	if(isDefined(level.tranzitVehicle))
		self thread createLocationHud();
	
	self scripts\perks::setZombiePerk("specialty_pistoldeath");
	
	self thread scripts\weather::playerWeather();
	self thread scripts\debug\valuedebugging::privateValueDebugHuds();
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
}

giveLoadout()
{
	self takeAllWeapons();
	self scripts\perks::clearZombiePerks();

	self giveWeapon(game["tranzit"].player_empty_hands, 0);

	self giveWeapon(game["tranzit"].player_start_weapon, 0);
	self giveMaxAmmo(game["tranzit"].player_start_weapon);

	if(game["tranzit"].playersReady)
		self setSpawnWeapon(game["tranzit"].player_start_weapon);
	else
	{
		self setSpawnWeapon(game["tranzit"].player_empty_hands);
		self thread survivorWakeUp();
	}
	
	self.pers["primaryWeapon"] = game["tranzit"].player_start_weapon;
	self.pers["secondaryWeapon"] = game["tranzit"].player_empty_hands;
	
	//also give 0 grenades to prepare the secondaryOffhand slot
	self giveWeapon("frag_grenade_mp");
	self setWeaponAmmoClip("frag_grenade_mp", 0);
	self switchToOffhand("frag_grenade_mp");

	//clear the actionSlots
	/*craftables (cod4: nightvision slot)*/	self SetActionSlot(1, ""); self.actionSlotItem = undefined;
	/*facemasks  (cod4: unused slot)*/		self SetActionSlot(2, ""); self.facemask = spawnStruct(); //DO NOT USE SetActionSlot() FOR THIS SLOT!
	/*explosives (cod4: c4/clay/rpg slot)*/	self SetActionSlot(3, ""); self.actionSlotWeapon = undefined;
	/*hardpoints (cod4: hardpoints slot)*/	self SetActionSlot(4, ""); self.actionSlotHardpoint = undefined;
	
	self thread scripts\battlechatter::monitorPlayerAmmo();
}

survivorWakeUp()
{
	self endon("disconnect");
	self endon("death");
	
	if(game["debug"]["status"] && !game["debug"]["playerAwakening"])
	{
		self.isAwake = true;
		return;
	}
	
	self.isAwake = false;
	
	self ShellShock("frag_grenade_mp", 10);
	self thread survivorWakeUpPainSound();
	
	//why doing a new hud when i can use an existing one ;)
	if(isDefined(self.maskToggleBg))
		self.maskToggleBg destroy();
	
	self.maskToggleBg = newClientHudElem(self);
	self.maskToggleBg.sort = -1;
	self.maskToggleBg.alignX = "left";
	self.maskToggleBg.alignY = "top";
	self.maskToggleBg.x = 0;
	self.maskToggleBg.y = 0;
	self.maskToggleBg.horzAlign = "fullscreen";
	self.maskToggleBg.vertAlign = "fullscreen";
	self.maskToggleBg.foreground = false;
	self.maskToggleBg setShader("black", 640, 480);
	
	while(self getStance() != "prone")
	{
		self freezeControls(false);
		self setStance("prone");
		wait .05;
		self freezeControls(true);
	}

	self freezeControls(true);
	self forceViewmodelAnimation("reload");

	self.maskToggleBg.alpha = 1;
	self.maskToggleBg fadeOverTime(2);
	self.maskToggleBg.alpha = 0;
	
	wait 8.2;
	
	while(self getStance() != "stand")
	{
		self freezeControls(false);
		self setStance("stand");
		wait .05;
		self freezeControls(true);
	}
	
	self freezeControls(true);
	
	wait .6;
	
	self forceViewmodelAnimation("raise");
	self.isAwake = true;
	
	//make sure I can move when just testing things on a map without zombies
	if(getDvarInt("developer") > 0)
		self freezeControls(false);
		
	if(isDefined(self.maskToggleBg))
		self.maskToggleBg destroy();
}

survivorWakeUpPainSound()
{
	self endon("disconnect");
	self endon("death");
	
	while(!self.isAwake)
	{
		self playLocalSound("breathing_hurt");
		wait .784;
		wait (0.1 + randomfloat (0.8));
	}
	
	self stopLocalSound("breathing_hurt");
	self playLocalSound("breathing_better");
}

playViewDeathAnim()
{
	self endon("disconnect");
	self endon("death");

	while(!self isOnGround())
		wait .05;

	//check if the player can go prone at the current position
	if(!self canGoProne(self isOnGround(), self getStance() == "prone"))
		self freezeControls(true);
	else
	{
		self takeAllWeapons();
		
		while(self getStance() != "prone")
		{
			self execClientCommand("goprone");
			wait .05;
		}
		
		self freezeControls(true);
		
		deathWeapon = getWeaponFromCustomName("player_death");
		
		self giveWeapon(deathWeapon);
		self switchToWeapon(deathWeapon);
	}
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
	origin_in_air = CharacterPhysicsTrace(true, self.origin + (0, 0, 2), self.origin + (0, 0, 60));
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
		if(isDefined(self.myLocArrow))
		{
			self.myLocArrow.x = self.origin[0];
			self.myLocArrow.y = self.origin[1];
			self.myLocArrow.z = self.origin[2] + 64;
		}
	
		self.velocity = self getVelocity();
		self.moveSpeed = length(self.velocity);
		wait .05;
	}
	
	//result: sprint is 285
}

monitorMelee()
{
	self endon("disconnect");
	self endon("death");
	
	while(1)
	{
		if(self isMeleeing())
		{
			if(weaponHasMeleeCharge(self getCurrentWeapon()))
				self thread activateKnifeAssist();
			
			while(self isMeleeing())
				wait .05;
		}
		
		wait .05;
	}
}

activateKnifeAssist()
{
	self endon("disconnect");
	self endon("death");
	self endon("stop_knifeassist");

	knife_maxRange = getDvarInt("player_meleeRange");
	if(knife_maxRange <= 0)
		return;

	knife_assist_maxRange = getDvarInt("scr_knife_assist_range");
	if(knife_assist_maxRange <= 0)
		return;
	
	knife_assist_maxAngle = getDvarInt("scr_knife_assist_angle");	
	if(knife_assist_maxAngle <= 0)
		return;
	
	targetInfo = [];
	targetInfo["alpha"] = undefined;
	targetInfo["player"] = undefined;
	targetInfo["vDirToTarget"] = undefined;
	for(i=0;i<level.players.size;i++)
	{
		if(level.players[i] == self)
			continue;
			
		if(!isAlive(level.players[i]))
			continue;
	
		if(!level.players[i] isAZombie())
			continue;
		
		vDist = Distance(self.origin, level.players[i].origin);		
		if(vDist > knife_assist_maxRange)
			continue;

		angleDiff = abs(maps\mp\gametypes\_missions::AngleClamp180(VectorToAngles(level.players[i].origin - self.origin)[1] - self getPlayerAngles()[1]));
		if(angleDiff > knife_assist_maxAngle)
			continue;

		//path to enemy clear?
		if( !BulletTracePassed(self.origin + (0,0,20), self.origin + (0,0,20) + AnglesToForward((0, self getPlayerAngles()[1], 0))*vDist, false, self) ||
			!BulletTracePassed(self.origin + (0,0,40), self.origin + (0,0,40) + AnglesToForward((0, self getPlayerAngles()[1], 0))*vDist, false, self) ||
			!BulletTracePassed(self.origin + (0,0,75), self.origin + (0,0,75) + AnglesToForward((0, self getPlayerAngles()[1], 0))*vDist, false, self))
			continue;

		//update the target
		if(!isDefined(targetInfo["alpha"]) || angleDiff < targetInfo["alpha"])
		{
			targetInfo["alpha"] = angleDiff;
			targetInfo["player"] = level.players[i];
			targetInfo["vDist"] = vDist;
			targetInfo["vDirToTarget"] = VectorToAngles(level.players[i].origin - self.origin);
		}
	}
	
	if(!isDefined(targetInfo["player"]) || !isAlive(targetInfo["player"]))
		return;
	
	//no lunge when close enough for default slash
	if(targetInfo["vDist"] <= knife_maxRange)
		return;
	
	//stop a jump
	if(!self isOnGround())
		self setOrigin(self.origin);

	trace = BulletTrace(self getEye(), self getEye() + AnglesToForward(self getPlayerAngles())*targetInfo["vDist"], true, self);
	
	//crosshair on enemy = teleport to player = damage
	if(isDefined(trace["entity"]) && trace["entity"] == targetInfo["player"])
	{
		//iPrintLnBold("crosshair on enemey");
		targetOrigin = targetInfo["player"].origin - AnglesToForward(targetInfo["vDirToTarget"])*knife_maxRange;
	}
	//crosshair NOT on enemy = teleport next to player = no damage
	else
	{
		//iPrintLnBold("crosshair NOT on enemey");
		targetOrigin = self.origin + AnglesToForward((0, self getPlayerAngles()[1], 0))*knife_assist_maxRange;
	}
	
	//sadly PlayerPhysicsTrace ignores characters so a trace is necessary first
	targetOrigin = BulletTrace(self.origin, targetOrigin, true, self)["position"];
	targetOrigin = PlayerPhysicsTrace(self.origin, targetOrigin);
	
	self setOrigin(targetOrigin);
	
	//apply the animations
	self forceViewmodelAnimation("meleecharge");
	self setWorldmodelAnim("torso", "pt_melee_pistol_2");
}

checkVehicle()
{
	self endon("disconnect");
	self endon("death");
	
	mantleSpot = undefined;
	
	while(1)
	{
		self.isOnTruck = scripts\vehicle::playerOnLoadingArea();
		
		if(!self.isOnTruck)
		{
			if(isDefined(level.tranzitVehicle) && isDefined(level.tranzitVehicle.mantleSpots) && isDefined(level.tranzitVehicle.mantleSpots[0]))
				mantleSpot = level.tranzitVehicle.mantleSpots[0];
		
			if(self scripts\vehicle::canMantleInVehicle(mantleSpot))
			{
				self thread scripts\survivors::showMantleHint();
			
				if(self jumpButtonPressed())				
					self scripts\vehicle::doMantleInVehicle();
			}
			else
			{
				if(isDefined(self.mantleHintHud))
					self.mantleHintHud destroy();
			}
		}
		else
		{
			if(isDefined(self.mantleHintHud))
				self.mantleHintHud destroy();
		}
		
		wait .05;
	}
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

damagePlayerInFog()
{
	self endon("disconnect");
	self endon("death");

	if(game["debug"]["status"] && game["debug"]["noFog"])
		return;

	wasInFog = false;
	soundPlayTime = 0;
	soundPlaying = false;
	lasthurttime = getTime();
	while(1)
	{
		wait .1;
	
		if(self scripts\maparea::isInPlayArea())
		{
			if(wasInFog)
			{
				wasInFog = false;
				
				if(soundPlaying)
				{
					soundPlayTime = 0;
					soundPlaying = false;
					self StopLocalSound("tabun_shock");
					self PlayLocalSound("tabun_shock_end");
				}
			}
		
			continue;
		}
	
		//no damage when wearing the gas mask
		if(	isDefined(self.facemask.active) && self.facemask.active &&
			isDefined(self.facemask.type) && self.facemask.type == "gas")
		{
			if(soundPlaying)
			{
				soundPlayTime = 0;
				soundPlaying = false;
				self StopLocalSound("tabun_shock");
				self PlayLocalSound("tabun_shock_end");
			}
		
			continue;
		}
	
		//no damage when riding the vehicle (that would just suck)
		if(isDefined(self.isOnTruck) && self.isOnTruck)
		{
			if(soundPlaying)
			{
				soundPlayTime = 0;
				soundPlaying = false;
				self StopLocalSound("tabun_shock");
				self PlayLocalSound("tabun_shock_end");
			}
		
			continue;
		}
	
		hurttime = getTime();
		randomizedTime = randomFloatRange(1.88, 2.33);
		if((hurttime - lasthurttime) < (randomizedTime*1000))
			continue;

		//restart the sound (tabun_shock has a length of 12 seconds)
		if(soundPlayTime > 12)
		{
			soundPlayTime = 0;
			soundPlaying = false;
		}

		if(!soundPlaying)
		{
			self PlayLocalSound("tabun_shock");
			soundPlaying = true;
		}

		iDamage = 2;
		wasInFog = true;
		soundPlayTime += (randomizedTime + 0.1);
		lasthurttime = hurttime;
				
		self ShellShock("frag_grenade_mp", 1);
		self [[level.callbackPlayerDamage]](self, self, iDamage, 0, "MOD_MELEE", "ak47_mp", self getEye(), VectorToAngles(self.origin - self getEye()), "none", 0, "without mask in fog", true, true);
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

createPositionHudForTeam(shader)
{
	self endon("death");
	self endon("disconnect");

	if(isDefined(self.myLocArrow))
		self.myLocArrow destroy();
	
	if(!isDefined(shader))
		shader = "waypoint_empty";
	
	self.myLocArrow = newTeamHudElem(self.pers["team"]);
	self.myLocArrow.x = self.origin[0];
	self.myLocArrow.y = self.origin[1];
	self.myLocArrow.z = self.origin[2];
	self.myLocArrow.isFlashing = false;
	self.myLocArrow.isShown = true;
	self.myLocArrow.baseAlpha = 1;
	self.myLocArrow.alpha = 1;
	self.myLocArrow.owner = self;
	self.myLocArrow.team = self.pers["team"];
	self.myLocArrow.target = self;
	self.myLocArrow setShader(shader, 15, 15);
	self.myLocArrow setWayPoint(false, shader);
	self.myLocArrow setTargetEnt(self.myLocArrow.target);
}

updatePositionHudForTeam(shader, alpha)
{
	if(!isDefined(shader))
		shader = "waypoint_empty";
	
	if(!isDefined(alpha))
		alpha = 1;
		
	self.myLocArrow setShader(shader, 15, 15);
	self.myLocArrow setWayPoint(false, shader);
	self.myLocArrow.baseAlpha = alpha;
	self.myLocArrow.alpha = alpha;
}

createSilhouetteWhenNooneCanSeeHim()
{
	self endon("disconnect");
	self endon("death");
	
	self.silhouette = false;
	
	while(1)
	{
		wait 1;
		
		//don't draw a silhouette when the player is alone
		if(level.aliveCount["allies"] == 1)
		{
			iPrintLnBold("only one player");
			continue;
		}
		
		drawSilhouette = true;
		for(i=0;i<level.players.size;i++)
		{
			//draw the silhouette when NO friendly player can see him, otherwise players who can see him will see a white skin
			if(level.players[i] isASurvivor())
			{
				if(level.players[i] == self)
					continue;
			
				visibilityAmount = self SightConeTrace(level.players[i] getEye(), level.players[i]);
				
				self iPrintLnBold(level.players[i].name + " can see you with " + visibilityAmount + "perc");
				
				if(visibilityAmount >= 0.1)
				{
					drawSilhouette = false;
					break;
				}
				
			}
		}
		
		//attach the silhouette model when it's not attached yet
		//dettach the silhouette model when it's attached only
		if(self.silhouette != drawSilhouette)
		{
			if(drawSilhouette)
				self setModel(level.surviormodels[self.curModelID].silhouette);
			else
				self setModel(level.surviormodels[self.curModelID].body);
			
			if(self.model == level.surviormodels[self.curModelID].silhouette)
				iPrintLnBold(self.name + " attached silhouette");
		}
		
		self.silhouette = drawSilhouette;
	}
}

createLocationHud()
{
	level endon( "game_ended" );

	self endon("disconnect");
	self endon("death");
	
	if(isDefined(self.locationTextHud))
		self.locationTextHud destroy();

	self.locationTextHud = NewClientHudElem(self);
	self.locationTextHud.font = "default";
	self.locationTextHud.fontScale = 1.4;
	self.locationTextHud.alignX = "left";
	self.locationTextHud.alignY = "top";
	self.locationTextHud.horzAlign = "left";
	self.locationTextHud.vertAlign = "top";
	self.locationTextHud.alpha = 0.75;
	self.locationTextHud.sort = 1;
	self.locationTextHud.x = 6;
	self.locationTextHud.y = 8;
	self.locationTextHud.archived = false;
	self.locationTextHud.foreground = true;
	self.locationTextHud.hidewheninmenu = true;
	self.locationTextHud.label = self getLocTextString("LOCATION_HUD_POS_UNKNOWN");

	locationName = undefined;
	if(isDefined(self.myAreaLocation))
	{
		locationName = scripts\maparea::getAreaNameFromID(self.myAreaLocation);
		if(isDefined(locationName))
		{
			self.locationTextHud.label = self getLocTextString("LOCATION_HUD_POS");
			self.locationTextHud setText(locationName);
		}
	}

	while(1)
	{
		prevLocation = self.myAreaLocation;

		wait 1;
	
		if(!isDefined(self.myAreaLocation))
		{
			self.locationTextHud.label = self getLocTextString("LOCATION_HUD_POS_UNKNOWN");
			self.locationTextHud setText("");
		}
		else
		{
			if(isDefined(prevLocation) && prevLocation == self.myAreaLocation)
				continue;
		
			locationName = scripts\maparea::getAreaNameFromID(self.myAreaLocation);
			if(isDefined(locationName))
			{
				self.locationTextHud.label = self getLocTextString("LOCATION_HUD_POS");
				self.locationTextHud setText(locationName);
			}
			else
			{
				self.locationTextHud.label = self getLocTextString("LOCATION_HUD_POS_UNKNOWN");
				self.locationTextHud setText("");
			}
		}
	}
}

showMantleHint()
{
	level endon( "game_ended" );

	self endon("disconnect");
	self endon("death");
	
	if(isDefined(self.mantleHintHud))
		self.mantleHintHud destroy();
	
	self.mantleHintHud = NewClientHudElem(self);
	self.mantleHintHud.font = "default";
	self.mantleHintHud.fontScale = 1.4;
	self.mantleHintHud.alignX = "right";
	self.mantleHintHud.alignY = "middle";
	self.mantleHintHud.horzAlign = "center";
	self.mantleHintHud.vertAlign = "middle";
	self.mantleHintHud.sort = 1;
	self.mantleHintHud.x = 65;
	self.mantleHintHud.y = 105;
	self.mantleHintHud.archived = false;
	self.mantleHintHud.foreground = true;
	self.mantleHintHud.hidewheninmenu = true;
	self.mantleHintHud.label = self getLocTextString("MANTLE_HINT");
	self.mantleHintHud setShader("hint_mantle", 40, 40);
	self.mantleHintHud.alpha = 1;
}