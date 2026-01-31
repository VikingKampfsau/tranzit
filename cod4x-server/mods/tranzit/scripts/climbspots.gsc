#include scripts\_include;

init()
{
	thread loadLadders();
	thread loadJumpTriggers();
	thread loadMantleTriggers();
}

/*-----------------------|
|         shared         |
|-----------------------*/
invertAngle(a)
{
	if(a > 0)
		return a - 180;
	else
		return a + 180;
}

botCheckLadderAndMantleWeapon()
{
	self endon("disconnect");
	self endon("death");

	while(1)
	{
		while(!self isOnLadder() && !self isMantling())
			wait .05;

		//force crouch - this fixes stuck bots when mantling e.g. a window
		self botAction("+gocrouch");

		//here?
		//self enableWeapons();
		//self switchToWeapon(self.zombieWeapon);
		//self setSpawnWeapon(self.zombieWeapon);

		wait .1;
		
		//or there?
		self enableWeapons();
		self switchToWeapon(self.zombieWeapon);
		self setSpawnWeapon(self.zombieWeapon);

		//reset the forced crouch
		self botAction("-gocrouch");
	}
}

/*-----------------------|
|        ladders         |
|-----------------------*/
loadLadders()
{
	level.ladderTriggers = getEntArray("trigger_ladder", "targetname");
		
	if(!isDefined(level.ladderTriggers) || !level.ladderTriggers.size)
		return;
	
	for(i=0;i<level.ladderTriggers.size;i++)
		level.ladderTriggers[i] thread initLadder();
}

initLadder()
{
	self endon("death");

	self.bottom = getEnt(self.target, "targetname");
	if(!isDefined(self.bottom))
	{
		self delete();
		return;
	}
	
	self.top = getEnt(self.bottom.target, "targetname");	
	if(!isDefined(self.top))
	{
		self delete();
		return;
	}
	
	if(game["debug"]["status"] && game["debug"]["climbSpotShow"])
	{
		bottomModel = spawn("script_model", self.bottom.origin);
		topModel = spawn("script_model", self.top.origin);
		
		bottomModel.angles = VectorToAngles(topModel.origin - bottomModel.origin);
		topModel.angles = VectorToAngles(bottomModel.origin - topModel.origin);
		
		bottomModel setModel("com_teddy_bear");
		topModel setModel("com_teddy_bear");
	}
	
	waypointBottom = getNearestWp(self.bottom.origin, 0);
	waypointTop = getNearestWp(self.top.origin, 0);
	
	addWpNeighbour(waypointBottom, waypointTop);
	addWpNeighbour(waypointTop, waypointBottom);

	self.inUse = false;

	while(1)
	{
		for(i=0;i<level.players.size;i++)
		{
			if(level.players[i] isTouching(self) && level.players[i] isAZombie())
			{
				if(!self.inUse && !level.players[i] isOnGround())
				{
					self.inUse = true;
					
					while(isDefined(level.players[i]) && !level.players[i] isOnGround())
						wait .05;
					
					self.inUse = false;
				}
			}
		}
		
		wait .05;
	}
}

botCheckLadderClimb()
{
	self endon("disconnect");
	self endon("death");
	
	if(self.zombieType == "avagadro")
		return;
	
	if(!isDefined(level.ladderTriggers) || level.ladderTriggers.size <= 0)
		return;
		
	startEnt = undefined;
	targetEnt = undefined;
		
	while(1)
	{
		wait .5;
	
		if(self isOnLadder() || self isMantling() || self.doJump || !self isOnGround() || self.climb)
			continue;

		if(isDefined(self.isAttacking) && self.isAttacking)
			continue;
	
		doLadderClimb = false;
		
		if(isDefined(level.ladderTriggers) && level.ladderTriggers.size > 0)
		{
			for(i=0;i<level.ladderTriggers.size;i++)
			{
				//allow one zombie at a time to use it
				//if(level.ladderTriggers[i].inUse)
				//	continue;
			
				if(self isTouching(level.ladderTriggers[i]))
				{
					targetEnts[0] = level.ladderTriggers[i].bottom;
					targetEnts[1] = level.ladderTriggers[i].top;
					
					startEnt = getClosestEnt(self.origin, targetEnts);
					targetEnt = getFarestEnt(self.origin, targetEnts);
					
					if(isDefined(startEnt) && isDefined(targetEnt))
					{
						//make him only climb when looking in the right direction
						//otherwise he will jump when stepping into the trigger
						if(self isLookingInEntDirection(targetEnt) && Distance2d(self.origin, startEnt.origin) <= 15)
						{
							//climb up only - down is a simple move
							if(targetEnt.origin[2] > startEnt.origin[2])
							{
								doLadderClimb = true;
								break;
							}
						}
					}
				}
			}
		}
		
		if(doLadderClimb)
		{
			self botClimbLadder(startEnt.origin, targetEnt.origin);
			continue;
		}
	}
}

