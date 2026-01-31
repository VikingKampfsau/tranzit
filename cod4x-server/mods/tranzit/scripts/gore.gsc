#include scripts\_include;

init()
{
	precacheShellshock("electrified");

	add_weapon("zombie_death_electric", "m14_reflex_mp", false);
	add_weapon("zombie_death_gravity", "m14_silencer_mp", false);

	add_effect("blood_headexplosion", "tranzit/gore/headexplode");
	add_effect("blood_legexplosion", "tranzit/gore/headexplode");
	add_effect("bloodspurt", "tranzit/gore/bloodspurt");
	
	add_effect("chainsaw_hit", "tranzit/chainsaw/chainsaw_blood_impact");
	add_effect("chainsaw_blood", "tranzit/chainsaw/chainsaw_blood_view");
	//add_effect("chainsaw_blood", "tranzit/chainsaw/chainsaw_blood_world");
	
	add_effect("dog_bite_death", "tranzit/zombie/dog_bite_death");
	add_effect("dog_bite_dmg", "tranzit/zombie/dog_bite_dmg");
	add_effect("dog_explosion", "tranzit/zombie/dog_explosion");
	
	add_effect("poisongas", "tranzit/zombie/quad_poisongas");
	add_effect("ground_fire_small_oneshot", "fire/ground_fire_small_oneshot");
	
	add_effect("player_torched", "fire/firelp_med_pm");
	add_effect("player_electrified", "tranzit/gore/electric_player_torso");
		
	add_effect("electric_bolt", "tranzit/gore/electric_bolt");
	add_effect("electric_shock", "tranzit/gore/electric_shock");
	add_effect("electric_shock_secondary", "tranzit/gore/electric_shock_secondary");
	
	add_effect("wavegun_body_explode", "tranzit/gore/wavegun_body_explode");
	
	add_sound("zombie_gib", "zombie_gib");
	add_sound("zombie_head_gib", "zombie_head_gib");
		
	add_sound("electric_impact", "electric_impact");
	add_sound("electric_arc_bounce", "electric_arc_bounce");
	
	add_sound("zapgun_cooking", "zapgun_cooking");
	add_sound("zapgun_ding", "zapgun_ding");

	//no idea yet how to use it
	add_sound("human_crunch", "human_crunch");
	
	level.electricDamageRadius = 400;
	level.electricDamageRadiusDecay = 20;
	level.electricDamageArcsMax = 5;
	level.electricDamageArcSpeed = 0.5;
	level.electricDamageMaxEnemies = 20;
	
	level.wavegunRadiusElectric = 250;
	level.wavegunRadiusGravity = 666;
}

/*--------------------------|
|  Damage & death behavior  |
|			(player)		|
|--------------------------*/
onSurvivorDamaged(sWeapon, sMeansOfDeath, sHitLoc, vPoint, eAttacker, eInflictor, noPainSound)
{
	if(!isDefined(noPainSound) || !noPainSound)
		self playSoundRef("gen_pain");

	if(!isDefined(eAttacker) || !eAttacker isAZombie())
		return;

	if(eAttacker.zombieType == "dog")
	{
		if(randomint(2))
			PlayFx(level._effect["dog_bite_dmg"], self getTagOrigin("j_spine4"));
		else
			PlayFx(level._effect["dog_bite_death"], self getTagOrigin("j_spine4"));
		
		return;
	}
	
	if(eAttacker.zombieType == "avagadro")
	{
		if(isDefined(sMeansOfDeath))
		{
			if(sMeansOfDeath == "MOD_MELEE")
				self thread electrifyPlayer(eAttacker, eInflictor, 0); //Melee Dmg is defined in weapon file
			else if(sMeansOfDeath == "MOD_PROJECTILE")
				self thread electrifyPlayer(eAttacker, eInflictor, game["tranzit"].avagadroRangeDamage);
		}
		
		return;
	}
}

