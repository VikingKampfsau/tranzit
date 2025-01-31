#include maps\mp\_utility;
#include common_scripts\utility;
#include scripts\_include;

init()
{
	add_sound("Generator_deploy", "generator_deploy");
	add_sound("Generator_power", "generator_power");
	add_sound("Generator_destroy", "detpack_explo_default");

	add_effect("generator_explode", "explosions/grenadeExp_metal");

	level.Generators = [];

	level.GeneratorModel = "buildable_generator_complete";	//model for the turret
	level.GeneratorHealth = 80;						//health
	level.GeneratorAliveTime = 0;						//time the generator is active until self destruction

	precacheModel(level.GeneratorModel);
}

WaitForGeneratorDeploy(prevWeapon)
{
	self endon("disconnect");
	self endon("death");

	self thread OwnerEvents();
	self disableWeapons();

	self.GeneratorCarry = spawn("script_model", self.origin + (0,0,30) + AnglesToForward(self.angles)*75);
	self.GeneratorCarry.angles = (0, self.angles[1], self.angles[2]);
	self.GeneratorCarry linkTo(self);
	self.GeneratorCarry setModel(level.GeneratorModel);

	self.triesToPlantGenerator = false;
	
	while(self getCurrentWeapon() == getWeaponFromCustomName("generator") || self getCurrentWeapon() == "none") //when disableWeapons() kicks in the weapon switchs to "none"
	{
		self thread showUseHintMessage(self getLocTextString("GENERATOR_DEPLOY_PRESS_BUTTON"), "attack");
	
		if(self AttackButtonPressed())
		{
			if(self CanDeploy())
			{
				if(isDefined(self.GeneratorCarry))
				{
					self.GeneratorCarry unlink();
					self.GeneratorCarry delete();
					
					self takeActionSlotWeapon("craftable");
				}
				
				break;
			}

			while(self AttackButtonPressed())
				wait .05;
		}
		else if(self AdsButtonPressed())
		{
			if(isDefined(self.GeneratorCarry))
			{
				self.GeneratorCarry unlink();
				self.GeneratorCarry delete();
					
				self takeActionSlotWeapon("craftable");
			}
		
			self giveActionslotWeapon("craftable", getWeaponFromCustomName("generator"), 1);
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

	if(isDefined(self.triesToPlantGenerator) && self.triesToPlantGenerator)
		return false;
	
	self.triesToPlantGenerator = true;
	
	start = self.origin + (0,0,30) + vectorscale(anglesToForward( self.angles ), 50);
	end = self.origin + (0,0,30) + vectorscale(anglesToForward( self.angles ), 75);

	left = vectorscale(anglesToRight( self.angles ), -10);
	right = vectorscale(anglesToRight( self.angles ), 10);
	back = vectorscale(anglesToForward( self.angles ), -6);
	
	canPlantThere1 = BulletTracePassed( start, end, true, self.GeneratorCarry);
	canPlantThere2 = BulletTracePassed( start + (0,0,-7) + left, end + left + back, true, self.GeneratorCarry);
	canPlantThere3 = BulletTracePassed( start + (0,0,-7) + right , end + right + back, true, self.GeneratorCarry);
	
	trace = BulletTrace( end, end - (0,0,250), false, self.GeneratorCarry );

	if( !canPlantThere1 || !canPlantThere2 || !canPlantThere3 || trace["fraction"] == 1 )
	{
		self iPrintlnBold(self getLocTextString("GENERATOR_BAD_SPOT"));
		self.triesToPlantGenerator = false;
		return false;
	}
	
	self thread SpawnGenerator(trace["position"], (0,int(self getPlayerAngles()[1]),0));
	self.triesToPlantGenerator = false;
	return true;
}

SpawnGenerator(pos, angles)
{
	wasPickedUp = false;
	slot = level.Generators.size;
	
	if(isDefined(self.hasPickedUpGenerator))
	{
		wasPickedUp = true;
		slot = self.hasPickedUpGenerator;
		self.hasPickedUpGenerator = undefined;
	}
		
	level.Generators[slot] = spawn("script_model", pos);
	level.Generators[slot] setModel(level.GeneratorModel);
	level.Generators[slot].id = slot;
	level.Generators[slot].owner = self;
	level.Generators[slot].angles = angles;
	level.Generators[slot].TakenDamage = 0;
	level.Generators[slot].alivetime = level.GeneratorAliveTime;

	level.Generators[slot] PlaySoundRef("Generator_deploy");
	
	level.Generators[slot] thread PickupTrigger();
	level.Generators[slot] thread PlayLoopPowerSound("Generator_power", 7);
	
	level.Generators[slot] SetContents(1);
	
	if(!wasPickedUp)
		level.GeneratorPickupStorage[slot] = spawnStruct();
	else
	{
		if(isDefined(level.GeneratorPickupStorage[slot].old_alivetime))
			level.Generators[slot].alivetime = level.GeneratorPickupStorage[slot].old_alivetime;
			
		if(isDefined(level.GeneratorPickupStorage[slot].old_takenDamage))
			level.Generators[slot].TakenDamage = level.GeneratorPickupStorage[slot].old_takenDamage;
	}
	
	level.Generators[slot] thread AliveTime();
	level.Generators[slot] thread GeneratorDamageMonitor();
	level.Generators[slot] thread enableAffectedPowerEnts();
}

PlayLoopPowerSound(sound, length)
{
	self endon("death");

	wait .5;

	while(1)
	{
		self PlaySoundRef(sound);
		wait (length);
	}
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

		player thread showTriggerUseHintMessage(self.PickupTrigger, player getLocTextString("GENERATOR_PICKUP_PRESS_BUTTON"));
		
		if(player UseButtonPressed())
		{
			if(player hasActionSlotWeapon("craftable"))
				continue;

			if(isDefined(player.hasPickedUpGenerator))
				continue;
	
			player.hasPickedUpGenerator = self.id;
			player giveActionslotWeapon("craftable", getWeaponFromCustomName("generator"), 1);
			
			self thread DeleteGenerator(true);
			break;
		}	
	}
}

AliveTime()
{
	self endon("death");
	
	if(level.GeneratorAliveTime <= 0)
		return;
	
	if(self.alivetime <= 0)
		self.alivetime = .1;
	
	while(self.alivetime > 0 && isDefined(self))
	{
		self.alivetime -= .1;
		wait .1;
	}

	if(isDefined(self))
		self thread DeleteGenerator();
}

GeneratorDamageMonitor()
{
	self endon("death");

	self setCanDamage(true);

	self.health = 9999;

	if(!isDefined(self.TakenDamage))
		self.TakenDamage = 0;
	
	while(self.TakenDamage < level.GeneratorHealth)
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

		self.TakenDamage += damage;
		if(self.TakenDamage >= level.GeneratorHealth)
		{		
			self thread DeleteGenerator();
			break;
		}
	}
}

