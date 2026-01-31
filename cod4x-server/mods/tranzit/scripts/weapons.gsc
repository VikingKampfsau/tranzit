#include scripts\_include;

init()
{
	precacheLocationSelector("map_artillery_selector");
	precacheShader("hud_temperature_gauge");
	precacheShellshock("animchanger");
	precacheShellshock("minigun");

	precacheModel("worldmodel_flametank");
	precacheModel("worldmodel_knife");

	add_weapon("alien_servant", "winchester1200_reflex_mp", true);
	add_weapon("fists", "defaultweapon_mp", false);
	add_weapon("player_death", "skorpion_reflex_mp", false);
	
	if(mapHasMinimap())
		add_weapon("location_selector", "location_selector_mp", false);
	else
		add_weapon("location_selector", "location_selector_grenade_mp", false);
	
	add_effect("turret_overheat_smoke", "distortion/armored_car_overheat");	
	add_effect("deathPortal_loop", "tranzit/raygun_mk3/fx_mk3_hole");
	add_effect("deathPortal_end", "tranzit/raygun_mk3/fx_mk3_dead");
	add_effect("zapgun_impact", "tranzit/zapguns/zapgun_impact");
	add_effect("smoke_location_marker", "red_smoke");
		
	add_sound("wpn_mk3_orb_creation", "wpn_mk3_orb_creation");
	add_sound("wpn_mk3_orb_loop", "wpn_mk3_orb_loop");
	add_sound("wpn_mk3_orb_disappear", "wpn_mk3_orb_disappear");
	add_sound("wpn_orb_damage", "wpn_orb_damage");
	
	add_sound("zapgun_impact", "zapgun_impact");
	
	level.minigun_minHeat = 60;
	level.minigun_maxHeat = 130;
	level.minigun_overheatRate = 1.26;
	level.minigun_cooldownRate = 0.95;
	
	level.deathPortals = [];
	
	if(!isDefined(level.mapSkyHeightScale))
		level.mapSkyHeightScale = 1;
}

/*----------------------|
|	Weapon Usage		|
|		(player)		|
|-----------------------*/

watchWeapons()
{
	level endon("game_ended");
	self endon("disconnect");
	self endon("death");
	
	if(self isAZombie())
	{
		self thread watchZombieWeaponUsage();
	}
	else
	{
		self thread watchSpecialUsage();
		self thread watchProjectileUsage();
	}
}

watchGrenadeUsage()
{
	self endon("disconnect");
	self endon("death");

	while(1)
	{
		self waittill("grenade_fire", grenade, weaponName);
		
		if(weaponName == getWeaponFromCustomName("emp_grenade"))
			grenade thread spawnEMPGrenade();
	}
}

watchProjectileUsage()
{
	level endon("game_ended");
	self endon("disconnect");
	self endon("death");
	
	while(1)
	{
		//just in case we already want to do something when the
		//weapon is fired
		self waittill("weapon_fired");
		
		curWeapon = self getCurrentWeapon();
		
		if(!isDefined(curWeapon) || curWeapon == "none")
			continue;
		
		if(weaponClass(curWeapon) == "rocketlauncher")
			self thread watchProjectileImpact();
	}
}

watchProjectileImpact()
{
	self endon("disconnect");

	launchPos = self getEye();

	self waittill("projectile_impact", weapon, impactPos /*, radius*/);

	if(weapon == getWeaponFromCustomName("raygun_ug"))
		thread createRaygunDeathPortal(launchPos, impactPos, self);
	else if(weapon == getWeaponFromCustomName("wavegun"))
		thread scripts\gore::microwaveImpact(impactPos, self, "normal");
	else if(weapon == getWeaponFromCustomName("wavegun_ug"))
		thread scripts\gore::microwaveImpact(impactPos, self, "upgraded");
}

