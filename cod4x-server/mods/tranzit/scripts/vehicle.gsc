#include common_scripts\utility;
#include maps\mp\_utility;

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

	curnode = getEnt("tranzit_start", "targetname");
	
	if(!isDefined(curnode))
		return;

	level.tranzitVehiclemaxSpeed = 210; //250;
	level.tranzitVehicleminSpeed = -105;
	
	level.tranzitPath = [];
	while(1)
	{
		if(!isDefined(curnode.script_wait))
			curnode.script_wait = 0;

		if(!isDefined(curnode.speed))
			curnode.speed = level.tranzitVehiclemaxSpeed;
	
		level.tranzitPath[level.tranzitPath.size] = curnode;

		nextnode = getEnt(curnode.target, "targetname");

		if(nextnode.target == "")
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
	
	level.tranzitVehicle = getEnt("tranzit_vehicle", "targetname");
	level.tranzitVehicle thread initVehicle();
}

initVehicle()
{
	self endon("death");
	
	//model & brush size (values taken from radiant)
	//to calculate collisions and rotation
	self.width = 46;
	self.height = 64;
	self.forwards = 72;
	self.backwards = -64;
	
	self.maxHealth = 1000;
	self.health = self.maxHealth;
	self.status = "alive";
	
	self.speed = 0;
	self.maxSpeed = level.tranzitVehiclemaxSpeed;
	self.minSpeed = level.tranzitVehicleminSpeed;
	self.accel = 7; //4;
	self.deccel = 5; //3;
	self.gear = 1;
	
	self.collisionBrush = getEnt("tranzit_vehicle_collision", "targetname");
	self.collisionBrush linkTo(self);
	
	self.curPos = level.tranzitPath[0];
	self.origin = level.tranzitPath[0].origin;
	self.nextPos = self vehicleGetNextDestination();

	if(isDefined(self.nextPos))
		self.angles = VectorToAngles(self.nextPos.origin - self.origin);

	self.baseAngles = self.angles; //this is important, else the rotation is wrong when the vehicle prefabs is not angles (0,0,0)

	//LinkTo() does not allow the player to stand on the brush
	//so we have to move this brush just like the vehicle itself	
	self.loadingArea = getEnt("tranzit_vehicle_loadingarea", "targetname");
	self.loadingArea.origin = self.origin;
	self.loadingArea.angles = self.angles - self.baseAngles;

	//LinkTo() does not work with triggers
	//so we have to move this brush just like the vehicle itself	
	self.loadingAreaTrigger = getEnt("tranzit_vehicle_loadingarea_trigger", "targetname");
	self.loadingAreaTrigger.origin = self getTagOrigin("tag_loading_area");
	self.loadingAreaTrigger.angles = self.angles - self.baseAngles;
	
	//LinkTo() does not work with triggers
	//so i add that trigger to the global mantleTriggers array
	self.mantleTrigger = getEnt("trigger_mantle_vehicle", "targetname");
	self.mantleTriggerLookEnt = getEnt(self.mantleTrigger.target, "targetname");
	self.mantleTriggerLookEnt.origin = self.origin - AnglesToForward(self.angles)*92 + (0,0,44);
	self.mantleTriggerLookEnt linkTo(self);
	
	self thread VehicleMantleTriggerStatus(true, true);
	self thread VehicleLoadingAreaTriggerStatus();
	self thread monitorPlayerJumpInAttempt();

	self thread vehicleWaiter(undefined);
	self thread CalculateSpeedBehaviour();
	
	if(!isDefined(level.mantleTriggers))
		wait 5;
	
	if(!isDefined(level.mantleTriggers))
		level.mantleTriggers = [];
		
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
		
		if(self.speed == 0)
			continue;
		
		if(player isMantling())
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
	
	wait .25;
	for(i=1;i<10;i++)
	{
		self setOrigin(level.tranzitVehicle.mantleTriggerLookEnt.origin + (0,0,1));
		wait .05;
	}
	
	self.mantleInVehicle = false;
}

