#include scripts\_include;

init()
{
	thread initMapAreas();
}

initMapAreas()
{
	level.mapAreas = getEntArray("maparea", "targetname");

	if(!level.mapAreas.size)
	{
		level waittill("tranzit_vehicle_init_done");
		level.mapAreas[0] = spawn("script_origin", level.tranzitVehicle.origin);
		level.mapAreas[0].spawner_id = 1;
	}

	for(i=0;i<level.mapAreas.size;i++)
	{
		if(!isDefined(level.mapAreas[i].spawner_id))
			level.mapAreas[i].spawner_id = 1;
		else
			level.mapAreas[i].spawner_id = int(level.mapAreas[i].spawner_id);
	}
	
	if(getDvarInt("create_spawnfile") <= 0 && getDvarInt("create_navmesh") <= 0)
		thread monitorMovementInMap();
}

getClosestMapArea(origin)
{
	curDist = undefined;
	tempDist = undefined;
	tempArea = undefined;
	
	for(i=0;i<level.mapAreas.size;i++)
	{
		curDist = Distance(origin, level.mapAreas[i].origin);
	
		if(!isDefined(tempDist) || curDist <= tempDist)
		{
			tempDist = curDist;
			tempArea = level.mapAreas[i];
			//tempArea.spawner_id = level.mapAreas[i].spawner_id;
		}
	}
		
	return tempArea;
}

getAreaNameFromID(areaID)
{
	if(!isDefined(areaID) || areaID <= 0 || areaID >= 900)
		return undefined;
		
	for(i=0;i<level.mapAreas.size;i++)
	{
		if(isDefined(level.mapAreas[i].spawner_id) && level.mapAreas[i].spawner_id == areaID)
			return level.mapAreas[i].script_location;
	}
	
	return undefined;
}

monitorMovementInMap()
{
	level endon("game_ended");
	level endon("game_will_end");

	wait 1;
	
	if(game["debug"]["status"] && !game["debug"]["startZombieSurvival"])
		return;

	while(1)
	{
		wait .5;

		for(i=0;i<level.players.size;i++)
		{
			if(level.players[i] isASpectator() || !isAlive(level.players[i]))
				continue;
		
			if(!level.players[i] isInPlayArea())
			{
				if(level.players[i] isAZombie())
				{
					if(game["tranzit"].wave < 11)
						continue;
					
					if(level.players[i].zombieType == "dwarf")
						continue;
				
					level.players[i] thread scripts\gore::torchPlayer();
				}
				else
				{
					if(level.players[i] isInLastStand())
						continue;
				
					if(level.players[i].moveSpeedScale != 0.8)
					{
						level.players[i].moveSpeedScale = 0.8;
						level.players[i] SetMoveSpeedScale(level.players[i].moveSpeedScale);
					}
				
					if(!level.players[i].underDwarfAttack && (!isDefined(level.players[i].isOnTruck) || !level.players[i].isOnTruck))
					{
						if(level.dwarfsLeft < game["tranzit"].zombie_max_dwarfs)
						{
							//level.players[i] iPrintLnBold("spawn dwarf to attack you!");
						
							level.players[i].underDwarfAttack = true;
							thread scripts\zombies::spawnWastelandDwarf(level.players[i]);
						}
					}
				}
			}
			else
			{
				if(level.players[i] isASurvivor())
				{
					if(level.players[i].moveSpeedScale != 1)
					{
						level.players[i].moveSpeedScale = 1.0;
						level.players[i] SetMoveSpeedScale(level.players[i].moveSpeedScale);
					}
				}
			}
		}
	}
}

isInPlayArea(area)
{
	self endon("disconnect");
	self endon("death");
	
	if(!isDefined(level.mapAreas) || !level.mapAreas.size)
	{
		self.myAreaLocation = 0;
		return true;
	}

	curLocation = 999;
	if(isDefined(area))
	{
		if(self isTouching(area))
			curLocation = area.spawner_id;
	}
	else
	{
		for(i=0;i<level.mapAreas.size;i++)
		{
			if(self isTouching(level.mapAreas[i]))
			{
				curLocation = level.mapAreas[i].spawner_id;
				break;
			}
		}
	}

	if(curLocation <= 0)
		curLocation = 0;
		
	self.myAreaLocation = curLocation;
	if(self.myAreaLocation > 0 && self.myAreaLocation < 900)
		return true;
	
	return false;
}

combatInArea(areaID)
{
	if(!isDefined(areaID) || areaID <= 0 || areaID >= 900)
		return false;

	for(i=0;i<level.players.size;i++)
	{
		if(level.players[i] isASurvivor() && isDefined(level.players[i].myAreaLocation) && level.players[i].myAreaLocation == areaID)
			return true;
	}
	
	return false;
}