watchSpecialUsage()
{
	level endon("game_ended");
	self endon("disconnect");
	self endon("death");

	if(!isDefined(self.minigun_huds))
		self.minigun_huds = [];

	minigunWeapon = getWeaponFromCustomName("minigun");
	chainsawWeapon = getWeaponFromCustomName("chainsaw");
	flamethrowerWeapon = getWeaponFromCustomName("flamethrower");
	
	self thread minigunOverheating(minigunWeapon);	
	
	while(1)
	{
		lastWeapon = self getCurrentWeapon();
		self waittill("weapon_change");
		curWeapon = self getCurrentWeapon();
	
		//iPrintLnBold("curWeapon " + curWeapon);
	
		if(	curWeapon == getWeaponFromCustomName("perksacola") ||
			curWeapon == getWeaponFromCustomName("syrette"))
		{
			self shellshock("animchanger", 0.05);
			continue;
		}
	
		if(curWeapon == getWeaponFromCustomName("location_selector"))
		{
			if(!isDefined(self.actionSlotHardpoint))
				continue;
			
			if(weaponType(getWeaponFromCustomName("location_selector")) == "grenade")
				self thread beginGrenadeLocationSelection(self.actionSlotHardpoint, lastWeapon);
			else
			{
				if(isDefined(self beginArtilleryLocationSelection(self.actionSlotHardpoint)))
					self takeActionSlotWeapon("hardpoint");
				
				if(isDefined(lastWeapon) && lastWeapon != "none")
					self switchToWeapon(lastWeapon);
			}
			
			continue;
		}
		
		if(curWeapon == minigunWeapon && lastWeapon != minigunWeapon)
		{
			self thread minigunAmmoCounter(minigunWeapon);
			self thread minigunOverheatHud();
			
			self shellshockAnimFix(curWeapon);
			self removeMinigunHud();
			continue;
		}
		
		if(curWeapon == chainsawWeapon && lastWeapon != chainsawWeapon)
		{
			self thread minigunAmmoCounter(chainsawWeapon);
		
			self shellshockAnimFix(curWeapon);
			self removeMinigunHud();
			continue;
		}
		
		if(curWeapon == flamethrowerWeapon && lastWeapon != flamethrowerWeapon)
		{
			self thread minigunAmmoCounter(flamethrowerWeapon);
		
			self shellshockAnimFix(curWeapon);
			self removeMinigunHud();
			continue;
		}
	}
}

/*-----------------------|
|		EMP Grenade		 |
|-----------------------*/

spawnEMPGrenade()
{
	finalPos = self.origin;
	while(isDefined(self))
	{
		finalPos = self.origin;
		wait .05;
	}
	
	maxEMPRadius = 200; //about 5 meters
	
	//kill the avagadro zombie when in range
	for(i=0;i<level.players.size;i++)
	{
		if(level.players[i] isAZombie() && isAlive(level.players[i]) && isDefined(level.players[i].zombieType) && level.players[i].zombieType == "avagadro")
		{
			if(Distance(level.players[i].origin, finalPos) <= maxEMPRadius)
				level.players[i] thread [[level.callbackPlayerDamage]](level.players[i], level.players[i], level.players[i].health + 666, 0, "MOD_RIFLE_BULLET", "none", level.players[i].origin, VectorToAngles(level.players[i].origin - level.players[i].origin), "head", 0, "EMPed");
		}
	}
	
	//destroy generators in range to shut down affected power entities
	if(isDefined(level.Generators) && level.Generators.size > 0)
	{	
		for(i=0;i<level.Generators.size;i++)
		{
			if(!isDefined(level.Generators[i]))
				continue;
		
			if(Distance(level.Generators[i].origin, finalPos) <= maxEMPRadius)
				level.Generators[i] thread scripts\generator::DeleteGenerator();
		}
	}
	
	wait .05; //give the DeleteGenerator threads some time to finish
	
	//disable all power entities in range
	entities = getEntArray();
	for(i=0;i<entities.size;i++)
	{
		if(!isDefined(entities[i].power))
			continue;

		if(Distance(entities[i].origin, finalPos) <= maxEMPRadius)
		{
			if(entities[i].power)
				entities[i].power = false;

			//reenable all power entities in range
			if(game["tranzit"].powerEnabled)
			{
				if(isInArray(level.vendingMachines, entities[i]))
					entities[i] thread scripts\perks::activateVendingMachine(false, 15);
				else if(isInArray(level.packapunchMachines, entities[i]))
					entities[i] thread scripts\packapunch::activatePackAPunchMachine(false, 15);
			}
		}
	}
}