VehicleMantleTriggerStatus(enabled, linked)
{
	self endon("death");
	self endon("stop_vehicle_mantle_trigger");

	self.mantleTrigger.angles = self.angles - self.baseAngles;

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
		
			if(level.players[i].origin[2] > self.loadingAreaTrigger.origin[2] && level.players[i] isTouching(self.loadingAreaTrigger))
				level.players[i].isOnTruck = true;
			else
			{
				if(level.players[i].isOnTruck)
					level.players[i] unlink();
				
				level.players[i].isOnTruck = false;
			}
			
			if(level.players[i] isASurvivor() && isAlive(level.players[i]))
			{
				if(level.players[i].isOnTruck)
				{
					if(!level.players[i] isMoving() && !level.players[i] Jumped())
						level.players[i] linkTo(self);
					else
						level.players[i] unlink();
				}
			}
		}
		
		wait .1;
	}
}

//did not get this debug to work - propably because the formular is calculating with m/s but the variables are inch/s
CalculateSpeedBehaviour()
{
	self endon("death");

	/*
	startSpeed = 0; 
	finalrun = false;
	result = undefined;
	path = level.tranzitPath;
	
	for(i=0;i<path.size && !finalrun;i++)
	{
		start = path[i];
		target = path[i+1];
		
		if(!isDefined(target)) 
		{
			target = path[0];
			finalrun = true;
		}

		if(target == start) 
		{
			iPrintLnBold("Error: start and end are equal");
			break;
		} 

		distToMove = Distance(start.origin, target.origin);
		
		maxSpeed = [];  
		acceleration = [];
		deccelaration = [];
		
		if(!isDefined(startSpeed) || startSpeed == 0)
			startSpeed = 1;
			
		for(v=startSpeed;10<=self.maxspeed;v++)
		{
			maxSpeed[v-1] = spawnStruct();
			acceleration[v-1] = spawnStruct();
			deccelaration[v-1] = spawnStruct();
			
			//we have to devide the path into subparts
			//1 = acceleration
			//1.1 we start from 0 speed
			if(path[i].script_wait > 0) 
			{
				acceleration[v-1].time = v / self.accel;
				acceleration[v-1].dist = 0.5 * self.accel * acceleration[v-1].time * acceleration[v-1].time;
			} 
			//1.2 we did not stop at the node and have speed left
			else
			{
				//v = a * t + startSpeed
				acceleration[v-1].time = (v - startSpeed) / self.accel;
				acceleration[v-1].dist = 0.5 * self.accel * acceleration[v-1].time * acceleration[v-1].time + startSpeed * acceleration[v-1].time;
			} 
			
			//2 = deccelaration 
			//2.1 final speed is 0 (stop at node) 
			if(path[i].script_wait > 0)
			{
				deccelaration[v-1].time = v / self.deccel;
				deccelaration[v-1].dist = 0.5 * self.deccel * deccelaration[v-1].time * deccelaration[v-1].time ;
				startSpeed = 0;
			}
			else
			//2.2 final speed not 0 (accelerate or deccelarate to new speed) 
			{
				//deccelarate (for sure the usual case) 
				if(isDefined(target.speed) && target.speed < v) 
				{
					deccelaration[v-1].time = v / self.deccel;
					deccelaration[v-1].dist = 0.5 * self.deccel * deccelaration[v-1].time * deccelaration[v-1].time;
					startSpeed = target.speed;
				} 
				//accelarate (could happen but i dont think very often) 
				//does this make sense at all? We accelerate after reaching it anyways 
				//else if(target.speed > v) 
				//{
				//	deccelaration[v-1].time = v / self.accel;
				//	deccelaration[v-1].dist = 0.5 * self.accel * deccelaration[v-1].time * deccelaration[v-1].time; ;
				//	startSpeed = target.speed;
				//}
				//keep up the speed
				else
				{
					deccelaration[v-1].time = 0;
					deccelaration[v-1].dist = 0;
					startSpeed = v;
				} 
			} 
			
			//3 = full speed between acceleration and deccelaration
			//no space left to move with full speed
			if((acceleration[v-1].dist + deccelaration[v-1].dist) >= distToMove)
			{
				maxSpeed[v-1].dist= 0;
				maxSpeed[v-1].time = 0;
				
				//v-1 is giving the result we are looking for
				result = v - 2;
				break;
			} 
			//enough space to move with full speed 
			else
			{
				maxSpeed[v-1].dist = (distToMove - acceleration[v-1].dist - deccelaration[v-1].dist);
				maxSpeed[v-1].time = maxSpeed[v-1].dist / v;
				
				//if v is not the max speed then we can not stop yet
				//because it's not sure how far the acceleration can go
				if(v != self.maxspeed)
					continue;
				
				//if v is at max then this is giving the result we are looking for
				result = v - 1;
			}
		}
		
		if(isDefined(result))
		{
			path[i].timeAccel = acceleration[result].time;
			path[i].timeDeccel = deccelaration[result].time;
			path[i].timeMaxSpeed = maxSpeed[result].time;
			path[i].timeTotalMove = path[i].timeAccel + path[i].timeDeccel + path[i].timeMaxSpeed;
	
			path[i].distAccel = acceleration[result].dist;
			path[i].distDeccel = deccelaration[result].dist;
			path[i].distMaxSpeed = maxSpeed[result].dist;
			path[i].distTotalMove = distToMove;
			
			result = undefined;
		} 
	} 
	
	for(i=0;i<1path.size;i++)
	{
		iPrintLnBold("acc " + path[i].timeAccel);
		iPrintLnBold("max " + path[i].timeMaxSpeed);
		iPrintLnBold("decc " + path[i].timeDeccel);
	}
	
	iPrintLnBold("calc done");
	*/
	
	self notify("tranzit_vehicle_init_done");
}

