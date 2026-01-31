#include scripts\_include;

init()
{
	//precacheModel("fake_hitbox_player_stand");

	add_weapon("zombie_dog", "ak47_gl_mp", false);
	add_weapon("zombie_dwarf", "g36c_gl_mp", false);
	add_weapon("zombie_human", "g3_gl_mp", false);
	add_weapon("zombie_quad", "m14_gl_mp", false);
	add_weapon("zombie_avagadro", "m16_gl_mp", false);
	
	add_weapon("player_dwarf_attacking", "m4_gl_mp", false);

	initZombieModel("quad", "bo_quad", "", "", "", "");
	initZombieModel("human", "body_zombie_01", "head_zombie_a", "body_zombie_01_upclean", "body_zombie_01_nolegs", "head_zombie_gib");
	initZombieModel("human", "body_zombie_01", "head_zombie_k", "body_zombie_01_upclean", "body_zombie_01_nolegs", "head_zombie_gib");
	initZombieModel("human", "body_zombie_01", "head_zombie_l", "body_zombie_01_upclean", "body_zombie_01_nolegs", "head_zombie_gib");
	initZombieModel("human", "body_zombie_01", "head_zombie_n", "body_zombie_01_upclean", "body_zombie_01_nolegs", "head_zombie_gib");
	initZombieModel("dog", "body_complete_zombie_hellhound", "", "", "", "");
	initZombieModel("dwarf", "body_complete_zombie_screecher", "", "", "", "");
	initZombieModel("avagadro", "body_complete_zombie_avagadro", "", "", "", "");
	
	add_effect("dog_ash_trail", "tranzit/zombie/dog_ash_trail");
	add_effect("dog_fire_trail", "tranzit/zombie/dog_fire_trail");
	add_effect("dog_breathe", "tranzit/zombie/dog_breathe");
	add_effect("dog_eye_glow", "tranzit/zombie/dog_eye_glow");
	add_effect("dog_lightning_spawn", "tranzit/zombie/dog_lightning_spawn");
	add_effect("dog_spawn_ground", "tranzit/zombie/dog_spawn_ground");
	add_effect("human_eye_glow", "tranzit/zombie/human_eye_glow");
	add_effect("human_spawn_dirt", "tranzit/zombie/human_spawn_dirt");

	add_effect("avagadro_appear", "tranzit/zombie/dog_lightning_spawn");
	add_effect("avagadro_disappear", "tranzit/zombie/dog_lightning_spawn");
	add_effect("avagadro_idle", "tranzit/trap/electric_trap");
	add_effect("avagadro_bolt", "tranzit/gore/electric_bolt");
	add_effect("avagadro_moving", "tranzit/zombie/avagadro_moving");

	add_effect("screecher_appear", "tranzit/zombie/screecher_disappear");
	add_effect("screecher_disappear", "tranzit/zombie/screecher_disappear");
	
	add_sound("spawn_dirt", "spawn_dirt");
	add_sound("spawn_lightning", "spawn_lightning");
	add_sound("avagadro_spawn", "avagadro_spawn");
	
	add_sound("zom_walk", "zom_walk");
	add_sound("zom_run", "zom_run");
	add_sound("zom_attack", "zom_attack");
	add_sound("zom_death", "zom_death");
	add_sound("zom_vocal", "zom_vocal");
	
	add_sound("dog_idle", "dog_idle");
	add_sound("dog_attack", "dog_attack");
	add_sound("dog_death", "dog_death");
	add_sound("dog_explode", "dog_explode");
	
	add_sound("crawler_attack", "crawler_attack");
	add_sound("crawler_death", "crawler_death");
	add_sound("crawler_walk", "crawler_walk");
	add_sound("crawler_vocal", "crawler_vocal");
	
	add_sound("quad_death", "quad_death");
	
	add_sound("screecher_attack", "screecher_attack");
	add_sound("screecher_death", "screecher_death");
	add_sound("screecher_disappear", "screecher_poof");
	
	add_sound("avagadro_attack", "avagadro_attack");
	add_sound("avagadro_death", "avagadro_death");
	add_sound("avagadro_pain", "avagadro_pain");
	add_sound("avagadro_loop", "avagadro_loop");
	add_sound("avagadro_warp_in", "avagadro_warp_in");
	add_sound("avagadro_warp_out", "avagadro_warp_out");
	
	level.avagadro = undefined;
	
	level.botMeleeDist = 64;
	level.botRangeAttackDist["avagadro"] = 512;
}

initZombieModel(type, body, head, crawlerTorso, crawlerGibLegs, GibHead)
{
	if(!isDefined(level.zombieModels))
		level.zombieModels = [];

	if(!isDefined(level.zombieModels[type]))
		level.zombieModels[type] = [];
	
	precacheModel(body);
	
	if(head != "")
		precacheModel(head);
	
	if(crawlerTorso != body && crawlerTorso != "")
		precacheModel(crawlerTorso);
		
	if(crawlerGibLegs != body && crawlerGibLegs != "")
		precacheModel(crawlerGibLegs);

	if(GibHead != "" && GibHead != head)
		precacheModel(GibHead);
	
	curEntry = level.zombieModels[type].size;
	level.zombieModels[type][curEntry] = spawnStruct();
	level.zombieModels[type][curEntry].entry = curEntry;
	level.zombieModels[type][curEntry].type = type;
	level.zombieModels[type][curEntry].body = body;
	level.zombieModels[type][curEntry].head = head;
	level.zombieModels[type][curEntry].crawler = crawlerTorso;
	level.zombieModels[type][curEntry].crawlerGibLegs = crawlerGibLegs;
	level.zombieModels[type][curEntry].gibhead = GibHead;
}

spawnWastelandDwarf(target)
{
	level endon( "game_ended" );

	dwarf = undefined;
	for(i=0;i<level.players.size;i++)
	{
		//get any dead zombie
		if(level.players[i] isAZombie())
		{
			if(isAlive(level.players[i]))
				continue;
				
			dwarf = level.players[i];
			break;
		}
	}
	
	//if no dead zombie available then check if there are
	//free slots and let a new one connect
	if(!isDefined(dwarf))
	{
		if(level.players.size < level.maxClients)
		{
			setDvar("scr_testclients", 1);
			level waittill("connected");
		}

		//restart this thread and wait for a dead zombie
		//(or the newly connected)	
		wait .5;
		thread spawnWastelandDwarf(target);
		return;
	}

	dwarf thread [[level.spawnPlayer]]("dwarf", target);
}

