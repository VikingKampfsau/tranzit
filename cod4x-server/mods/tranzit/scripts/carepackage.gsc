#include maps\mp\_utility;
#include common_scripts\utility;
#include scripts\_include;
#include scripts\debug\drawdebuggers;

init()
{
	precacheModel("vehicle_blackhawk");
	precacheModel("com_plasticcase_green_big");

	add_effect("carepackage_smoke", "tranzit/misc/carepackage_smoke");
	add_effect("carepackage_light", "tranzit/misc/carepackage_light");

	level.crateOwnerUseTime = 2;
	level.crateNonOwnerUseTime = 4;
	
	level.totalcps = 0;
	level.maximumcps = 6;
	level.cp_content = [];
	level.carepackageFlySpeed = 100;

	AddToPackage("airstrike_mp", "Airstrike", 50);
	
	AddToPackage("instakill", "Insta-Kill", 10);
	AddToPackage("doublepoints", "x2 Points", 10);
	AddToPackage("maxammo", "Ammo", 10);
	AddToPackage("nuke", "Nuke", 10);
	AddToPackage("carpenter", "Carpenter", 10);
}

AddToPackage(weapon, hinttxt, chance)
{
	struct = spawnstruct();
	struct.weapon = weapon;
	struct.hinttxt = hinttxt;
	struct.chance = chance;
	
	level.cp_content[level.cp_content.size] = struct;
}

useCarepackageHeli(supportType, targetLocation)
{
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
	dropInfo.cpFallTime = sqrt(2*dropInfo.cpFlyHeight/getDvarFloat("g_gravity"));	
	dropInfo.cpFallDist = (level.carepackageFlySpeed*dropInfo.cpFallTime);
	dropInfo.releaseLocation = dropInfo.targetLocation + (0,0,dropInfo.planeFlyHeight) - AnglesToForward(dropInfo.cpDir)*dropInfo.cpFallDist;
	
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
	
	self setvehgoalpos(dropInfo.releaseLocation, 0);
	self waittillmatch("goal");
	
	self thread DropCarePackage(dropInfo);
	
	self setvehgoalpos(dropInfo.planeEndPoint, 0);
	self waittillmatch("goal");
	
	self stopLoopSound();
	self hide();
	wait .1;
	self delete();
}

physicsLaunchZ(dropInfo)
{
	self endon("death");
	
	speed = level.carepackageFlySpeed;
	dir = AnglesToForward(dropInfo.cpDir);
	forward = dir * speed * 0.1;
	downwards = -0.5 * getDvarFloat("g_gravity") * sqr(0.1);
	nextPos = self.origin + forward + (0,0,downwards);
	trace = BulletTrace(self.origin, nextPos, false, self);
	
	iPrintLnBold(self.origin + " -> " + nextPos);
	
	//started in or on solid
	if(trace["fraction"] < 1)
	{
		iPrintLnBold("started in solid");
		
		if(isDefined(trace["entity"]))
			iPrintLnBold(trace["entity"].classname);
		
		return;
	}

	iPrintLnBold("starting bounce check");

	helper = spawn("script_model", self.origin);
	helper.angles = self.angles;
	helper setModel(self.model);
	helper moveGravity(dir * speed, dropInfo.cpFallTime);
	self hide();

	bounced = 0;
	safetyBreak = 0;
	prevorigin = helper.origin;
	while(1)
	{
		prevorigin = helper.origin;
		
		wait .05;
		
		trace = BulletTrace(prevorigin, helper.origin, false, helper);
		
		drawDebugLine(prevorigin, helper.origin, (1,1,1), 1, 600); //show where it came from
		iPrintLnBold(prevorigin + " -> " + helper.origin);
		
		//Bounce
		if(trace["fraction"] < 1)
		{
			tempOrigin = trace["position"];
			tempAngles = helper.angles;
		
			iPrintLnBold("do bounce - " + speed);
			//reduce the velocity to prevent an endless bouncing
			if(bounced == 0)
				speed *= 2;
			else if(bounced == 1)
				speed /= 2;
			else
				speed *= 0.42;
			
			//reflect the velocity
			//this will bounce up to where it came from
			//dir = AnglesToForward(VectorToAngles(tempOrigin - prevorigin));
			//forward = dir * (speed * -1); //bounce in opposite direction
			dir = AnglesToUp(trace["normal"]);
			forward = dir * speed;
			
			drawDebugLine(tempOrigin, tempOrigin + forward, (1,0,0), 1, 600); //show direction of dir
			drawDebugLine(tempOrigin, tempOrigin + (0,0,250), (0,1,0), 1, 600); //show direction upwards
			
			helper delete();
			helper = spawn("script_model", tempOrigin);
			helper.angles = tempAngles;
			helper setModel(self.model);
			
			if(bounced <= 2 && speed >= 60)
				helper moveGravity(forward, 999);
			else
			{
				iPrintLnBold("final bounce");
			
				fallTime = sqrt(2*length(forward)/getDvarFloat("g_gravity")); //not correct becuase the gravity is not recognized upwards? or?
				helper moveGravity(forward, fallTime);
				wait fallTime;
				break;
			}
			
			bounced++;
		}
		
		if(helper.origin != prevorigin)
		{
			safetyBreak = 0;
			continue;
		}
		
		//for debugging - have to find a proper solution
		safetyBreak++;
		if(safetyBreak >= 10)
		{
			iPrintLnBold("safetyBreak");
			break;
		}
	}
	
	self show();
	self.origin = helper.origin;
	self.angles = helper.angles;
	helper delete();
	
	iPrintLnBold("stopped bounce check");
}

DropCarePackage(dropInfo)
{
	level.totalcps++;

	wait 3; //can i remove/lower this later or will this make the trace hit the helicopter?

	carepackage = spawn("script_model", dropInfo.releaseLocation - (0,0,dropInfo.cpUnderHelicopter));
	carepackage.angles = (0,RandomInt(360),0);
	carepackage.targetname = "trajectory_debug";
	carepackage setModel("com_plasticcase_green_big");
	
	//use only one of them
	carepackage moveGravity(AnglesToForward(dropInfo.cpDir)*level.carepackageFlySpeed, dropInfo.cpFallTime);
	//carepackage physicsLaunchZ(dropInfo); //does not look really good
	
	carepackage.type = "carepackage";
	carepackage.owner = self.owner;

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

	carepackage.fxEnt = spawn("script_model", carepackage.origin + (0,0,40));
	carepackage.fxEnt setModel("tag_origin");
	carepackage.fxEnt linkTo(carepackage);

	wait .05;
	playFxOnTag(level._effect["carepackage_light"], carepackage.fxEnt, "tag_origin");
	wait (dropInfo.cpFallTime-0.05);

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

ForceOrigin(prevorigin, entity)
{
	self endon("death");

	while(1)
	{
		if(isDefined(prevorigin) && self.origin != prevorigin)
			self.origin = prevorigin;
		else if(isDefined(entity) && self.origin != entity.origin)
			self.origin = entity.origin;
		
		wait .05;
	}
}

DontBlockBots()
{
	self endon("death");

	while(1)
	{
		self waittill("trigger", player);
		
		if(player isAZombie())
			player thread scripts\zombies::botJump();
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

		player thread showTriggerUseHintMessage(self.trigger, player getLocTextString("CAREPACKAGE_OPEN_PRESS_BUTTON"), undefined, self.content.hinttxt);

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
	
	if(isHardpointWeapon(newWeapon) && self hasActionSlotWeapon("hardpoint"))
	{
		if(self.actionSlotHardpoint != newWeapon)
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

	self giveNewWeapon(newWeapon);

	return;
}