#include maps\mp\_utility;
#include common_scripts\utility;
#include scripts\_include;

init()
{
	add_sound("sentry_gun_deploy", "sentry_gun_deploy");
	add_sound("sentry_gun_turning", "sentry_gun_turning");
	add_sound("sentry_gun_fire", "weap_rpd_turret_fire");
	add_sound("sentry_gun_destroy", "detpack_explo_default");

	add_effect("sentry_flash", "muzzleflashes/saw_flash_wv");
	add_effect("sentry_shell", "shellejects/saw");
	add_effect("sentry_blood", "impacts/flesh_hit_body_fatal_exit");
	add_effect("sentry_explode", "explosions/grenadeExp_metal");

	level.SentryGun = [];
	level.SentryPickupStorage = [];

	level.SentryModel = "buildable_turret_complete";	//model for the turret
	level.SentryAimMinDist = 10;						//the position in front of the turret the targeting starts
	level.SentryRotation = 100;							//max rotation angles (divide by 2 for each side)
	level.SentryHealth = 80;							//health
	level.SentryAimDist = 1000;							//distance to detect enemies
	level.SentryAimHeight = 1000;						//max height it can detect enemies in
	level.SentryFireDelay = 0.05;						//delay between 2 shots
	level.SentryAliveTime = 0;							//time the turret is active until self destruction
	level.SentryDetectionDot = abs(cos(level.SentryRotation));

	precacheModel(level.SentryModel);
}

WaitForSentryDeploy(prevWeapon)
{
	self endon("disconnect");
	self endon("death");

	self thread OwnerEvents();
	self disableWeapons();

	self.SentryCarry = spawn("script_model", self.origin + (0,0,30) + AnglesToForward(self.angles)*75);
	self.SentryCarry.angles = (0, self.angles[1], self.angles[2]);
	self.SentryCarry linkTo(self);
	self.SentryCarry setModel(level.SentryModel);

	self.triesToPlantSentry = false;
	
	while(self getCurrentWeapon() == getWeaponFromCustomName("sentrygun") || self getCurrentWeapon() == "none") //when disableWeapons() kicks in the weapon switchs to "none"
	{
		self thread showUseHintMessage(self getLocTextString("SENTRYGUN_DEPLOY_PRESS_BUTTON"), "attack");
	
		if(self AttackButtonPressed())
		{
			if(self CanDeploy())
			{
				if(isDefined(self.SentryCarry))
				{
					self.SentryCarry unlink();
					self.SentryCarry delete();
					
					self takeActionSlotWeapon("craftable");
				}
				
				break;
			}

			while(self AttackButtonPressed())
				wait .05;
		}
		else if(self AdsButtonPressed())
		{
			if(isDefined(self.SentryCarry))
			{
				self.SentryCarry unlink();
				self.SentryCarry delete();
					
				self takeActionSlotWeapon("craftable");
			}
		
			self giveActionslotWeapon("craftable", getWeaponFromCustomName("sentrygun"), 1);
			break;
		}

		wait .05;
	}
	
	self enableWeapons();
	
	if(isDefined(prevWeapon) && prevWeapon != "none")
		self switchToWeapon(prevWeapon);
}

//CanDeploy by Braxi
CanDeploy()
{
	self endon("disconnect");
	self endon("death");

	if(isDefined(self.triesToPlantSentry) && self.triesToPlantSentry)
		return false;
	
	self.triesToPlantSentry = true;
	
	start = self.origin + (0,0,30) + vectorscale(anglesToForward( self.angles ), 50);
	end = self.origin + (0,0,30) + vectorscale(anglesToForward( self.angles ), 75);

	left = vectorscale(anglesToRight( self.angles ), -10);
	right = vectorscale(anglesToRight( self.angles ), 10);
	back = vectorscale(anglesToForward( self.angles ), -6);
	
	canPlantThere1 = BulletTracePassed( start, end, true, self.SentryCarry);
	canPlantThere2 = BulletTracePassed( start + (0,0,-7) + left, end + left + back, true, self.SentryCarry);
	canPlantThere3 = BulletTracePassed( start + (0,0,-7) + right , end + right + back, true, self.SentryCarry);
	
	trace = BulletTrace( end, end - (0,0,250), false, self.SentryCarry );

	if( !canPlantThere1 || !canPlantThere2 || !canPlantThere3 || trace["fraction"] == 1 )
	{
		self iPrintlnBold("Bad spot!");
		self.triesToPlantSentry = false;
		return false;
	}
	
	self thread SpawnSentry(trace["position"], (0,int(self getPlayerAngles()[1]),0));
	self.triesToPlantSentry = false;
	return true;
}

