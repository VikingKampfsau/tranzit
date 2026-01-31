#include maps\mp\_utility;
#include common_scripts\utility;
#include scripts\_include;
#include scripts\debug\drawdebuggers;

init()
{
	precacheModel("vehicle_blackhawk");
	precacheModel("com_plasticcase_green_big");

	add_effect("carepackage_smoke", "red_smoke");
	
	add_effect("spotlight", "misc/spotlight_large");
	add_effect("spotlight_dlight", "misc/spotlight_dlight");
	add_effect("white_blink", "misc/aircraft_light_white_blink");
	add_effect("white_blink_tail", "misc/aircraft_light_red_blink");
	add_effect("wingtip_green", "misc/aircraft_light_wingtip_green");
	add_effect("wingtip_red", "misc/aircraft_light_wingtip_red");

	add_weapon("chainsaw", "skorpion_acog_mp", true);
	add_weapon("flamethrower", "uzi_acog_mp", true);
	add_weapon("raygun", "briefcase_bomb_mp", true);
	
	level.crateOwnerUseTime = 2;
	level.crateNonOwnerUseTime = 4;
	
	level.totalcps = 0;
	level.maximumcps = 6;
	level.cp_content = [];
	level.carepackageFlySpeed = 100;

	//sum of the chances has to be 100!
	AddToPackage("hardpoint", 	"airstrike", 							"Airstrike", 				4);
	AddToPackage("weapon", 		getWeaponFromCustomName("chainsaw"), 	"Chainsaw", 				2);
	AddToPackage("weapon", 		getWeaponFromCustomName("flamethrower"), "Flamethrower", 			5);
	AddToPackage("weapon", 		getWeaponFromCustomName("raygun"), 		"Raygun", 					3);
	AddToPackage("powerup", 	"instakill", 							"Insta-Kill", 				8);
	AddToPackage("powerup", 	"doublepoints", 						"x2 Points", 				8);
	AddToPackage("powerup", 	"maxammo", 								"Ammo", 					9);
	AddToPackage("powerup", 	"nuke", 								"Nuke", 					7);
	AddToPackage("powerup", 	"carpenter", 							"Carpenter", 				9);
	AddToPackage("perk", 		"perk_quickrevive", 					"PERK_QUICKREVIVE", 		5);
	AddToPackage("perk", 		"specialty_fastreload", 				"PERK_FASTRELOAD", 			5);
	AddToPackage("perk", 		"specialty_rof", 						"PERK_ROF", 				5);
	AddToPackage("perk", 		"specialty_armorvest", 					"PERK_ARMORVEST", 			5);
	AddToPackage("perk", 		"specialty_bulletdamage", 				"PERK_BULLETDAMAGE", 		5);
	AddToPackage("perk", 		"specialty_explosivedamage", 			"PERK_EXPLOSIVEDAMAGE", 	5);
	AddToPackage("perk", 		"specialty_longersprint", 				"PERK_LONGERSPRINT", 		5);
	AddToPackage("perk", 		"specialty_bulletaccuracy", 			"PERK_BULLETACCURACY", 		5);
	AddToPackage("perk", 		"specialty_bulletpenetration", 			"PERK_BULLETPENETRATION", 	5);
}

AddToPackage(type, weapon, hinttxt, chance)
{
	struct = spawnstruct();
	struct.type = type;
	struct.weapon = weapon;
	struct.hinttxt = hinttxt;
	struct.chance = chance;
	
	level.cp_content[level.cp_content.size] = struct;
}

useCarepackageHeli(supportType, targetLocation, use_map_artillery_selector)
{
	if(!use_map_artillery_selector)
	{
		playSoundAtPosition("smokegrenade_explode_default", targetLocation);
		playFx(level._effect["smoke_location_marker"], targetLocation);
	}
	
	thread spawnSupplyHeli(targetLocation, self);
}