#using_animtree("multiplayer");
botClimbLadder(startPos, endPos)
{
	self endon("disconnect");
	self endon("death");
	
	self.climb = true;
	
	if(isDefined(self.linkedMoveHelper))
		self.linkedMoveHelper delete();
	
	self.linkedMoveHelper = spawn("script_model", self.origin);
	
	self freezeControls(true);
	self linkTo(self.linkedMoveHelper);

	climbInfo = spawnStruct();
	climbInfo.totalHeight = CalcDif(self.origin[2], endPos[2]);
	climbInfo.rungTime = getAnimLength(%ai_zombie_ladder_climb); //climbs 32,33 up
	climbInfo.rungHeight = 32.33;
	climbInfo.rungAmount = int(climbInfo.totalHeight / climbInfo.rungHeight);

	for(i=0;i<climbInfo.rungAmount;i++)
	{
		//up
		if(startPos[2] < endPos[2])
		{
			if(self.origin[2] > endPos[2])
				break;
		
			targetPos = BotPlayerPhysicsTrace(self.origin, self.origin + (0,0,climbInfo.rungHeight));
		}
		else
		{
			if(self.origin[2] <= endPos[2])
				break;
		
			targetPos = BotPlayerPhysicsTrace(self.origin, self.origin - (0,0,climbInfo.rungHeight));
		}
		
		self setWorldmodelAnim("both", "ai_zombie_ladder_climb");
		self.linkedMoveHelper moveTo(targetPos, climbInfo.rungTime);
		wait climbInfo.rungTime;
	}

	//perform a little forward push to make sure he will not fall down the ladder
	if(startPos[2] < endPos[2])
		targetPos = BotPlayerPhysicsTrace(self.origin, endPos + AnglesToForward(self.angles)*(Distance2d(self.origin, endPos)+5));
	else
		targetPos = BotPlayerPhysicsTrace(self.origin, endPos);
	
	self.linkedMoveHelper moveTo(targetPos, 0.5);
	wait .05;

	self unLink();
	self freezeControls(false);
	
	self.linkedMoveHelper delete();
	
	self.climb = false;
}

/*-----------------------|
|      high jumps        |
|-----------------------*/
loadJumpTriggers()
{
	level.jumpTriggers = getEntArray("trigger_jump", "targetname");
	
	for(i=0;i<level.jumpTriggers.size;i++)
		level.jumpTriggers[i] thread initJumpTrigger();
}

initJumpTrigger()
{
	self endon("death");
	
	targetEnts = getEntArray(self.target, "targetname");
	if(!isDefined(targetEnts) || targetEnts.size != 2)
	{
		self delete();
		return;
	}
	
	if(game["debug"]["status"] && game["debug"]["climbSpotShow"])
	{
		bottomModel = spawn("script_model", targetEnts[0].origin);
		topModel = spawn("script_model", targetEnts[1].origin);
		
		bottomModel.angles = VectorToAngles(topModel.origin - bottomModel.origin);
		topModel.angles = VectorToAngles(bottomModel.origin - topModel.origin);
		
		bottomModel setModel("com_teddy_bear");
		topModel setModel("com_teddy_bear");
	}
	
	addWpNeighbour(getNearestWp(targetEnts[0].origin, 0), getNearestWp(targetEnts[1].origin, 0));
	addWpNeighbour(getNearestWp(targetEnts[1].origin, 0), getNearestWp(targetEnts[0].origin, 0));
	
	self.inUse = false;

	while(1)
	{
		for(i=0;i<level.players.size;i++)
		{
			if(level.players[i] isTouching(self) && level.players[i] isAZombie())
			{
				if(!self.inUse && !level.players[i] isOnGround())
				{
					self.inUse = true;
					
					while(isDefined(level.players[i]) && !level.players[i] isOnGround())
						wait .05;
					
					self.inUse = false;
				}
			}
		}
		
		wait .05;
	}
}