/*--------------------------|
|		Zombie Weapons		|
|  like Avagadro lightnings	|
|--------------------------*/

watchZombieWeaponUsage()
{
	level endon("game_ended");
	self endon("disconnect");
	self endon("death");
	
	if(self.zombieType != "avagadro")
		return;
	
	while(1)
	{	
		self waittill("weapon_fired");
		
		curWeapon = self getCurrentWeapon();
		
		if(curWeapon == getWeaponFromCustomName("zombie_avagadro"))
		{
			if(isDefined(self.myTarget) && isPlayer(self.myTarget) && isAlive(self.myTarget))
			{
				self playSoundRef("avagadro_attack");
			
				//	/*self*/ thread fireElectricProjectile(self.myTarget);
				self thread guidElectricProjectile(self.myTarget);
			}
		}
	}
}

guidElectricProjectile(target)
{
	level endon("game_ended");

	tempRange = 99999999;
	electricBolt = undefined;

	projectiles = getEntArray("rocket", "classname");
	for(i=0;i<projectiles.size;i++)
	{
		if(!isDefined(self))
			return;
	
		dist = distance(self.origin, projectiles[i].origin);
	
		if(dist < tempRange)
		{
			tempRange = dist;
			electricBolt = projectiles[i];
		}
	}

	if(!isDefined(electricBolt))
		return;
		
	if(!isDefined(target) || !isPlayer(target) || !isAlive(target))
		return;

	electricBolt Missile_SetTarget(target, target getTagOrigin("j_spine4") - target.origin);
}

fireElectricProjectile(target)
{
	tag = "tag_weapon_right";
	if(!modelHasTag(self.model, tag))
	{
		tag = "tag_weapon_left";
		if(!modelHasTag(self.model, tag))
			return;
	}

	eletricBall = spawn("script_model", self getTagOrigin(tag));
	eletricBall setModel("tag_origin");
	
	wait .05;
	playFXOnTag(level._effect["avagadro_bolt"], eletricBall, "tag_origin");
	
	while(1)
	{
		if(!isDefined(target) || !isPlayer(target) || !isAlive(target))
			break;
		
		targetPos = target getTagOrigin("j_spine4");
		
		if(Distance(eletricBall.origin, targetPos) <= 39)
		{
			target thread scripts\gore::electrifyPlayer(/*self*/ undefined, eletricBall, game["tranzit"].avagadroRangeDamage);
			break;
		}
	
		time = (distance(eletricBall.origin, targetPos) / 150); //have to play around with the speed
		
		if(time < 0.05)
			time = 0.05;
		
		eletricBall moveTo(targetPos, time);
		
		wait .05;
	}
	
	if(isDefined(eletricBall))
		eletricBall delete();
}

/*------------------|
|		Minigun		|
|------------------*/

shellshockAnimFix(curWeapon)
{
	self thread minigunShellshock();	
	
	while(self getCurrentWeapon() == curWeapon)
		wait .05;
		
	self notify("end_shellshockAnimFix");
}

minigunShellshock()
{
	self endon("disconnect");
	self endon("death");
	self endon("end_shellshockAnimFix");
	
	//SHELLSHOCK WILL FIX THE 3RD PERSON ANIMATIONS (INFINITE LOOP) FOR MINIGUN AND CHAINSAW
	//WHEN SWITCHING WEAPONS / THROWING GRENADES PLAYER MODEL WILL FREEZE
	
	while(1)
	{	
		self shellshock("minigun", 0.05);
		wait .05;
	}
}