SpawnSentry(pos, angles)
{
	wasPickedUp = false;
	slot = level.SentryGun.size;
	
	if(isDefined(self.hasPickedUpSentry))
	{
		wasPickedUp = true;
		slot = self.hasPickedUpSentry;
		self.hasPickedUpSentry = undefined;
	}
		
	level.SentryGun[slot] = spawn("script_model", pos);
	level.SentryGun[slot] setModel(level.SentryModel);
	level.SentryGun[slot] HidePart("tag_mower", level.SentryModel);
	level.SentryGun[slot].id = slot;
	level.SentryGun[slot].owner = self;
	level.SentryGun[slot].power = false;
	level.SentryGun[slot].angles = angles;
	level.SentryGun[slot].startangles = angles;
	level.SentryGun[slot].TakenDamage = 0;
	level.SentryGun[slot].alivetime = level.SentryAliveTime;
	level.SentryGun[slot].baseModel = level.SentryGun[slot];
	level.SentryGun[slot].firedelay = level.SentryFireDelay;
	level.SentryGun[slot].left_maxrotation = (int(angles[0]), int(angles[1]+level.SentryRotation/2), int(angles[2]));
	level.SentryGun[slot].right_maxrotation = (int(angles[0]), int(angles[1]-level.SentryRotation/2), int(angles[2]));
	
	level.SentryGun[slot].Bipod = spawn("script_model", pos);
	level.SentryGun[slot].Bipod setModel(level.SentryModel);
	level.SentryGun[slot].Bipod HidePart("tag_rpd", level.SentryModel);
	level.SentryGun[slot].Bipod HidePart("tag_ammo_box", level.SentryModel);
	level.SentryGun[slot].Bipod.angles = level.SentryGun[slot].angles;
	level.SentryGun[slot].Bipod.baseModel = level.SentryGun[slot];

	level.SentryGun[slot] PlaySoundRef("sentry_gun_deploy");
	level.SentryGun[slot] thread PickupTrigger();
	level.SentryGun[slot] thread monitorPower();
	level.SentryGun[slot] thread CoverArea();
	
	level.SentryGun[slot] SetContents(1);
	level.SentryGun[slot].Bipod SetContents(1);
	
	if(!wasPickedUp)
		level.SentryPickupStorage[slot] = spawnStruct();
	else
	{
		if(isDefined(level.SentryPickupStorage[slot].old_alivetime))
			level.SentryGun[slot].alivetime = level.SentryPickupStorage[slot].old_alivetime;
			
		if(isDefined(level.SentryPickupStorage[slot].old_takenDamage))
			level.SentryGun[slot].TakenDamage = level.SentryPickupStorage[slot].old_takenDamage;
	}
	
	level.SentryGun[slot] thread AliveTime();
	level.SentryGun[slot] thread SentryDamageMonitor();
	level.SentryGun[slot].Bipod thread SentryDamageMonitor();
}

PickupTrigger()
{
	self endon("death");
	
	self.PickupTrigger = spawn("trigger_radius", self.origin, 0, 50, 50);
	
	while(1)
	{
		self.PickupTrigger waittill("trigger", player);
		
		if(!player isReadyToUse())
			continue;

		player thread showTriggerUseHintMessage(self.PickupTrigger, player getLocTextString("SENTRYGUN_PICKUP_PRESS_BUTTON"));
		
		if(player UseButtonPressed())
		{
			if(player hasActionSlotWeapon("craftable"))
				continue;

			if(isDefined(player.hasPickedUpSentry))
				continue;
	
			player.hasPickedUpSentry = self.id;
			player giveActionslotWeapon("craftable", getWeaponFromCustomName("sentrygun"), 1);
			
			self thread DeleteSentry(true);
			break;
		}	
	}
}

monitorPower()
{
	self endon("death");
	
	power = false;
	while(1)
	{
		wait 1;
	
		power = false;
		for(i=0;i<level.Generators.size;i++)
		{
			if(isDefined(level.Generators[i]) && Distance(self.origin, level.Generators[i].origin) <= 350)
			{
				power = true;
				break;
			}
		}
		
		self.power = power;
	}
}

CoverArea()
{
	self endon("death");

	while(!isDefined(self.power) || !self.power)
		wait .1;

	trace = BulletTrace(self GetTagOrigin("tag_flash"), self GetTagOrigin("tag_flash") + AnglesToForward(self.angles)*999999999, false, self);
	self.SentryAimDist = distance(trace["position"], self GetTagOrigin("tag_flash"));

	if(self.SentryAimDist > level.SentryAimDist)
		self.SentryAimDist = level.SentryAimDist;

	self.SentryAimHeight = level.SentryAimHeight;
		
	trigger = spawn("trigger_radius", self GetTagOrigin("tag_flash") - (0, 0, self.SentryAimHeight), 0, self.SentryAimDist, self.SentryAimHeight*2);

	self.state = "observe";
	self.currenttarget = undefined;

	self thread Observing();
	
	while(1)
	{
		trigger waittill("trigger", player);

		if(!self.power)
			continue;
		
		if(isDefined(self.currenttarget) || self.state == "attack")
			continue;
		
		if(!isPlayer(player) || !isAlive(player))
			continue;
		
		if(player isASurvivor())
			continue;

		if(lengthSquared(player getVelocity()) < 10)
			continue;
			
		if(!player AffectingSentry(self))
			continue;

		self thread ShootTarget(player);
	}
}

