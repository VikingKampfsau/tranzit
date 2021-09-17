#include maps\mp\_utility;
#include scripts\_include;

init()
{
	precacheHeadIcon("head_icon_revive");
	precacheModel("zombie_tombstone");

	add_weapon("syrette", "concussion_grenade_mp");

	level.lastStandReviveTime = 4;
	level.lastStandReviveDist = 50;
	level.lastStandBleedOutTime = 30;
}

putInLastStand(eInflictor, attacker, iDamage, sMeansOfDeath, sWeapon, vDir, sHitLoc, psOffsetTime, deathAnimDuration)
{
	if(level.playerCount["allies"] <= 1)
		return;

	if(self.zombieRankCounts > 0)
	{
		//self iPrintLnBOld("might reset zombieRankCounts");
	
		self.possibleZombieRankCountReset = true;
	}

	randomSurvivor = getRandomPlayer(game["defenders"]);
	
	if(randomSurvivor != self)
		randomSurvivor playSoundRef("gen_rebuild_board");

	self playSoundRef("revive_down_gen");

	self.health = 1;
	self.pers["downs"]++;
	self setStat(2402, self.pers["downs"]);
	
	self.lastStandParams = spawnstruct();
	self.lastStandParams.eInflictor = eInflictor;
	self.lastStandParams.attacker = attacker;
	self.lastStandParams.iDamage = iDamage;
	self.lastStandParams.sMeansOfDeath = sMeansOfDeath;
	self.lastStandParams.sWeapon = sWeapon;
	self.lastStandParams.vDir = vDir;
	self.lastStandParams.sHitLoc = sHitLoc;
	self.lastStandParams.lastStandStartTime = gettime();
	
	weaponslist = self getweaponslist();
	assertex( isdefined( weaponslist ) && weaponslist.size > 0, "Player's weapon(s) missing before dying -=Last Stand=-" );

	self thread maps\mp\gametypes\_gameobjects::onPlayerLastStand();

	newWeapon = "colt45_mp";
	grenadeTypePrimary = "frag_grenade_mp";

	// check if player has pistol
	for(i=0;i<weaponslist.size;i++)
	{
		if(isAPistol(weaponslist[i]))
		{
			newWeapon = weaponslist[i];
			break;
		}
	}

	self GetInventory();
	self takeallweapons();
	self giveWeapon(newWeapon);
	self giveMaxAmmo(newWeapon);
	self switchToWeapon(newWeapon);
	self GiveWeapon(grenadeTypePrimary);
	self SetWeaponAmmoClip(grenadeTypePrimary, 0);
	self SwitchToOffhand(grenadeTypePrimary);
	
	self scripts\perks::clearZombiePerks();
	
	self thread [[level.onXPEvent]]("laststand");
	
	self thread lastStandTimer(level.lastStandBleedOutTime);
}

lastStandTimer(delay)
{
	level endon("game_ended");
	self endon("death" );
	self endon("disconnect");
	self endon("game_ended");
	self endon("revived");

	self thread createReviveObject();
	
	self.lastStand = true;
	self thread showUseHintMessage(self getLocTextString("REVIVE_LAST_STAND"), "revive", undefined, undefined, delay);
	
	self saveHeadIcon();		
	self.headiconteam = self.pers["team"];
	self.headicon = "head_icon_revive";	
	
	self thread createBleedOutHud();

	wait delay;
	
	self thread LastStandBleedOut();
}

LastStandBleedOut()
{
	if(isDefined(self.bleedOverlay))
		self.bleedOverlay destroy();
	
	self clearLowerHintMessage();
	self deleteUseHintMessages();

	self.lastStand = false;
	self.useLastStandParams = true;
	self ensureLastStandParamsValidity();
	self suicide();
}

ensureLastStandParamsValidity()
{
	// attacker may have become undefined if the player that killed me has disconnected
	if ( !isDefined( self.lastStandParams.attacker ) )
		self.lastStandParams.attacker = self;
}