minigunAmmoCounter(weapon)
{
	self endon("end_minigun_ammo_watch");
	self endon("disconnect");
	self endon("death");
	
	// DISPLAY MINIGUN AMMO ON THE BOTTOM OF THE SCREEN
	// BECAUSE MINIGUN MAX AMMO IS 999 AND LOOKS STUPID
	// IF IT'S DISPLAYED AS BELTFED AMMO :/
	
	if(isDefined(self.minigun_huds["ammoCounter"]))
		self.minigun_huds["ammoCounter"] destroy();
		
	self.minigun_huds["ammoCounter"] =  NewClientHudElem(self);
	self.minigun_huds["ammoCounter"].font = "objective";
	self.minigun_huds["ammoCounter"].alignX = "right";
	self.minigun_huds["ammoCounter"].alignY = "bottom";
	self.minigun_huds["ammoCounter"].horzAlign = "right";
	self.minigun_huds["ammoCounter"].vertAlign = "bottom";
	self.minigun_huds["ammoCounter"].x = -12;
	self.minigun_huds["ammoCounter"].y = -12;
	self.minigun_huds["ammoCounter"].archived = true;
	self.minigun_huds["ammoCounter"].fontScale = 1.4;
	//self.minigun_huds["ammoCounter"].glowColor = (1, 0, 0);
	//self.minigun_huds["ammoCounter"].glowAlpha = 1;
	self.minigun_huds["ammoCounter"].foreground = true;
	self.minigun_huds["ammoCounter"].hidewheninmenu = true;
	self.minigun_huds["ammoCounter"] setValue(self getWeaponAmmoClip(weapon));
	self.minigun_huds["ammoCounter"].alpha = 1;
	
	while(1)
	{
		self waittill("weapon_fired"); //wait .05;
	
		self.minigun_huds["ammoCounter"] setValue(self getWeaponAmmoClip(weapon));
	}
}

minigunOverheating(minigunWeapon)
{
	self endon("disconnect");
	self endon("death");

	remainingClipSize = 0;

	increment = 0;
	iPercentage = 0;

	newColor = [];
	color_cold = (1.0, 0.9, 0.0);
	color_warm = (1.0, 0.5, 0.0);
	color_hot = (0.9, 0.16, 0.0);
	
	self.cooldown = false;
	self.overheat = 0;
	
	while(1)
	{
		if(self GetCurrentWeapon() == minigunWeapon  && (self getWeaponAmmoClip(minigunWeapon) > 0 || remainingClipSize > 0))
		{
			if(self AttackButtonPressed() && self getWeaponAmmoClip(minigunWeapon) > 0)
			{
				if(self.overheat < level.minigun_maxHeat && !self.cooldown)
					self.overheat += level.minigun_cooldownRate + level.minigun_overheatRate;
				else
				{
					//self ExecClientCommand("-attack");
					self.cooldown = true;
					
					remainingClipSize = self getWeaponAmmoClip(minigunWeapon);
					self setWeaponAmmoStock(minigunWeapon, remainingClipSize);
					self setWeaponAmmoClip(minigunWeapon, 0);
				}
			}
			
			if(self.cooldown)
			{
				if(isDefined(self.overheateffect))
					PlayFxOnTag(level._effect["turret_overheat_smoke"], self.overheateffect, "tag_origin");	
			}
		}
		
		if(self.cooldown)
		{
			if(self.overheat < level.minigun_minHeat)
			{
				self.cooldown = false;
				self setWeaponAmmoStock(minigunWeapon, 0);
				self setWeaponAmmoClip(minigunWeapon, remainingClipSize);
			}
		}

		if(isDefined(self.overheat))
		{
			if(self.overheat > 0)
			{
				self.overheat -= level.minigun_cooldownRate;
			
				if(self.overheat <= 0)
					self.overheat = 0;
			
				iPercentage = int(self.overheat/level.minigun_maxHeat*100);
				
				for(i=0;i<3;i++)
				{
					//cold
					if(iPercentage <= 40)
					{
						increment = (color_warm[i]-color_cold[i])/100;
						newColor[i] = color_cold[i]+(increment*iPercentage);
					}
					//warm
					else if(iPercentage > 40 && iPercentage <= 80)
					{
						increment = (color_hot[i]-color_warm[i])/100;
						newColor[i] = color_warm[i]+(increment*iPercentage);
					}
					//hot
					else
					{
						newColor[i] = color_hot[i];
					}
				}

				if(isDefined(self.minigun_huds["overheat_status"]))
				{
					self.minigun_huds["overheat_status"].alpha = 0.8;
					self.minigun_huds["overheat_status"].color = (newColor[0], newColor[1], newColor[2]);
					
					newScale = int((150 - int(4 + abs(self.minigun_huds["overheat_bg"].y - self.minigun_huds["overheat_status"].y))) / level.minigun_maxHeat * self.overheat);
					
					if(newScale <= 0)
						newScale = 1;
					
					self.minigun_huds["overheat_status"] ScaleOverTime( 0.05, 10, newScale);
				}
			}
		}

	wait .05;
	}
}