spawnZombie(zombieType, target)
{
	self endon("disconnect");
	self endon("death");

	//stay hidden until fully initialized
	//this will fix the bad crawl anim
	self hide();
	
	self.zombieType = "human";
	if(isDefined(zombieType))
		self.zombieType = zombieType;
	else
	{
		if(game["tranzit"].specialWaveType == "dogs")
			self.zombieType = "dog";
		else if(game["tranzit"].specialWaveType == "quads")
			self.zombieType = "quad";
	}

	self.linkedToPlayer = false;
	self.isCrawler = false;
	self.isOnFire = false;
	self.isWaved = false;
	self.isElectrified = false;
	self.doJump = false;
	self.climb = false;
	
	self.mantleInVehicle = false;
	
	self.godmode = false;
	self.isNapalmBurning = false;
		
	self.zombieTypeNo = randomInt(level.zombieModels[self.zombieType].size);
	self.zombieSkill = randomFloatRange(0.3, 0.9);
	
	self setZombieModel();
	self setZombieVars();
	self giveLoadout();
	self freezeControls(true);
	self setMovespeedScale(self.moveSpeedScale);
	self playSpawnFx();

	if(isDefined(self.damageTrigger))
		self.damageTrigger delete();
		
	if(isDefined(self.linkedMoveHelper))
		self.linkedMoveHelper delete();
		
	if(isDefined(self.glowFxEnt))
		self.glowFxEnt delete();

	if(isDefined(self.pers["isBot"]) && self.pers["isBot"])
		self thread botBehavior(target);
}

setZombieModel()
{
	self detachAll();
	self setModel(level.zombieModels[self.zombieType][self.zombieTypeNo].body);
	
	if(isDefined(level.zombieModels[self.zombieType][self.zombieTypeNo].head) && level.zombieModels[self.zombieType][self.zombieTypeNo].head != "")
		self attach(level.zombieModels[self.zombieType][self.zombieTypeNo].head);
		
	self setZombieGlowFx();
}

setZombieGlowFx()
{
	self endon("disconnect");
	self endon("death");

	if(self.zombieType == "avagadro")
	{
		if(isDefined(self.glowFxEnt))
			self.glowFxEnt delete();
		
		self.glowFxEnt = spawn("script_model", self.origin + (0,0,53));
		self.glowFxEnt setModel("tag_origin");
		self.glowFxEnt linkTo(self);
	}

	wait .1; //important to make fx visible

	switch(self.zombieType)
	{
		case "dog":
			PlayFXOnTag(level._effect["dog_breathe"], self, "j_nose");
			PlayFXOnTag(level._effect["dog_ash_trail"], self, "j_spine2");
			PlayFXOnTag(level._effect["dog_fire_trail"], self, "j_spine2");
			PlayFXOnTag(level._effect["dog_eye_glow"], self, "j_eyeball_le");
			PlayFXOnTag(level._effect["dog_eye_glow"], self, "j_eyeball_ri");
			break;
		
		case "human":
			if(self playermodelHasTag("j_eyeball_le"))
				PlayFXOnTag(level._effect["human_eye_glow"], self, "j_eyeball_le");	
			if(self playermodelHasTag("j_eyeball_ri"))
				PlayFXOnTag(level._effect["human_eye_glow"], self, "j_eyeball_ri");
			break;
		
		case "avagadro":
			PlayFXOnTag(level._effect["avagadro_moving"], self.glowFxEnt, "tag_origin");
			break;
		
		case "dwarf":
		case "quad":
		default:
			break;
	}
}

playSpawnFx()
{
	switch(self.zombieType)
	{
		case "dog":
			if(randomInt(2))
				playFx(level._effect["dog_lightning_spawn"], self.origin);
			else
				playFx(level._effect["dog_spawn_ground"], self.origin);

			self playSoundRef("spawn_lightning");
			earthquake(0.4, 0.5, self.origin, 512);
			break;
		
		case "human":
			playFx(level._effect["human_spawn_dirt"], self.origin);
			self playSoundRef("spawn_dirt");
			break;
		
		case "avagadro":
			playFx(level._effect["avagadro_appear"], self.origin);
			self playSoundRef("avagadro_warp_in");
			break;
		
		case "dwarf":
			PlayFx(level._effect["screecher_appear"], self.origin);
			break;

		case "quad":
		default:
			break;
	}
}

setZombieVars()
{
	self.maxhealth = level.zombie_health;
	self.health = self.maxhealth;
	self.moveType = "walk";

	switch(self.zombieType)
	{
		case "avagadro":
			self.moveSpeedScale = 1.0;			// move speed multiplier
			self.meleeSpeed = 2;			// timeout between melee attacks
			self.fireSpeed = 4;			// timeout between range attacks
			self.damagePoints = 66;			// damage dealt per attack
			self.runChance = 0;				// chance this bot starts as a runner
			self.sprintChance = 0;			// chance this bot starts as a sprinter
			self.moveType = "walk";
			self.maxhealth = 666;
			self.health = 666;
			break;
	
		case "dog":
			self.moveSpeedScale = 1.0;			// move speed multiplier
			self.meleeSpeed = 2.5;			// timeout between melee attacks
			self.damagePoints = 30;			// damage dealt per attack
			self.runChance = 0;				// chance this bot starts as a runner
			self.sprintChance = 0;			// chance this bot starts as a sprinter
			self.moveType = "run";
			break;
			
		case "dwarf":
			self.moveSpeedScale = 1.4;				// move speed multiplier
			self.meleeSpeed = 1;			// timeout between melee attacks
			self.damagePoints = 16;				// damage dealt per attack
			self.runChance = 1;				// chance this bot starts as a runner
			self.sprintChance = 0;			// chance this bot starts as a sprinter
			self.moveType = "run";
			self.maxhealth = 520;
			self.health = 520;
			break;
		
		case "quad":
			self.moveSpeedScale = 0.4;			// move speed multiplier
			self.meleeSpeed = 1.4;			// timeout between melee attacks
			self.damagePoints = 30;				// damage dealt per attack
			self.runChance = 0.6;			// chance this bot starts as a runner
			self.sprintChance = 0.6;		// chance this bot starts as a sprinter	
			self.moveType = "run";
			break;
			
		case "human":
		default:
			self.moveSpeedScale = 0.8;			// move speed multiplier
			self.meleeSpeed = 1.8;			// timeout between melee attacks
			self.damagePoints = 20;				// damage dealt per attack
			self.runChance = 0.4;			// chance this bot starts as a runner
			self.sprintChance = 0.3;		// chance this bot starts as a sprinter	
			self.moveType = "walk";
			break;
	}
	
	if(game["tranzit"].wave > 8)
	{
		if(randomFloat(1) < self.runChance)
			self.moveType = "run";
		else if(randomFloat(1) < self.sprintChance)
			self.moveType = "sprint";
	}
	else if(game["tranzit"].wave > 3)
	{
		if(randomFloat(1) < self.runChance)
			self.moveType = "run";
	}
}

