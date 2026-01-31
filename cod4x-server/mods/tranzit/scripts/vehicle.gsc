//in map source the vehicle under map to make sure it's not blocking the waypoints during compile process
//the vehicle is moved to the start location when playing the map 

#include common_scripts\utility;
#include maps\mp\_utility;

#include scripts\debug\drawdebuggers;
#include scripts\_include;

init()
{
	precacheModel("defaultvehicle_mp");
	precacheModel("pb_vehicle_truck");

	if(level.gametype != "tranzit")
		return;

	add_effect("vehicle_exhaust", "tranzit/vehicle/vehicle_exhaust");
	add_effect("vehicle_light", "misc/car_headlight_beam");

	add_sound("horn_warn", "horn_warn");
	add_sound("horn_leave", "horn_leave");

	add_sound("hummer_start", "hummer_start");
	//add_sound("hummer_idle_high", "hummer_idle_high");
	//add_sound("hummer_engine_high", "hummer_engine_high");
	add_sound("hummer_idle_tranzit", "hummer_idle_tranzit");
	add_sound("hummer_engine_tranzit", "hummer_engine_tranzit");

	if(getDvarInt("onTruckTolerance") < 15)
		setDvar("onTruckTolerance", 15);

	if(!game["debug"]["status"])
	{
		mpVehicle = getEnt("tranzit_vehicle_new", "targetname");
		
		if(isDefined(mpVehicle))
			mpVehicle delete();
	}

	level.vehicleNodesAmount = initVehiclePath();

	if(isDefined(level.vehicleNodesAmount) && level.vehicleNodesAmount > 0)
		spawnTranzitVehicle();
}

initVehiclePath()
{
	//to connect the path for zombie mantle waypoints are required
	while(!isDefined(level.wpAmount) || level.wpAmount <= 0)
		wait .05;

	path[0] = getEnt("tranzit_start", "targetname");
	if(!isDefined(path) || path.size <= 0)
		return 0;
	
	for(i=0;;i++)
	{
		trace = BulletTrace(path[i].origin + (0,0,100), path[i].origin - (0,0,9999), false, path[i]);
		
		if(isDefined(trace["position"]))
			path[i].origin = trace["position"];
	
		path[i].radius = 200;
	
		//move the path info into an array of the engine to free the variables
		initVehicleNode(i, path[i].speed, path[i].script_wait, path[i].radius, path[i].origin);
	
		if(!isDefined(path[i].target))
			break;
			
		if(path[i].target == path[0].targetname)
			break;
	
		path[i+1] = getEnt(path[i].target, "targetname");
	}
	
	if(!isDefined(path) || path.size <= 1)
		return 0;
	
	nodeCount = path.size;
	
	//delete the path nodes to free some entities
	for(i=1;i<path.size;i++)
		path[i] delete();
		
	return nodeCount;
}
	
spawnTranzitVehicle()
{
	//use the mp vehicle inside the map to spawn the sp like vehicle
	tempMapVehicle = getEnt("tranzit_vehicle_temp", "targetname");
	level.tranzitVehicle = spawnScriptedVehicle("pb_vehicle_truck", "humvee", "pb_vehicle_truck", tempMapVehicle.origin, tempMapVehicle.angles);
	level.tranzitVehicle.angles = tempMapVehicle.angles;
	tempMapVehicle delete();
	
	if(!isDefined(level.tranzitVehicle))
	{
		iPrintLnBold("vehicle is not defined");
		return;
	}
	
	level.tranzitVehicle thread initTranzitVehicle();
}