MinigunOverheatHud()
{
	self endon("disconnect");
	self endon("death");

	if(!isDefined(self.overheateffect))
	{
		self.overheateffect = spawn("script_model", (0,0,0));
		self.overheateffect setmodel("tag_origin");
		self.overheateffect.origin = self.origin;
		self.overheateffect.angles = self.angles;
		self.overheateffect linkto(self, "tag_weapon_right", (12,0,0), (0,0,0));
	}

	if(!isdefined(self.minigun_huds["overheat_bg"]))
	{
		self.minigun_huds["overheat_bg"] = newClientHudElem(self);
		self.minigun_huds["overheat_bg"].alignX = "right";
		self.minigun_huds["overheat_bg"].alignY = "bottom";
		self.minigun_huds["overheat_bg"].horzAlign = "right";
		self.minigun_huds["overheat_bg"].vertAlign = "bottom";
		self.minigun_huds["overheat_bg"].x = 2;
		self.minigun_huds["overheat_bg"].y = -120;
		self.minigun_huds["overheat_bg"] setShader("hud_temperature_gauge", 35, 150);
	}
	
	if(!isdefined(self.minigun_huds["overheat_status"]))
	{
		self.minigun_huds["overheat_status"] = newClientHudElem(self);
		self.minigun_huds["overheat_status"].alignX = "right";
		self.minigun_huds["overheat_status"].alignY = "bottom";
		self.minigun_huds["overheat_status"].horzAlign = "right";
		self.minigun_huds["overheat_status"].vertAlign = "bottom";
		self.minigun_huds["overheat_status"].x = -10;
		self.minigun_huds["overheat_status"].y = -154;
		self.minigun_huds["overheat_status"].color = (1,.9,0);
		self.minigun_huds["overheat_status"].alpha = 0;
		self.minigun_huds["overheat_status"] setShader("white", 10, 1);
	}
}

removeMinigunHud()
{
	self endon("disconnect");
	self endon("death");
	
	self notify("end_minigun_ammo_watch");
	
	if(isDefined(self.minigun_huds["ammoCounter"]))
		self.minigun_huds["ammoCounter"] destroy();

	if(isDefined(self.minigun_huds["overheat_bg"]))
		self.minigun_huds["overheat_bg"] destroy();

	if(isDefined(self.minigun_huds["overheat_status"]))
		self.minigun_huds["overheat_status"] destroy();

	if(isDefined(self.overheateffect))
		self.overheateffect delete();
}

/*--------------------------|
|		Upgraded Raygun		|
|		Death Portal		|
|--------------------------*/

createRaygunDeathPortal(from, to, owner)
{
	if(isDefined(to))
		playSoundAtPosition("wpn_mk3_orb_creation", to);

	if(!isDefined(from) || !isDefined(to) /*|| !isDefined(owner)*/)
		return;

	goBack = 40; //tweak me
	radius = 600; //tweak me
	duration = 30; //tweak me
	midpos = undefined;
	
	dir = vectorNormalize(to - from);
	midpos = to - (dir[0]*goBack, dir[1]*goBack, dir[2]*goBack);
	
	//check if there is already a deathportal around
	if(level.deathPortals.size > 1)
	{
		for(i=0;i<(level.deathPortals.size -1);i++)
		{
			if(Distance(midpos, level.deathPortals[i].origin) <= radius)
				return;
		}
	}
		
	//spawn it
	curEntry = level.deathPortals.size;
	level.deathPortals[curEntry] = spawnFx(level._effect["deathPortal_loop"], midpos);
	level.deathPortals[curEntry].owner = owner;
	level.deathPortals[curEntry].radius = radius;
	level.deathPortals[curEntry] thread absorbEntities(duration);
	
	triggerFx(level.deathPortals[curEntry], 0.1);
	
	level.deathPortals[curEntry] playLoopSoundRef("wpn_mk3_orb_loop");
	
	while(isDefined(level.deathPortals[curEntry]))
		wait .05;
	
	level.deathPortals = RemoveUndefinedEntriesFromArray(level.deathPortals);
}