DeleteGenerator(wasPickedUp)
{
	if(isDefined(wasPickedUp) && wasPickedUp)
	{
		level.GeneratorPickupStorage[self.id].id = self.id;
		level.GeneratorPickupStorage[self.id].old_alivetime = self.alivetime;
		level.GeneratorPickupStorage[self.id].old_takenDamage = self.TakenDamage;
	}
	else
	{
		thread scripts\craftables::reactivateCraftedWeaponPickup(getWeaponFromCustomName("generator"));

		playFX(level._effect["generator_explode"], self getTagOrigin("tag_origin"));
		self PlaySoundRef("Generator_destroy");
	}
	
	self.PickupTrigger delete();
	
	self disableAffectedPowerEnts();
	self delete();
	
	RemoveUndefinedEntriesFromArray(level.Generators);
}

OwnerEvents()
{
	self endon("disconnect");
	
	self notify("Generator_player_event_handler");
	self endon("Generator_player_event_handler");
	
	self waittill_any("death", "end_respawn"); //("joined_spectators", "joined_team", "death", "spawned_player");
	
	if(isDefined(self.GeneratorCarry))
	{
		self.GeneratorCarry unlink();
		self.GeneratorCarry delete();
		self enableWeapons();
	}

	/*if(!isDefined(level.Generators) || !level.Generators.size)
		return;
	
	for(i=0;i<level.Generators.size;i++)
	{
		if(isDefined(level.Generators[i]) && level.Generators[i].owner == self)
			level.Generators[i] thread DeleteGenerator();
	}*/
}

enableAffectedPowerEnts()
{
	if(game["tranzit"].powerEnabled)
		return;

	self.affectedPowerEnts = [];

	entities = getEntArray();
	for(i=0;i<entities.size;i++)
	{
		if(!isDefined(entities[i].power))
			continue;
	
		if(self damageConeTrace(entities[i].origin, entities[i]) <= 0)
			continue;

		self.affectedPowerEnts[self.affectedPowerEnts.size] = entities[i];

		if(isInArray(level.vendingMachines, entities[i]))
			entities[i] thread scripts\perks::activateVendingMachine(true);
		else if(isInArray(level.packapunchMachines, entities[i]))
			entities[i] thread scripts\packapunch::activatePackAPunchMachine(true);
		else if(isInArray(level.scriptableLight, entities[i]))
			entities[i] thread scripts\power::lightUpScriptableLight(true);
	}
}

disableAffectedPowerEnts()
{
	if(game["tranzit"].powerEnabled)
		return;

	if(!isDefined(self.affectedPowerEnts) || self.affectedPowerEnts.size <= 0)
		return;

	for(i=0;i<self.affectedPowerEnts.size;i++)
	{
		if(game["tranzit"].powerEnabled)
			break;
	
		if(isDefined(self.affectedPowerEnts[i]))
			self.affectedPowerEnts[i].power = false;
	}
}

zombieCloseToGenerator()
{
	for(i=0;i<level.Generators.size;i++)
	{
		if(self isInGeneratorRadius(level.Generators[i]))
			return level.Generators[i];
	}
	
	return undefined;
}

isInGeneratorRadius(generator)
{
	if(!isDefined(generator))
		return false;

	if(Distance(self.origin, generator.origin) > 350)
		return false;

	if(self damageConeTrace(generator.origin, generator) <= 0)
		return false;
	
	return true;
}