onSurvivorKilled(attacker, sMeansOfDeath, sWeapon)
{
	self endon("disconnect");

	//last player died (in prone because of the hand anims)
	//the anim call is in playViewDeathAnim() in survivors.gsc
	if(level.aliveCount["allies"] <= 1)
	{
		//the game forces the player into thirdperson
		//to let them watch themselves die
		//cg_thirdperson_range is already set for
		//all players in killAllSurvivorsInLastStand()
		//self setClientDvar("cg_thirdpersonRange", 10);
		
		self.camera = spawn("script_model", self.origin);
		self.camera.angles = self.angles; //self getPlayerAngles();
		self linkTo(self.camera);
		
		self.camera.speed = 5; //tweak me
		self.camera.endPos = CharacterPhysicsTrace(true, self.camera.origin, self.camera.origin - AnglesToForward(self.camera.angles)*100);
		time = Distance(self.camera.origin, self.camera.endPos) / self.camera.speed;
		
		if(time < 0.05)
			time = 0.05;
		
		self.camera moveTo(self.camera.endPos, time);
		
		return;
	}
}

/*--------------------------|
|  Damage & death behavior  |
|			(zombie)		|
|--------------------------*/
zombiePainSound()
{
	self endon("disconnect");
	self endon("death");

	switch(self.zombieType)
	{
		case "avagadro": self playSoundRef("avagadro_pain"); break;
		case "human":
		case "dog":
		case "dwarf":
		case "quad":
		default: break;
	}
}

onZombieDamaged(sWeapon, sMeansOfDeath, sHitLoc, vPoint, eAttacker, eInflictor)
{
	if(!isDefined(self) || !isAlive(self))
		return;
	
	self thread zombiePainSound();
	
	if(!isDefined(sHitLoc) || !isDefined(sMeansOfDeath))
	{
		//iPrintLnBold("sHitLoc or sMeansOfDeath not defined");
		return;
	}
	
	if(self.zombieType != "human")
	{
		if(sWeapon == getWeaponFromCustomName("wunderwaffe") || sWeapon == getWeaponFromCustomName("wavegun") || sWeapon == getWeaponFromCustomName("wavegun_ug"))
			self [[level.callbackPlayerDamage]](eAttacker, eAttacker, self.health + 666, 0, "MOD_RIFLE_BULLET", sWeapon, self.origin, (0,0,0), "head", 0, "waveguned");
	
		//iPrintLnBold("not human zombie");
		return;
	}
	
	if(isDefined(sWeapon))
	{
		//iPrintLnBold(sWeapon);
	
		if(sMeansOfDeath == "MOD_MELEE")
			return;
	
		if(sWeapon == getWeaponFromCustomName("flamethrower"))
		{
			self thread torchPlayer();
			return;
		}
		else if(sWeapon == getWeaponFromCustomName("wunderwaffe"))
		{
			self thread electrifyZombie(eAttacker, true); 
			return;
		}
		else if(sWeapon == getWeaponFromCustomName("chainsaw"))
		{
			PlayFx(level._effect["chainsaw_blood"], vPoint);
			//do not return otherwise the zombie does not lose his legs when they are cut off
		}
		else
		{
			return;
		}
	}
	
	if(isExplosiveDamage(sMeansOfDeath))
	{
		//grenades and projectiles have sHitLoc = "none"
		//so let's fake it
		if(sHitLoc == "none")
		{
			distHead = Distance(vPoint, self.origin + (0,0,60));
			distTorso = Distance(vPoint, self.origin + (0,0,44));
			distKnees = Distance(vPoint, self.origin + (0,0,25));
		
			if(distHead < distTorso)
				sHitLoc = "head";
			else if(distKnees < distTorso)
				sHitLoc = "right_leg_upper";
			else
				sHitLoc = "torso_upper";
		}
	}
		
	switch(sHitLoc)
	{
		case "torso_lower":
		case "right_leg_upper":
		case "left_leg_upper":			
		case "right_leg_lower":
		case "left_leg_lower":
		case "right_foot":
		case "left_foot":
		{
			PlayFx(level._effect["blood_legexplosion"], self getTagOrigin("j_mainroot"));
		
			self playSoundRef("zombie_gib");
			self thread scripts\zombies::makeCrawler();
			break;
		}
		
		case "helmet":
		case "head":
		case "neck":
		case "torso_upper":
		case "right_arm_upper":
		case "left_arm_upper":
		case "right_arm_lower":
		case "left_arm_lower":
		case "right_hand":
		case "left_hand":
		case "gun":
		default: break;
	}
}