spawnSupplyHeli(targetLocation, owner)
{
	direction = (0, randomfloat(360), 0);
	planeHalfDistance = 8000;//24000;
	planeFlyHeight = 850;

	startPoint = targetLocation + (0,0,planeFlyHeight) + vector_scale(AnglesToForward(direction), planeHalfDistance *-1);
	endPoint = targetLocation + (0,0,planeFlyHeight) + vector_scale(AnglesToForward(direction), planeHalfDistance);

	//find the sky height of the map
	skyCalc = getSkyHeight(targetLocation, true);
	MapSkyPos = skyCalc[0];
	targetLocation = skyCalc[1];
	
	/*if(!isDefined(MapSkyPos) || (targetLocation[2] + planeFlyHeight) >= MapSkyPos[2])
	{
		if(!isDefined(MapSkyPos)) iPrintLnBold("MapSkyPos undefined");
		if((targetLocation[2] + planeFlyHeight) >= MapSkyPos[2])
			iPrintLnBold("MapSkyPos out of skybox. Skypos[2]: " + MapSkyPos[2] + " TargetPos[2]:" + targetLocation[2]);
	}*/
	
	if(isDefined(MapSkyPos) && (targetLocation[2] + planeFlyHeight) < MapSkyPos[2])
	{
		//iPrintLnBold("found bottom of skybox at: " + MapSkyPos[2]); //backlot bottom = 2304
	
		//check if a higher planeFlyHeight is possible
		//(CoD4 is at 850 which is not high enough but the sky in shipment is at 2400+ which is way to high)
		clearPath = true;
		testHeight = planeFlyHeight;
		for(i=1;i<int((MapSkyPos[2]-planeFlyHeight-targetLocation[2])/100);i++)
		{
			startPoint = targetLocation + (0,0,testHeight) + vector_scale(AnglesToForward(direction), planeHalfDistance *-1);
			endPoint = targetLocation + (0,0,testHeight) + vector_scale(AnglesToForward(direction), planeHalfDistance);
		
			trace = BulletTrace(startPoint, endPoint, false, undefined);
			
			//trace has hit anything
			if(trace["fraction"] < 1)
			{
				//ignore anything that has no 'real' surface (like the sides of the skybox)
				if(isDefined(trace["surfacetype"]) && trace["surfacetype"] != "default")
					clearPath = false;
			}
			
			//already outside the skybox
			if((targetLocation[2] + testHeight) >= MapSkyPos[2])
				clearPath = false;

			if(!clearPath)
				break;
				
			testHeight += 100;
		}
		
		testHeight -= 100;
		if(testHeight > planeFlyHeight)
			planeFlyHeight = testHeight;
		
		//iPrintLnBold("planeFlyHeight: " + planeFlyHeight);
		startPoint = targetLocation + (0,0,planeFlyHeight) - vector_scale(AnglesToForward(direction), planeHalfDistance);
		endPoint = targetLocation + (0,0,planeFlyHeight) + vector_scale(AnglesToForward(direction), planeHalfDistance);
	}
	
	dropInfo = spawnStruct();
	dropInfo.planeStartPoint = startPoint;
	dropInfo.planeEndPoint = endPoint;
	dropInfo.planeFlyHeight = planeFlyHeight;
	dropInfo.targetLocation = targetLocation;
	dropInfo.cpUnderHelicopter = 130;

	dropInfo.cpDir = VectorToAngles(VectorNormalize(dropInfo.planeEndPoint - dropInfo.planeStartPoint));
	dropInfo.cpFlyHeight = (dropInfo.planeFlyHeight - dropInfo.cpUnderHelicopter);
	dropInfo.releaseLocation = dropInfo.targetLocation + (0,0,dropInfo.planeFlyHeight);
	
	//drawDebugLine(startPoint, dropInfo.releaseLocation, (0,1,0), 1, 600); //flypath from start to releaseLocation
	//drawDebugLine(dropInfo.targetLocation, dropInfo.targetLocation + (0,0,dropInfo.planeFlyHeight), (1,0,0), 1, 600); //targetLocation up to the helicopter height
	//drawDebugLine(dropInfo.releaseLocation, dropInfo.releaseLocation - (0,0,dropInfo.planeFlyHeight), (0,0,1), 1, 600); //releaseLocation down to the ground
	//drawDebugLine(dropInfo.releaseLocation, dropInfo.targetLocation, (1,1,1), 1, 600); //releaseLocation down to the targetLocation
	
	level.CpChopper = spawnHelicopter(owner, startPoint, vectorToAngles(vectorNormalize(endPoint - startPoint)), "blackhawk_mp", "vehicle_blackhawk");
	level.CpChopper playLoopSound("mp_cobra_helicopter");
	level.CpChopper SetDamageStage(3);
	level.CpChopper.owner = owner;

	level.CpChopper thread CallSupplyHeli(dropInfo);
}