giveLoadout()
{
	//clear the actionSlots
	/*craftables (cod4: nightvision slot)*/	self SetActionSlot(1, ""); self.actionSlotItem = undefined;
	/*facemasks  (cod4: unused slot)*/		self SetActionSlot(2, ""); self.actionSlotMask = undefined;
	/*explosives (cod4: c4/clay/rpg slot)*/	self SetActionSlot(3, ""); self.actionSlotWeapon = undefined;
	/*hardpoints (cod4: hardpoints slot)*/	self SetActionSlot(4, ""); self.actionSlotHardpoint = undefined;

	self takeAllWeapons();
	self scripts\perks::clearZombiePerks();

	self.zombieWeapon = getWeaponFromCustomName("zombie_" + self.zombieType);

	self GiveWeapon(self.zombieWeapon, 0);
	self GiveMaxAmmo(self.zombieWeapon);
	self SetSpawnWeapon(self.zombieWeapon);
	
	self.pers["primaryWeapon"] = self.zombieWeapon;
	self.pers["secondaryWeapon"] = "none";
}

botBehavior(forcedTarget)
{
	self endon("disconnect");
	self endon("death");

	level endon("game_ended");
	level endon("game_will_end");

	self notify("bot_start_thinking");
	self endon("bot_start_thinking");
	
	self.atTarget = true;
	self.myTarget = undefined;
	self.myMoveTarget = undefined;
	self.isAttacking = false;
	self.nextWp = undefined;
	self.underway = false;
	self.myWaypoint = undefined;
	self.targetWp = undefined;
	self.idleTime = 0;

	self freezeControls(false);
	self botStop();
	
	if(!self isAZombie())
	{
		self [[level.axis]]();
		return;
	}
	
	if(self.zombieType == "dwarf")
	{
		level.dwarfsLeft++;
		
		//zombie initialized - make him visible
		self show();
	}
	else
	{
		level.zombiesSpawned++;
	
		if(self.zombieType == "avagadro")
		{
			level.zombiesSpawned--;
		
			//zombie initialized - make him visible
			self show();
		
			self thread avagadroBehavior(forcedTarget);
			return;
		}
	
		//start the anim to make it look like he crawls out of the ground
		self setWorldmodelAnim("both", "ai_zombie_climbout_ground");
		//a short delay before making the zombie visible to make sure the anim is playing
		wait .2;
		self show();
		//wait for the crawl anim to finish
		wait 5.4;

		self thread scripts\climbspots::botCheckMantle();
		self thread scripts\climbspots::botCheckHighJump();
		self thread scripts\climbspots::botCheckLadderClimb();
		self thread scripts\climbspots::botCheckLadderAndMantleWeapon();
	}

	self thread zombieGrowl();
	self thread botCheckCombatDistance();
	
	while(1)
	{
		wait .1;
	
		if(self.zombieType == "dwarf")
		{
			if(isDefined(forcedTarget))
				self.myTarget = forcedTarget;

			if(isDefined(self.myTarget))
			{
				if(!isAlive(self.myTarget) || self.myTarget isInLastStand() || (isDefined(self.myTarget.isOnTruck) && self.myTarget.isOnTruck))
				{
					//consolePrint("dwarf " + self getEntityNumber() + " target died or is on vehicle - suicide\n");
					self [[level.callbackPlayerDamage]](self, self, self.health + 666, 0, "MOD_RIFLE_BULLET", "none", self.origin, (0,0,0), "head", 0, "target died or is on vehicle");
				}
			
				//consolePrint("dwarf " + self getEntityNumber() + " has target: " + self.myTarget.name + " " + self.myTarget getEntityNumber() + "\n");
				self botAttackTarget("player");
			}

			if(!self.isAttacking)
			{
				//if no enemy available suicide
				if(!isDefined(self.myMoveTarget))
					self suicide();
			}
			
			if(!isDefined(self.myMoveTarget))
				self.myMoveTarget = self.myTarget;
			
			if(isDefined(self.myMoveTarget))
				self botCalculateNextStepTowards();
		}
		else
		{
			self.myTarget = undefined;
			if(isDefined(forcedTarget))
				self.myTarget = forcedTarget;
		
			//music attracts him so first check for a monkeybomb around
			if(!isDefined(self.myTarget))
			{
				self.myTarget = self scripts\monkeybomb::zombieCloseToMonkeyBomb();
				if(isDefined(self.myTarget))
				{
					if(isDefined(self.myTarget.parent) && self.myTarget.parent.classname == "grenade")
						self.myMoveTarget = self.myTarget;
				}
			}

			//no monkeybomb -> is he at a barricade?
			if(!isDefined(self.myTarget))
			{
				self.myTarget = self scripts\barricades::zombieCloseToBarricade();
				if(isDefined(self.myTarget) && isDefined(self.myTarget.barricadeHealth))
				{
					if(self.myTarget.barricadeHealth > 0 /*&& self isLookingAtEntity(self.myTarget)*/)
					{
						self botMoveTo(self.origin);
						self botAttackTarget("barricade");
					}
				}
			}
			
			//no barricade around -> maybe he is close to any other damageable entity that is not a player?
			if(!isDefined(self.myTarget))
			{
				self.myTarget = self scripts\sentrygun::zombieCloseToSentrygun();

				if(!isDefined(self.myTarget))
					self.myTarget = self scripts\generator::zombieCloseToGenerator();
				
				if(isDefined(self.myTarget))
					self botAttackTarget("entity");
			}
			
			if(!isDefined(self.myTarget))
			{
				self.myTarget = self botGetBestAttackableTarget();	
				if(isDefined(self.myTarget))
					self botAttackTarget("player");
			}

			if(!self.isAttacking)
			{
				//if no enemy available move to the center of the play area
				if(!isDefined(self.myMoveTarget))
					self.myMoveTarget = scripts\maparea::getClosestMapArea(self.origin);
			}
			
			if(!isDefined(self.myMoveTarget))
				self.myMoveTarget = self.myTarget;
			
			if(isDefined(self.myMoveTarget))
			{
				//before moving the zombie check if has has to climb on the vehicle
				if(self.zombieType == "human" && isPlayer(self.myMoveTarget))
				{
					if(isDefined(self.myMoveTarget.isOnTruck) && self.myMoveTarget.isOnTruck)
					{
						self.isOnTruck = scripts\vehicle::playerOnLoadingArea();
			
						if(self.isOnTruck)
						{
							//iPrintLnBold(self.name + " is on truck.");
						}
						else
						{
							closestVehicleMantleSpot = self scripts\vehicle::getClosestMantleSpot();
							if(isDefined(closestVehicleMantleSpot))
							{
								self.myMoveTarget = getEnt(closestVehicleMantleSpot, "targetname");
								
								if(self scripts\vehicle::canMantleInVehicle(self.myMoveTarget))
								{
									self scripts\vehicle::doMantleInVehicle(self.myMoveTarget);
									continue;
								}
							}
						}
					}
				}
				
				if(isDefined(self.myMoveTarget))
					self botCalculateNextStepTowards();
			}
		}
	}
}