initTranzitVehicle()
{
	self endon("death");
	
	self.origin = getEnt("tranzit_start", "targetname").origin;
	
	//health info
	self.maxHealth = 1000;
	self.health = self.maxHealth;
	self.status = "alive";

	self.spawnAngles = self.angles;	
	self.isAtBusstop = true;
	
	//spawn an entity to play the engine sounds
	//script_vehicle can not play loop sounds
	self.soundEnt = spawn("script_model", self.origin);
	self.soundEnt linkTo(self);
	
	//the trigger to start the engine
	self.trigger = getEnt("vehicle_trigger", "targetname");
	if(!isDefined(self.trigger))
		self.trigger = spawn("trigger_radius", self.origin, 0, 120, 100);
	else
	{
		self.trigger.originOffset = self.trigger.origin - self.origin;
		self.trigger.angleOffset = self.trigger.angles - self.spawnAngles;
	}
	
	curArea = scripts\maparea::getClosestMapArea(self.origin);
	curWP = getNearestWp(self GetTagOrigin("tag_body"), curArea.spawner_id);
	
	//create the mantle spots and link them
	mantleSpots[0] = "tag_mantlespot_back";
	mantleSpots[1] = "tag_mantlespot_left_1";
	mantleSpots[2] = "tag_mantlespot_left_2";
	mantleSpots[3] = "tag_mantlespot_right_1";
	mantleSpots[4] = "tag_mantlespot_right_2";
	
	for(i=0;i<mantleSpots.size;i++)
	{
		self.mantleSpots[i] = spawn("script_origin", self GetTagOrigin(mantleSpots[i]));
		self.mantleSpots[i].targetname = mantleSpots[i];
		self.mantleSpots[i].waypoint = getNearestWp(self.mantleSpots[i].origin, curArea.spawner_id);
		self.mantleSpots[i].mantleAreaWp = curWP;
		self.mantleSpots[i] linkTo(self);
		
		if(!isDefined(curWP) || curWP < 0 || !isDefined(self.mantleSpots[i].waypoint) || self.mantleSpots[i].waypoint < 0)
		{
			consolePrint("Can not find a waypoint for " + mantleSpots[i] + "\n");
			continue;
		}
		
		addWpNeighbour(self.mantleSpots[i].waypoint, curWP);
		addWpNeighbour(curWP, self.mantleSpots[i].waypoint);
	}
	
	self.mantleDist = 20;
	
	self thread vehicleWaiter();
	self thread vehicleTouched();
	
	if(game["debug"]["status"])
	{
		while(isDefined(self))
		{	
			wait .05;
			
			if(game["debug"]["vehicle_draw_loadingarea"])
			{
				area = spawnStruct();
				area.edges[0] = self GetTagOrigin("tag_loadingarea_front_left") + (0,0,90);
				area.edges[1] = self GetTagOrigin("tag_loadingarea_front_right") + (0,0,90);
				area.edges[2] = self GetTagOrigin("tag_loadingarea_back_left") + (0,0,90);
				area.edges[3] = self GetTagOrigin("tag_loadingarea_back_right") + (0,0,90);
				thread scripts\debug\drawdebuggers::drawDebugRectangle(area);
			}
			
			if(game["debug"]["vehicle_draw_mantlespots"])
			{
				wait 1;
				for(i=0;i<mantleSpots.size;i++)
				{
					Print3d(getWpOrigin(self.mantleSpots[i].waypoint), "WP " + i, (1,0,0), 0.85, 0.5, 40);
					Print3d(self.mantleSpots[i].origin, "CLIMB + i", (1,0,0), 0.85, 0.5, 40);
				}
			}
		}
	}
}

vehicleWaiter()
{
	self endon("death");

	while(!level.players.size)
		wait 1;

	while(!game["tranzit"].playersReady)
		wait .5;

	engineStarted = false;
	while(1)
	{
		for(i=0;i<level.players.size;i++)
		{
			if(level.players[i] isASurvivor() && level.players[i] isTouching(self.trigger) && level.players[i] isReadyToUse())
			{
				level.players[i] thread showTriggerUseHintMessage(self.trigger, level.players[i] getLocTextString("VEHICLE_START_PRESS_BUTTON"));
				
				if(level.players[i] UseButtonPressed())
				{
					engineStarted = true;
					break;
				}
			}
		}
		
		if(engineStarted)
			break;

		wait .05;
	}
	
	self.trigger.origin = self.origin + self.trigger.originOffset + (0,0,10000);
	
	wait 1;
	
	self playSoundRef("hummer_start");

	wait 2;

	self thread vehicleExhaustFX();
	self thread vehicleMoveOnPath();
}

vehicleMoveOnPath()
{
	self endon("death");

	self.isAtBusstop = false;

	nodeData = spawnStruct();
	
	circled = false;
	engineStarted = false;
	for(i=0;i<=level.vehicleNodesAmount;i++)
	{
		if(!engineStarted)
		{
			engineStarted = true;
			i++;
		}
	
		self.moveSound = true;
	
		if(i == (level.vehicleNodesAmount))
			i = 0;
		
		nodeData.index = getVehicleNodeData(i, "id");
		nodeData.speed = getVehicleNodeData(i, "speed");
		nodeData.stoptime = getVehicleNodeData(i, "stoptime");
		nodeData.goalRadius = getVehicleNodeData(i, "goalradius");
		nodeData.origin = getVehicleNodeData(i, "origin");
		
		nodeData.isStopPos = false;
		if(isDefined(nodeData.stoptime) && nodeData.stoptime > 0)
			nodeData.isStopPos = true;
		
		self SetSpeed(nodeData.speed, 12.55, 12.55/2); //<speed>, <acceleration>, <deceleration> in mph
		self SetVehGoalPos(nodeData.origin, nodeData.isStopPos);	
		
		if(isDefined(nodeData.goalRadius) && nodeData.goalRadius > 0)
		{
			self setNearGoalNotifyDist(nodeData.goalRadius);
			self waittill_any("near_goal", "goal");
		}
		else
		{
			self waittill("goal");
		}
		
		if(nodeData.isStopPos)
		{
			if(i == 0)
				circled = true;
			
			self vehicleWaitAtDestination(nodeData.stoptime, circled);
		}
	}
}