createBleedOutHud()
{
	self endon("disconnect");

	self.bleedOverlay = newclientHudElem(self);
	self.bleedOverlay.horzAlign = "fullscreen";
	self.bleedOverlay.vertAlign = "fullscreen";
	self.bleedOverlay.alignX = "left";
	self.bleedOverlay.alignY = "top";
	self.bleedOverlay.x = 0;
	self.bleedOverlay.y = 0;
	self.bleedOverlay.sort = 0;
	self.bleedOverlay.foreground = true;
	self.bleedOverlay.color = (0,1,0);
	self.bleedOverlay setShader("overlay_low_health", 640, 480);

	self.bleedOverlay.alpha = 0;
	self.bleedOverlay FadeOverTime(level.lastStandBleedOutTime * 2/3);
	self.bleedOverlay.alpha = 1;
}

createReviveObject()
{
	self endon("death");
	self endon("disconnect");

	self.HasMedic = false;

	reviveObj = spawn("script_model", self.origin);
	reviveObj.isInUse = false;
	reviveObj.isInUseBy = undefined;
	reviveObj.victim = self;

	if(isDefined(self.isOnTruck) && self.isOnTruck)
	{
		reviveObj linkTo(level.tranzitVehicle);
		self linkTo(reviveObj);
	}
	else
	{
		while(!self isOnGround())
			wait .05;
			
		reviveObj thread MoveReviveObj(self);
	}
	
	reviveObj thread monitorReviveAttempts();
}

MoveReviveObj(player)
{
	level endon("game_ended");
	self endon("death");

	if(!isDefined(player))
		return;
		
	if(!isAlive(player))
		return;
	
	player linkTo(self);
	
	newPos = player.origin + (0,0,5);
	for(i=0;;i++)
	{
		wait .1;
	
		if(i % 40)
		{
			if(isDefined(player.voice))
				player playSoundRef("gen_pain");
		}

		if(!isDefined(player) || !isAlive(player))
			break;
		
		if(player forwardButtonPressed())
			newPos += AnglesToForward((player.angles[0], player.angles[1], 0))*2;

		if(player backbuttonpressed())
			newPos -= AnglesToForward((player.angles[0], player.angles[1], 0))*2;
		
		if(player moveleftbuttonpressed())
			newPos -= AnglesToRight((player.angles[0], player.angles[1], 0))*2;
		
		if(player moverightbuttonpressed())
			newPos += AnglesToRight((player.angles[0], player.angles[1], 0))*2;

		newPos = PlayerPhysicsTrace(player.origin + (0,0,5), newPos);
		newPos = PlayerPhysicsTrace(newPos, newPos - (0,0,1000));
		
		if(newPos[2] < player.origin[2])
		{
			if(abs(newPos[2] - player.origin[2]) > level.lastStandReviveDist)
				continue;
		}

		self MoveTo(newPos, 0.1);
	}
}

monitorReviveAttempts()
{
	self endon("death");
		
	while(isDefined(self.victim) && isAlive(self.victim))
	{
		wait .1;
		
		if(!isDefined(self.victim) || !isAlive(self.victim))
			break;
		
		if(self.isInUse)
			continue;
		
		progress = 999;
		for(i=0;i<level.players.size;i++)
		{
			if(!isDefined(self.victim) || !isAlive(self.victim))
				break;

			if(Distance(level.players[i].origin, self.origin) > level.lastStandReviveDist)
				continue;
				
			if(!level.players[i] isReadyToUse())
				continue;
			
			if(self.victim == level.players[i])	
				continue;
			
			level.players[i] setLowerHintMessage(level.players[i] getLocTextString("REVIVE_HEAL_PRESS_BUTTON"), 1);
			level.players[i].lowerMessage SetPlayerNameString(self.victim);
						
			if(level.players[i] UseButtonPressed())
			{
				self.isInUse = true;
				self.isInUseBy = level.players[i];
			}
		}
		
		if(self.isInUse)
		{
			if(self.isInUseBy getCurrentWeapon() != getWeaponFromCustomName("syrette"))
				self.isInUseBy GetInventory();

			self.isInUseBy thread giveSyrette();
			progress = self.isInUseBy reviveProgress(self.victim);
			self.isInUseBy thread takeSyrette();
			
			if(!isDefined(self.victim) || !isAlive(self.victim))
				break;
		}

		if(isDefined(progress) && progress <= 0)
		{
			self.isInUseBy.pers["revives"]++;
			self.isInUseBy setStat(2403, self.isInUseBy.pers["revives"]);
			self.isInUseBy thread [[level.onXPEvent]]("laststand", undefined, -1);
		
			finishRevive(self);
			break;
		}
		
		self.isInUse = false;
		self.isInUseBy = undefined;
	}
	
	self delete();
}