onZombieKilled(attacker, sMeansOfDeath, sWeapon)
{
	thread scripts\statistics::incStatisticValue("zombies_killed", 2417, 1);

	if(isDefined(self.eyeGlowFx))
		self.eyeGlowFx delete();

	//if(isDefined(self.damageTrigger))
	//	self.damageTrigger delete();

	if(self.zombieType == "avagadro")
	{
		if(isDefined(self.glowFxEnt))
			self.glowFxEnt delete();
	
		level.avagadro = undefined;
		PlayFx(level._effect["avagadro_disappear"], self.origin);
		self playSoundRef("avagadro_death");
	}
	else if(self.zombieType == "quad")
	{
		self playSoundRef("quad_explode");
		thread spawnPoisonCloud(self.origin);
	}
	else if(self.zombieType == "dog")
	{
		PlayFx(level._effect["dog_explosion"], self getTagOrigin("j_spine4"));
		
		self radiusDamage( self.origin, 100, 15, 5, self);
		self playSoundRef("dog_explode");
	}
	else if(self.zombieType == "dwarf")
	{
		thread scripts\statistics::incStatisticValue("screechers_killed", 2418, 1);
	
		PlayFx(level._effect["screecher_disappear"], self.origin);
		self playSoundRef("screecher_death");
		wait 1;	
		playSoundAtPosition("screecher_disappear", self.origin);
	}
	else if(self.zombieType == "human")
	{
		if(self.isCrawler)
		{
			self playSoundRef("crawler_death");
			return;
		}
	
		attackerShouting = randomInt(10);
		
		if(sMeansOfDeath != "MOD_HEAD_SHOT")
		{
			self playSoundRef("zom_death");
			
			if(!attackerShouting)
			{
				if(isExplosiveDamage(sMeansOfDeath))
					attacker playSoundRef("feedback_kill_explo");
				else if(sMeansOfDeath == "MOD_MELEE")
					attacker playSoundRef("special_melee_insta");
				else
				{
					random = randomint(4);
					if(random == 0)
						attacker playSoundRef("feedback_close");
					else if(random == 1)
						attacker playSoundRef("feedback_dmg_close");
					else if(random == 2)
						attacker playSoundRef("feedback_killstreak");
					else if(random == 3)
						attacker playSoundRef("gen_kill");	
				}
			}
		}
		else
		{
			if(level.zombieModels[self.zombieType][self.zombieTypeNo].gibhead == "")
				return;

			if(!isDefined(sWeapon))
				return;
				
			switch(WeaponClass(sWeapon))
			{
				case "mg":
				case "rifle":
				case "smg":
				case "spread":
					if(!attackerShouting)
						attacker playSoundRef("feedback_kill_headd");
				
					self playSoundRef("zombie_head_gib");
					PlayFxOnTag(level._effect["bloodspurt"], self, "j_head");
					PlayFx(level._effect["blood_headexplosion"], self getTagOrigin("j_head"));
				
					self detachAll();		
					self setModel(level.zombieModels[self.zombieType][self.zombieTypeNo].body);
					self attach(level.zombieModels[self.zombieType][self.zombieTypeNo].gibhead);
					break;
			
				case "pistol":
				default: break;
			}
		}
	}
}

/*--------------------------|
|  Damage & death behavior  |
|	(player & zombie)		|
|--------------------------*/
spawnCorpse(eInflictor, sMeansOfDeath, sWeapon, vDir, sHitLoc, deathAnimDuration)
{
	if(self isAZombie())
	{
		if(self.zombieType == "avagadro")
			return;
	}

	body = self clonePlayer(deathAnimDuration);
	if(self isOnLadder() || self isMantling())
		body startRagDoll();

	deathAnim = body getcorpseanim();
	deathAnimLength = getanimlength(deathAnim);
		
	self.body = body;
	self.body.isCorpse = true;

	if(sWeapon == getWeaponFromCustomName("wunderwaffe"))
	{
		tag = "J_SpineUpper";
		
		if(self.zombieType == "dog")
			tag = "J_Spine1";

		if(randomInt(2) > 0)
			fx = "electric_shock";
		else
			fx = "electric_shock_secondary";

		PlayFx(level._effect[fx], self getTagOrigin(tag));
		body playsound("electric_impact");
		
		wait (deathAnimLength);
	}
	else if(sWeapon == getWeaponFromCustomName("wavegun") || sWeapon == getWeaponFromCustomName("wavegun_ug"))
	{
		tag = "j_mainroot";
		fx = "ground_fire_small_oneshot";

		PlayFx(level._effect[fx], self.origin);
		body playsound("zapgun_cooking");

		wait (deathAnimLength);

		tag = "j_mainroot";
		fx = "wavegun_body_explode";
		
		if(isDefined(body))
		{		
			body playsound("zapgun_ding");
			PlayFx(level._effect[fx], body.origin);
			body delete();
		}
	}
	else
	{
		//normal corpse behavior
		thread maps\mp\gametypes\_globallogic::delayStartRagdoll(body, sHitLoc, vDir, sWeapon, eInflictor, sMeansOfDeath);
	}
}
/*--------------------------|
|		Damage behavior		|
|			(player)		|
|---------------------------|
|		Poision Gas			|
|--------------------------*/