vehicleWaitAtDestination(stopTime, circled)
{
	self.moveSound = false;
	self.isAtBusstop = true;

	if(!circled)
	{
		curArea = scripts\maparea::getClosestMapArea(self.origin);
		curWP = getNearestWp(self GetTagOrigin("tag_body"), curArea.spawner_id);
		
		for(i=0;i<self.mantleSpots.size;i++)
		{
			addWpNeighbour(curWP, getNearestWp(self.mantleSpots[i].origin, curArea.spawner_id));
			addWpNeighbour(getNearestWp(self.mantleSpots[i].origin, curArea.spawner_id), curWP);
		}
	}

	if(!isDefined(stopTime) || stopTime > 30)
		stopTime = 30;
	
	wait 5;

	self.trigger.origin = self.origin + self.trigger.originOffset;
	self.trigger.angles = self.angles + self.trigger.angleOffset;
	
	timePassed = 0;
	engineStarted = false;
	while(timePassed < stopTime)
	{
		for(i=0;i<level.players.size;i++)
		{
			if(level.players[i] isASurvivor() && level.players[i] isTouching(self.trigger) && level.players[i] isReadyToUse())
			{
				level.players[i] thread showTriggerUseHintMessage(self.trigger, level.players[i] getLocTextString("VEHICLE_START_PRESS_BUTTON"));
				
				if(level.players[i] UseButtonPressed())
				{
					engineStarted = true;
					break;
				}
			}
		}
	
		if(engineStarted)
			break;
	
		if(timePassed == (stopTime/2))
			self playSoundRef("horn_warn");
	
		wait .05;
		timePassed += 0.05;
	}
	
	self.trigger.origin = self.origin + self.trigger.originOffset + (0,0,10000);
	self.isAtBusstop = false;
	
	self playSoundRef("horn_leave");
}

vehicleExhaustFX()
{
	self endon("death");

	//playingMoveSound = false;
	//playingIdleSound = false;

	playingSound = false;
	while(1)
	{
		wait .2;
	
		if(modelHasTag(self.model, "tag_engine_left"))
			playfxontag(level._effect["vehicle_exhaust"], self, "tag_engine_left");
			
		if(self.isAtBusstop)
		{
			self.soundEnt playLoopSoundRef("hummer_idle_tranzit");
			
			while(self.isAtBusstop)
				wait .1;
		}
		else
		{
			self.soundEnt playLoopSoundRef("hummer_engine_tranzit");
			
			while(!self.isAtBusstop)
				wait .1;
		}
		
		self.soundEnt stopLoopSound();
	}
}

vehicleTouched()
{
	self endon("death");

	while(1)
	{
		self waittill("vehicle_touch", eTouchedEnt, iVehicleSpeed, vMoveDir, vhitDir, iDamage);
		
		if(!isPlayer(eTouchedEnt) || !isAlive(eTouchedEnt))
			continue;
		
		self thread damageTouchedEnt(eTouchedEnt, iVehicleSpeed, vMoveDir, vhitDir, iDamage);
	}
}

//do i need a damage delay between two damage calls?
damageTouchedEnt(eTouchedEnt, iVehicleSpeed, vMoveDir, vhitDir, iDamage)
{
	eTouchedEnt endon("disconnect");
	eTouchedEnt endon("death");
	
	if(eTouchedEnt isASurvivor())
	{
		//do not damage a survivor
		//when he's not prone
		if(eTouchedEnt getStance() != "prone")
			return;
		
		//if prone only when he's not on the truck
		if(isDefined(eTouchedEnt.isOnTruck) && eTouchedEnt.isOnTruck)
			return;
		
		iDamage = self.health;
	}
	
	//damage the player/zombie
	eTouchedEnt [[level.callbackPlayerDamage]](self, self, iDamage, 0, "MOD_CRUSH", "none", self.origin, VectorToAngles(eTouchedEnt.origin - self.origin), "none", 0, "crushed by vehicle");
}

