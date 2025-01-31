#include common_scripts\utility;
#include maps\mp\_utility;

#include scripts\debug\drawdebuggers;
#include scripts\_include;

init()
{
	if(level.gametype != "tranzit")
		return;

	add_effect("vehicle_exhaust", "tranzit/vehicle/vehicle_exhaust");
	add_effect("vehicle_light", "misc/car_headlight_beam");

	add_sound("horn_warn", "horn_warn");
	add_sound("horn_leave", "horn_leave");

	add_sound("hummer_start", "hummer_start");
	add_sound("hummer_idle_high", "hummer_idle_high");
	add_sound("hummer_engine_high", "hummer_engine_high");

	//to connect the path for zombie mantle waypoints are required
	while(!isDefined(level.wpAmount) || level.wpAmount <= 0)
		wait .05;

	curnode = getEnt("tranzit_start", "targetname");
	
	if(!isDefined(curnode) || !isDefined(curnode.target) || isEmptyString(curnode.target))
		return;

	level.tranzitVehiclemaxSpeed = 210; //250;
	level.tranzitVehicleminSpeed = -105;
	level.tranzitVehicleAcceleration = 7;
	level.tranzitVehicleDeceleration = 5;
	
	level.tranzitPath = [];
	while(1)
	{
		if(!isDefined(curnode.script_wait))
			curnode.script_wait = 0;

		if(!isDefined(curnode.speed))
			curnode.speed = level.tranzitVehiclemaxSpeed;
		else
			curnode.speed *= 17.6; //mph to iph
	
		saveTranzitPath(level.tranzitPath.size, curnode);

		nextnode = getEnt(curnode.target, "targetname");
//do not delete until the new vehicle is working		//curnode delete();

		if(!isDefined(nextnode) || !isDefined(nextnode.target) || isEmptyString(nextnode.target))
			break;

		if(nextnode.target == level.tranzitPath[0].targetname)
		{
			if(!isDefined(nextnode.speed))
				nextnode.speed = level.tranzitVehiclemaxSpeed;
		
			level.tranzitPath[level.tranzitPath.size] = nextnode;
			break;
		}
		
		curnode = nextnode;
	}
	
	if(level.tranzitPath.size <= 1)
		return;
	
	precalculateSpeedBehaviour();
	
	level.tranzitVehicle = getEnt("tranzit_vehicle", "targetname");
	level.tranzitVehicle thread initVehicle();
}

saveTranzitPath(entryNo, node)
{
	level.tranzitPath[entryNo] = spawnStruct();
	level.tranzitPath[entryNo].origin = node.origin;
	level.tranzitPath[entryNo].angles = node.angles;
	level.tranzitPath[entryNo].target = node.target;
	level.tranzitPath[entryNo].targetname = node.targetname;
	level.tranzitPath[entryNo].script_wait = node.script_wait;
	level.tranzitPath[entryNo].speed = node.speed;
}

addAccelerationInfoToTranzitPath(entryNo, distToTarget, accelTime, decelTime, maxSpeedTime)
{
	level.tranzitPath[entryNo].accel = accelTime;
	level.tranzitPath[entryNo].maxSpeed = maxSpeedTime;
	level.tranzitPath[entryNo].decel = decelTime;
	level.tranzitPath[entryNo].timeToTarget = accelTime + maxSpeedTime + decelTime;
	level.tranzitPath[entryNo].distToTarget = distToTarget;
}