spawnPoisonCloud(origin)
{
	playFx(level._effect["poisongas"], origin);

	time = 0;
	radius = 30;
	
	//this values need an adjustment depending on the effect
	maxtime = 30;
	maxradius = 230;
	
	while(1)
	{
		if(time >= maxtime)
			break;

		for(i=0;i<level.players.size;i++)
		{
			if(!isDefined(level.players[i]) || !isPlayer(level.players[i]))
				continue;
		
			if(level.players[i] isAZombie())
				continue;

			if(!isAlive(level.players[i]) || level.players[i] isInLastStand())
				continue;
		
			if(Distance(level.players[i].origin, origin) > radius)
				continue;
		
			if(	isDefined(level.players[i].facemask.active) && level.players[i].facemask.active &&
				isDefined(level.players[i].facemask.type) && level.players[i].facemask.type == "gas")
		
			level.players[i] thread inhalePoison(origin, maxradius);
		}
		
		if(radius < maxradius)
			radius += 20;

		time++;
		wait 0.5;
	}
}

inhalePoison(origin, maxradius)
{
	level endon("game_ended");
	level endon("game_will_end");
	
	self endon("disconnect");
	self endon("death");

	self thread poisonPainSound(origin, maxradius);
	self ShellShock("frag_grenade_mp", 1);
}

poisonPainSound(origin, maxradius)
{
	level endon("game_ended");
	level endon("game_will_end");

	self endon("death");
	self endon("disconnect");

	if(isDefined(self.AlreadyInhaled) && self.AlreadyInhaled)
		return;

	soundPlaying = false;

	while(1)
	{
		wait .1;
		
		//no damage when wearing the gas mask
		if(	isDefined(self.facemask.active) && self.facemask.active &&
			isDefined(self.facemask.type) && self.facemask.type == "gas")
			insideGas = false;
		else
			insideGas = (Distance(self.origin, origin) <= maxradius);
		
		if(!isDefined(insideGas))
			break;
		
		if(insideGas && !soundPlaying)
		{
			self PlayLocalSound("tabun_shock");
			soundPlaying = true;
		}
		else if(!insideGas)
		{
			self StopLocalSound("tabun_shock");
			self PlayLocalSound("tabun_shock_end");
			self.AlreadyInhaled = false;
			break;
		}
	}
}

/*--------------------------|
|		Damage behavior		|
|			(player)		|
|---------------------------|
|	Avagardo Lightning		|
|--------------------------*/

electrifyPlayer(eAttacker, eInflictor, iDamage)
{
	self endon("disconnect");

	if(!isDefined(self) || !isAlive(self))
		return;
	
	if(!isDefined(eAttacker))
		eAttacker = self;
		
	if(!isDefined(eInflictor))
		eInflictor = eAttacker;
	
	PlayFxOnTag(level._effect["player_electrified"], self, "j_spineLower");
	PlayFxOnTag(level._effect["player_electrified"], self, "j_spine4");

	self shellshock("electrified", 1.5);
	
	if(isDefined(iDamage) && iDamage > 0)
		self thread [[level.callbackPlayerDamage]](eInflictor, eAttacker, iDamage, 0, "MOD_RIFLE_BULLET", getWeaponFromCustomName("wunderwaffe"), self.origin, (0,0,0), "head", 0, "wunderwaffe");
}

/*--------------------------|
|		Damage behavior		|
|			(zombie)		|
|---------------------------|
|		Flamethrower		|
|--------------------------*/