vehicleWaiter(delay)
{
	self endon("death");

	self waittill("tranzit_vehicle_init_done");

	while(!game["tranzit"].playersReady)
		wait .5;

	if(!isDefined(delay))
		delay = 9999999999;

	self.trigger = getEnt("vehicle_trigger", "targetname");
	if(!isDefined(self.trigger))
		self.trigger = spawn("trigger_radius", self.origin, 0, 120, 100);
	else
	{
		self.trigger.origin = self.origin;
		self.trigger.angles = self.angles - self.baseAngles;
	}

	engineStarted = false;
	while(delay > 0)
	{
		for(i=0;i<level.players.size;i++)
		{
			if(level.players[i] isASurvivor() && level.players[i] isTouching(self.trigger))
			{
				level.players[i] thread showTriggerUseHintMessage(self.trigger, level.players[i] getLocTextString("VEHICLE_START_PRESS_BUTTON"));
				
				if(level.players[i] isReadyToUse() && level.players[i] UseButtonPressed())
				{
					self.trigger.origin = self.trigger.origin + (0,0,10000);
					engineStarted = true;
					break;
				}
			}
		}
		
		if(engineStarted)
			break;

		wait .05;
		delay -= .05;
	}
	
	//give the trigger message some time to notice the trigger is gone
	wait 1;
	
	//and when the message disappeared we can move the trigger back in place
	self.trigger.origin = self.trigger.origin - (0,0,10000);

	self thread vehicleThink();
}