avagadroBehavior(forcedTarget)
{
	self endon("disconnect");
	self endon("death");

	level endon("game_ended");
	level endon("game_will_end");

	self notify("avagadro_start_thinking");
	self endon("avagadro_start_thinking");
	
	self thread zombieGrowl();
	//self thread botCheckCombatDistance();
	
	self playLoopSoundRef("avagadro_loop");
	//PlayFXOnTag(level._effect["avagadro_idle"], self, "tag_origin");
	
	while(1)
	{
		wait .1;

		self.myTarget = undefined;
		if(isDefined(forcedTarget) && isPlayer(forcedTarget) && isAlive(forcedTarget))
			self.myTarget = forcedTarget;

		if(!isDefined(self.myTarget))
		{
			self.myTarget = self botGetBestAttackableTarget();	
			if(isDefined(self.myTarget))
				self botAttackTarget("player");
		}

		if(!self.isAttacking)
		{
			//if no enemy available move to the center of the play area
			if(!isDefined(self.myMoveTarget))
				self.myMoveTarget = scripts\maparea::getClosestMapArea(self.origin);
				
			self.idleTime += 0.1;
		}
		
		if(!isDefined(self.myMoveTarget))
			self.myMoveTarget = self.myTarget;
		
		if(isDefined(self.myMoveTarget))
		{
			if(self.idleTime >= game["tranzit"].avagadroIdleTime)
				self botCalculateNextStepTowards();
		}
	}
}

botCalculateNextStepTowards()
{
	self endon("disconnect");
	self endon("death");
	
	//only one instance allowed
	self notify("botCalculateNextStep");
	self endon("botCalculateNextStep");
	
	if(self isMantling() || self.doJump || (isDefined(self.mantleInVehicle) && self.mantleInVehicle))
		return;
	
	//if(!isDefined(self.myWaypoint)) uncomment this line when the lags return
	{
		if(!isDefined(self.myAreaLocation))
			self.myAreaLocation = 0;

		self.myWaypoint = getNearestWp(self.origin, self.myAreaLocation);
	}

	target = self.myMoveTarget;
	if(!isDefined(target))
		return;
	
	if(!isDefined(target.myAreaLocation))
		target.myAreaLocation = 0;

	self.targetWp = getNearestWp(target.origin, target.myAreaLocation);
	
	if(self.myWaypoint < 0 || self.targetWp < 0)
		return;
	
	self.moveDirect = false;
	self.atTarget = false;
	self.lookAt = undefined;
	
	if(!isDefined(self.underway))
		self.underway = false;
	
	//the bot can move to the target freely
	freePath = false;
	if(isPlayer(target) && target.isOnTruck && isDefined(self.isOnTruck) && self.isOnTruck)
		freePath = true;
	if(isDefined(target.targetname) && isSubStr(target.targetname, "tag_mantlespot_"))
		freePath = true;
	else if(CharacterPhysicsTrace(false, self.origin + (0,0,5), target.origin + (0,0,5)) == target.origin + (0,0,5))
		freePath = true;
	
	if(freePath)
	{
		//the bot can move to the target freely when there is no hole (like roof at loading area)
		loops = int(Distance2d(self.origin + (0,0,5), target.origin + (0,0,5)) / 20);
		for(j=1;j<=loops;j++)
		{
			forward = VectorNormalize(target.origin - self.origin);
			if(BulletTracePassed(self.origin + (0,0,5) + anglesToForward(forward)*20*j, self.origin + (0,0,5) - (0,0,50) + anglesToForward(forward)*20*j, false, self))
			{
				freePath = false;
				break;
			}
		}
	}
	
	if(freePath)
		self.moveDirect = true;
	else
	{
		if(self.underway)
		{
			if(self.targetWp == self.myWaypoint)
			{
				self.moveDirect = true;
				self.underway = false;
				self.atTarget = true;
				//self.myWaypoint = undefined;
				self.myMoveTarget = undefined;
			}
			else
			{
				if(!isDefined(self.nextWp) || self.nextWp < 0)
				{
					//iPrintLnBold("return 1");
						return;
				}
				
				if(self.targetWp == self.nextWp)
				{
					if(Distance2d(target.origin, self.origin) <= Distance2d(getWpOrigin(self.nextWp), self.origin))
					{
						self.moveDirect = true;
						self.underway = false;
						//self.myWaypoint = undefined;
					}
				}
			}
		}
		else
		{
			if(self.targetWp == self.myWaypoint)
			{
				self.moveDirect = true;
				self.underway = false;
				self.atTarget = true;
				//self.myWaypoint = undefined;
				self.myMoveTarget = undefined;
			}
			else
			{
				astar_path = self scripts\navmesh::PathfindingAlgorithm(self.myWaypoint, self.targetWp);
				
				if(!isDefined(astar_path))
					self.nextWp = undefined;
				else
					self.nextWp = astar_path[0];

				self.underway = true;

				if(!isDefined(self.nextWp))
				{
					self.underway = false;
					
					//astar failed - don't try again unless the target player changes his position
					curTargetWp = self.targetWp;
					while(curTargetWp == self.targetWp)
					{
						wait .1;
						
						if(!isDefined(target) || !isPlayer(target) || !isAlive(target))
							break;
						
						self.targetWp = getNearestWp(target.origin, target.myAreaLocation);
					}
					
					return;
				}
			}
		}
	}
	
	if(self.moveDirect)
	{
		if(!isDefined(self.isAttacking) || !self.isAttacking)
		{
			if(isDefined(target))
			{
				if(isPlayer(target))
					self.lookAt = target getTagOrigin("j_spine4");
				if(!isDefined(self.lookAt))
					self.lookAt = target.origin + (0,0,self getEye()[2]);
				
				time = self botCalculateAimTime(self.lookAt, "movement");
				self botDoAim(self.lookAt, time);
			}
		}
		
		self botDoMove(target.origin);
	}
	else
	{
		if(isDefined(self.nextWp) && self.nextWp >= 0)
		{
			moveTo = getWpOrigin(self.nextWp);
			if(!isDefined(self.isAttacking) || !self.isAttacking)
			{
				/*if(isDefined(target))
				{
					if(isPlayer(target))
						self.lookAt = target getTagOrigin("j_spine4");
					if(!isDefined(self.lookAt))
						self.lookAt = target.origin + (0,0,self getEye()[2];
					
					time = self botCalculateAimTime(self.lookAt, "movement");
					self botDoAim(self.lookAt, time);
				}*/
				
				self.lookAt = moveTo + (0,0,self getEye()[2]);
				time = self botCalculateAimTime(self.lookAt, "movement");
				self botDoAim(self.lookAt, time);
			}
			
			self botDoMove(moveTo);
			
			if(Distance2d(moveTo, self.origin) <=  19.68)
			{
				self.underway = false;
				self.myWaypoint = self.nextWp;
			}
		}
	}
}