precalculateSpeedBehaviour()
{
	debugInfo = spawnStruct();
	debugInfo.timeStep = 0.1; //same value as used in the vehicleThink() loop
	debugInfo.timeTotal = 0;
	debugInfo.timeDriven = 0;
	debugInfo.timeStopped = 0;
	debugInfo.totalDist = 0;
	
	//copy the settings from the vehicle
	maxSpeed = level.tranzitVehiclemaxSpeed;
	accel = level.tranzitVehicleAcceleration / debugInfo.timeStep;
	decel = level.tranzitVehicleDeceleration / debugInfo.timeStep;

	//copy the vehicle path and add the start point as final path node
	debugInfo.path = level.tranzitPath;
	debugInfo.path[debugInfo.path.size] = level.tranzitPath[0];

	speedbehaviour = spawnStruct();
	speedbehaviour.accel = [];
	speedbehaviour.decel = [];
	speedbehaviour.maxSpeed = [];
	
	speedAtNode = 0;
	
	//calculate the accelerations, decelertations and maxSpeeds no matter if the vehicle can really reach them
	for(i=0;i<(debugInfo.path.size -1);i++)
	{
		debugInfo.path[i].id = i;
	
		curPos = debugInfo.path[i];
		target = debugInfo.path[i+1];
		speedbehaviour.distToTarget[i] = Distance(curPos.origin, target.origin);
		
		//calculate the maximum possible speed for this movement
		//the vehicle has to accelerate and decelerate (if there is a distance left then this is driven at max speed)
		speedbehaviour.accel[i] = spawnStruct();
		speedbehaviour.accel[i].dist = 0;
		speedbehaviour.accel[i].time = 0;
		speedbehaviour.decel[i] = spawnStruct();
		speedbehaviour.decel[i].dist = 0;
		speedbehaviour.decel[i].time = 0;
		speedbehaviour.maxSpeed[i] = spawnStruct();
		
		//only calculate an acceleration when the current speed is not the maximum
		//and the vehicle has not to decelerate
		if(speedAtNode < maxSpeed && (!isDefined(target.script_wait) || target.script_wait <= 0))
		{
			speedbehaviour.accel[i].dist = sqr(maxSpeed) / (2*accel);
			speedbehaviour.accel[i].time = sqrt(2*speedbehaviour.accel[i].dist / accel);
			
			speedAtNode += (speedbehaviour.accel[i].time * accel);
		}
		//or when it stopped at last node and has to start moving again
		else if(i > 1 && isDefined(debugInfo.path[i-1].script_wait) && debugInfo.path[i-1].script_wait > 0)
		{
			speedbehaviour.accel[i-1].dist = sqr(maxSpeed) / (2*accel);
			speedbehaviour.accel[i-1].time = sqrt(2*speedbehaviour.accel[i-1].dist / accel);
			
			speedAtNode += (speedbehaviour.accel[i].time * accel);
		}
		
		//vehicle has to stop at the target
		if(target.script_wait > 0)
		{
			speedbehaviour.decel[i].dist = sqr(maxSpeed) / (2*decel);
			speedbehaviour.decel[i].time = sqrt(2*speedbehaviour.decel[i].dist / decel);
		}
		//vehicle has to slow down
		else if(target.speed < curPos.speed)
		{
			speedbehaviour.decel[i].dist = sqr(target.speed) / (2*decel);
			speedbehaviour.decel[i].time = sqrt(2*speedbehaviour.decel[i].dist / decel);
			
			speedAtNode -= (speedbehaviour.decel[i].time * decel);
		}
		//vehicle can pass the target without decelertation = nothing to do
		else
		{
			speedAtNode = maxSpeed;
		}
		
		speedbehaviour.maxSpeed[i].dist = speedbehaviour.distToTarget[i] - speedbehaviour.accel[i].dist - speedbehaviour.decel[i].dist;
		speedbehaviour.maxSpeed[i].time = speedbehaviour.maxSpeed[i].dist / maxSpeed;
	}

	consolePrint("nodes calculated: " + speedbehaviour.maxSpeed.size + "\n");
	
	//fix the accelerations, decelertations and maxSpeeds when there is not enough space to drive with max speed
	for(i=0;i<(debugInfo.path.size -1);i++)
	{
		distLeft = 0;
	
		//not enough space to drive with max speed
		if(speedbehaviour.maxSpeed[i].dist < 0)
		{
			//calculate the maximum possible speed by 'faking' a distance of 1 unit
			posMaxSpeed = sqrt(speedbehaviour.distToTarget[i] / ((1/(2*accel)) + (1/(2*accel))));
		
			//vehicle has to decelerate before reaching its maximum speed
			if(speedAtNode < posMaxSpeed)
			{
				consolePrint("^1" + i + " -> " + (i+1) + " path dist " + speedbehaviour.distToTarget[i] + " not long enough to reach maximum speed of " + speedAtNode + ". Maxiumum possible speed is " + posMaxSpeed + "\n");
				
				//recalculate the acceleration and decelertation times with the max possible speed
				consolePrint("^1" + i + " -> " + (i+1) + " not enough space to drive with max speed:" + " (speedAtNode < posMaxSpeed) " + "\n");
			
				speedbehaviour.accel[i].dist = sqr(posMaxSpeed) / (2*accel);
				speedbehaviour.accel[i].time = sqrt(2*speedbehaviour.accel[i].dist / accel);
				
				speedbehaviour.decel[i].dist = sqr(posMaxSpeed) / (2*decel);
				speedbehaviour.decel[i].time = sqrt(2*speedbehaviour.decel[i].dist / decel);
				
				speedbehaviour.maxSpeed[i].dist = speedbehaviour.distToTarget[i] - speedbehaviour.accel[i].dist - speedbehaviour.decel[i].dist;
				speedbehaviour.maxSpeed[i].time = speedbehaviour.maxSpeed[i].dist / posMaxSpeed;
				
				speedAtNode = posMaxSpeed;
				
				consolePrint("^1" + i + " -> " + (i+1) + " new speed applied.\n");
			}
			//vehicle is to fast and there is not enough space to decelerate to zero
			else
			{
				consolePrint("^3" + i + " -> " + (i+1) + " not enough space to decelerate to zero!\n");
				consolePrint("^3" + i + " -> " + (i+1) + " Available: " + speedbehaviour.distToTarget[i] + "\n");
				consolePrint("^3" + i + " -> " + (i+1) + " Required: " + speedbehaviour.decel[i].dist + "\n");
				
				/*old
				distLeft = (speedbehaviour.decel[i].dist - speedbehaviour.distToTarget[i]);
				
				//since the path is not long enough to decelerate:
				//do not accelerate
				speedbehaviour.accel[i].dist = 0;
				speedbehaviour.accel[i].time = 0;
				//decelerate the full distance
				speedbehaviour.decel[i].dist = speedbehaviour.distToTarget[i];
				speedbehaviour.decel[i].time = sqrt(2*speedbehaviour.decel[i].dist / decel);
				//no max speed when the full path is used to decelerate
				speedbehaviour.maxSpeed[i].dist = 0;
				speedbehaviour.maxSpeed[i].time = 0;
				
				//fix the last calculated path nodes to start decelertion in previous subpaths
				for(j=(i-1);distLeft > 0;j--)
				{
					//jump at the end of the path when the current node is the beginning of the vehicle path
					if(j < 0) j = (debugInfo.path.size -2);
			
					//the vehicle entered this section with maximum speed
					if(speedbehaviour.decel[j-1].dist <= 0)
					{
						additionalDecelDelay = sqr(maxSpeed) / (2*distLeft);
						additionalDecelTime = maxSpeed / additionalDecelDelay;
					
						//do not accelerate (already at max speed)
						//speedbehaviour.accel[j].dist = 0;
						//speedbehaviour.accel[j].time = 0;
						//decelerate within the previously missing distance
						speedbehaviour.decel[j].dist = distLeft;
						speedbehaviour.decel[j].time = maxSpeed / additionalDecelDelay;
						//reduce the max speed time if there is any left
						speedbehaviour.maxSpeed[j].dist = (speedbehaviour.distToTarget[j] - speedbehaviour.accel[j].dist - speedbehaviour.decel[j].dist);
						speedbehaviour.maxSpeed[j].time = speedbehaviour.maxSpeed[j].dist / maxSpeed;
					}
					//the vehicle did not enter this section with maximum speed (like there is a bevel where the vehicle already started a deceleration)
					else
					{
//TO DO
					}
					
					consolePrint("speedbehaviour.distToTarget[j]: " + speedbehaviour.distToTarget[j] + "\n");
					consolePrint("accel dist: " + speedbehaviour.accel[j].dist + " decel dist: " + speedbehaviour.decel[j].dist + " maxSpeed dist: " + speedbehaviour.maxSpeed[j].dist + "\n");
					consolePrint("accel time: " + speedbehaviour.accel[j].time + " decel time: " + speedbehaviour.decel[j].time + " maxSpeed time: " + speedbehaviour.maxSpeed[j].time + "\n");
					
					//the distance between this node and the previous one was big enough to decel
					//so no need to check the next previous path
					if(distLeft > speedbehaviour.distToTarget[j])
					{
						consolePrint("previous distance is big enough for the remaining deceleration of " + distLeft + "\n");
						break;
					}
					
					distLeft -= speedbehaviour.decel[j].dist;
					consolePrint("reduced distLeft. remaining: " + distLeft + "\n");
				}*/
				
				//new
				//change the strength of the deceleration
				decel = sqr(debugInfo.path[i].speed) / (2*speedbehaviour.distToTarget[i]);
			
				speedbehaviour.accel[i].dist = 0;
				speedbehaviour.accel[i].time = 0;
				
				speedbehaviour.decel[i].dist = speedbehaviour.decel[i].dist;
				speedbehaviour.decel[i].time = sqrt(2*speedbehaviour.decel[i].dist / decel);
				
				speedbehaviour.maxSpeed[i].dist = 0;
				speedbehaviour.maxSpeed[i].time = 0;
				
				consolePrint("^3" + i + " -> " + (i+1) + " deceleration rate increased to " + decel + ".\n\n");
			}
			
			continue;
		}
		
		//not enough space to accelerate to max speed
		if(speedbehaviour.accel[i].dist > speedbehaviour.distToTarget[i])
		{
			consolePrint("^3" + i + " -> " + (i+1) + " not enough space to accelerate to max speed!\n");
			consolePrint("^3" + i + " -> " + (i+1) + " Available: " + speedbehaviour.distToTarget[i] + "\n");
			consolePrint("^3" + i + " -> " + (i+1) + " Required: " + speedbehaviour.accel[i].dist + "\n");
			
			/*old
			distLeft = (speedbehaviour.accel[i].dist - speedbehaviour.distToTarget[i]);
			additionalAccelDelay = sqr(maxSpeed) / (2*distLeft);
			additionalAccelTime = maxSpeed / additionalAccelDelay;

			//since the path is not long enough to accelerate:
			//accelerate the full distance
			speedbehaviour.accel[i].dist = speedbehaviour.distToTarget[i];
			speedbehaviour.accel[i].time = sqrt(2*speedbehaviour.accel[i].dist / accel);
			//do not decelerate
			speedbehaviour.decel[i].dist = 0;
			speedbehaviour.decel[i].time = 0;
			//no max speed when the full path is used to accelerate
			speedbehaviour.maxSpeed[i].dist = 0;
			speedbehaviour.maxSpeed[i].time = 0;

			//fix the next calculated path nodes to extend the acceleration
			for(j=(i+1);distLeft > 0;j++)
			{
				//jump at the beginning of the path when the current node is the end of the vehicle path
				if(j > (debugInfo.path.size-1)) j = 0;
		
				//the distance between this node and the next one is not enough to accel too
				if(distLeft > speedbehaviour.distToTarget[j])
				{
					consolePrint("next distance is not big enough for the remaining acceleration\n");
					
//TO DO
//Since this distance is not long enough the vehicle has to accelerate in next subpath too
				}
				//the distance between this node and the next one is big enough to accel
				else
				{
					//the vehicle will leave this section with maximum speed
					if(speedbehaviour.accel[j+1].dist <= 0)
					{
//TO DO - Untested code		
						//accelerate within the previously missing distance
						speedbehaviour.accel[j].dist = distLeft;
						speedbehaviour.accel[j].time = maxSpeed / additionalAccelDelay;
						//do not decelerate
						//speedbehaviour.decel[j].dist = 0;
						//speedbehaviour.decel[j].time = 0;
						
						//reduce the max speed time if there is any left
						speedbehaviour.maxSpeed[j].dist = (speedbehaviour.distToTarget[j] - speedbehaviour.accel[j].dist - speedbehaviour.decel[j].dist);
						speedbehaviour.maxSpeed[j].time = speedbehaviour.maxSpeed[j].dist / maxSpeed;
						
						consolePrint("speedbehaviour.distToTarget[j]: " + speedbehaviour.distToTarget[j] + "\n");
						consolePrint("accel dist: " + speedbehaviour.accel[j].dist + " decel dist: " + speedbehaviour.decel[j].dist + " maxSpeed dist: " + speedbehaviour.maxSpeed[j].dist + "\n");
						consolePrint("accel time: " + speedbehaviour.accel[j].time + " decel time: " + speedbehaviour.decel[j].time + " maxSpeed time: " + speedbehaviour.maxSpeed[j].time + "\n");
					}
					//the vehicle will not leave this section with maximum speed
					else
					{
//TO DO - Untested code	
						posMaxSpeed = debugInfo.path[j].speed;
						
						speedbehaviour.accel[j].dist = distLeft;
						speedbehaviour.accel[j].time = posMaxSpeed / additionalAccelDelay;
						//do not decelerate
						//speedbehaviour.decel[j].dist = 0;
						//speedbehaviour.decel[j].time = 0;
						
						//reduce the max speed time if there is any left
						speedbehaviour.maxSpeed[j].dist = (speedbehaviour.distToTarget[j] - speedbehaviour.accel[j].dist - speedbehaviour.decel[j].dist);
						speedbehaviour.maxSpeed[j].time = speedbehaviour.maxSpeed[j].dist / posMaxSpeed;
					}
					break;
				}
			}
			*/
			
			//new
			//change the strength of the acceleration
			accel = sqr(debugInfo.path[i].speed) / (2*speedbehaviour.distToTarget[i]);
			
			if(speedbehaviour.accel[i].dist > speedbehaviour.distToTarget[i])
				speedbehaviour.accel[i].dist = speedbehaviour.distToTarget[i];
			speedbehaviour.accel[i].time = sqrt(2*speedbehaviour.accel[i].dist / accel);
			
			speedbehaviour.decel[i].dist = 0;
			speedbehaviour.decel[i].time = 0;
			
			speedbehaviour.maxSpeed[i].dist = (speedbehaviour.distToTarget[i] - speedbehaviour.accel[i].dist - speedbehaviour.decel[i].dist);
			speedbehaviour.maxSpeed[i].time = speedbehaviour.maxSpeed[i].dist / debugInfo.path[i+1].speed;
			
			consolePrint("^3" + i + " -> " + (i+1) + " acceleration rate increased to " + accel + ".\n\n");
			
			continue;
		}
	}


	for(i=0;i<(debugInfo.path.size -1);i++)
	{
		debugInfo.timeDriven += speedbehaviour.accel[i].time;
		debugInfo.timeDriven += speedbehaviour.decel[i].time;
		debugInfo.timeDriven += speedbehaviour.maxSpeed[i].time;
		
		debugInfo.totalDist += speedbehaviour.accel[i].dist;
		debugInfo.totalDist += speedbehaviour.decel[i].dist;
		debugInfo.totalDist += speedbehaviour.maxSpeed[i].dist;

		addAccelerationInfoToTranzitPath(i, speedbehaviour.distToTarget[i], speedbehaviour.accel[i].time, speedbehaviour.decel[i].time, speedbehaviour.maxSpeed[i].time);

		consolePrint(i + "->" + (i+1) + 
			" Acc: " + speedbehaviour.accel[i].time + "s (" + speedbehaviour.accel[i].dist + 
			") Max : " + speedbehaviour.maxSpeed[i].time + "s (" + speedbehaviour.maxSpeed[i].dist + 
			") Dec: " + speedbehaviour.decel[i].time + "s (" + speedbehaviour.decel[i].dist + 
			") Tot: " + debugInfo.path[i].timeToTarget + " (" + debugInfo.path[i].distToTarget + 
			") Avrg Spd: " + (debugInfo.path[i].distToTarget/debugInfo.path[i].timeToTarget) + ")\n");

		if(debugInfo.path[i+1].script_wait > 0)
		{
			debugInfo.timeTotal = debugInfo.timeStopped + debugInfo.timeDriven;
			consolePrint("Stop at " + (i+1) + " reached after: " + debugInfo.timeTotal + "\n");
		
			if(debugInfo.path[i+1] != debugInfo.path[0])
			{
				delay = debugInfo.path[i+1].script_wait;
				if(!isDefined(delay) || delay > 30)
					delay = 30;
				
				debugInfo.timeStopped += delay;
			}
		}
	}
	
	debugInfo.timeTotal = debugInfo.timeStopped + debugInfo.timeDriven;
	
	consolePrint("Calculated total drive time: " + debugInfo.timeTotal + " (driven: " + debugInfo.timeDriven + ", stopped: " + debugInfo.timeStopped + ") dist: " + debugInfo.totalDist  + "\n");
}