vehicleThink()
{
	self endon("death");
	
	self playSoundRef("hummer_start");
	
	wait 2;
	
	//self thread VehicleMantleTriggerStatus(false);
	
	if(isDefined(self GetTagOrigin("tag_light_left_front")))
		playfxontag(level._effect["vehicle_light"], self, "tag_light_left_front");
	
	if(isDefined(self GetTagOrigin("tag_light_right_front")))
		playfxontag(level._effect["vehicle_light"], self, "tag_light_right_front");
	
	self.curPos = level.tranzitPath[0];
	self.origin = level.tranzitPath[0].origin;
	self.nextPos = self vehicleGetNextDestination();
	
	if(isDefined(self.nextPos))
	{
		self.angles = VectorToAngles(self.nextPos.origin - self.origin);
			
		self.loadingArea.origin = self.origin;
		self.loadingArea.angles = self.angles - self.baseAngles;
		
		self.loadingAreaTrigger.origin = self getTagOrigin("tag_loading_area");
		self.loadingAreaTrigger.angles = self.angles - self.baseAngles;
	}
	
	moveSound = false;
	playExhaustFX = false;
	distBreak = undefined;
	timeStep = 0.1;
	
	while(1)
	{
		wait timeStep;
		
		self.trigger.origin = self.origin;
		self.trigger.angles = self.angles - self.baseAngles;
		
		playExhaustFX = !playExhaustFX;
		
		if(playExhaustFX)
		{
			if(isDefined(self GetTagOrigin("tag_exhaust")))
				playfxontag(level._effect["vehicle_exhaust"], self, "tag_exhaust");
		}
		
		self.anglesForward = anglesToForward(self.angles);
		self.anglesRight = anglesToRight(self.angles);

		if(self.speed < self.maxSpeed && !isDefined(distBreak))
			self.speed += self.accel;
		
		if(self.speed > self.maxSpeed)
			self.speed = self.maxSpeed;
		else if(self.speed < self.minSpeed)
			self.speed = self.minSpeed;

		self.gear = 1;

		if(self.speed < 0)
			self.gear = -1;

		if(self.speed * self.gear >= 0)
		{
			// check the vehicle collision:
			// use simple 2 traces from each side to the center + a forwad ofset
			// this method is more safe than checking against a horizontal or
			// vertical trace			
			s = vectorScale(self.anglesRight, self.width);
			h = (0, 0, self.height);

			if(self.gear > 0)
			{
				f = vectorScale(self.anglesForward, self.forwards);
				fs = vectorScale(self.anglesForward, self.speed * self.gear); //self.maxSpeed);
			}
			else
			{
				f = vectorScale(self.anglesForward, self.backwards);
				fs = vectorScale(self.anglesForward, self.speed * self.gear); //self.minSpeed);
			}

			trace = bulletTrace(self.origin + s + h + f, self.origin - s + h + f + fs, true, self);

			// skip the second if were colliding in the first instance
			if(trace["fraction"] == 1)
				trace = bulletTrace(self.origin - s + h + f, self.origin + s + h + f + fs, true, self);

			// if the trace collision isnt a real collision, move the vehicle 
			if(!self isColliding(trace))
			{
				target = self vehicleGetNextDestination();
				self.nextPos = target;

				//rotation: (pitch (up/down), yaw(left/right), roll)
				rotateDirection = VectorToAngles(target.origin - self.origin);

				chord = Distance(self.origin, target.origin);
				angles = rotateDirection; //VectorToAngles(target.origin - self.curPos.origin);
				alpha = abs(angles[1]);
				
				while(alpha >= 180)
					alpha -= 180;

				if(alpha == 0)
					arclength = chord;
				else
				{
					radius = chord/(2*sin(alpha/2));	
					arclength = (radius * 3.14159265359 * alpha) / 180;
				}
			
				if(self.speed != 0)
					time = abs(arclength / self.speed * timeStep);
				else
					time = timeStep;

				// fetch the ground-pos and align the vehicle
				s = vectorScale(self.anglesRight, self.width);
				f = vectorScale(self.anglesForward, self.forwards + self.speed);
				b = vectorScale(self.anglesForward, self.backwards);
				h = (0, 0, int(self.height/2));
				flt = bulletTrace(self.origin + f - s + h, self.origin + f - s - h, false, self);
				frt = bulletTrace(self.origin + f + s + h, self.origin + f + s - h, false, self);
				bt = bulletTrace(self.origin + b + h, self.origin + b - h, false, self);
				diff = frt["position"] - flt["position"];
				pitch = vectorToAngles(flt["position"] + vectorScale(diff, 0.5) - bt["position"]);
				roll = vectorToAngles(diff);
				
				//finally move it
				distToTarget = Distance(self.origin, target.origin);
				distanceToMove = (self.speed * timeStep);
				
				if(distToTarget < 1)
					distToTarget = 0;
				
				if(distToTarget < distanceToMove)
					distanceToMove = distToTarget;
				
				//iPrintLnBold(distToTarget + " / " + distanceToMove);
				
				moveVec = vectorNormalize(target.origin - self.origin); //self.anglesForward; //direct way: moveVec = vectorNormalize(target.origin - self.origin);
				desiredPosition = vectorScale (moveVec, distanceToMove);
				desiredPosition = desiredPosition + self.origin;
				
				if(distToTarget >= 1)
				{
					self.angles = (pitch[0], self.angles[1], roll[0]);
					self rotateTo((0, rotateDirection[1], 0), time);
					self moveTo(desiredPosition, timeStep);
					
					self.loadingArea rotateTo((0, rotateDirection[1], 0) - self.baseAngles, time);
					self.loadingArea moveTo(desiredPosition, timeStep);
					
					self.loadingAreaTrigger.origin = self getTagOrigin("tag_loading_area");
					self.loadingAreaTrigger.angles = self.angles - self.baseAngles;
					
					if(!moveSound)
					{
						moveSound = true;
						self stopLoopSound();
						self playLoopSoundRef("hummer_engine_high");
					}
				}
				
				if(!isDefined(distBreak))
				{
					distBreak = ((self.speed * timeStep * self.speed * timeStep) / (2 * self.deccel * timeStep));
					distBreak += distanceToMove;
					
					self.speed -= self.deccel;
				}

				
				//iPrintLnBold("dist: " + Distance(self.origin, target.origin));

				//when about to reach the target and
				if(distToTarget <= distBreak)
				{
					//stop at target
					//works
					if(target.script_wait > 0)
					{
						self.speed -= self.deccel;

						//now we are that close that we can say we are there
						if(distToTarget <= self.speed)
							self.speed = 0;

					}
					//pass the target
					else
					{
						//but has to slow down
						//works
						if(target.speed < self.speed)
							self.speed -= self.deccel;
					
						//and keep the speed = do nothing
						//works - lol
						
						//now we are that close that we can say we pass it
						//works
						if(distToTarget <= self.speed)
							self.curPos = target;
					}

					//target reached
					//works
					if(self.speed <= 0)
					{
						self.speed = 0;
						self.curPos = target;
						
						if(moveSound)
						{
							moveSound = false;
							self stopLoopSound();
							self playLoopSoundRef("hummer_idle_high");
						}
						
						//stop at target and wait a bit
						if(target.script_wait > 0)
						{
							//consolePrint("vehicle at bus stop\n");
							//consolePrint("origin: " + self.origin + "\n");
							//consolePrint("angles: " + self.angles + "\n");
						
							self thread VehicleMantleTriggerStatus(true, true);
						
							if(target.script_wait < 30)
								wait target.script_wait;
							else
							{
								wait (target.script_wait - 15);
								self playSoundRef("horn_warn");
								wait 15;
							}
							
							self playSoundRef("horn_leave");
							//self thread VehicleMantleTriggerStatus(false);
							
							distBreak = undefined;
							continue;
						}
					}					
				}
				else
				{
					distBreak = undefined;
					self.speed += self.deccel;
				}
			}
		}
	}
}

vehicleGetNextDestination()
{
	self endon("death");
	
	if(self.gear > 0)
		return getEnt(self.curPos.target, "targetname");
	
	if(self.gear < 0 && self.origin == self.curPos.origin)
		return getEnt(self.curPos.targetname, "target");
	
	return self.curPos;
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
		trace["entity"] thread bouncePlayerBack(self);
		return false;
	}
	else
	{
		//depending on the entity we might have to do damage or stop the vecihle
		//but that has to be checked in later process of the development
		return false;
	}
}

bouncePlayerBack(vehicle)
{
	self endon("disconnect");
	self endon("death");

	if(self isAZombie())
	{
		vDir = vectorNormalize(self.origin - vehicle.origin);
		self thread [[level.callbackPlayerDamage]](vehicle, self, self.health, 0, "MOD_CRUSH", "none", self.origin, vDir, "none", 0);
		return;
	}
	
	power = 1000;
	for(i=0;i<5;i++)
	{
		health = self.health;
		self.health += power;

		self finishPlayerDamage(vehicle, self, power, 0, "MOD_PROJECTILE", "none", vehicle.origin, self.origin - vehicle.origin, "none", 0);

		self.health = health;
		self setNormalHealth(self.health);
	}
}