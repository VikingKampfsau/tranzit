#include scripts\_include;

init()
{
	add_sound("break_barrier_piece", "break_boards");
	add_sound("rebuild_barrier_piece", "repair_boards");
	add_sound("barrier_rebuild_slam", "board_slam");
	
	add_sound("debris_move", "whoosh");

	thread loadDoors();
	thread loadBlockers();
	thread loadBarricades();
}

loadDoors()
{
	level.doors = getEntArray("door", "targetname");
		
	if(!isDefined(level.doors) || !level.doors.size)
		return;
		
	//loop through all doors and find the linked parts
	for(i=0;i<level.doors.size;i++)
		level.doors[i] thread initDoor();
}

initDoor()
{
	self endon("death");
	
	if(isDefined(self.radius) && isDefined(self.height))
		self.trigger = spawn("trigger_radius", self.origin - (0,0,25), 0, self.radius, self.height);
	else
	{
		if(isDefined(self.radius) && !isDefined(self.height))
			self.trigger = spawn("trigger_radius", self.origin - (0,0,25), 0, self.radius, 64);
		else if(!isDefined(self.radius) && isDefined(self.height))
			self.trigger = spawn("trigger_radius", self.origin - (0,0,25), 0, 32, self.height);
		else
			self.trigger = spawn("trigger_radius", self.origin - (0,0,25), 0, 32, 64);
	}
	
	while(1)
	{
		self.trigger waittill("trigger", player);
		
		if(!player isReadyToUse())
			continue;
		
		player thread showTriggerUseHintMessage(self.trigger, player getLocTextString("BARRICADES_DOOR_OPEN"), scripts\money::getPrice("barricade_open_door"));
		
		if(!player scripts\money::hasEnoughMoney("barricade_open_door"))
			continue;
		
		if(player UseButtonPressed())
		{		
			player thread [[level.onXPEvent]]("barricade_open_door");
			self thread openDoor();
			break;
		}
	}
	
	self.trigger delete();
}

openDoor()
{
	//show disappear fx and sound
	playfx(level._effect["entitiy_disappear"], self.origin);
	playsoundatposition("debris_move", self.origin);

	self vibrate((randomIntRange(5,10), randomIntRange(5,10), 0), 10, 0.5, 3);

	//connect the waypoints to allow zombies to move through the doorway
	waypoints = getEntArray(self.target, "targetname");

	addWpNeighbour(getNearestWp(waypoints[0].origin, 0), getNearestWp(waypoints[1].origin, 0));
	addWpNeighbour(getNearestWp(waypoints[1].origin, 0), getNearestWp(waypoints[0].origin, 0));

	for(i=0;i<waypoints.size;i++)
		waypoints[i] delete();
	
	//activate spawns that are inside this area
	if(isDefined(self.groupname))		
		thread scripts\spawnlogic::toggleSpawnGroup(self.groupname, true);
	
	//wait until the end of the vibration
	wait 3;
	
	self delete();
}

loadBlockers()
{
	level.blockers = getEntArray("blocker", "targetname");
	
	if(!isDefined(level.blockers) || !level.blockers.size)
		return;
	
	//loop through all blockers and find the linked parts
	for(i=0;i<level.blockers.size;i++)
	{
		level.blockers[i].parts = [];
		parts = getEntArray(level.blockers[i].target, "targetname");
		
		for(j=0;j<parts.size;j++)
		{
			parts[j].startPos = parts[j].origin;
			parts[j].targetPos = parts[j].origin + (0, 0, 5000);
			
			level.blockers[i].parts[level.blockers[i].parts.size] = parts[j];
		}
		
		level.blockers[i] thread initBlocker();
	}
}