getClosestMantleSpot()
{
	self endon("disconnect");
	self endon("death");

	mantleSpots[0] = level.tranzitVehicle.mantleSpots[0].targetname;
	
	if(self isAZombie())
	{
		for(i=1;i<level.tranzitVehicle.mantleSpots.size;i++)
			mantleSpots[mantleSpots.size] = level.tranzitVehicle.mantleSpots[i].targetname;
	}
	
	if(mantleSpots.size == 1)
		return mantleSpots[0];

	closest = undefined;
	tempDist = 99999999;
	for(i=0;i<mantleSpots.size;i++)
	{
		dist = Distance(level.tranzitVehicle GetTagOrigin(mantleSpots[i]), self.origin);
		if(dist <= tempDist)
		{
			tempDist = dist;
			closest = mantleSpots[i];
		}
	}
	
	return closest;
}

canMantleInVehicle(mantleSpot)
{
	self endon("disconnect");
	self endon("death");

	if(!isDefined(level.tranzitVehicle))
		return false;

	if(self isAZombie() && !level.tranzitVehicle.isAtBusstop)
		return false;

	if(Distance2d(self.origin, level.tranzitVehicle.origin) > 500)
		return false;

	if(!self isReadyToUse(false, false))
		return false;

	if(self isASurvivor())
	{
		if(!self isLookingAtEntity(level.tranzitVehicle))
			return false;
	}

	if(!isDefined(mantleSpot))
	{
		mantleSpot = self getClosestMantleSpot();
	
		if(isDefined(mantleSpot))
			mantleSpot = getEnt(mantleSpot, "targetname");
	}
	
	if(!isDefined(mantleSpot))
		return false;
	
	if(self.origin[2] > mantleSpot.origin[2])
		return false;
	
	if(Distance2d(self.origin, mantleSpot.origin) > level.tranzitVehicle.mantleDist)
		return false;

	return true;
}

#using_animtree("multiplayer");
doMantleInVehicle(mantleSpot)
{
	self endon("disconnect");
	self endon("death");

	mantleInfo = spawnStruct();

	self.mantleInVehicle = true;

	if(!isDefined(mantleSpot))
	{
		mantleSpot = self getClosestMantleSpot();
	
		if(isDefined(mantleSpot))
			mantleSpot = getEnt(mantleSpot, "targetname");
	}

	if(!isDefined(mantleSpot))
		return;

	if(isSubStr(mantleSpot.targetname, "back"))
		mantleInfo.mantleSpot = "back";
	else
		mantleInfo.mantleSpot = "side";

	if(isDefined(self.linkedMoveHelper))
		self.linkedMoveHelper delete();
	
	self.linkedMoveHelper = spawn("script_model", mantleSpot.origin);
	self.linkedMoveHelper.angles = level.tranzitVehicle.angles;
	
	if(self isAZombie())
		self botStop();
	
	self freezeControls(true);
	self linkTo(self.linkedMoveHelper); //avoids flickering caused by gravity

	if(self isASurvivor())
	{
		if(mantleInfo.mantleSpot == "back")
		{
			self disableWeapons();
			self setWorldmodelAnim("both", "mp_mantle_up_45");
			
			mantleInfo.climbs = getAnimLength(%mp_mantle_up_45)/0.05;
			mantleInfo.movement = getFakeMantleValues(45);
		}
	}
	else
	{
		if(mantleInfo.mantleSpot == "back")
		{
			self setWorldmodelAnim("both", "sp_mantle_up_45");
			
			mantleInfo.climbs = getAnimLength(%sp_mantle_up_45)/0.05;
			mantleInfo.movement = getFakeMantleValues(45);
		}
		else
		{
			self setWorldmodelAnim("both", "sp_mantle_up_57");
			
			mantleInfo.climbs = getAnimLength(%sp_mantle_up_57)/0.05;
			mantleInfo.movement = getFakeMantleValues(57);
		}
	}

	for(i=0;i<mantleInfo.climbs;i++)
	{
		if(!isDefined(mantleInfo.movement.forward[i]) || !isDefined(mantleInfo.movement.up[i]))
			break;
	
		offset = self.linkedMoveHelper.origin - level.tranzitVehicle.origin;
		newPos = level.tranzitVehicle.origin;
		newPos += offset;
		newPos += anglesToForward(VectorToAngles(level.tranzitVehicle GetTagOrigin("tag_body") - self.origin)) * mantleInfo.movement.forward[i];
		newPos += (0,0,mantleInfo.movement.up[i]);
		
		self.linkedMoveHelper moveTo(newPos, 0.05);
		
		wait 0.05;
	}
		
	self unlink();
	self freezeControls(false);
	self enableWeapons();
	
	self.linkedMoveHelper delete();
	
	self.mantleInVehicle = false;
}