botCheckCombatDistance()
{
	level endon("game_ended");
	level endon("game_will_end");

	self endon("disconnect");
	self endon("death");

	while(1)
	{
		killme = true;
		maxDist = 3000;
		
		if(self.zombieType == "dwarf")
			maxDist = 500;
		
		for(i=0;i<level.players.size;i++)
		{
			if(isDefined(level.players[i].isAtRootOfEvil) && level.players[i].isAtRootOfEvil)
			{
				killme = false;
				break;
			}
		
			if(level.players[i] isASurvivor() && isAlive(level.players[i]))
			{
				if(Distance(self.origin, level.players[i].origin) <= maxDist)
				{
					killme = false;
					break;
				}
			}
		}
		
		if(killme)
		{
			//is this save?
			//zombies should respawn in new area instead of simple death (or stupid slow walk to new area)
			if(self.zombieType != "dwarf")
				level.zombiesSpawned--;
			
			//zombie is outside the player range/view so no need for damage (and head pop effect) - just suicide
			//self [[level.callbackPlayerDamage]](self, self, self.health + 666, 0, "MOD_RIFLE_BULLET", "ak47_mp", self.origin, (0,0,0), "head", 0, "outside the player range/view");
			self suicide();
			break;
		}
		
		wait 3;
	}
}

botMelee(iDamage, damageDelay)
{
	self endon("disconnect");
	self endon("death");

	//zombies melee each other when moving in group and won't damage the player
	//instead of executing "+melee" it's better to play the anim and damage the player directly

	wait damageDelay; //melee anim time before damage is inflicted

	velocity = self getVelocity();
	moveSpeed = length(velocity);

	switch(self.zombieType)
	{
		case "human":
			//crawler = prone
			if(/*self getStance() == "prone"*/self.isCrawler)
			{
				//idle
				if(moveSpeed == 0)
					self setWorldmodelAnim("torso", "ai_zombie_attack_crawl_lunge");
				else
					self setWorldmodelAnim("torso", "ai_zombie_attack_crawl");
			}
			//grabbing through barricade = crouch
			else if(self getStance() == "crouch")
			{
				self setWorldmodelAnim("both", "ai_zombie_window_attack_arm_L_out");
				//self setWorldmodelAnim("both", "ai_zombie_window_attack_arm_r_out");
			}
			else
			{
				//idle
				if(moveSpeed == 0)
				{
					random = randomInt(3);
					if(random == 0) self setWorldmodelAnim("both", "ai_zombie_attack_v1");
					else if(random == 1) self setWorldmodelAnim("both", "ai_zombie_attack_v3");
					else if(random == 2) self setWorldmodelAnim("both", "ai_zombie_attack_v4");
				}
				else
				{
					self setWorldmodelAnim("torso", "ai_pt_zombie_attack_v1");
				}
			}
			break;
	
		case "dog":
			self setWorldmodelAnim("both", "zombie_dog_run_attack");
			break;
		
		case "dwarf":
			self setWorldmodelAnim("both", "ai_zombie_screecher_headpull");
			break;
		
		case "quad":
			random = randomInt(3);
			if(random == 0) self setWorldmodelAnim("both", "ai_zombie_quad_attack");
			else if(random == 1) self setWorldmodelAnim("both", "ai_zombie_quad_attack_2");
			else if(random == 2) self setWorldmodelAnim("both", "ai_zombie_quad_attack_3");
			break;

		case "avagadro":
			self setWorldmodelAnim("both", "ai_zombie_avogadro_melee_attack_v1");
			break;

		default: break;
	}

	if(isPlayer(self.myTarget))
	{
		if(!isAlive(self.myTarget))
			return;
	
		self.myTarget thread [[level.callbackPlayerDamage]](self, self, iDamage, 0, "MOD_MELEE", self.zombieWeapon, self.origin, VectorToAngles(self.myTarget.origin - self.origin), "torso", 0, "attacked by zombie through barricade");
	}
	else
	{
		self.myTarget notify("damage", iDamage, self, VectorToAngles(self.myTarget.origin - self.origin), self.origin, "MOD_MELEE");
	}
}