initBlocker()
{
	self endon("death");
	
	self.trigger = spawn("trigger_radius", self.origin - (0,0,25), 0, 180, 262);

	while(1)
	{
		self.trigger waittill("trigger", player);
		
		if(!player isReadyToUse())
			continue;
		
		player thread showTriggerUseHintMessage(self.trigger, player getLocTextString("BARRICADES_BLOCKER_OPEN"), scripts\money::getPrice("barricade_open_door"));
		
		if(!player scripts\money::hasEnoughMoney("barricade_open_door"))
			continue;
		
		if(player UseButtonPressed())
		{
			player thread [[level.onXPEvent]]("barricade_open_door");
			self thread removeBlocker();
			break;
		}
	}
	
	self.trigger delete();
}

removeBlocker()
{
	//show disappear fx and sound
	playfx(level._effect["entitiy_disappear"], self.origin);
	playsoundatposition("debris_move", self.origin);

	//move it into the sky
	for(i=0;i<self.parts.size;i++)
		self.parts[i] thread removeBlockerParts(self);
	
	self waittill("blocker_removed");

	//connect the waypoints to allow zombies to move the new free way
	waypoints = [];
	for(i=0;i<self.parts.size;i++)
	{
		if(self.parts[i].classname == "script_origin")
			waypoints[waypoints.size] = self.parts[i];
		else
			self.parts[i] delete();
	}

	addWpNeighbour(getNearestWp(waypoints[0].origin, 0), getNearestWp(waypoints[1].origin, 0));
	addWpNeighbour(getNearestWp(waypoints[1].origin, 0), getNearestWp(waypoints[0].origin, 0));

	for(i=0;i<waypoints.size;i++)
		waypoints[i] delete();

	//activate spawns that are inside this area
	if(isDefined(self.groupname))		
		thread scripts\spawnlogic::toggleSpawnGroup(self.groupname, true);

	self delete();
}

removeBlockerParts(mother)
{
	self endon("death");

	self moveZ(18, .5);
	wait .5;

	self vibrate((randomIntRange(25,50), randomIntRange(25,50), 0), 15, 0.5, 3);
	wait 3;
	self moveTo(self.targetPos, abs(self.targetPos[2] - self.startPos[2])/1000);
	wait .1; //wait (abs(self.targetPos[2] - self.startPos[2])/1000);
	
	mother notify("blocker_removed");
}

loadBarricades()
{
	level.barricades = getEntArray("barricade", "targetname");
	parts = getEntArray("barricade_part", "targetname");
	
	//no barricades found - check for rotu map
	if(!isDefined(level.barricades) || !level.barricades.size)
	{
		wait 2;
		
		if(isDefined(level.rotuBarricade))
			level.barricades = getEntArray(level.rotuBarricade["Name"], "targetname");
	}
		
	//nothing found - return
	if(!isDefined(level.barricades) || !level.barricades.size)
		return;
	
	//loop through all barricades and find the linked parts
	for(i=0;i<level.barricades.size;i++)
	{
		level.barricades[i].parts = [];
		
		if(!isDefined(level.rotuBarricade))
		{
			for(j=0;j<parts.size;j++)
			{
				parts[j] solid(); 
				parts[j].startPos = parts[j].origin;
				parts[j].startAngle = parts[j].angles;
				
				if(Distance(parts[j].origin, level.barricades[i].origin) <= 35)
				{
					parts[j].repairPos = level.barricades[i].origin + (0, 60, 25);
					level.barricades[i].parts[level.barricades[i].parts.size] = parts[j];
				}
			}
		}
		else
		{
			parts = [];
			for(j=0;j<100;j++)
			{
				tempParts = getEntArray(level.barricades[i].target + j, "targetname");
				parts[j] = level.barricades[i] getClosestEnt(level.barricades[i].origin, tempParts);

				if(!isDefined(parts[j]))
					break;
					
				parts[j] solid(); 
				parts[j].startPos = parts[j].origin;
				parts[j].startAngle = parts[j].angles;
				parts[j].repairPos = level.barricades[i].origin + (0, 60, 25);
				
				level.barricades[i].parts[level.barricades[i].parts.size] = parts[j];
			}
		}
		
		level.barricades[i] thread initBarricade();
	}
}