initVehicle()
{
	self endon("death");
	
	//health info
	self.maxHealth = 1000;
	self.health = self.maxHealth;
	self.status = "alive";
	
	//model & brush size (values taken from radiant)
	//to calculate collisions and rotation
	self.dimension = spawnStruct();
	self.dimension.width = 46; //origin sideways to the end of the front loadingArea
	self.dimension.height = 64; //height from ground to the top of the loadingArea
	self.dimension.forwardLength = 72; //origin forward to the middle of the front wheels
	self.dimension.backwardLength = -64; //origin back to the middle of the back wheels
	
	self.collmap = spawnStruct();
	self.collmap.height = 46; //height from ground to center of the bumper
	self.collmap.forwardLength = 128; //origin forward to the end of the bumper
	self.collmap.backwardLength = -110; //origin back to the end of the vehicle
	
	self.movementInfo = spawnStruct();
	self.movementInfo.maxSpeed = level.tranzitVehiclemaxSpeed;
	self.movementInfo.minSpeed = level.tranzitVehicleminSpeed;
	self.movementInfo.accel = level.tranzitVehicleAcceleration;
	self.movementInfo.decel = level.tranzitVehicleDeceleration;
	self.movementInfo.speed = 0;
	self.movementInfo.stops = 0;
	self.movementInfo.loops = 0;
	
	self.movementInfo.isAtStopLocation = true;
	self.movementInfo.curPos = level.tranzitPath[0];
	self.movementInfo.nextPos = level.tranzitPath[1];
	self.origin = level.tranzitPath[0].origin;

	self.movementInfo.anglesForward = anglesToForward(self.angles);
	self.movementInfo.anglesRight = anglesToRight(self.angles);

	self.tire = spawnStruct();
	
	//store the angles the vehicle was placed initially placed in map
	//this is important otherwise the rotation for attached brushmodels and triggers fails
	self.spawnAngles = self.angles;
	
	//the trigger to start the engine
	self.trigger = getEnt("vehicle_trigger", "targetname");
	if(!isDefined(self.trigger))
		self.trigger = spawn("trigger_radius", self.origin, 0, 120, 100);
	else
	{
		self.trigger.originOffset = self.trigger.origin - self.origin;
		self.trigger.angleOffset = self.trigger.angles - self.spawnAngles;
	}

	//the collision brushmodel to make the model solid
	self.collisionBrush = getEnt("tranzit_vehicle_collision", "targetname");
	self.collisionBrush linkTo(self);
	
	//loadingArea = the platform the players stand on
	//LinkTo() does not allow the player to stand on the brush
	//so we have to move this brush just like the vehicle itself	
	self.loadingArea = getEnt("tranzit_vehicle_loadingarea", "targetname");
	self.loadingArea.angleOffset = self.loadingArea.angles - self.spawnAngles;

	//loadingAreaTrigger = the trigger to detect if players are on the vehicle
	//LinkTo() does not work with triggers
	//so we have to move this brush just like the vehicle itself	
	self.loadingAreaTrigger = getEnt("tranzit_vehicle_loadingarea_trigger", "targetname");
	self.loadingAreaTrigger.origin -= (0,0,18); //move it down by the half of it's height so it's center is at correct position
	self.loadingAreaTrigger.originOffset = self.loadingAreaTrigger.origin - self.origin;
	self.loadingAreaTrigger.angleOffset = self.loadingArea.angles - self.spawnAngles;
	
	//mantleTrigger = a trigger to detect where zombies can climb onto the platform the players stand on
	//LinkTo() does not work with triggers
	//so i add that trigger to the global mantleTriggers array
	self.mantleTrigger = getEnt("trigger_mantle_vehicle", "targetname");
	self.mantleTrigger.originOffset = self.mantleTrigger.origin - self.origin;
	self.mantleTrigger.angleOffset = self.mantleTrigger.angles - self.spawnAngles;
	
	//mantleTriggerLookEnt = an entity that tells the zombies where to climb when inside mantleTrigger
	self.mantleTriggerLookEnt = getEnt(self.mantleTrigger.target, "targetname");
	self.mantleTriggerLookEnt.originOffset = self.mantleTriggerLookEnt.origin - self.origin;
	self.mantleTriggerLookEnt.angleOffset = self.mantleTriggerLookEnt.angles - self.spawnAngles;
	self.mantleTriggerLookEnt linkTo(self);
	
	//Apply the correct starting rotation to everything
	if(isDefined(self.movementInfo.nextPos))
	{
		self.angles = VectorToAngles(self.movementInfo.nextPos.origin - self.origin);
		self.loadingArea.angles = self.angles + self.loadingArea.angleOffset;
		self.loadingAreaTrigger.angles = self.angles + self.loadingAreaTrigger.angleOffset;
		self.mantleTriggerLookEnt.angles = self.angles + self.mantleTriggerLookEnt.angleOffset;
	}
	
	addWpNeighbour(getNearestWp(self.mantleTrigger.origin, 0), getNearestWp(self.loadingAreaTrigger.origin + (0,0,18), 0));
	
	//once everything is in place link the vehicle
	self linkTo(self.loadingArea);
	
	self thread VehicleMantleTriggerStatus(true, true);
	self thread VehicleLoadingAreaTriggerStatus();
	self thread monitorPlayerJumpInAttempt();

	self thread vehicleWaiter();
	
	if(!isDefined(level.mantleTriggers))
		wait 5;
	
	if(!isDefined(level.mantleTriggers))
		level.mantleTriggers = [];
		
	//self.mantleTrigger thread scripts\barricades::initMantleTrigger();
	level.mantleTriggers[level.mantleTriggers.size] = self.mantleTrigger;
}