CallSupplyHeli(dropInfo)
{
	self endon("death");
	
	self clearTargetYaw();
	self clearGoalYaw();
	self setspeed(90, 40);	
	self setyawspeed(75, 45, 45);
	self setmaxpitchroll(15, 15);
	self setneargoalnotifydist(200);
	self setturningability(0.9);	
	
	self thread createHeliLights(dropInfo.targetLocation);
	
	self setvehgoalpos(dropInfo.releaseLocation, 1);
	self waittillmatch("goal");
	
	self thread DropCarePackage(dropInfo);
	wait 5; //3 from DropCarePackage + 2
	
	self helicopterSearchlight_off();
	
	self setvehgoalpos(dropInfo.planeEndPoint, 0);
	self waittillmatch("goal");
	
	self stopLoopSound();
	self hide();
	wait .1;
	self delete();
}

createHeliLights(targetPos)
{
	self endon("death");
	
	//light on ground
	self.spotlight = spawn("script_model", self getTagOrigin("tag_barrel"));
	self.spotlight.angles = VectorToAngles(VectorNormalize(targetPos - self getTagOrigin("tag_barrel")));
	self.spotlight setModel("tag_origin");
	self.spotlight linkto(self, "tag_barrel");
	
	//light on heli
	self.dlight = spawn("script_origin", self getTagOrigin("tag_ground"));
	self.dlight setModel("tag_origin");
	self.dlight.spot_radius = 256;
	
	//simple blinking lights (we don't stop them so we can trigger them right away
	wait .05;
	playFxOnTag(level._effect["white_blink"], self, "tag_light_belly");
	playFxOnTag(level._effect["wingtip_green"], self, "tag_light_L_wing");
	playFxOnTag(level._effect["wingtip_red"], self, "tag_light_R_wing");
	wait .3;
	playFxOnTag(level._effect["white_blink_tail"], self, "tag_light_tail");
		
	while(Distance2D(self.origin, targetPos) > 9000)
		wait 0.5;
	
	self thread helicopterSearchlight_on(targetPos);
}

helicopterSearchlight_off()
{
	if(isDefined(self.dlight))
		self.dlight delete();
		
	if(isDefined(self.spotlight))
		self.spotlight delete();
}

helicopterSearchlight_on(targetPos)
{
	self endon("death");

	wait 0.5;
	playFxOnTag(level._effect["spotlight"], self.spotlight, "tag_origin");
	playFxOnTag(level._effect["spotlight_dlight"], self.dlight, "tag_origin");
	
	while(1)
	{
		wait .05;
		
		if(!isDefined(self.dlight))
			break;
		
		if(isDefined(self.spotlight))
		{
			self unlink();
			self.spotlight.angles = VectorToAngles(VectorNormalize(targetPos - self getTagOrigin("tag_barrel")));
			self.spotlight linkto(self, "tag_barrel");
		}
	
		if(Distance2D(self.dlight.origin, targetPos) > self.dlight.spot_radius)
			continue;
	
		forward = anglesToForward(self getTagAngles("tag_barrel"));
		start = self getTagOrigin("tag_barrel");
		end = start + vectorscale(forward, 3000);

		trace = bulletTrace(start, end, false, self);
		dropspot = trace["position"] + vectorscale(forward, -96);

		self.dlight moveTo(dropspot, .05);
	}
}