botDoAim(target, time)
{
	self endon("disconnect");
	self endon("death");

	if(!isDefined(target))
		return;
		
	if(!isPlayer(target))
		self botLookAt(target, time);
	else
	{
		if(!isAlive(target))
			return;
		
		self botLookAt(target getTagOrigin("pelvis"), time);
	}
}

botCalculateAimTime(target, type)
{
	self endon("disconnect");
	self endon("death");

	time = 0;
	
	angleDiffYaw = maps\mp\gametypes\_missions::AngleClamp180(VectorToAngles(target - self.origin)[1] - self getPlayerAngles()[1]);
	angleDiffRoll = maps\mp\gametypes\_missions::AngleClamp180(VectorToAngles(target - self.origin)[2] - self getPlayerAngles()[2]);

	//use the bigger angleDiff to calculate the aim time
	if(abs(angleDiffYaw) > abs(angleDiffRoll))
		time = abs(angleDiffYaw * 0.01 * (1.1 - self.zombieSkill));
	else
		time = abs(angleDiffRoll * 0.01 * (1.1 - self.zombieSkill));

	if(self isFlashbanged())
		time += 1;
		
	if(time <= 0.05)
		time = 0.05;
	
	return time;
}

botGetBestAttackableTarget()
{
	self endon("disconnect");
	self endon("death");
	
	//Can we see any enemies?
	self.possibleTargets = undefined;
	self.possibleTargets = [];
	for(i=0;i<level.players.size;i++)
	{
		if(botEnemyIsDetectable(level.players[i]))	
			self.possibleTargets[self.possibleTargets.size] = level.players[i];
	}
	
	//only 1 enemy found -> he is the target
	if(self.possibleTargets.size == 1)
		return self.possibleTargets[0];
	//more than 1 enemy found -> get the best target
	else if(self.possibleTargets.size > 1)
	{
		for(i=0;i<self.possibleTargets.size;i++)
		{
			rate = 1;
			
			//Any obstacles in our way?
			rate += self.possibleTargets[i] SightConeTrace(self GetEye(), self.possibleTargets[i]) * 10;

			//Is it in melee range? If so it is our new target, no matter how it was rated yet
			if(Distance(self.possibleTargets[i].origin, self.origin) <= 64)
				rate += 1000000;
			else
			{
				//rate it's distance -> more distance = longer movement => bad rating
				distRate = (100 - (Distance(self.possibleTargets[i].origin, self.origin) * 0.01 / 2));
				
				if(distRate > 0)
					rate += distRate;
			}
			
			self.possibleTargets[i].rate = rate;
		}
		
		//get the best rated enemy
		tempRate = 0;
		tempTarget = undefined;
		for(i=0;i<self.possibleTargets.size;i++)
		{
			if(self.possibleTargets[i].rate >= tempRate)
			{
				tempRate = self.possibleTargets[i].rate;
				tempTarget = self.possibleTargets[i];
			}
		}

		return tempTarget;
	}
	
	//no enemy in sight - pick the closest
	//undefined if still no enemy available
	return self botGetClosestEnemy();
}

botGetClosestEnemy()
{
	self endon("disconnect");
	self endon("death");
	
	tempDist = 999999;
	tempEnemy = undefined;
	for(i=0;i<level.players.size;i++)
	{
		if(!isDefined(level.players[i]) || !isPlayer(level.players[i]))
			continue;
			
		if(level.players[i] isASpectator() || level.players[i] isAZombie())
			continue;

		if(self == level.players[i])
			continue;
	
		if(!isAlive(level.players[i]))
			continue;
			
		dist = Distance(self.origin, level.players[i].origin);
		if(dist <= tempDist)
		{
			tempDist = dist;
			tempEnemy = level.players[i];
		}
	}

	return tempEnemy;
}

botEnemyIsDetectable(player)
{
	self endon("disconnect");
	self endon("death");
	
	if(!isDefined(player) || !isPlayer(player) || player isASpectator() || player isAZombie())
		return false;
		
	if(!isAlive(player) || player isInLastStand())
		return false;
	
	//if(player SightConeTrace(self GetEye(), player) <= 0.35)
	//	return false;
		
	//if(Distance(self.origin, player.origin) > 5000)
	//	return false;

	//player in the back
	//angleDiff = maps\mp\gametypes\_missions::AngleClamp180(VectorToAngles(player.origin - self.origin)[1] - self getPlayerAngles()[1]);
	//if(abs(angleDiff) > 30)
	//	return false;

	return true;
}

botCanMeleeAttackTarget(entity)
{
	self endon("disconnect");
	self endon("death");
	
	if(!isDefined(entity))
		return false;
		
	if(Distance(self.origin, entity.origin) > level.botMeleeDist)
		return false;
		
	if(entity SightConeTrace(self GetEye(), entity) <= 0.35)
		return false;

	if(isPlayer(entity))
	{
		if(entity isASpectator() || entity isAZombie())
			return false;
		
		if(!isAlive(entity) || entity isInLastStand())
			return false;
	}

	return true;
}

botCanRangeAttackTarget(entity)
{
	self endon("disconnect");
	self endon("death");
		
	if(!isDefined(entity))
		return false;
		
	if(Distance(self.origin, entity.origin) > level.botRangeAttackDist[self.zombieType])
		return false;
		
	if(entity SightConeTrace(self GetEye(), entity) <= 0.35)
		return false;

	if(isPlayer(entity))
	{
		if(entity isASpectator() || entity isAZombie())
			return false;
		
		if(!isAlive(entity) || entity isInLastStand())
			return false;
	}

	return true;
}

botEntityIsAttackable(entity)
{
	self endon("disconnect");
	self endon("death");

	if(Distance(self.origin, entity.origin) > level.botMeleeDist)
		return false;
		
	if(isDefined(entity.health) && entity.health <= 0)
		return false;
		
	return true;
}

canAttackTarget(type)
{
	if(!self isOnLadder() && !self isMantling() && !self.doJump)
	{
		if(isDefined(self.myTarget))
		{
			if(type == "entity" && self botEntityIsAttackable(self.myTarget))
				return true;
		
			if(type == "barricade")
			{
				if(self.myTarget.barricadeHealth > 0)
					return true;
					
				return false;
			}
		
			if(self botCanMeleeAttackTarget(self.myTarget))
			{
				if(self.zombieType == "dwarf")
				{
					if(!self.linkedToPlayer)
						self botLinkToPlayer();
				}
			
				return true;
			}
			
			if(self.zombieType == "avagadro")
			{
				if(self botCanRangeAttackTarget(self.myTarget))
					return true;
			}
		}
	}
	
	return false;
}