botCheckHighJump()
{
	self endon("disconnect");
	self endon("death");
	
	if(self.zombieType == "avagadro")
		return;
	
	if(!isDefined(level.jumpTriggers) || level.jumpTriggers.size <= 0)
		return;
		
	startEnt = undefined;
	targetEnt = undefined;
		
	while(1)
	{
		wait .5;
	
		if(self isOnLadder() || self isMantling() || self.doJump || !self isOnGround() || self.climb)
			continue;

		if(isDefined(self.isAttacking) && self.isAttacking)
			continue;
	
		doJump = false;
		
		if(isDefined(level.jumpTriggers) && level.jumpTriggers.size > 0)
		{
			for(i=0;i<level.jumpTriggers.size;i++)
			{
				//allow one zombie at a time to use it
				//if(level.jumpTriggers[i].inUse)
				//	continue;
			
				if(self isTouching(level.jumpTriggers[i]))
				{
					targetEnts = getEntArray(level.jumpTriggers[i].target, "targetname");
					
					if(!isDefined(targetEnts) || targetEnts.size <= 0)
						continue;
				
					startEnt = getClosestEnt(self.origin, targetEnts);
					targetEnt = getFarestEnt(self.origin, targetEnts);
					
					if(isDefined(startEnt) && isDefined(targetEnt))
					{
						//make him only jump when looking in the right direction
						//otherwise he will jump when stepping into the trigger
						if(self isLookingInEntDirection(targetEnt))
						{
							//jump up only - down is a simple move
							if(targetEnt.origin[2] > startEnt.origin[2])
							{
								doJump = true;
								break;
							}
						}
					}
				}
			}
		}
		
		if(doJump)
		{
			self botJump(startEnt.origin, targetEnt.origin);
			continue;
		}
	}
}

#using_animtree("multiplayer");
botJump(jumpStart, jumpTarget)
{
	self endon("disconnect");
	self endon("death");

	self botStop();

	self.doJump = true;
	while(self getStance() != "stand")
	{
		self setStance("stand");
		wait .05;
	}

	//stock jump or mantle
	if(!isDefined(jumpTarget))
	{
		self botAction("+gostand");
		wait .05;
		self botAction("-gostand");
	}
	//high jump
	else
	{
		if(isDefined(self.linkedMoveHelper))
			self.linkedMoveHelper delete();
		
		self.linkedMoveHelper = spawn("script_model", jumpStart);
		
		self freezeControls(true);
		self linkTo(self.linkedMoveHelper); //avoids flickering caused by gravity
		
		jumpTimes = spawnStruct();
		jumpTimes.land = getAnimLength(%ai_zombie_land);				//0,83
		jumpTimes.up_total = getAnimLength(%ai_zombie_jump_up);			//1,167
		jumpTimes.up_bend =  0.86;										//0,86 seconds
		jumpTimes.up_air = jumpTimes.up_total - jumpTimes.up_bend;	//0,307 seconds
		jumpTimes.total = jumpTimes.up_total + jumpTimes.land;
		
		self setWorldmodelAnim("both", "ai_zombie_jump_up");
		wait jumpTimes.up_bend;
		self.linkedMoveHelper fake_physicslaunch_over_time(jumpTarget, (jumpTimes.up_air + jumpTimes.land));
		wait (jumpTimes.up_air);
		wait (jumpTimes.land);
		
		self unlink();
		self freezeControls(false);
		
		self.linkedMoveHelper delete();
	}
	
	self.doJump = false;
}
/*-----------------------|
|         mantle         |
|-----------------------*/
loadMantleTriggers()
{
	level.mantleTriggers = getEntArray("trigger_mantle", "targetname");
	
	for(i=0;i<level.mantleTriggers.size;i++)
		level.mantleTriggers[i] thread initMantleTrigger();
}