Observing()
{
	self endon("death");
	
	delay = 0;
	self.TurningLeft = false;
	self.TurningRight = false;
	
	while(1)
	{
	wait 0.05;

		if(self.state != "observe")
			continue;
			
		if(!self.power)
			continue;

		//self PlaySoundRef("sentry_gun_turning");
		
		if(self.angles == self.startangles && !self.TurningLeft && !self.TurningRight)
		{
			delay = level.SentryRotation/60;
			acceal = int(delay/2*100)/100;
			deceal = delay - acceal;
		
			if(randomInt(2) == 0)
			{
				self.TurningLeft = true;
				self NewRotation(self.left_maxrotation, delay, acceal, deceal);
			}
			else
			{
				self.TurningRight = true;
				self NewRotation(self.right_maxrotation, delay, acceal, deceal);
			}
		}
		else
		{
			delay = level.SentryRotation/30;
			acceal = int(delay/1.6*100)/100;
			deceal = delay - acceal;
	
			if(self.TurningLeft)
			{
				self NewRotation(self.right_maxrotation, delay, acceal, deceal);
				self.TurningLeft = false;
				self.TurningRight = true;
			}
			else if(self.TurningRight)
			{
				self NewRotation(self.left_maxrotation, delay, acceal, deceal);
				self.TurningLeft = true;
				self.TurningRight = false;
			}
		}

	wait (delay+1);
	}
}

ShootTarget(target)
{
	self endon("death");

	self.state = "attack";
	self.currenttarget = target;
	
	self thread AimForTarget();
	
	i = 1;
	while(isDefined(self.currenttarget) && isAlive(self.currenttarget) && self.currenttarget AffectingSentry(self))
	{
		i++;

		if(int(i/2) == (i/2))
		{
			self PlaySoundRef("sentry_gun_fire");
			PlayFxOnTag(level._effect["sentry_flash"], self, "tag_flash");
			PlayFx(level._effect["sentry_shell"], self GetTagOrigin("tag_brass"), anglesToRight(self.angles));
		}

		//trace = BulletTrace(self GetTagOrigin("tag_flash"), self GetTagOrigin("tag_flash") + AnglesToForward(self.angles)*999999999, true, self);
		//if(isDefined(trace["entity"]) && trace["entity"] == self.currenttarget)
		if(self.currenttarget AffectingSentry(self, true))
		{
			if(isDefined(self.owner) && isPlayer(self.owner))
				self.currenttarget finishPlayerDamage(self, self.owner, 35, 0, "MOD_RIFLE_BULLET", getWeaponFromCustomName("sentrygun"), self GetTagOrigin("tag_flash"), VectorToAngles(self.currenttarget.origin - self GetTagOrigin("tag_flash")), "none", 0 );
			else
				self.currenttarget finishPlayerDamage(self, self.currenttarget, 35, 0, "MOD_RIFLE_BULLET", getWeaponFromCustomName("sentrygun"), self GetTagOrigin("tag_flash"), VectorToAngles(self.currenttarget.origin - self GetTagOrigin("tag_flash")), "none", 0 );

			PlayFx(level._effect["sentry_blood"], self.currenttarget GetTagOrigin("j_spine4"));
		}
		
		wait .05;
	}

	self.state = "observe";
	self.currenttarget = undefined;
}

AimForTarget()
{
	self endon("death");
	
	while(isDefined(self.state) && self.state == "attack")
	{
		if(!isDefined(self.currenttarget))
			break;
	
		dif = CalcDif(self.angles[1], self.currenttarget.angles[1]);
		time = 0.3;
		
		if(dif > 90 && dif <= 120)
			time = 0.2;
		else if(dif > 50 && dif <= 90)
			time = 0.1;
		else if(dif > level.SentryAimMinDist && dif <= 50)
			time = 0.05;
		
		self NewRotation(VectorToAngles(self.currenttarget.origin - self.origin), time);

	wait .05;
	}
}