monitorPlayerJumpInAttempt()
{
	self endon("death");
	
	while(1)
	{
		wait .05;
		
		self.mantleTrigger waittill("trigger", player);
		
		if(player isAZombie())
			continue;
		
		if(!player isMantling())
		{
			if(self.movementInfo.speed == 0)
				continue;
		}
		else
		{
			if(!isDefined(player.mantleInVehicle) || !player.mantleInVehicle)
				player thread teleportIntoVehicle();
		}
	}
}

teleportIntoVehicle()
{
	self endon("disconnect");
	self endon("death");
	
	self.mantleInVehicle = true;
	
	wait .2; //wait a bit to start the mantle anim
	for(i=1;i<10;i++)
	{
		wait .05;

		posOnTruck = level.tranzitVehicle.mantleTriggerLookEnt.origin + (0,0,5);
		trace = BulletTrace(posOnTruck + (0,0,15), posOnTruck - (0,0,25), false, undefined);
		
		if(isDefined(trace["position"]))
			posOnTruck = trace["position"] + (0,0,25); //make sure the player is teleported on top of the clip
		
		self setOrigin(posOnTruck);
	}
	
	self.mantleInVehicle = false;
}

VehicleMantleTriggerStatus(enabled, linked)
{
	self endon("death");
	self endon("stop_vehicle_mantle_trigger");

	self.mantleTrigger.angles = self.angles + self.mantleTrigger.angleOffset;

	if(isDefined(enabled) && enabled)
	{
		self.mantleTrigger.origin = self.origin - AnglesToForward(self.angles)*110 + (0,0,22);
		
		if(isDefined(linked) && linked)
		{
			while(1)
			{
				wait .05;
				self.mantleTrigger.origin = self.origin - AnglesToForward(self.angles)*110 + (0,0,22);
			}
		}
	}
	else
	{
		self.mantleTrigger.origin = self.origin - (0,0,100000);
		
		self notify("stop_vehicle_mantle_trigger");
	}
}