DropCarePackage(dropInfo)
{
	level.totalcps++;

	wait 3; //can i remove/lower this later or will this make the trace hit the helicopter?

	carepackage = spawnPhysicsObject("com_plasticcase_green_big", dropInfo.releaseLocation - (0,0,dropInfo.cpUnderHelicopter), (RandomFloatRange(-7,7), RandomInt(360), RandomFloatRange(-7,7)), (0,0,0));
	
	//failed to create a physics model - delete the script_model and do nothing
	if(carepackage.classname == "script_model")
	{
		level.totalcps--;
		
		self.owner iPrintLnBold(self.owner getLocTextString("CAREPACKAGE_CONTENT_NONE"));
		
		carepackage delete();
		return;
	}
	
	carepackage.type = "carepackage";
	carepackage.owner = self.owner;

	//real players could be blocked with 'carepackage setContents(1)' but that wouldn't make bots jump over
	//so let's keep the trigger workaround
	carepackage.blocker = [];
	carepackage.blocker[0] = spawn("trigger_radius", carepackage.origin, 0, 32, 35);
	carepackage.blocker[1] = spawn("trigger_radius", carepackage.origin + vectorscale(anglesToRight(carepackage.angles), 32), 0, 32, 35);
	carepackage.blocker[2] = spawn("trigger_radius", carepackage.origin + vectorscale(anglesToRight(carepackage.angles), -32), 0, 32, 35);
	
	for(i=0;i<carepackage.blocker.size;i++)
	{
		carepackage.blocker[i] thread ForceOrigin(undefined, carepackage);
		carepackage.blocker[i] thread DontBlockBots();
	}

	carepackage.deathtrigger = spawn("trigger_radius", carepackage.origin, 0, 50, 1);
	carepackage.deathtrigger thread ForceOrigin(undefined, carepackage);
	carepackage.deathtrigger thread MakeDeadly(carepackage);

	carepackage.fxEnt = spawn("script_model", carepackage.origin + (0,0,30));
	carepackage.fxEnt setModel("tag_origin");
	carepackage.fxEnt linkTo(carepackage);

	carepackage maps\mp\gametypes\_weapons::waitTillNotMoving();

	playFxOnTag(level._effect["carepackage_smoke"], carepackage.fxEnt, "tag_origin");

	carepackage.deathtrigger delete();

	for(i=0;i<carepackage.blocker.size;i++)
		carepackage.blocker[i] setContents(1);
	
	carepackage.trigger = spawn("trigger_radius", carepackage.origin - (0,0,40), 0, 100, 80);
	carepackage.content = CalculateContent();
		
	if(isDefined(self.owner))
		carepackage thread crateUseThinkOwner();

	carepackage thread crateUseThink(self.owner);
}

DontBlockBots()
{
	self endon("death");

	while(1)
	{
		self waittill("trigger", player);
		
		if(player isAZombie())
			player thread scripts\climbspots::botJump();
	}
}

MakeDeadly(eInflictor)
{
	self endon("death");

	while(1)
	{
		self waittill("trigger", player);
		
		if(player isASurvivor())
		{
			player SetOrigin(player.origin + (0,0,40));
			continue;
		}
		
		player thread [[level.callbackPlayerDamage]](eInflictor, eInflictor.owner, player.health + 666, 0, "MOD_SUICIDE", "none", self.origin, VectorToAngles(player.origin - self.origin), "none", 0, "carepacked fell on you");
	}
}

CalculateContent()
{
	random = RandomInt(100);
	parent = 0;
	
	for(i=0;i<level.cp_content.size;i++)
	{
		next = parent + level.cp_content[i].chance;
	
		if(random >= parent && random < next)
			return level.cp_content[i];
		
		parent = next;
	}
	
	return level.cp_content[0];
}

crateUseThink(owner)
{
	while(isDefined(self))
	{
		self.trigger waittill("trigger", player);
		
		if(!isAlive(player))
			continue;
			
		if(!player isOnGround())
			continue;

		if(!player isReadyToUse())
			continue;
		
		if(isDefined(self.owner) && self.owner == player)
			continue;
		
		useEnt = self spawnUseEnt();
		result = useEnt useHoldThink(player, level.crateNonOwnerUseTime);
		
		if(isDefined(useEnt))
			useEnt Delete();

		if(result)
		{
			player GivePackageContent(self);
			break;
		}
	}
}

crateUseThinkOwner() 
{
	while(isDefined(self))
	{
		self.trigger waittill("trigger", player);

		if(!isDefined(self.owner))
			break;
		
		if(!isAlive(player))
			continue;
			
		if(!player isOnGround())
			continue;

		if(player != self.owner)
			continue;
	
		if(!player isReadyToUse())
			continue;

		contentText = player getLocTextString(self.content.hinttxt);
		if(contentText == "")
			contentText = self.content.hinttxt;

		player thread showTriggerUseHintMessage(self.trigger, player getLocTextString("CAREPACKAGE_OPEN_PRESS_BUTTON"), undefined, contentText);

		result = self useHoldThink(player, level.crateOwnerUseTime);

		if(result)
		{
			player GivePackageContent(self);
			break;
		}
	}
}

useHoldThink(player, useTime) 
{
	player freezeControls(true);
	player disableWeapons();
	self.curProgress = 0;
	self.inUse = true;
	self.useRate = 0;
	self.useTime = useTime;

	result = useHoldThinkLoop(player);
	
	if(isDefined(player) && isAlive(player))
	{
		player enableWeapons();
		player freezeControls(false);
	}
	
	if(isDefined(self))
		self.inUse = false;
	
	if(isdefined(result) && result)
		return true;
	
	return false;
}