initBarricade()
{
	wait 10;

	self endon("death");

	self.isUseable = false;
	self.curPart = 0;
	
	self thread initBarricadeTrigger();
	
	self setCanDamage(true);

	//trigger_damage resets it's health to 32.000 so we have to fix it this way
	self.maxhealth = 100 * self.parts.size;
	self.barricadeHealth = self.maxhealth;
	
	while(1)
	{
		self waittill("damage", damage, attacker);
		
		if(!attacker isAZombie())
			continue;
		
		damage = 100;
		self.barricadeHealth -= damage;
		
		if(self.barricadeHealth < 0)
			self.barricadeHealth = 0;
		
		activePart = (self.parts.size - int(((self.barricadeHealth - 1)  / self.maxhealth) * self.parts.size + 1));

		if(activePart != self.curPart)
		{
			self.parts[self.curPart] removePart();
			self.curPart = activePart;
			
			self.isUseable = true;
			self.trigger.origin = self.origin;
		}
	}
}

initBarricadeTrigger()
{
	self.trigger = spawn("trigger_radius", self.origin, 0, 50, 50);
	self.trigger.origin = self.origin - (0,0,50000);
	
	while(1)
	{
		self.trigger waittill("trigger", player);
		
		if(!player isReadyToUse())
			continue;
		
		if(!self.isUseable)
			continue;
		
		player thread showTriggerUseHintMessage(self.trigger, player getLocTextString("BARRICADES_PLANK_REPAIR"));
		
		if(player UseButtonPressed())
		{
			self.isUseable = false;
			self restorePart(player);
			self.isUseable = true;
		}
	}
}

removePart()
{
	self endon("death");

	if(isDefined(level.barricadeBreakFX))
		PlayFX(level.barricadeBreakFX, self.origin);

	self playSoundRef("break_barrier_piece");
	self notSolid(); 
	
	dist = 100 + RandomInt( 100 );
	dest = self.origin + (AnglesToForward(self.angles) * dist);
	trace = BulletTrace(dest + (0, 0, 16), dest + (0, 0, -200), false, undefined);

	if(trace["fraction"] == 1)
		dest = dest + (0, 0, -200);
	else
		dest = trace["position"];
	
	time = self fake_physicslaunch(dest, 200 + RandomInt(100));
	
	if(RandomInt(100) > 40)
		self RotatePitch(180, time * 0.5);
	else
		self RotatePitch(90, time, time * 0.5); 
	
	wait time;
}

restorePart(player)
{
	self endon("death");

	if(self.curPart > 0)
	{
		self.barricadeHealth = int(self.maxhealth / self.parts.size * (self.parts.size - self.curPart + 1));
		self.curPart--;
		curPart = self.curPart;
		
		self.parts[curPart] rotateTo(self.parts[curPart].startAngle, .05);
		self.parts[curPart] moveTo(self.parts[curPart].repairPos, .5, 0, 0);
		wait .6;
		self.parts[curPart] moveTo(self.parts[curPart].startPos, .1, 0, 0);
		self playSoundRef("barrier_rebuild_slam");
		wait .1;
		self.parts[curPart] solid();
		
		if(isDefined(level.barricadeBuildFX))
			PlayFX(level.barricadeBuildFX, self.origin + (0, 0, 128));
	
		self playSoundRef("rebuild_barrier_piece");
		
		if(isDefined(player))
		{
			player thread [[level.onXPEvent]]("barricade_repair_single");
			
			if(!randomInt(10))
				player playSoundRef("gen_rebuild_board");
		}
	}
	
	if(self.barricadeHealth == self.maxhealth)
	{
		self.isUseable = false;
		self.trigger.origin = self.origin - (0,0,50000);
	}
}

restoreAllParts()
{
	self endon("death");
	
	while(self.curPart > 0)
		self restorePart(undefined);
}

zombieCloseToBarricade()
{
	self endon("disconnect");

	for(i=0;i<level.barricades.size;i++)
	{
		if(isDefined(level.barricades[i]) && self isTouching(level.barricades[i]))
			return level.barricades[i];
	}
	
	return undefined;
}