VehicleLoadingAreaTriggerStatus()
{
	self endon("death");
	
	while(isDefined(self.loadingAreaTrigger))
	{
		for(i=0;i<level.players.size;i++)
		{
			if(!isDefined(level.players[i].isOnTruck))
				level.players[i].isOnTruck = false;
				
			if(!isDefined(level.players[i].isLinkedToVehicle))
				level.players[i].isLinkedToVehicle = false;
		
			//if(level.players[i] isASurvivor() && isAlive(level.players[i]))
			//	level.players[i] iPrintLnBold("on truck: " + level.players[i].isOnTruck);
		
			if(level.players[i].origin[2] >= self.loadingAreaTrigger.origin[2] && level.players[i] isTouching(self.loadingAreaTrigger))
			{
				if(!self.movementInfo.isAtStopLocation)
					level.players[i].isOnTruck = true;
				else
				{
					if(level.players[i].isOnTruck)
					{
						level.players[i].isOnTruck = false;
					
						level.players[i] iPrintLnBold("vehicle stopped - free to move");
						level.players[i] unlink();
						level.players[i].isLinkedToVehicle = false;
					}
				}
			}
			else
			{
				if(level.players[i].isOnTruck)
				{
					level.players[i] iPrintLnBold("you fell off - not in trigger");
					level.players[i] unlink();
					level.players[i].isLinkedToVehicle = false;
				}
				
				level.players[i].isOnTruck = false;
				
				if(level.players[i] isASurvivor() && isAlive(level.players[i]))
				{
					//speed him up when he is not on the vehicle
					if(level.players[i].moveSpeedScale != 1)
					{
						level.players[i].moveSpeedScale = 1;
						level.players[i] SetMoveSpeedScale(level.players[i].moveSpeedScale);
					}
				}
			}
			
			if(level.players[i] isASurvivor() && isAlive(level.players[i]))
			{
				if(level.players[i].isOnTruck)
				{
					if(!level.players[i] isMoving() && !level.players[i] Jumped())
					{
						if(!level.players[i].isLinkedToVehicle)
						{
							level.players[i] linkTo(self);
							level.players[i].isLinkedToVehicle = true;
						}
					}
					else
					{
						//slow him down to avoid fall of from vehicle by accident
						if(level.players[i].moveSpeedScale != 0.5)
						{
							level.players[i].moveSpeedScale = 0.5;
							level.players[i] SetMoveSpeedScale(level.players[i].moveSpeedScale);
						}
					
						if(level.players[i] isMoving())
							level.players[i] iPrintLnBold("you fell off - moved");
						
						if(level.players[i] Jumped())
							level.players[i] iPrintLnBold("you fell off - jumped");

						if(level.players[i].isLinkedToVehicle)
							level.players[i] iPrintLnBold("you fell off - no idea why");
						
						level.players[i] unlink();
						level.players[i].isLinkedToVehicle = false;
					}
				}
			}
		}
		
		wait .1;
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
	self thread vehicleMontitorRotation();
	//self thread vehicleMontitorCollision();
}

vehicleExhaustFX()
{
	self endon("death");

	playingMoveSound = false;

	while(1)
	{
		wait .2;
	
		if(modelHasTag(self.model, "tag_exhaust"))
			playfxontag(level._effect["vehicle_exhaust"], self, "tag_exhaust");
			
		if(self.movementInfo.moveSound && !playingMoveSound)
		{
			self stopLoopSound();
			self playLoopSoundRef("hummer_engine_high");
			playingMoveSound = true;
		}
		
		if(!self.movementInfo.moveSound && playingMoveSound)
		{
			self stopLoopSound();
			playingMoveSound = false;
		}
	}
}

vehicleMoveOnPath()
{
	self endon("death");
	
	self.debugInfo = spawnStruct();
	self.debugInfo.startTime = (getTime()/1000);
	consolePrint("Vehicle started at: " + self.debugInfo.startTime + "\n");
	
	self.movementInfo.isAtStopLocation = false;
	
	if(modelHasTag(self.model, "tag_light_left_front"))
		playfxontag(level._effect["vehicle_light"], self, "tag_light_left_front");
	
	if(modelHasTag(self.model, "tag_light_right_front"))
		playfxontag(level._effect["vehicle_light"], self, "tag_light_right_front");
	
	timeStep = 0.1;
	for(i=0;i<level.tranzitPath.size;i++)
	{
		self.movementInfo.moveSound = true;
		self.movementInfo.curPos = level.tranzitPath[i];
		
		if(i >= (level.tranzitPath.size-1))
			i = -1;
		
		self.movementInfo.nextPos = level.tranzitPath[i+1];

		consolePrint(
			"moving to " + (i+1) + 
			" (dist " + Distance(self.movementInfo.curPos.origin,self.movementInfo.nextPos.origin) +
			") in " + self.movementInfo.curPos.timeToTarget + 
			"s (= avrg spd " + (Distance(self.movementInfo.curPos.origin,self.movementInfo.nextPos.origin)/self.movementInfo.curPos.timeToTarget) + 
			", accel: " + self.movementInfo.curPos.accel + 
			" decel: " + self.movementInfo.curPos.decel + ")\n");

		//remember: the vehicle (self) is linked to self.loadingArea
		/*move vehicle to next location*/
		self.loadingArea moveTo(self.movementInfo.nextPos.origin, self.movementInfo.curPos.timeToTarget, self.movementInfo.curPos.accel, self.movementInfo.curPos.decel);
			
		//when there is no deceleration
		if(!isDefined(self.movementInfo.curPos.decel) || self.movementInfo.curPos.decel <= 0)
			wait self.movementInfo.curPos.timeToTarget;
		//when the vehicle has to stop at target or has to decel for any other reason
		else if(self.movementInfo.curPos.decel > 0)
		{
			wait (self.movementInfo.curPos.timeToTarget - self.movementInfo.curPos.decel);
			self.loadingArea moveTo(self.movementInfo.nextPos.origin, self.movementInfo.curPos.decel, 0, 0);
			wait self.movementInfo.curPos.decel;
		}
	
		//stop at target
		if(self.movementInfo.nextPos.script_wait > 0)
			self vehicleWaitAtDestination();
			
		if(i == -1)
		{
			self.movementInfo.loops++;
			consolePrint("--- vehicle loop finished ---\n");
		}
	}
}

vehicleWaitAtDestination()
{
	//vehicle reached a stop position within the path
	self.debugInfo.timeDriven = (getTime()/1000) - self.debugInfo.startTime;

	if(!isDefined(self.debugInfo.stopTime))
		self.debugInfo.stopTime = [];

	currentStop = self.debugInfo.stopTime.size;
	delay = self.movementInfo.nextPos.script_wait;
	
	if(!isDefined(delay) || delay > 30)
		delay = 30;
	
	self.debugInfo.stopTime[currentStop] = delay;
	
	consolePrint("Vehicle stops after: " + self.debugInfo.timeDriven + " for " + self.debugInfo.stopTime[currentStop] + "\n");
	self.debugInfo.timeDriven += self.debugInfo.stopTime[currentStop];

	//vehicle is back at the start position
	if(self.movementInfo.curPos == level.tranzitPath[0])
	{
		self.debugInfo.totalDriveTime = self.debugInfo.timeDriven;
	
		self.debugInfo.timeStopped = 0;
		for(i=0;i<(self.debugInfo.stopTime.size -1);i++)
			self.debugInfo.timeStopped += self.debugInfo.stopTime[i];
		
		self.debugInfo.timeDriven = self.debugInfo.totalDriveTime - self.debugInfo.timeStopped;
		
		consolePrint("Vehicle drive time: " + self.debugInfo.totalDriveTime + " (driven: " + self.debugInfo.timeDriven + ", stopped: " + self.debugInfo.timeStopped + ")\n");
	}
	
	if(self.movementInfo.loops == 0)
	{
		//consolePrint("add a waypoint at: " + (self.loadingAreaTrigger.origin+ (0,0,18)) + "\n");
		addWpNeighbour(getNearestWp(self.mantleTrigger.origin, 0), getNearestWp(self.loadingAreaTrigger.origin + (0,0,18), 0));
	}

	//enable the mantle trigger
	self thread VehicleMantleTriggerStatus(true, true);
	
	self.movementInfo.moveSound = false;
	self.movementInfo.isAtStopLocation = true;

	wait 5;

	self.trigger.origin = self.origin + self.trigger.originOffset;
	self.trigger.angles = self.angles + self.trigger.angleOffset;
	
	delay = self.movementInfo.nextPos.script_wait;
	
	if(!isDefined(delay) || delay > 30)
		delay = 30;
	
	timePassed = 0;
	engineStarted = false;
	while(timePassed < delay)
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
	
		if(timePassed == (delay/2))
			self playSoundRef("horn_warn");
	
		wait .05;
		timePassed += 0.05;
	}
	
	self.trigger.origin = self.origin + self.trigger.originOffset + (0,0,10000);
	
	self playSoundRef("horn_leave");
	
	self.movementInfo.isAtStopLocation = false;
	
	//disable the mantle trigger
	//self thread VehicleMantleTriggerStatus(false);
}