reviveProgress(victim)
{
	timer = level.lastStandReviveTime;

	if(self scripts\perks::hasZombiePerk("perk_quickrevive"))
		timer /= 2;

	self.bar = self maps\mp\gametypes\_hud_util::createBar((1,1,1), 128, 8);
	self.bar maps\mp\gametypes\_hud_util::setPoint("CENTER", 0, 0, 0);
	self.bar maps\mp\gametypes\_hud_util::updateBar(0, 1/timer);
			
	self.isReviving = true;
	victim.HasMedic = true;
	
	//self disableWeapons();
	
	while(1)
	{
		wait .05;
		timer -= .05;
	
		if(!isDefined(self) || !isAlive(self))
			break;
			
		if(!self UseButtonPressed())
			break;
		
		if(timer <= 0)
			break;
		
		if(!isDefined(victim) || !isAlive(victim))
			break;
		
		if(Distance(victim.origin, self.origin) > level.lastStandReviveDist)
			break;
		
		if(victim != self)
		{
			if(self isInLastStand())
				break;
		}
	}

	if(isDefined(self))
	{
		self enableWeapons();
		self.isReviving = false;
	
		if(isDefined(self.bar))
			self.bar maps\mp\gametypes\_hud_util::destroyElem();
	}
	
	if(isDefined(victim))
	{
		victim.HasMedic = false;
		
		if(!isAlive(victim))
			victim restoreHeadIcon();
	}
	
	return timer;
}

finishRevive(reviveObj)
{
	//just in case it is still there (no idea why but it happens sometimes)
	reviveObj.isInUseBy.isReviving = false;
		
	if(isDefined(reviveObj.isInUseBy.bar))
		reviveObj.isInUseBy.bar maps\mp\gametypes\_hud_util::destroyElem();

	reviveObj.victim clearLowerHintMessage();
	reviveObj.victim reviveVictim();
}
	
reviveVictim()
{
	self endon("disconnect");
	self endon("death");

	self notify("revived");

	if(isDefined(self.bleedOverlay))
		self.bleedOverlay destroy();

	dropTarget = PlayerPhysicsTrace(self.origin + (0,0,5), self.origin);
	
	self spawn(dropTarget, self.angles);
	self playSoundRef("revive_revived");
	
	self.lastStand = false;
	self.useLastStandParams = undefined;
	self.health = self.maxhealth;

	self restoreHeadIcon();
	self GiveInventory();
	wait .1;
	self SwitchToPreviousWeapon();
	self scripts\perks::setZombiePerk("specialty_pistoldeath");
}

giveSyrette()
{
	self endon("disconnect");
	self endon("death");

	medicine = getWeaponFromCustomName("syrette");

	self TakeAllWeapons();
	self GiveWeapon(medicine);
	self SwitchToNewWeapon(medicine, .05);
	self freezeControls(true);
}

takeSyrette()
{
	self endon("disconnect");
	self endon("death");
	
	medicine = getWeaponFromCustomName("syrette");
	
	self TakeWeapon(medicine);		
	self GiveInventory();
	wait .1;
	self SwitchToPreviousWeapon();
	self freezeControls(false);
	self.isReviving = false;
}