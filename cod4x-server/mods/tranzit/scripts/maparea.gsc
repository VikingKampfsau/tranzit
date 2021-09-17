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
	level endon( "game_ended" );

	self endon("disconnect");
	self endon("death");
	
	if(isDefined(level.tranzitVehicle))
		self thread createLocationHud();
	
	while(1)
	{
		wait .5;
		
		if(self isInLastStand())
			continue;
		
		if(!self isInPlayArea())
		{
			if(self isAZombie())
			{
				if(game["tranzit"].wave < 11)
					continue;
				
				if(self.zombieType == "dwarf")
					continue;
			
				self thread scripts\gore::torchPlayer();
			}
			else
			{
				if(self.moveSpeedScale != 0.8)
				{
					self.moveSpeedScale = 0.8;
					self SetMoveSpeedScale(self.moveSpeedScale);
				}
			
				if(!self.underDwarfAttack && !self.isOnTruck)
				{
					self.underDwarfAttack = true;
					thread scripts\zombies::spawnWastelandDwarf(self);
				}
			}
		}
		else
		{
			if(self.moveSpeedScale != 1)
			{
				self.moveSpeedScale = 1.0;
				self SetMoveSpeedScale(self.moveSpeedScale);
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

createLocationHud()
{
	level endon( "game_ended" );

	self endon("disconnect");
	self endon("death");
	
	if(isDefined(self.locationTextHud))
		self.locationTextHud destroy();

	self.locationTextHud = NewClientHudElem(self);
	self.locationTextHud.font = "default";
	self.locationTextHud.fontScale = 1.4;
	self.locationTextHud.alignX = "left";
	self.locationTextHud.alignY = "top";
	self.locationTextHud.horzAlign = "left";
	self.locationTextHud.vertAlign = "top";
	self.locationTextHud.alpha = 0.75;
	self.locationTextHud.sort = 1;
	self.locationTextHud.x = 6;
	self.locationTextHud.y = 8;
	self.locationTextHud.archived = false;
	self.locationTextHud.foreground = true;
	self.locationTextHud.hidewheninmenu = true;
	self.locationTextHud.label = self getLocTextString("LOCATION_HUD_POS_UNKNOWN");

	locationName = undefined;
	if(isDefined(self.myAreaLocation))
	{
		locationName = getAreaNameFromID(self.myAreaLocation);
		if(isDefined(locationName))
		{
			self.locationTextHud.label = self getLocTextString("LOCATION_HUD_POS");
			self.locationTextHud setText(locationName);
		}
	}

	while(1)
	{
		prevLocation = self.myAreaLocation;

		wait 1;
	
		if(!isDefined(self.myAreaLocation))
		{
			self.locationTextHud.label = self getLocTextString("LOCATION_HUD_POS_UNKNOWN");
			self.locationTextHud setText("");
		}
		else
		{
			if(isDefined(prevLocation) && prevLocation == self.myAreaLocation)
				continue;
		
			locationName = getAreaNameFromID(self.myAreaLocation);
			if(isDefined(locationName))
			{
				self.locationTextHud.label = self getLocTextString("LOCATION_HUD_POS");
				self.locationTextHud setText(locationName);
			}
			else
			{
				self.locationTextHud.label = self getLocTextString("LOCATION_HUD_POS_UNKNOWN");
				self.locationTextHud setText("");
			}
		}
	}
}