playerOnLoadingArea()
{
	self endon("disconnect");
	self endon("death");

	if(isDefined(level.tranzitVehicle))
	{
		Box = spawnStruct();
		Box.height = 90;
		Box.P[1] = level.tranzitVehicle GetTagOrigin("tag_loadingarea_back_left") - anglesToForward(level.tranzitVehicle.angles)*getDvarInt("onTruckTolerance");
		Box.P[2] = level.tranzitVehicle GetTagOrigin("tag_loadingarea_front_left") - anglesToRight(level.tranzitVehicle.angles)*getDvarInt("onTruckTolerance");
		Box.P[3] = level.tranzitVehicle GetTagOrigin("tag_loadingarea_front_right") + anglesToRight(level.tranzitVehicle.angles)*getDvarInt("onTruckTolerance");
		Box.P[4] = level.tranzitVehicle GetTagOrigin("tag_loadingarea_back_right") - anglesToForward(level.tranzitVehicle.angles)*getDvarInt("onTruckTolerance");
	
		if(pointInBox(self.origin, Box))
			return true;
	}
	
	return false;
}

getFakeMantleValues(height)
{
	self endon("disconnect");
	self endon("death");

	movement = spawnStruct();
	movement.forward = [];
	movement.up = [];
	movement.forwardTotal = 0;
	movement.upTotal = 0;

	//height 40-45
	if(height >= 40 && height <= 45)
	{
		movement.forward[0] = 0.0630938;	movement.up[0] = -2.10764;
		movement.forward[1] = 0.356247;		movement.up[1] = -1.74875;
		movement.forward[2] = 0.785158;		movement.up[2] = -1.15387;
		movement.forward[3] = 1.17018;		movement.up[3] = 2.00903;
		movement.forward[4] = 1.75315;		movement.up[4] = 4.04947;
		movement.forward[5] = 1.87155;		movement.up[5] = 4.23547;
		movement.forward[6] = 2.26154;		movement.up[6] = 5.21416;
		movement.forward[7] = 2.0106;		movement.up[7] = 4.91475;
		movement.forward[8] = 2.12568;		movement.up[8] = 5.64873;
		movement.forward[9] = 1.57796;		movement.up[9] = 4.9456;
		movement.forward[10] = 1.34554;		movement.up[10] = 5.35199;
		movement.forward[11] = 0.573189;	movement.up[11] = 4.32843;
		movement.forward[12] = 0.105746;	movement.up[12] = 2.46849;
		movement.forward[13] = 1.000000;	movement.up[12] = 1.86484; //my own push to avoid stucks
	}
	else if(height >= 55 && height <= 60)
	{
		movement.forward[0] = 0.090332;		movement.up[0] = -0.849243;
		movement.forward[1] = 0.544434;		movement.up[1] = -1.9538;
		movement.forward[2] = 0.943848;		movement.up[2] = -3.05229;
		movement.forward[3] = 0.19141;		movement.up[3] = -3.15398;
		movement.forward[4] = 0.01807;		movement.up[4] = -1.47141;
		movement.forward[5] = 2.999023;		movement.up[5] = 2.0808258;
		movement.forward[6] = 5.915039;		movement.up[6] = 3.564064;
		movement.forward[7] = 6.890625;		movement.up[7] = 3.27346;
		movement.forward[8] = 8.82666;		movement.up[8] = 4.38924;
		movement.forward[9] = 9.853516;		movement.up[9] = 6.18337;
		movement.forward[10] = 5.76416;		movement.up[10] = 7.60235;
		movement.forward[11] = 2.82373;		movement.up[11] = 8.55428;
		movement.forward[12] = 6.03418;		movement.up[12] = 10.30683;
		movement.forward[13] = 5.02002;		movement.up[13] = 9.5439;
		movement.forward[14] = 3.1084;		movement.up[14] = 8.80595;
		movement.forward[15] = 2.21436;		movement.up[15] = 8.89041;
		movement.forward[16] = 2.33301;		movement.up[16] = 6.25919;
		movement.forward[17] = 1.55555;		movement.up[16] = 4.44444; //my own push to avoid stucks
	}
	
	additionalForwardStepDist = level.tranzitVehicle.mantleDist/movement.forward.size;
	
	for(i=0;i<movement.forward.size;i++)
	{
		movement.forward[i] += additionalForwardStepDist;
		movement.forwardTotal += movement.forward[i];
	}
	
	for(i=0;i<movement.up.size;i++)
		movement.upTotal += movement.up[i];
	
	return movement;
}