torchPlayer()
{
	self endon("disconnect");
	self endon("death");
		
	if(self.isOnFire)
		return;
	
	if(!self playermodelHasTag("j_mainroot"))
		return;
	
	PlayFxOnTag(level._effect["player_torched"], self, "j_mainroot");
	
	self.isOnFire = true;
	while(self.isOnFire)
	{
		wait randomFloatRange(0.6, 1.1);

		for(i=0;i<level.players.size;i++)
		{
			if( self SightConeTrace(level.players[i] GetEye(), self) > 0 &&
				Distance(self.origin, level.players[i].origin) <= 90 &&
				isAlive(level.players[i])
				)
			{
				if(level.players[i].myAreaLocation > 0 && level.players[i].myAreaLocation < 900)
					level.players[i] thread [[level.callbackPlayerDamage]](level.players[i], level.players[i], 1, 0, "MOD_SUICIDE", "none", level.players[i].origin, (0,0,0), "head", 0, "torched");
			}
		}
	}
}

/*--------------------------|
|		Wunderwaffe			|
|--------------------------*/

electrifyZombie(attacker, radiusDmg)
{
	self endon("disconnect");
		
	if(self.isElectrified)
		return;

	if(!isDefined(attacker.electrifiedEnemies))
		attacker.electrifiedEnemies = 0;
		
	attacker.electrifiedEnemies = 1;
	
	if(isDefined(radiusDmg) && radiusDmg)
	{
		//iPrintLnBold("electrify him and all around");
		self electricArcDamage(self, attacker, 1);
	}
	else
	{
		//iPrintLnBold("electrify just him");
		self thread electricDamageShock(self, attacker, 1);
	}
	
	attacker.electrifiedEnemies = 0;
}

electricArcDamage(source_enemy, attacker, arc_num)
{
	//iPrintLnBold("damage him");

	//get all zombies within the damage radius
	enemies = self getEnemiesInElectricDamageRadius(level.electricDamageRadius - (level.electricDamageRadiusDecay * arc_num));

	//damage the zombie that was shot
	self thread electricDamageShock(source_enemy, attacker, arc_num);
	
	//damage all zombies within the damage radius 
	for(i=0;i<enemies.size;i++)
	{
		//iPrintLnBold("damage zombie in radius");
	
		//do not damage the zombie the electric arc comes from
		if(enemies[i] == self)
			continue;
		
		if(electricArcDamageEnd(arc_num + 1, attacker.electrifiedEnemies))
			continue;
		
		attacker.electrifiedEnemies++;

		//start a new arc from the damaged zombie
		enemies[i] electricArcDamage(self, attacker, arc_num + 1);
	}
}

electricArcDamageEnd(arc_num, enemies_hit_num)
{
	//max arc count reached
	if(arc_num >= level.electricDamageArcsMax)
		return true;

	//max enemy count (=kills) reached
	if(enemies_hit_num >= level.electricDamageMaxEnemies)
		return true;

	//no more zombies in damage radius
	if(level.electricDamageRadius - (level.electricDamageRadiusDecay * arc_num) <= 0)
		return true;

	return false;
}

getEnemiesInElectricDamageRadius(distance)
{
	zombies = [];
	for(i=0;i<level.players.size;i++)
	{
		if(level.players[i] == self)
			continue;
	
		if(level.players[i] isAZombie())
		{
			zombies[zombies.size] = level.players[i];
			continue;
		}
	}

	enemies = [];
	if(isDefined(zombies))
	{
		for(i=0;i<zombies.size;i++)
		{
			if(!isDefined(zombies[i]) || !isAlive(zombies[i]))
			{
				//iPrintLnBold("enemy check: not defined or not alive");
				continue;
			}

			if(isDefined(zombies[i].isElectrified) && zombies[i].isElectrified)
			{
				//iPrintLnBold("enemy check: already electrified");
				continue;
			}
			
			if(isDefined(zombies[i].zombieType) && zombies[i].zombieType == "avagadro")
			{
				//iPrintLnBold("enemy check: avagadro does not take electric damage");
				continue;
			}
	
			if(self.zombieType == "dog")
				sourcePos = self GetTagOrigin("J_Spine1");
			else
				sourcePos = self GetTagOrigin("J_SpineUpper");

			if(zombies[i].zombieType == "dog")
				targetPos = zombies[i] GetTagOrigin("J_Spine1");
			else
				targetPos = zombies[i] GetTagOrigin("J_SpineUpper");
			
			if(!isDefined(targetPos))
			{
				//iPrintLnBold("enemy check: no head found in model");
				continue;
			}

			if(Distance(targetPos, sourcePos) > distance)
			{
				//iPrintLnBold("enemy check: not in range " + Distance(origin, targetPos) + " / " + distance);
				continue;
			}

			if(!bulletTracePassed(targetPos, sourcePos, false, self))
			{
				trace = bulletTrace(targetPos, sourcePos, false, self);
				//iPrintLnBold("enemy check: trace failed: Fraction " + trace["fraction"] + " Start " + sourcePos + " End " + targetPos + " Hitpos " + trace["position"]);
				
				//i have no idea why it fails at 0.94-0.95 so let's do it that way
				if(trace["fraction"] < 0.9)
					continue;
			}

			enemies[enemies.size] = zombies[i];
		}
	}

	//iPrintLnBold("enemies: " + enemies.size);

	return enemies;
}