AffectingSentry(sentry, checkDamageAngle)
{
	self endon("disconnect");
	self endon("death");

	pos = self getEye();
	
	dirToPos = pos - sentry GetTagOrigin("tag_flash");
	sentryForward = anglesToForward(sentry.angles);
	
	dist = vectorDot(dirToPos, sentryForward);
	if(dist < level.SentryAimMinDist)
		return false;
	
	//checks if the player can be seen by the sentry and is not behind a wall/entity
	if(self SightConeTrace(sentry GetTagOrigin("tag_flash"), self) <= 0.2)
		return false;

	//from claymore
	dirToPos = vectornormalize( dirToPos );
	
	dot = vectorDot( dirToPos, sentryForward );
	
	if(isDefined(checkDamageAngle) && checkDamageAngle)
		return ( dot > abs(cos(10)) );
		
	return ( dot > level.SentryDetectionDot );
}

AliveTime()
{
	self endon("death");
	
	if(level.SentryAliveTime <= 0)
		return;
	
	if(self.alivetime <= 0)
		self.alivetime = .1;
	
	while(self.alivetime > 0 && isDefined(self))
	{
		self.alivetime -= .1;
		wait .1;
	}

	if(isDefined(self))
		self thread DeleteSentry();
}

SentryDamageMonitor()
{
	self endon("death");

	self setCanDamage(true);

	self.health = 9999;

	if(!isDefined(self.baseModel.TakenDamage))
		self.baseModel.TakenDamage = 0;
	
	while(self.baseModel.TakenDamage < level.SentryHealth)
	{
		self waittill("damage", damage, attacker, vDir, vPoint, sMeansOfDeath);

		if(isPlayer(attacker) && attacker isASurvivor())
			continue;

		switch(sMeansOfDeath)
		{
			case "MOD_PROJECTILE":
			case "MOD_EXPLOSIVE":
			case "MOD_GRENADE": damage *= 3; break;
			case "MOD_MELEE": damage *= 2; break;
			default: break;
		}

		attacker thread maps\mp\gametypes\_damagefeedback::updateDamageFeedback(false);
		
		self.baseModel.TakenDamage += damage;
		if(self.baseModel.TakenDamage >= level.SentryHealth)
		{
			self.baseModel thread DeleteSentry();
			break;
		}
	}
}

DeleteSentry(wasPickedUp)
{
	//in case it's a pickup only
	self.TurningLeft = false;
	self.TurningRight = false;

	if(isDefined(wasPickedUp) && wasPickedUp)
	{
		level.SentryPickupStorage[self.id].id = self.id;
		level.SentryPickupStorage[self.id].old_alivetime = self.alivetime;
		level.SentryPickupStorage[self.id].old_takenDamage = self.TakenDamage;
	}
	else
	{
		thread scripts\craftables::reactivateCraftedWeaponPickup(getWeaponFromCustomName("sentrygun"));
	
		playFX(level._effect["sentry_explode"], self getTagOrigin("tag_origin"));
		self PlaySoundRef("sentry_gun_destroy");
	}
	
	self.PickupTrigger delete();
	self.Bipod delete();
	self delete();
}

OwnerEvents()
{
	self endon("disconnect");
	
	self notify("sentry_player_event_handler");
	self endon("sentry_player_event_handler");
	
	self waittill_any("death", "end_respawn"); //("joined_spectators", "joined_team", "death", "spawned_player");
	
	if(isDefined(self.SentryCarry))
	{
		self.SentryCarry unlink();
		self.SentryCarry delete();
		self enableWeapons();
	}

	/*if(!isDefined(level.SentryGun) || !level.SentryGun.size)
		return;
	
	for(i=0;i<level.SentryGun.size;i++)
	{
		if(isDefined(level.SentryGun[i]) && level.SentryGun[i].owner == self)
			level.SentryGun[i] thread DeleteSentry();
	}*/
}

NewRotation(newangles, time, acceal, decceal)
{
	self endon("death");
	self notify("sentry_newrotation");
	self endon("sentry_newrotation");

	if(self.angles[1] <= -360)
		self.angles = (self.angles[0], self.angles[1] + 360, self.angles[2]);
	if(self.angles[1] >= 360)
		self.angles = (self.angles[0], self.angles[1] - 360, self.angles[2]);
	
	if(isDefined(acceal) && isDefined(decceal))
		self RotateTo(newangles, time, acceal, decceal);
	else
		self RotateTo(newangles, time);
}


zombieCloseToSentrygun()
{
	self endon("disconnect");
	self endon("death");

	for(i=0;i<level.SentryGun.size;i++)
	{
		if(self isInSentrygunRadius(level.SentryGun[i]))
			return level.SentryGun[i];
	}
	
	return undefined;
}

isInSentrygunRadius(sentrygun)
{
	if(!isDefined(sentrygun))
		return false;

	if(Distance(self.origin, sentrygun.origin) > 350)
		return false;

	if(self damageConeTrace(sentrygun.origin, sentrygun) <= 0)
		return false;
	
	return true;
}