botLinkToPlayer()
{
	self botStop();
	self scripts\climbspots::botJump();

	PlayFx(level._effect["screecher_disappear"], self.origin);
	
	wait .5;
	
	if(isDefined(self.myTarget) && isPlayer(self.myTarget) && isAlive(self.myTarget))
	{
		self setOrigin(self.myTarget getTagOrigin("j_spine4"));
		self setPlayerAngles(self.myTarget getPlayerAngles());
		self linkTo(self.myTarget, "j_spine4");

		PlayFx(level._effect["screecher_disappear"], self.origin);

		self.linkedToPlayer = true;
		self.myTarget.dwarfOnShoulders = self;
		
		self thread monitorKnifeDamage();
	}
}

/* old - with the tranzit_extrafunctions plugin i added isMeleeing(), a trigger/model to detect damage is not required anymore
monitorKnifeDamage()
{
	self endon("disconnect");
		
	//trigger_radius does not detect damage so it's not possible to spawn a trigger and check for knife impact
	//what about an invisible model infront of the player?
	self.damageTrigger = spawn("script_model", self.myTarget.origin);
	self.damageTrigger.angles = self.myTarget getPlayerAngles();
	self.damageTrigger endon("death");
	self.damageTrigger setModel("fake_hitbox_player_stand");
	self.damageTrigger setCanDamage(true);
	self.damageTrigger.health = 999999;
	
	//model allows linkto, trigger requires a loop that sets the new origin
	self.damageTrigger linkTo(self.myTarget);
	
	weapon = getWeaponFromCustomName("player_dwarf_attacking");
	self.myTarget GetInventory();
	self.myTarget takeAllWeapons();
	self.myTarget giveWeapon(weapon);
	self.myTarget switchToWeapon(weapon);
	
	while(1)
	{
		self.damageTrigger waittill("damage", amount, attacker, vDir, vPoint, sMeansOfDeath);

		self.damageTrigger.health += amount;

		if(!isDefined(self) || !isAlive(self))
			break;

		if(!isDefined(self.myTarget) || !isAlive(self.myTarget))
			break;
			
		if(!isDefined(sMeansOfDeath) || sMeansOfDeath != "MOD_MELEE")
			continue;

		if(!isDefined(attacker) || attacker != self.myTarget)
			continue;
		
		self [[level.callbackPlayerDamage]](self.damageTrigger, attacker, amount, 0, "MOD_MELEE", "none", self.myTarget.origin, self.origin - self.myTarget.origin, "none", 0, "player knifed dwarf");
		
		if(self.health <= 0)
			break;
	}
	
	if(isDefined(self))
	{
		if(isDefined(self.damageTrigger))
			self.damageTrigger delete();
			
		if(isDefined(self.myTarget))
		{
			self.myTarget.dwarfOnShoulders = undefined;
			
			self.myTarget GiveInventory();
			wait .1;
			self.myTarget SwitchToPreviousWeapon();
		}
	}
}
*/

monitorKnifeDamage()
{
	player = self.myTarget;
	weapon = getWeaponFromCustomName("player_dwarf_attacking");

	player GetInventory();
	player takeAllWeapons();
	player giveWeapon(weapon);
	player switchToWeapon(weapon);
	
	while(1)
	{
		if(!isDefined(self) || !isAlive(self))
			break;

		if(!isDefined(player) || !isAlive(player))
			break;
			
		if(!player isMeleeing())
		{
			wait 0.05;
			continue;
		}

		//the damage will kill it - no need to wait until the melee attack is over
		if(self.health <= 130)
		{
			if(isDefined(player))
			{
				player takeWeapon(weapon);
				player GiveInventory();
			}
		}
		
		self [[level.callbackPlayerDamage]](player, player, 130, 0, "MOD_MELEE", "none", player.origin, VectorToAngles(player.origin - self.origin), "none", 0, "player knifed dwarf - new");

		//the damage killed it - no need to wait until the melee attack is over
		if(!isDefined(self) || !isAlive(self))
			break;

		while(player isMeleeing())
			wait 0.05;
	}
	
	if(isDefined(player))
	{
		if(player hasWeapon(weapon))
		{
			player takeWeapon(weapon);
			player GiveInventory();
		}
		
		wait .1;
		player SwitchToPreviousWeapon();
		player.dwarfOnShoulders = undefined;
	}
}