useHoldThinkLoop(player)
{
	level endon("game_ended");
	level endon("game_will_end");

	player.IsOpeningCrate = true;
	
	while(isDefined(self) && isAlive(player) && player useButtonPressed() && self.curProgress < self.useTime)
	{
		player thread personalUseBar(self);
	
		self.curProgress += self.useRate*0.05;
		self.useRate = 1;

		if(self.curProgress >= self.useTime)
		{
			self.inUse = false;
			player.IsOpeningCrate = undefined;
			return isAlive(player);
		}
	wait .05;
	}
	
	player.IsOpeningCrate = undefined;
	
	return false;
}

personalUseBar(object) 
{
	self endon("disconnect");
	
	if(isDefined(self.useBar))
		return;
	
	self.useBar = self maps\mp\gametypes\_hud_util::createBar((1,1,1), 128, 8);
	self.useBar maps\mp\gametypes\_hud_util::setPoint("CENTER", 0, 0, 0);

	lastRate = -1;
	while(isAlive(self) && isDefined(object) && object.inUse && !level.gameEnded)
	{
		if(lastRate != object.useRate)
		{
			if(object.curProgress > object.useTime)
				object.curProgress = object.useTime;

			self.useBar maps\mp\gametypes\_hud_util::updateBar(object.curProgress/object.useTime, 1/object.useTime);

			if(!object.useRate)
				self.useBar maps\mp\gametypes\_hud_util::hideElem();
			else
				self.useBar maps\mp\gametypes\_hud_util::showElem();
		}

		lastRate = object.useRate;
		wait .05;
	}
	
	self.useBar maps\mp\gametypes\_hud_util::destroyElem();
}

spawnUseEnt()
{
	useEnt = spawn("script_origin", self.origin);
	useEnt.curProgress = 0;
	useEnt.inUse = false;
	useEnt.useRate = 0;
	useEnt.useTime = 0;
	useEnt.owner = self;
	
	useEnt thread useEntOwnerDeathWaiter(self);
	return useEnt;
}

useEntOwnerDeathWaiter(owner)
{
	self endon("death");
	owner waittill("death");
	
	self delete();
}

GivePackageContent(carepackage)
{
	self endon("death");
	self endon("disconnect");
	
	for(i=0;i<carepackage.blocker.size;i++)
		carepackage.blocker[i] delete();
		
	carepackage.trigger delete();
	carepackage.fxEnt delete();
	carepackage delete();
	
	level.totalcps--;
	
	newWeapon = carepackage.content.weapon;
	
	if(!isDefined(newWeapon))
	{
		self iPrintLnBold(self getLocTextString("CAREPACKAGE_CONTENT_NONE"));
		return;
	}
	
	for(i=0;i<level.PowerUps.size;i++)
	{
		if(newWeapon == level.PowerUps[i].name)
		{
			thread scripts\zombie_drops::activateZombiePowerUp(level.PowerUps[i]);
			return;
		}
	}

	if(isHardpointWeapon(newWeapon))
	{
		if(self hasActionSlotWeapon("hardpoint"))
		{
			if(self.actionSlotHardpoint != newWeapon)
			{
				self iPrintLnBold(self getLocTextString("CAREPACKAGE_CONTENT_NONE"));
				return;
			}
		}
	}
	else if(scripts\perks::isDefaultPerk(newWeapon) || scripts\perks::isZombiePerk(newWeapon))
	{
		self scripts\perks::shoutOutPerk(newWeapon);
		self scripts\perks::setZombiePerk(newWeapon);
		return;
	}
	else
	{
		if(getSubStr(newWeapon, newWeapon.size - 3, newWeapon.size) != "_mp")
			newWeapon = newWeapon + "_mp";

		if(isOtherExplosive(newWeapon) && self hasActionSlotWeapon("weapon"))
		{
			if(self.actionSlotWeapon != newWeapon)
			{
				self iPrintLnBold(self getLocTextString("CAREPACKAGE_CONTENT_NONE"));
				return;
			}
		}
		
		if(self hasWeapon(newWeapon))
		{
			self giveMaxAmmo(newWeapon);
			return;
		}
	}
	
	self giveNewWeapon(newWeapon);
}