initMantleTrigger()
{
	self endon("death");
	
	targetEnts = getEntArray(self.target, "targetname");
	if(!isDefined(targetEnts) || targetEnts.size != 2)
	{
		self delete();
		return;
	}
	
	if(game["debug"]["status"] && game["debug"]["climbSpotShow"])
	{
		startModel = spawn("script_model", targetEnts[0].origin);
		endModel = spawn("script_model", targetEnts[1].origin);
		
		startModel.angles = VectorToAngles(endModel.origin - startModel.origin);
		endModel.angles = VectorToAngles(startModel.origin - endModel.origin);
		
		startModel setModel("com_teddy_bear");
		endModel setModel("com_teddy_bear");
	}
	
	addWpNeighbour(getNearestWp(targetEnts[0].origin, 0), getNearestWp(targetEnts[1].origin, 0));
	addWpNeighbour(getNearestWp(targetEnts[1].origin, 0), getNearestWp(targetEnts[0].origin, 0));
	
	self.inUse = false;

	while(1)
	{
		for(i=0;i<level.players.size;i++)
		{
			if(level.players[i] isTouching(self) && level.players[i] isAZombie())
			{
				if(!self.inUse && level.players[i] isMantling())
				{
					self.inUse = true;
					
					while(isDefined(level.players[i]) && level.players[i] isMantling())
						wait .05;
					
					self.inUse = false;
				}
			}
		}
		
		wait .05;
	}
}

botCheckMantle()
{
	self endon("disconnect");
	self endon("death");
	
	if(self.zombieType == "avagadro")
		return;
	
	if(!isDefined(level.mantleTriggers) || level.mantleTriggers.size <= 0)
	{
		//do not return on rotu maps or the bot teleport through clipswont work
		if(game["tranzit"].mapType != "rotu")
			return;
	}
		
	while(1)
	{
		wait .5;
	
		if(self isOnLadder() || self isMantling() || self.doJump || self.climb)
			continue;

		if(isDefined(self.isAttacking) && self.isAttacking)
			continue;
	
		doMantle = false;
		isInMantleTrigger = false;
		
		if(isDefined(level.mantleTriggers) && level.mantleTriggers.size > 0)
		{
			for(i=0;i<level.mantleTriggers.size;i++)
			{
				//allow one zombie at a time to use it
				//if(level.mantleTriggers[i].inUse)
				//	continue;
			
				if(self isTouching(level.mantleTriggers[i]))
				{
					isInMantleTrigger = true;
					targetEnts = getEntArray(level.mantleTriggers[i].target, "targetname");
					
					if(!isDefined(targetEnts) || targetEnts.size <= 0)
						continue;
				
					targetEnt = getFarestEnt(self.origin, targetEnts);
					
					if(isDefined(targetEnt))
					{
						if(self isLookingAtEntity(targetEnt) && self.origin[2] <= targetEnt.origin[2])
						{
							doMantle = true;
							break;
						}	
					}
					else
					{
						for(j=0;j<targetEnts.size;j++)
						{
							if(self isLookingAtEntity(targetEnts[j]) && self.origin[2] <= targetEnts[j].origin[2])
							{
								doMantle = true;
								break;
							}
						}
						
						if(doMantle)
							break;
					}
				}
			}
		}
		
		if(doMantle)
		{
			self botMantle();
			continue;
		}
		else
		{
			if(!isInMantleTrigger && isDefined(self.nextWp))
			{
				//teleport bots through clips (rotu maps usually use clip instead of clip_player at zombie entrances)
				if(game["tranzit"].mapType == "rotu")
				{
					//we can run up to 16 units without jumping
					//default jump height is 39
					trace = BotPlayerPhysicsTrace(self.origin + (0,0,17), getWpOrigin(self.nextWp) + (0,0,17));
					if(trace != getWpOrigin(self.nextWp) + (0,0,17))
					{
						if(Distance(self.origin + (0,0,17), trace) < 64)
							self scripts\zombies::moveThroughClip(getWpOrigin(self.nextWp) + (0,0,17), 27);
					}
				}
			}
		}
	}
}

botMantle()
{
	self botJump();
}