botAttackTarget(type)
{
	self endon("disconnect");
	self endon("death");
	
	self botAction("-melee");
	self botAction("-fire");
	
	self.myMoveTarget = self.myTarget;
	
	if(!isDefined(type))
		type = "";
	
	attackTimeOut = 0;
	while(isDefined(self.myTarget) && self canAttackTarget(type))
	{
		self botAction("-melee");
		self botAction("-fire");
	
		if(isDefined(self.idleTime))
			self.idleTime = 0;
	
		self.isAttacking = true;
		
		if(!isDefined(self.myTarget))
			break;
		
		self.lookAt = undefined;
		if(isPlayer(self.myTarget))
			self.lookAt = self.myTarget getTagOrigin("j_spine4");
		if(!isDefined(self.lookAt))
		{
			self.lookAt = self.myTarget.origin + (0,0,self getEye()[2]);
		
			if(type == "barricade")
				self.lookAt = self.myTarget.origin + (0,0,50);
		}
		
		time = self botCalculateAimTime(self.lookAt, "attack");
		self botDoAim(self.lookAt, time);
		
		if(time < 0.1)
			time = 0.1;

		wait time;

		attackTimeOut -= time;
		
		if(attackTimeOut > 0)
			continue;

		attackTimeOut = 0;
		windowAttack = false;

		if(isDefined(self.myTarget))
		{
			//make him stand still before attacking
			self botStop();
		
			if(self botCanMeleeAttackTarget(self.myTarget) || (type == "barricade" && self.myTarget.barricadeHealth > 0) || (type == "entity" && self botEntityIsAttackable(self.myTarget)))
			{
				if(self.zombieType == "avagadro" && self.model == "") self setZombieModel();
			
				//make the bot attack player behind the window every now and then
				if(type == "barricade")
				{
					for(i=0;i<level.players.size;i++)
					{
						if(level.players[i] isASurvivor() && Distance2d(self.origin, level.players[i].origin) <= 64)
						{
							windowAttack = true;
							break;
						}
					}
				}
				
				//in waw it is a chance of 50% that they try to grab players through window
				if(windowAttack && randomInt(100) >= 50 && self.myTarget.barricadeHealth < self.myTarget.maxhealth)
				{
					iDamage = 20;
					meleeAnimTime = 1.91;
					damageDelay = meleeAnimTime*2/3;
				}
				else
				{
					iDamage = self.damagePoints;
					meleeAnimTime = 0.82;
					damageDelay = meleeAnimTime*2/3;
				
					if(self.zombieType == "dwarf")
					{
						self.myTarget scripts\survivors::updateClawDmgHud();
				
						//reduce the damage when wearing a mask because the dwarf will not scratch the face directly
						if(isDefined(self.myTarget.facemask.active) && self.myTarget.facemask.active)
							iDamage = int(iDamage/2);
					}
				}
				
				self PlayAttackSound();
				self botMelee(iDamage, damageDelay);
				wait (meleeAnimTime-damageDelay); //remaining melee anim time after damage
				
				if(isDefined(self.meleeSpeed) && self.meleeSpeed > 0.05)
					attackTimeOut += self.meleeSpeed;
					
				continue;
			}
			
			if(self.zombieType == "avagadro")
			{
				if(self.model == "") self setZombieModel();
			
				if(self botCanRangeAttackTarget(self.myTarget))
				{
					self GiveMaxAmmo(self.zombieWeapon);
					self botAction("+fire");
					self PlayAttackSound();

					wait 1.80; //fire anim time is 1.74
	
					if(isDefined(self.fireSpeed) && self.fireSpeed > 0)
						attackTimeOut += self.fireSpeed;
						
					continue;
				}
			}
		}
	}
	
	self botAction("-melee");
	self botAction("-fire");
	
	wait .05;
	
	if(self.zombieType != "dwarf")
		self.myTarget = undefined;
	
	self.isAttacking = false;
}

PlayAttackSound()
{
	switch(self.zombieType)
	{
		case "human":
			if(self.isCrawler)
				self playSoundRef("crawler_attack");
			else
				self playSoundRef("zom_attack");
			break;
	
		case "dog":
			self playSoundRef("dog_attack");
			break;
		
		case "dwarf":
			self playSoundRef("screecher_attack");
			break;
			
		case "quad":					
		default: break;
	}
}

botDoMove(destination)
{
	if(self.zombieType == "avagadro")
	{
		self setModel("");
		self moveThroughClip(destination, game["tranzit"].avagadroTeleportSpeed, true);
		self setZombieModel();
	}
	else
	{
		//set the new movement type (ads = walk)
		if(self.moveType == "walk")
		{
			//self botAction("-sprint");
			self botAction("+ads");
		}
		else if(self.moveType == "sprint")
		{
			//self botAction("-ads");
			self botAction("+sprint");
		}
		else
		{
			//reset bot movement type to default = run
			self botAction("-ads");
			self botAction("-sprint");
		}
			
		if(self scripts\maparea::combatInArea(self.myAreaLocation))
			self setMovespeedScale(self.moveSpeedScale);
		else
		{
			if(self.zombieType != "dwarf")
			{
				if(game["tranzit"].wave >= 11)
					self thread scripts\gore::torchPlayer();
			
				self setMovespeedScale(self.moveSpeedScale * 1.5);
			}
		}
			
		//move
		self botMoveTo(destination);
	}
}

makeCrawler()
{
	self endon("disconnect");
	self endon("death");
	
	if(self.zombieType != "human")
		return;
	
	if(self.isCrawler)
		return;
	
	self.isCrawler = true;
	
	self detachAll();
	
	if(self.model != level.zombieModels[self.zombieType][self.zombieTypeNo].crawler && level.zombieModels[self.zombieType][self.zombieTypeNo].crawler != "")
		self setModel(level.zombieModels[self.zombieType][self.zombieTypeNo].crawler);

	self attach(level.zombieModels[self.zombieType][self.zombieTypeNo].head);
	self attach(level.zombieModels[self.zombieType][self.zombieTypeNo].crawlerGibLegs);

	self botStop();
	self botAction("-ads");
	self botAction("-sprint");
	
	while(1)
	{
		if(self GetStance() != "prone")
		{
			if(!self.doJump)
			{
				//self setStance("prone"); //not working as desired
				self botAction("+goprone");
			}
		}
		
		wait .1;
	}
}

zombieGrowl()
{
	self endon("disconnect");
	self endon("death");

	//play some growling sounds every now and then
	while(1)
	{
		switch(self.zombieType)
		{
			case "human":
				if(self.isCrawler)
				{
					if(randomInt(2))
						self playSoundRef("crawler_walk");
					else
						self playSoundRef("crawler_vocal");
				}
				else
				{
					if(self.moveType == "run")
						self playSoundRef("zom_run");
					else
					{					
						if(randomInt(2))
							self playSoundRef("zom_walk");
						else
							self playSoundRef("zom_vocal");
					}
				}
				break;
		
			case "dog":
				self playSoundRef("dog_idle");
				break;
			
			case "dwarf":
			case "quad":
			case "avagadro":
			default: break;
		}

		wait randomIntRange(3,15);
	}
}

moveThroughClip(targetPos, speed, ignorePlayerPhysics)
{
	if(!isDefined(self.linkedMoveHelper))
		self.linkedMoveHelper = spawn("script_origin", (0,0,0));
	
	self.linkedMoveHelper.origin = self.origin + (0,0,17);
	self.linkedMoveHelper.angles = self.angles;
	self linkTo(self.linkedMoveHelper);
	
	target = targetPos;
	if(!isDefined(ignorePlayerPhysics) || !ignorePlayerPhysics)
		target = CharacterPhysicsTrace(false, targetPos, self.linkedMoveHelper.origin);
	
	time = (distance(self.linkedMoveHelper.origin, target)/speed);
	
	if(time <= 0)
		time = 0.05;
	
	self.linkedMoveHelper moveTo(target, time);
	wait (time + 0.05);
	
	self unlink();
	self.linkedMoveHelper delete();
}