absorbEntities(duration)
{
	self endon("death");
	
	while(1)
	{
		if(!isDefined(duration) || duration <= 0)
			break;
	
		self.affectedEnts = [];
		entities = getEntArray();

		for(i=0;i<entities.size;i++)
		{
			if(self damageConeTrace(entities[i].origin, entities[i]) <= 0)
				continue;
			
			if(entities[i].classname == "noclass" && isDefined(entities[i].isCorpse))
			{
				entities[i] delete();
				continue;
			}
			
			if((isPlayer(entities[i]) && entities[i] isAZombie()) ||
				entities[i].classname == "grenade"
				)
			{
				self.affectedEnts[self.affectedEnts.size] = entities[i];
			}
		}
	
		if(!isDefined(self.affectedEnts) || !self.affectedEnts.size)
		{
			wait .5;
			continue;
		}
			
		for(i=0;i<self.affectedEnts.size;i++)
		{
			if(!isDefined(self.affectedEnts[i]))
				continue;
		
			dist = Distance2D(self.origin, self.affectedEnts[i].origin);
			if(dist <= 50)
			{
				if(!isPlayer(self.affectedEnts[i]))
					self.affectedEnts[i] delete();
				else
				{
					if(self.affectedEnts[i] isAZombie() && isAlive(self.affectedEnts[i]))
					{
						if(isDefined(self.owner) && isPlayer(self.owner))
							self.affectedEnts[i] thread [[level.callbackPlayerDamage]](self.owner, self.owner, self.affectedEnts[i].health + 666, 0, "MOD_RIFLE_BULLET", "ak47_mp", self.affectedEnts[i].origin, VectorToAngles(self.affectedEnts[i].origin - self.affectedEnts[i].origin), "head", 0, "killed by a portal");
						else
							self.affectedEnts[i] thread [[level.callbackPlayerDamage]](self.affectedEnts[i], self.affectedEnts[i], self.affectedEnts[i].health + 666, 0, "MOD_RIFLE_BULLET", "ak47_mp", self.affectedEnts[i].origin, VectorToAngles(self.affectedEnts[i].origin - self.affectedEnts[i].origin), "head", 0, "killed by a portal");
					}
				}
				
				self PlaySoundRef("wpn_orb_damage");
				
				self.affectedEnts[i] = undefined;
			}
			else if(dist <= self.radius)
			{
				//targetPos = self.affectedEnts[i].origin + AnglesToForward(VectorToAngles(self.origin - self.affectedEnts[i].origin)) * 40;
				//time = 0.1;
				
				targetPos = self.origin;
				time = float(dist/70);
				
				if(isPlayer(self.affectedEnts[i]))
				{
					if(self.affectedEnts[i] isAZombie())
						self.affectedEnts[i] playerMoveTo(targetPos, time, -25);
				}
				else
				{
					if(isSubStr(self.affectedEnts[i].classname, "script_"))
						self.affectedEnts[i] moveTo(targetPos, time);
					else
						self.affectedEnts[i] grenadeMoveTo(targetPos, time, 0);
				}
			}
		}
		
		self.affectedEnts = RemoveUndefinedEntriesFromArray(self.affectedEnts);
			
		wait .1;
		duration -= 0.1;
	}

	for(i=0;i<self.affectedEnts.size;i++)
	{
		if(self.affectedEnts[i] isAZombie() && isAlive(self.affectedEnts[i]))
			self.affectedEnts[i] unlink();
	}

	self stopLoopSound();

	playSoundAtPosition("wpn_mk3_orb_disappear", self.origin);
	playFx(level._effect["deathPortal_end"], self.origin);

	wait .05;

	self delete();
}

grenadeMoveTo(targetPos, time, offset)
{
	self endon("death");

	for(i=1;i<=(time/0.05);i++)
	{
		teleportTo = self.origin + (0,0,offset) + AnglesToForward(VectorToAngles(targetPos - self.origin))*(Distance(self.origin, targetPos)/i);
		self.origin = teleportTo;
	}
}