electricDamageShock(source_enemy, attacker, arc_num)
{
	//iPrintLnBold("damage called");

	self endon("disconnect");

	if(!isDefined(self) || !isAlive(self))
		return;
		
	if(!isDefined(attacker))
		return;

	if(!isDefined(attacker.electrifiedEnemies))
		attacker.electrifiedEnemies = 0;

	self.isElectrified = true;
	attacker.electrifiedEnemies++;

	if(arc_num > 1)
		wait RandomFloatRange(0.2, 0.6) * arc_num;

	if(source_enemy != self)
	{
		if(arc_num <= level.electricDamageArcsMax)
			source_enemy playElectricArcFx(self);
	}

	//return when the zombie died while the arc moving fx played
	if(!isDefined(self) || !isAlive(self))
		return;

	deathAnimWeapon = getWeaponFromCustomName("zombie_death_electric");

	self takeAllWeapons();
	self giveWeapon(deathAnimWeapon);
	self setSpawnWeapon(deathAnimWeapon);
	
	//get the origin the arc comes from
	origin = source_enemy.origin;
	if(!isDefined(origin) || source_enemy == self)
		origin = attacker.origin;

	wait .05; //make sure he has the weapon before he dies

	//return when the zombie died while waiting for his deathweapon
	if(!isDefined(self) || !isAlive(self))
		return;
	
	self [[level.callbackPlayerDamage]](attacker, attacker, self.health + 666, 0, "MOD_RIFLE_BULLET", getWeaponFromCustomName("wunderwaffe"), origin, (0,0,0), "head", 0, "electric bolt");
}

playElectricArcFx(target)
{
	if(!isDefined(self) || !isDefined(target))
	{
		wait(level.electricDamageArcSpeed);
		return;
	}
	
	//iPrintLnBold("play damage fx");

	if(self.zombieType == "dog")
		source_origin = self GetTagOrigin("J_Spine1");
	else
		source_origin = self GetTagOrigin("J_SpineUpper");

	if(target.zombieType == "dog")
		target_origin = target GetTagOrigin("J_Spine1");
	else
		target_origin = target GetTagOrigin("J_SpineUpper");

	if(Distance(source_origin, target_origin) < 59)
		return;
	
	fxEnt = spawn("script_model", source_origin);
	fxEnt SetModel("tag_origin");

	wait .05; //important to make fx visible
	
	PlayFxOnTag(level._effect["electric_bolt"], fxEnt, "tag_origin");
	playsoundatposition("electric_arc_bounce", fxEnt.origin);
	
	fxEnt moveTo(target_origin, level.electricDamageArcSpeed);
	fxEnt waittill("movedone");
	fxEnt delete();
}

/*--------------------------|
|			Wavegun			|
|--------------------------*/

microwaveImpact(impactPos, attacker, upgradeState)
{
	playSoundAtPosition("zapgun_impact", impactPos);
	playFx(level._effect["zapgun_impact"], impactPos);

	if(!isDefined(upgradeState))
		upgradeState = "normal";
	
	//normal = dual wield -> small electric damage and small gravity damage
	//upgrade = both pistols put together to a rifle -> bigger gravity damage
	
	if(upgradeState == "normal")
	{
		//get all zombies within the damage radius
		enemiesForElectricDmg = getEnemiesInMicrowaveDamageRadius(impactPos, 0, level.wavegunRadiusElectric);
		enemiesForGravityDmg = getEnemiesInMicrowaveDamageRadius(impactPos, level.wavegunRadiusElectric, level.wavegunRadiusGravity);

		//damage all zombies within the damage radius 
		for(i=0;i<enemiesForElectricDmg.size;i++)
			enemiesForElectricDmg[i] thread electricDamageShock(enemiesForElectricDmg[i], attacker, 1);
			
		for(i=0;i<enemiesForGravityDmg.size;i++)
			enemiesForGravityDmg[i] thread microwaveDamage(attacker);
	}
	else
	{
		//get all zombies within the damage radius
		enemies = getEnemiesInMicrowaveDamageRadius(impactPos, 0, level.wavegunRadiusGravity*1.25);

		//damage all zombies within the damage radius 
		for(i=0;i<enemies.size;i++)
			enemies[i] microwaveDamage(attacker);
	}
}