//remember: the vehicle (self) is linked to self.loadingArea
//rotation: (pitch(up/down), yaw(left/right), roll(up/down "wings"))
vehicleMontitorRotation()
{
	self endon("death");

	nextPos = self.movementInfo.nextPos;

	self.movementInfo.rotateTime = 0.1;
	
	while(1)
	{
		wait self.movementInfo.rotateTime;
		
		self.movementInfo.speed = length(self.loadingArea getEntVelocity());
		
		if(self.movementInfo.isAtStopLocation)
			continue;
		
		self.movementInfo.rotDirInCurMoment = VectorToAngles(self.movementInfo.nextPos.origin - self.origin);
		
		//vehicle already passed the node, do not rotate to it
		if(nextPos != self.movementInfo.nextPos)
		{
			nextPos = self.movementInfo.nextPos;
			continue;
		}
		
		/*calculate the alignment of the vehicle*/
		self.movementInfo.anglesForward = anglesToForward(self.angles);
		self.movementInfo.anglesRight = anglesToRight(self.angles);
		//setup the directions and their length
		/*right*/	self.dimension.s = vectorScale(self.movementInfo.anglesRight, self.dimension.width);
		/*forward*/	self.dimension.f = vectorScale(self.movementInfo.anglesForward, self.dimension.forwardLength);
		/*back*/	self.dimension.b = vectorScale(self.movementInfo.anglesForward, self.dimension.backwardLength);
		/*up*/		self.dimension.h = (0, 0, int(self.dimension.height/2));
		
		//get the positions of the tires
		self.tire.frontLeft = self.origin + self.dimension.f - self.dimension.s;
		self.tire.frontRight = self.origin + self.dimension.f + self.dimension.s;
		self.tire.backLeft = self.origin + self.dimension.b - self.dimension.s; 
		self.tire.backRight = self.origin + self.dimension.b + self.dimension.s;
		
		//trace for the ground on every wheel
		/*front left*/	flt = bulletTrace(self.tire.frontLeft + self.dimension.h, self.tire.frontLeft - self.dimension.h, false, self)["position"];
		/*front right*/ frt = bulletTrace(self.tire.frontRight + self.dimension.h, self.tire.frontRight - self.dimension.h, false, self)["position"];
		/*back left*/ 	blt = bulletTrace(self.tire.backLeft + self.dimension.h, self.tire.backLeft - self.dimension.h, false, self)["position"];
		/*back right*/ 	brt = bulletTrace(self.tire.backRight + self.dimension.h, self.tire.backRight - self.dimension.h, false, self)["position"];
		
		//pitch = atan2((Cz-(Az+Bz)/2), sqrt(sqr(Cy-Ay)+sqr(Cx-Ax)) //A = front left tire, B = front right tire, C = Back tire with the farest distance to the origin of the vehicle
		//roll = atan2((Bz-Az), (By-Ay) //A = front left tire, B = front right tire
		self.movementInfo.pitch = atan2(((flt[2]+frt[2])/2 - brt[2]), sqrt(sqr(blt[1]-flt[1])+sqr(blt[0]-flt[0]))) + self.loadingArea.angleOffset[0] - self.loadingArea.angles[0];
		self.movementInfo.yaw = maps\mp\gametypes\_missions::AngleClamp180(VectorToAngles(self.movementInfo.nextPos.origin - self.movementInfo.curPos.origin)[1] + self.loadingArea.angleOffset[1] - self.loadingArea.angles[1]);
		//changing the roll looks better but the risk for unexpected behaviour and stuck vehicle (or players falling off) is to high
		//self.movementInfo.roll = atan2((flt[2]-frt[2]), (flt[1]-frt[1])) + self.loadingArea.angleOffset[2] - self.loadingArea.angles[2];
		self.movementInfo.roll = self.movementInfo.rotDirInCurMoment[2];
		
		/*rotate vehicle to next location and apply ground angles*/
		//i can not call them all at once - the first two are ignored
		//self.loadingArea rotatePitch(self.movementInfo.pitch, self.movementInfo.rotateTime);
		//self.loadingArea rotateYaw(self.movementInfo.yaw, self.movementInfo.curPos.timeToTarget);
		//self.loadingArea rotateRoll(self.movementInfo.roll, self.movementInfo.rotateTime);
		//convert it into a single rotateTo()
		self.movementInfo.yaw = (self.movementInfo.yaw/(self.movementInfo.curPos.timeToTarget*(1/self.movementInfo.rotateTime)));
		self.loadingArea rotateTo(self.loadingArea.angles + (self.movementInfo.pitch, self.movementInfo.yaw, self.movementInfo.roll), self.movementInfo.rotateTime);
		
		//rotate and move unlinked parts to the next location
		self.mantleTrigger.angles = self.angles + self.mantleTrigger.angleOffset;
		self.mantleTrigger.origin = self.origin + self.mantleTrigger.originOffset;
		self.loadingAreaTrigger.angles = self.angles + self.loadingAreaTrigger.angleOffset;
		self.loadingAreaTrigger.origin = self.origin + self.loadingAreaTrigger.originOffset;
	}
}