playerMoveTo(targetPos, time, offset)
{
	self endon("disconnect");
	self endon("death");

	linker = spawn("script_model", self.origin + (0,0,offset));
	
	self unlink(); //just in case
	self linkTo(linker);
	
	linker moveTo(targetPos, time);
	
	wait time;
	
	self unlink();
	linker delete();
}

/*--------------------------------------|
|				Airsupport				|
|		not added - but they work		|
|			will i ever add it?			|
|--------------------------------------*/
//honestly i prefer the smoke grenade - just like in 'kill the king'
//but this can also be used on maps with minimaps
beginArtilleryLocationSelection(supportType)
{
	self beginLocationSelection("map_artillery_selector");
	self.selectingLocation = true;

	self thread endSelectionOn("disconnect");
	self thread endSelectionOn("death");
	self thread endSelectionOn("determine_location");
	self thread endSelectionOn("cancel_location");
	self thread endSelectionOnGameEnd();

	self endon("stop_location_selection");
	self waittill("confirm_location", targetLocation); //targetLocation[2] is always 0, i'll fix that in each airsupport script
	
	used_map_artillery_selector = true;
	
	if(self confirmedLocationSelection(supportType, targetLocation, used_map_artillery_selector))
		return true;
	
	return false;
}

beginGrenadeLocationSelection(supportType, lastWeapon)
{
	self notify("beginGrenadeLocationSelection_only_once");
	self endon("beginGrenadeLocationSelection_only_once");

	self waittill("grenade_fire", grenade);

	self takeActionSlotWeapon("hardpoint");
	if(isDefined(lastWeapon) && lastWeapon != "none")
		self switchToWeapon(lastWeapon);

	targetLocation = grenade.origin;
	while(1)
	{
		wait .15;
		
		if(!isDefined(grenade))
			break;
		
		if(grenade.origin == targetLocation)
			break;
		
		targetLocation = grenade.origin;
	}
	
	used_map_artillery_selector = false;
	return self confirmedLocationSelection(supportType, targetLocation, used_map_artillery_selector);
}

confirmedLocationSelection(supportType, targetLocation, used_map_artillery_selector)
{
	self endon("disconnect");

	if(!isDefined(supportType))
		supportType = "airstrike";

	switch(supportType)
	{
		case "airstrike":
		case "napalm":
		{
			if(isDefined(level.airstrikeInProgress))
			{
				self iPrintLnBold(level.hardpointHints["airstrike_mp_not_available"]);
				self thread stopLocationSelection(false);
				return false;
			}
			
			self thread startAirSupport(supportType, targetLocation, used_map_artillery_selector, scripts\airstrike::useAirstrike);
			return true;
		}
		
		case "carepackage":
		{
			if(isDefined(level.carepackageInProgress))
			{
				self iPrintLnBold(level.hardpointHints["helicopter_mp_not_available"]);
				self thread stopLocationSelection(false);
				return false;
			}
			
			if(level.totalcps > level.maximumcps)
			{
				self iPrintLnBold(self getLocTextString("CAREPACKAGE_UNABLE_TO_CALL"));
				self thread stopLocationSelection(false);
				return false;
			}

			self thread startAirSupport(supportType, targetLocation, used_map_artillery_selector, scripts\carepackage::useCarepackageHeli);
			return true;
		}
		
		default: return false;
	}
}

startAirSupport(supportType, targetLocation, used_map_artillery_selector, usedCallback)
{
	self notify("determine_location");
	wait .05;
	self thread stopLocationSelection(false);
	self thread [[usedCallback]](supportType, targetLocation, used_map_artillery_selector);
}

endSelectionOn(waitfor)
{
	self endon("stop_location_selection");
	
	self waittill(waitfor);
	self thread stopLocationSelection((waitfor == "disconnect"));
}

endSelectionOnGameEnd()
{
	self endon("stop_location_selection");
	
	level waittill("game_ended");	
	self thread stopLocationSelection(false);
}

stopLocationSelection(disconnected)
{
	if(!isDefined(disconnected) || !disconnected)
	{
		self endLocationSelection();
		self.selectingLocation = undefined;
	}

	self notify("stop_location_selection");
}