getEnemiesInMicrowaveDamageRadius(impactPos, minDist, maxDist)
{
	zombies = [];
	for(i=0;i<level.players.size;i++)
	{
		if(level.players[i] == self)
			continue;
	
		if(level.players[i] isAZombie())
		{
			zombies[zombies.size] = level.players[i];
			continue;
		}
	}

	enemies = [];
	if(isDefined(zombies))
	{
		for(i=0;i<zombies.size;i++)
		{
			if(!isDefined(zombies[i]) || !isAlive(zombies[i]))
			{
				//iPrintLnBold("enemy check: not defined or not alive");
				continue;
			}

			if(isDefined(zombies[i].isWaved) && zombies[i].isWaved)
			{
				//iPrintLnBold("enemy check: already waved");
				continue;
			}
			
			if(isDefined(zombies[i].isElectrified) && zombies[i].isElectrified)
			{
				//iPrintLnBold("enemy check: already electrified");
				continue;
			}
			
			if(isDefined(zombies[i].zombieType) && zombies[i].zombieType == "avagadro")
			{
				//iPrintLnBold("enemy check: avagadro does not take electric damage");
				continue;
			}

			if(zombies[i].zombieType == "dog")
				targetPos = zombies[i] GetTagOrigin("J_Spine1");
			else
				targetPos = zombies[i] GetTagOrigin("J_SpineUpper");

			if(!isDefined(targetPos))
			{
				//iPrintLnBold("enemy check: no head found in model");
				continue;
			}

			dist = Distance(targetPos, impactPos);

			if(dist <= minDist)
			{
				//iPrintLnBold("enemy check: to close " + Distance(impactPos, targetPos) + " / " + minDist);
				continue;
			}

			if(dist > maxDist)
			{
				//iPrintLnBold("enemy check: not in range " + Distance(impactPos, targetPos) + " / " + maxDist);
				continue;
			}

			if(!bulletTracePassed(targetPos, impactPos, false, self))
			{
				trace = bulletTrace(targetPos, impactPos, false, self);
				//iPrintLnBold("enemy check: trace failed: Fraction " + trace["fraction"] + " Start " + impactPos + " End " + targetPos + " Hitpos " + trace["position"]);
				
				//i have no idea why it fails at 0.94-0.95 so let's do it that way
				if(trace["fraction"] < 0.9)
					continue;
			}

			enemies[enemies.size] = zombies[i];
		}
	}

	//iPrintLnBold("enemies: " + enemies.size);

	return enemies;
}

microwaveDamage(attacker)
{
	self endon("disconnect");

	if(!isDefined(self) || !isAlive(self))
		return;
		
	if(!isDefined(attacker))
		return;

	self.isWaved = true;

	wait RandomFloatRange(0.1, 0.6);

	//return when the zombie died while the non-gravity kicks in
	if(!isDefined(self) || !isAlive(self))
		return;

	deathAnimWeapon = getWeaponFromCustomName("zombie_death_gravity");

	self takeAllWeapons();
	self giveWeapon(deathAnimWeapon);
	self setSpawnWeapon(deathAnimWeapon);
	
	//get the origin the damage came from
	origin = self.origin;
	if(!isDefined(origin) || isDefined(attacker))
		origin = attacker.origin;

	wait .05; //make sure he has the weapon before he dies

	//return when the zombie died while waiting for his deathweapon
	if(!isDefined(self) || !isAlive(self))
		return;
	
	self [[level.callbackPlayerDamage]](attacker, attacker, self.health + 666, 0, "MOD_RIFLE_BULLET", getWeaponFromCustomName("wavegun"), origin, (0,0,0), "head", 0, "microwaved");
}