vehicleMontitorCollision()
{
	self endon("death");

	timeStep = 0.1;
	while(1)
	{
		wait timeStep;
		
		if(self.movementInfo.isAtStopLocation)
			continue;

		if(self.movementInfo.speed >= 0)
		{
			// check the vehicle collision
			// perform traces around the vehicle
			/*right*/	self.collmap.s = vectorScale(self.movementInfo.anglesRight, self.dimension.width + 4);
			/*forward*/	self.collmap.f = vectorScale(self.movementInfo.anglesForward, self.dimension.forwardLength + self.movementInfo.speed);
			/*back*/	self.collmap.b = vectorScale(self.movementInfo.anglesForward, self.dimension.backwardLength);
			/*up*/		self.collmap.h = (0, 0, self.collmap.height);

			/*front: fl to fr*/	self.collmap.collTrace[0] = bulletTrace(self.origin + self.collmap.f - self.collmap.s + self.collmap.h, self.origin + self.collmap.f + self.collmap.s + self.collmap.h, true, self);
			/*left: bl to fl*/	self.collmap.collTrace[1] = bulletTrace(self.origin + self.collmap.b - self.collmap.s + self.collmap.h, self.origin + self.collmap.f - self.collmap.s + self.collmap.h, true, self);
			/*right: fr to br*/	self.collmap.collTrace[2] = bulletTrace(self.origin + self.collmap.f + self.collmap.s + self.collmap.h, self.origin + self.collmap.b + self.collmap.s + self.collmap.h, true, self);

			self.movementInfo.collided = false;
			for(i=0;i<self.collmap.collTrace.size;i++)
			{
				if(self isColliding(self.collmap.collTrace[i]))
				{
					self.movementInfo.collided = true;
					break;
				}
			}
		}
	}
}

isColliding(trace)
{
	//nothing to collide with
	if(trace["fraction"] == 1)
		return false;

	//-- something is in our way, what is it? -- //
	
	/* in tranzit the vehicle follows a path - it can not fall out of map
	//prevent falling out of the map ("fake" ground collision)
	if(trace["surfacetype"] == "default")
		return true;
	*/
	
	//not an entity
	if(!isDefined(trace["entity"]))
		return true;

	//an entity
	if(isPlayer(trace["entity"]))
	{
		iPrintLnBold("collided with " + trace["entity"].name);
		trace["entity"] thread pushPlayer(self, 1, 5, false, true);
		return false;
	}
	else
	{
		//depending on the entity we might have to do damage or stop the vecihle
		//but that has to be checked in later process of the development
		
		if(trace["entity"].classname != "noclass")
			iPrintLnBold("collided with " + trace["entity"].classname);
		else
		{
			if(trace["entity"].isCorpse)
				iPrintLnBold("collided with a corpse");
			else
				iPrintLnBold("collided with an entity but no player");
		}
		
		return false;
	}
}