/*-----------------------|
|	math related		 |
|-----------------------*/
sqr(value)
{
	return (value*value);
}

float(value, round)
{
	if(isString(value))
	{
		value = strToK(value, ".");
		
		if(value.size == 1)
			value = int(value[0]);
		else
		{
			loop = value[1].size;
			value[0] = int(value[0]);
			value[1] = int(value[1]);
		
			for(i=1;i<=loop;i++)
				value[1] *= 0.1;
			
			if(value[0] > 0)
				value = value[0] + value[1];
			else
				value = value[0] - value[1];
		}
	}

	if(isDefined(round) && round)
		return (int(value*100)/100);
		
	return value;
}

roundUpToTen(value)
{
	new = value - value % 10; 
	
	if(new < value)
		new += 10; 

	return new; 
}

placesBeforeDecimal(value)
{
	count = 0;
	absValue = abs(value);  
	
	while(1)
	{
		absValue *= 0.1;
		count += 1; 

		if(absValue < 1)
			return count; 
	}
}

crossProduct(vec_1, vec_2)
{
	return (vec_1[1]*vec_2[2] - vec_1[2]*vec_2[1], 
			vec_1[2]*vec_2[0] - vec_1[0]*vec_2[2],
			vec_1[0]*vec_2[1] - vec_1[1]*vec_2[0]);
}

CalcDif(x, y)
{
	/*dif = x - y;
	
	if(dif < 0)
		dif *= -1;*/
		
	dif = abs(x - y);

	return dif;
}

pointInGeometry(point, geoObject, geoIsTrigger)
{
	pointIsInGeometry = false;

	if(isDefined(geoIsTrigger) && geoIsTrigger)
	{
		entity = spawn("script_origin", point);
		
		if(entity isTouching(geoObject))
			pointIsInGeometry = true;
			
		entity delete();
		
		return pointIsInGeometry;
	}
	
	//the object is not trigger - we have to do some math
	/*min = cube.cornerA;
	max = cube.cornerC;

	if(	(point[0] >= min[0] && point[0] <= max[0]) &&
		(point[1] >= min[1] && point[1] <= max[1]) &&
		(point[2] >= min[2] && point[2] <= max[2]))
			pointIsInGeometry = true;

	return pointIsInGeometry;*/
}

DegToRad(degrees)
{
	pi = 3.14159265359;
	radians = degrees * pi / 180;
	
	return radians;
}

/*-----------------------|
|	array related		 |
|-----------------------*/
RemoveUndefinedEntriesFromArray(array)
{
	tempArray = [];
	
	if(array.size > 0)
	{
		for(i=0;i<array.size;i++)
		{
			if(isDefined(array[i]))
				tempArray[tempArray.size] = array[i];
		}
	}
	
	return tempArray;
}

removeArrayItem(array, item)
{
	temp = [];
	for(i=0;i<array.size;i++)
	{
		if(array[i] == item)
			continue;
			
		temp[temp.size] = array[i];
	}

	return temp;
}

removeArrayIndex(array, index)
{
	tempArray = [];

	for(i=0;i<array.size;i++)
	{
		if(i < index)
			tempArray[i] = array[i];
		else if(i > index)
			tempArray[i - 1] = array[i];
	}

	return tempArray;
}

isInArray(array, x, y, z)
{
	for(i=0;i<array.size;i++)
	{
		if(isDefined(x) && array[i] == x)
			return true;
			
		if(isDefined(y) && array[i] == y)
			return true;
		
		if(isDefined(z) && array[i] == z)
			return true;
	}

	return false;
}

reverseArray(array)
{
	tempArray = [];

	for(i=array.size-1;i>=0;i--)
		tempArray[tempArray.size] = array[i];

	return tempArray;
}

shuffleArray(array)
{
	currentIndex = array.size;
	temporaryValue = undefined;
	randomIndex = undefined;

	// While there remain elements to shuffle...
	while(currentIndex != 0)
	{
		// Pick a remaining element...
		randomIndex = randomInt(currentIndex);
		currentIndex -= 1;

		// And swap it with the current element.
		temporaryValue = array[currentIndex];
		array[currentIndex] = array[randomIndex];
		array[randomIndex] = temporaryValue;
	}
	
	return array;
}

addArrayToArray(firstArray, secondArray, onlyNewEntries)
{
	if(!isDefined(onlyNewEntries))
		onlyNewEntries = false;

	if(firstArray.size <= 0)
		return secondArray; 
		
	if(secondArray.size <= 0)
		return firstArray; 

	newarray = firstArray; 
	
	for(i=0;i<secondArray.size;i++)
	{
		if(!onlyNewEntries)
			newarray[newarray.size] = secondArray[i];
		else
		{
			foundmatch = false; 
			for(j=0;j<firstArray.size;j++)
			{
				if(secondArray[i] == firstArray[j])
				{
					foundmatch = true; 
					break; 
				}
			}
			
			if(foundmatch)
				continue; 

			newarray[newarray.size] = secondArray[i];
		}
	}

	return newarray; 
}

removeArrayContentFromArray(array, exclusionsArray)
{
	newarray = array;
	for(i=0;i<exclusionsArray.size;i++)
	{
		if(isInArray(array, exclusionsArray[i]))
			newarray = removeArrayItem(newarray, exclusionsArray[i]);
	}
	
	return newarray;
}

/* 
 ============= 
///ScriptDocBegin
"Name: getClosest( <org> , <array> , <dist> )"
"Summary: Returns the closest entity in < array > to location < org > "
"Module: Distance"
"CallOn: "
"MandatoryArg: <org> : Origin to be closest to."
"MandatoryArg: <array> : Array of entities to check distance on"
"OptionalArg: <dist> : Minimum distance to check"
"Example: friendly = getclosest( level.player.origin, allies );"
"SPMP: singleplayer"
///ScriptDocEnd
 ============= 
*/ 
getClosest( org, array, dist )
{
	return compareSizes( org, array, dist, ::closerFunc );
}
closerFunc( dist1, dist2 )
{
	return dist1 >= dist2;
}

fartherFunc( dist1, dist2 )
{
	return dist1 <= dist2;
}
compareSizes( org, array, dist, compareFunc )
{
	if( !array.size )
		return undefined;
	if( isdefined( dist ) )
	{
		ent = undefined;
		keys = getArrayKeys( array );
		for( i = 0; i < keys.size; i ++ )
		{
			newdist = distance( array[ keys[ i ] ].origin, org );
			if( [[ compareFunc ]]( newDist, dist ) )
				continue;
			dist = newdist;
			ent = array[ keys[ i ] ];
		}
		return ent;
	}

	keys = getArrayKeys( array );
	ent = array[ keys[ 0 ] ];
	dist = distance( ent.origin, org );
	for( i = 1; i < keys.size; i ++ )
	{
		newdist = distance( array[ keys[ i ] ].origin, org );
		if( [[ compareFunc ]]( newDist, dist ) )
			continue;
		dist = newdist;
		ent = array[ keys[ i ] ];
	}
	return ent;
}

/*-----------------------|
|	hud/msg related		 |
|-----------------------*/
monitorFakeTriggerHintStringDisplay(text)
{
	level endon("game_ended");
	self endon("death");
	
	self notify("monitorFakeTriggerHintStringDisplay");
	self endon("monitorFakeTriggerHintStringDisplay");
	
	while(1)
	{
		for(i=0;i<level.players.size;i++)
		{
			if(!level.players[i] isASurvivor())
				continue;
		
			if(level.players[i] isTouching(self.trigger))
			{
				if(level.players[i] isReadyToUse())
					level.players[i] thread fakeTriggerHintString(self.trigger, text);
			}
		}
		
		wait .1;
	}
}

fakeTriggerHintString(trigger, text)
{
	self endon("disconnect");

	if(isDefined(self.fakeTriggerHintString))
		return;

	self.fakeTriggerHintString = NewClientHudElem(self);
	self.fakeTriggerHintString.alignX = "center";
	self.fakeTriggerHintString.alignY = "middle";
	self.fakeTriggerHintString.horzalign = "center";
	self.fakeTriggerHintString.vertalign = "middle";
	self.fakeTriggerHintString.sort = 1;
	self.fakeTriggerHintString.alpha = 1;
	self.fakeTriggerHintString.x = -2;
	self.fakeTriggerHintString.y = 60;
	self.fakeTriggerHintString.font = "default";
	self.fakeTriggerHintString.fontscale = 1.44;
	self.fakeTriggerHintString.archived = false;
	self.fakeTriggerHintString.hidewheninmenu = true;
	self.fakeTriggerHintString.label = self getLocTextString(text);
	
	while(1)
	{
		if(!isAlive(self) || !self isTouching(trigger) || !isDefined(self.fakeTriggerHintString))
			break;
	
		self.fakeTriggerHintString MoveOverTime(0.5);
		self.fakeTriggerHintString.x = 2;
	
		wait 0.5;

		if(!isAlive(self) || !self isTouching(trigger) || !isDefined(self.fakeTriggerHintString))
			break;

		self.fakeTriggerHintString MoveOverTime(0.5);
		self.fakeTriggerHintString.x = -2;
	
		wait 0.5;
	}
		
	self.fakeTriggerHintString destroy();
}

showUseHintMessage(locText, buttonType, overWriteExisting, subValue, subString, subTimer)
{
	self endon("disconnect");

	if(!isDefined(overWriteExisting))
		overWriteExisting = true;

	if(isDefined(self.useHintText) && !overWriteExisting)
		return;

	if(isDefined(self.useHintText))
		self.useHintText destroy();

	self.useHintText = NewClientHudElem(self);
	self.useHintText.alignX = "center";
	self.useHintText.alignY = "middle";
	self.useHintText.horzalign = "center";
	self.useHintText.vertalign = "middle";
	self.useHintText.sort = 1;
	self.useHintText.alpha = 1;
	self.useHintText.x = 0;
	self.useHintText.y = 60;
	self.useHintText.font = "default";
	self.useHintText.fontscale = 1.44;
	self.useHintText.archived = false;
	self.useHintText.hidewheninmenu = true;
	self.useHintText.label = locText;
	
	if(isDefined(subValue))
		self.useHintText setValue(subValue);

	if(isDefined(subString))
		self.useHintText setText(subString);
		
	if(isDefined(subTimer))
		self.useHintText setTimer(subTimer);
	
	while(isAlive(self) && isDefined(self.useHintText) && !level.gameEnded)
	{
		if(isDefined(buttonType))
		{
			if(isDefined(self.lastStand) && !self.lastStand)
			{
				if(buttonType == "revive")
				break;
			}
		
			if(buttonType == "use" && self useButtonPressed())
				break;
				
			if(buttonType == "attack" && self attackButtonPressed())
				break;
				
			if(buttonType == "ads" && self adsButtonPressed())
				break;
		}
	
		wait 0.05;
	}

	if(isDefined(self.useHintText))
		self.useHintText destroy();
}

showTriggerUseHintMessage(trigger, locText, subValue, subString, subTimer)
{
	self endon("disconnect");

	if(isDefined(self.triggerUseHintText))
		return;

	self.triggerUseHintText = NewClientHudElem(self);
	self.triggerUseHintText.alignX = "center";
	self.triggerUseHintText.alignY = "middle";
	self.triggerUseHintText.horzalign = "center";
	self.triggerUseHintText.vertalign = "middle";
	self.triggerUseHintText.sort = 1;
	self.triggerUseHintText.alpha = 1;
	self.triggerUseHintText.x = -2;
	self.triggerUseHintText.y = 60;
	self.triggerUseHintText.font = "default";
	self.triggerUseHintText.fontscale = 1.44;
	self.triggerUseHintText.archived = false;
	self.triggerUseHintText.hidewheninmenu = true;
	self.triggerUseHintText.label = locText;
	
	if(isDefined(self.useHintText))
		self.triggerUseHintText.y = 75;
	
	if(isDefined(subValue))
		self.triggerUseHintText setValue(subValue);

	if(isDefined(subString))
		self.triggerUseHintText setText(subString);
		
	if(isDefined(subTimer))
		self.triggerUseHintText setTimer(subTimer);
	
	while(1)
	{
		if(!isAlive(self) || !isDefined(trigger) || !self isTouching(trigger) || !isDefined(self.triggerUseHintText))
			break;
	
		self.triggerUseHintText MoveOverTime(0.5);
		self.triggerUseHintText.x = 2;
	
		wait 0.5;

		if(!isAlive(self) || !isDefined(trigger) || !self isTouching(trigger) || !isDefined(self.triggerUseHintText) || level.gameEnded)
			break;

		self.triggerUseHintText MoveOverTime(0.5);
		self.triggerUseHintText.x = -2;
	
		wait 0.5;
	}

	if(isDefined(self.triggerUseHintText))
		self.triggerUseHintText destroy();
}

deleteUseHintMessages(normal, triggerBased)
{
	self endon("disconnect");

	if(!isDefined(normal)) normal = true;
	if(!isDefined(triggerBased)) triggerBased = true;

	if(normal && isDefined(self.useHintText))
		self.useHintText destroy();
	
	if(triggerBased && isDefined(self.triggerUseHintText))
		self.triggerUseHintText destroy();
}

setLowerHintMessage(text, delay)
{
	if(self isABot())
		return;
	
	delay = abs(delay);
	if(delay > 60)
		delay = 60;

	if(isDefined(self.lowerMessage))
	{
		self.lowerMessage.label = text;
		self.lowerMessage.alpha = 1;
		self.lowerMessage FadeOverTime(delay);
		self.lowerMessage.alpha = 0;
		
		self thread clearAfterFade(delay);
	}
}

clearAfterFade(delay)
{
	self notify("clearAfterFade");
	self endon("clearAfterFade");
	
	wait delay;
	self clearLowerHintMessage();
}

clearLowerHintMessage()
{
	if(isDefined(self.lowerMessage))
	{
		self.lowerMessage.label = &"";
		self.lowerMessage setText("");
	}
}

saveHeadIcon()
{
	if(isdefined(self.headicon))
		self.oldheadicon = self.headicon;

	if(isdefined(self.headiconteam))
		self.oldheadiconteam = self.headiconteam;
}

restoreHeadIcon()
{
	if(isdefined(self.oldheadicon))
		self.headicon = self.oldheadicon;

	if(isdefined(self.oldheadiconteam))
		self.headiconteam = self.oldheadiconteam;
}

/*-----------------------|
|	sound related		 |
|-----------------------*/
add_sound(ref, alias)
{
	if(!isDefined(level.zombie_sounds))
		level.zombie_sounds = []; 

	curEntry = level.zombie_sounds.size;
	level.zombie_sounds[curEntry] = spawnStruct();
	level.zombie_sounds[curEntry].ref = ref;
	level.zombie_sounds[curEntry].alias = alias;
}

getZombieSoundalias(ref)
{
	for(i=0;i<level.zombie_sounds.size;i++)
	{
		if(level.zombie_sounds[i].ref == ref)
			return level.zombie_sounds[i].alias;
	}
	
	return ref;
}

playSoundRef(ref)
{
	alias = getZombieSoundalias(ref);
	
	self playSound(alias);
}

playLoopSoundRef(ref)
{
	alias = getZombieSoundalias(ref);
	
	self playLoopSound(alias);
}

playSoundAtPosition(alias, pos)
{
	alias = getZombieSoundalias(alias);

	origin = spawn("script_origin", pos);
	origin playSound(alias);

	origin thread removeSoundEnt();
}

removeSoundEnt()
{
	self endon("death");
	wait 60;
	self delete();
}

playSoundToAllPlayers(alias, entity)
{
	alias = getZombieSoundalias(alias);

	usePlayer = false;
	if(!isDefined(entity))
		usePlayer = true;

	for(i=0;i<level.players.size;i++)
	{
		if(level.players[i] isASurvivor())
		{
			if(usePlayer)
				level.players[i] PlaySoundToPlayer(alias, level.players[i]);
			else
				entity PlaySoundToPlayer(alias, level.players[i]);
		}
	}
}

playLocalSoundToAllPlayers(alias)
{
	alias = getZombieSoundalias(alias);

	for(i=0;i<level.players.size;i++)
	{
		if(level.players[i] isASurvivor())
			level.players[i] playLocalSound(alias);
	}
}

/*-----------------------|
|	entity related		 |
|-----------------------*/
isLookingAt(entity)
{
	if(!isDefined(entity))
		return false;

	entityPos = entity.origin;
	playerPos = self getEye();

	entityPosAngles = vectorToAngles( entityPos - playerPos );
	entityPosForward = anglesToForward( entityPosAngles );

	playerPosAngles = self getPlayerAngles();
	playerPosForward = anglesToForward( playerPosAngles );

	newDot = vectorDot( entityPosForward, playerPosForward );

	if ( newDot < 0.72 ) {
		return false;
	} else {
		return true;
	}
}

getClosestEnt(curOrigin, array)
{
	temp = undefined;
	tempDist = 9999999999;
	
	for(i=0;i<array.size;i++)
	{
		dist = Distance(curOrigin, array[i].origin);
		if(dist <= tempDist)
		{
			temp = array[i];
			tempDist = dist;
		}
	}
	
	return temp;
}

getFarestEnt(curOrigin, array)
{
	temp = undefined;
	tempDist = 0;
	
	for(i=0;i<array.size;i++)
	{
		dist = Distance(curOrigin, array[i].origin);
		if(dist >= tempDist)
		{
			temp = array[i];
			tempDist = dist;
		}
	}
	
	return temp;
}

/*-----------------------|
|	player related		 |
|-----------------------*/
GetUniquePlayerID()
{
	guid = self GetGuid();
	
	if(!isDefined(guid) || guid == "")
		guid = self GetPlayerID();
		
	if(!isDefined(guid))
		return "";
		
	return guid;
}

getPlayer(value)
{
	if(!isDefined(value) || !value.size)
		return undefined;

	//A Name for sure
	if(value.size > 2)
	{
		counter = 0;
		player = 0;

		for(i=0;i<level.players.size;i++)
		{
			if(isSubStr(toLower(level.players[i].name), toLower(value))) 
			{
				player = level.players[i];
				counter++;
			}
		}
		
		if(counter == 1)
			return player;
	}
	//A Slot
	else
	{
		for(i=0;i<level.players.size;i++)
		{
			if(level.players[i] getEntityNumber() == int(value)) 
				return level.players[i];
		}
	}
	
	return undefined;
}

TeamHasFreeSlots(team)
{
	if(team != "spectator")
	{
		teamPlayers = GetPlayersInTeam(team);
		
		if(team == game["defenders"] && teamPlayers.size >= 4)
			return false;
		
		if(team == game["attackers"] && teamPlayers.size >= level.teamLimit)
			return false;
	}

	return true;
}

GetPlayersInTeam(team)
{
	teamPlayers = [];
	for(i=0;i<level.players.size;i++)
	{
		if(level.players[i].pers["team"] == team)
			teamPlayers[teamPlayers.size] = level.players[i];
	}

	return teamPlayers;
}

GetPlayersInTeams()
{
	team[game["attackers"]] = 0;
	team[game["defenders"]] = 0;
	for(i=0;i<level.players.size;i++)
	{
		if(level.players[i].pers["team"] == game["attackers"])
			team[game["attackers"]]++;
		else if(level.players[i].pers["team"] == game["defenders"])
			team[game["defenders"]]++;
	}

	return team;
}

getRandomPlayer(team)
{
	if(!isDefined(level.players) || !level.players.size)
		return undefined;

	tempArray = [];
	for(i=0;i<level.players.size;i++)
	{
		if(level.players[i].pers["team"] == team)
			tempArray[tempArray.size] = level.players[i];
	}

	return tempArray[randomInt(tempArray.size)];
}

isABot()
{
	if(!isDefined(self.pers["isBot"]))
		return false;
		
	return self.pers["isBot"];
}

isAZombie()
{
	if(isPlayer(self) && isDefined(self.pers["team"]) && self.pers["team"] == game["attackers"])
		return true;
		
	return false;
}

isASurvivor()
{
	if(isPlayer(self) && isDefined(self.pers["team"]) && self.pers["team"] == game["defenders"])
		return true;
		
	return false;
}

isASpectator()
{
	if(!isDefined(self.pers["team"]))
		return true;

	if(self.pers["team"] == "spectator")
		return true;
		
	return false;
}

isReviving()
{
	if(!isDefined(self.isReviving))
		return false;

	return self.isReviving;
}

isInLastStand()
{
	if(!isDefined(self.lastStand))
		self.lastStand = false;

	return self.lastStand;
}

isFlashbanged()
{
	if(isDefined(self.flashEndTime) && gettime() < self.flashEndTime)
		return true;
		
	if(isDefined(self.concussionEndTime) && gettime() < self.concussionEndTime)
		return true;
		
	if(isDefined(self.beingArtilleryShellshocked) && self.beingArtilleryShellshocked)
		return true;

	return false;
}

isReadyToUse()
{
	if(!self isASurvivor())
		return false;
		
	if(self isInLastStand())
		return false;
		
	if(self isReviving())
		return false;
		
	return true;
}

isMoving()
{
	if(self forwardButtonPressed())
		return true;
				
	if(self backButtonPressed())
		return true;

	if(self moveLeftButtonPressed())
		return true;

	if(self moveRightButtonPressed())
		return true;

	return false;
}

Jumped()
{
	if(self jumpButtonPressed())
		return true;
		
	return false;
}

GetInventory()
{
	self endon("death");
	self endon("disconnect");
	
	//self.prevweapon = self GetCurrentWeapon();
	self.weapons = self getweaponslist();
	self.weaponsAmmoStock = [];
	self.weaponsAmmoClips = [];
	
	for(i=0;i<self.weapons.size;i++)
	{
		self.weaponsAmmoClips[i] = self getWeaponAmmoClip(self.weapons[i]);
		self.weaponsAmmoStock[i] = self getWeaponAmmoStock(self.weapons[i]);
	}
}

ReplaceInInventory(replace, insert)
{
	self endon("death");
	self endon("disconnect");
	
	if(!isDefined(replace) || !isDefined(insert))
		return;

	if(!isDefined(self.weapons) || !self.weapons.size)
		return;

	for(i=0;i<self.weapons.size;i++)
	{
		if(!isDefined(self.weapons[i]) || self.weapons[i] == "" || self.weapons[i] == "none")
			continue;
		
		if(self.weapons[i] == replace)
		{
			self.weapons[i] = insert;
			self.weaponsAmmoClips[i] = WeaponClipSize(self.weapons[i]);
			self.weaponsAmmoStock[i] = WeaponMaxAmmo(self.weapons[i]);
		}
	}
}

GiveInventory()
{
	self endon("death");
	self endon("disconnect");

	if(!isDefined(self.weapons) || !self.weapons.size)
		return;

	for(i=0;i<self.weapons.size;i++)
	{
		if(!isDefined(self.weapons[i]) || self.weapons[i] == "" || self.weapons[i] == "none")
			continue;
	
		self giveweapon(self.weapons[i]);

		if(isAGrenade(self.weapons[i]))
			self switchToOffhand(self.weapons[i]);
	
		if(!isDefined(self.weaponsAmmoClips[i]))
			self setWeaponAmmoClip(self.weapons[i], WeaponClipSize(self.weapons[i]));
		else
			self setWeaponAmmoClip(self.weapons[i], self.weaponsAmmoClips[i]);
			
		if(!isDefined(self.weaponsAmmoStock[i]))
			self setWeaponAmmoStock(self.weapons[i], WeaponMaxAmmo(self.weapons[i]));	
		else
			self setWeaponAmmoStock(self.weapons[i], self.weaponsAmmoStock[i]);	
	}
}

SwitchToPreviousWeapon()
{
	self endon("death");
	self endon("disconnect");
	
	if(isDefined(self.prevweapon) && self HasWeapon(self.prevweapon))
	{
		self SwitchToWeapon(self.prevweapon);
		return;
	}
	
	if(!isDefined(self.weapons))
		return;
	
	for(i=0;i<self.weapons.size;i++)
	{
		if(!isDefined(self.weapons[i]) || self.weapons[i] == "" || self.weapons[i] == "none")
			continue;
	
		if(!isAGrenade(self.weapons[i]))
		{
			self SwitchToWeapon(self.weapons[i]);
			break;
		}
	}
}

hasAttached(model)
{
	for(i=0;i<self getAttachSize();i++)
	{
		if(self getAttachModelName(i) == model)
			return true;
	}
	
	return false;
}

hasActionSlotWeapon(type)
{
	if(isDefined(type))
	{
		if(type == "craftable")
			return isDefined(self.actionSlotItem);
		else if(type == "weapon")
			return isDefined(self.actionSlotWeapon);
		else if(type == "hardpoint")
			return isDefined(self.actionSlotHardpoint);
	}
	
	return false;
}

giveActionslotWeapon(type, weapon, ammo)
{
	self endon("disconnect");
	self endon("death");

	if(!isDefined(type) || type == "weapon")
	{
		self giveWeapon(weapon);
		self.actionSlotWeapon = weapon;
		self setActionSlot(3, "weapon", weapon);
	}
	else if(type == "hardpoint")
	{
		self.actionSlotHardpoint = weapon;
		weapon = getWeaponFromCustomName("location_selector");		
		self giveWeapon(weapon);
		self setActionSlot(4, "weapon", weapon);
	}
	else
	{
		self giveWeapon(weapon);
		self.actionSlotItem = weapon;
		self setActionSlot(1, "weapon", weapon);
	}
	
	self setWeaponAmmoClip(weapon, 0);
	self setWeaponAmmoStock(weapon, 0);

	if(isDefined(ammo) && ammo > 0)
	{
		clipSize = self getWeaponAmmoClip(weapon);
		
		if(clipSize <= ammo)
			self setWeaponAmmoClip(weapon, ammo);
		else
		{
			self setWeaponAmmoClip(weapon, clipSize);
			self setWeaponAmmoStock(weapon, ammo - clipSize);
		}
	}
}

takeActionSlotWeapon(type)
{
	self endon("disconnect");
	self endon("death");
	
	if(!isDefined(type) || type == "weapon")
	{
		self takeWeapon(self.actionSlotWeapon);
		self SetActionSlot(3, "");
		self.actionSlotWeapon = undefined;
	}
	else if(type == "hardpoint")
	{
		self takeWeapon(getWeaponFromCustomName("location_selector"));
		self SetActionSlot(4, "");
		self.actionSlotHardpoint = undefined;
	}
	else
	{
		self takeWeapon(self.actionSlotItem);
		self SetActionSlot(1, "");
		self.actionSlotItem = undefined;
	}
}

upateMainWeapons()
{
	if(!self hasWeapon(self.pers["primaryWeapon"]))
		self.pers["primaryWeapon"] = "none";

	if(!self hasWeapon(self.pers["secondaryWeapon"]))
		self.pers["secondaryWeapon"] = "none";
}

getUsedWeaponSlot()
{
	//primaryWeapon slot is not empy
	if(self.pers["primaryWeapon"] != "none" && self.pers["primaryWeapon"] != game["tranzit"].player_empty_hands)
		return "primaryWeapon";
	
	//secondaryWeapon slot is not empy
	if(self.pers["secondaryWeapon"] != "none" || self.pers["secondaryWeapon"] != game["tranzit"].player_empty_hands)
		return "secondaryWeapon";
	
	//both empy
	return undefined;
}

getEmptyWeaponSlot()
{
	emptySlot = undefined;

	self upateMainWeapons();

	//primaryWeapon slot is empy
	if(self.pers["primaryWeapon"] == "none" || self.pers["primaryWeapon"] == game["tranzit"].player_empty_hands)
		emptySlot = "primaryWeapon";
	
	//secondaryWeapon slot is empy
	if(self.pers["secondaryWeapon"] == "none" || self.pers["secondaryWeapon"] == game["tranzit"].player_empty_hands)
		emptySlot = "secondaryWeapon";

	return emptySlot;
}

giveNewWeapon(newWeapon, noWeaponSwitch, keepHands)
{
	if(isAGrenade(newWeapon))
	{
		noWeaponSwitch = true;
		keepHands = true;
	}
	else
	{
		slot = self getEmptyWeaponSlot();
		
		if(isDefined(slot))
		{
			if(isDefined(self.pers[slot]) && self.pers[slot] != "none")
			{
				if(!isDefined(keepHands) || !keepHands)
					self takeWeapon(self.pers[slot]);
			}
		}
		else
		{
			self takeCurrentWeapon();
			slot = self getEmptyWeaponSlot();
		}
		
		self.pers[slot] = newWeapon;
	}
	
	if(isHardpointWeapon(newWeapon))
		self giveActionslotWeapon("hardpoint", newWeapon);
	else
	{
		if(isOtherExplosive(newWeapon))
			self giveActionslotWeapon("weapon", newWeapon, 1);
		else
			self giveWeapon(newWeapon);
	
		self giveMaxAmmo(newWeapon);
		
		if(!isDefined(noWeaponSwitch) || !noWeaponSwitch)
			self switchToNewWeapon(newWeapon, .05);
	}
}

/*-----------------------|
|	weapon related		 |
|-----------------------*/
add_weapon(ref, weapon)
{
	if(!isDefined(level.tranzitWeapon))
		level.tranzitWeapon = []; 

	curEntry = level.tranzitWeapon.size;
	level.tranzitWeapon[curEntry] = spawnStruct();
	level.tranzitWeapon[curEntry].name = ref;
	level.tranzitWeapon[curEntry].weapon = weapon;
	precacheItem(weapon);
}

getWeaponFromCustomName(name)
{
	for(i=0;i<level.tranzitWeapon.size;i++)
	{
		if(level.tranzitWeapon[i].name == name)
			return level.tranzitWeapon[i].weapon;
	}
	
	return "";
}

hasMaxAmmo()
{
	self endon("disconnect");
	self endon("death");
	
	self.weapons = self getweaponslist();
	for(i=0;i<self.weapons.size;i++)
	{
		if(!self hasMaxAmmoForWeapon(self.weapons[i]))
			return false;
	}
	
	return true;
}

hasMaxAmmoForWeapon(weapon)
{
	self endon("disconnect");
	self endon("death");

	clipSize = WeaponClipSize(weapon);
	stockSize = WeaponMaxAmmo(weapon);
	
	remainingClip = self getWeaponAmmoClip(weapon);
	remainingStock = self getWeaponAmmoStock(weapon);
	
	if(remainingClip >= clipSize && remainingStock >= stockSize)
		return true;
		
	return false;
}

GiveAmmoForAllWeapons()
{
	self endon("disconnect");
	self endon("death");
	
	self.weapons = self getweaponslist();
	for(i=0;i<self.weapons.size;i++)
		self GiveMaxAmmo(self.weapons[i]);
}

switchToNewWeapon(weapon, delay)
{
	self endon("disconnect");
	self endon("death");
	
	wait delay;
	self switchToWeapon(weapon);
}

takeCurrentWeapon()
{
	curWeapon = self getCurrentWeapon();
	
	if(curWeapon == self.pers["primaryWeapon"])
		self.pers["primaryWeapon"] = "none";
	else if(curWeapon == self.pers["secondaryWeapon"])
		self.pers["secondaryWeapon"] = "none";
		
	self takeWeapon(curWeapon);
}

isHeadShot(sWeapon, sHitLoc, sMeansOfDeath)
{
	return (sHitLoc == "head" || sHitLoc == "helmet") && sMeansOfDeath != "MOD_MELEE" && sMeansOfDeath != "MOD_IMPACT" && !isTurret(sWeapon);
}

isExplosiveDamage(sMeansOfDeath)
{
	explosivedamage = "MOD_GRENADE MOD_GRENADE_SPLASH MOD_PROJECTILE MOD_PROJECTILE_SPLASH MOD_EXPLOSIVE";
	
	return isSubstr(explosivedamage, sMeansOfDeath);
}

isExplosiveObjectInflictor(eInflictor, sWeapon)
{
	// explosive barrel/car detection
	if(sWeapon == "none" && isDefined(eInflictor))
	{
		if(isDefined(eInflictor.targetname) && eInflictor.targetname == "explodable_barrel")
			sWeapon = "explodable_barrel";
		else if(isDefined(eInflictor.destructible_type) && isSubStr(eInflictor.destructible_type, "vehicle_"))
			sWeapon = "destructible_car";
	}
	
	return sWeapon;
}

isAGrenade(weapon)
{
	return isSubStr(weapon, "_grenade_");
}

isAPistol(weapon)
{
	if(WeaponClass(weapon) == "pistol")
		return true;

	return false;
}

isOtherExplosive(weapon)
{
	if(isSubStr(weapon, "c4_mp"))
		return true;
	if(isSubStr(weapon, "claymore_mp"))
		return true;
	if(isSubStr(weapon, "rpg_mp"))
		return true;

	return false;
}

isHardpointWeapon(weapon)
{
	/*
	if(weapon == "radar_mp" || weapon == "airstrike_mp" || weapon == "helicopter_mp")
		return true;
	if(weapon == "briefcase_bomb_mp")
		return true;
	*/

	return false;
}

isTurret(weapon)
{
	return isSubStr(weapon, "_bipod_");
}

/*-----------------------|
|	motion related		 |
|-----------------------*/
fake_physicslaunch( target_pos, power )
{
	start_pos = self.origin; 
	
	///////// Math Section
	// Reverse the gravity so it's negative, you could change the gravity
	// by just putting a number in there, but if you keep the dvar, then the
	// user will see it change.
	gravity = GetDvarInt( "g_gravity" ) * -1; 

	dist = Distance( start_pos, target_pos ); 
	time = dist / power; 
	delta = target_pos - start_pos; 
	drop = 0.5 * gravity *( time * time ); 
	
	velocity = ( ( delta[0] / time ), ( delta[1] / time ), ( delta[2] - drop ) / time ); 
	///////// End Math Section

	self MoveGravity( velocity, time );
	return time;
}

//frim ow mod - no idea what it does
Distort()
{
	//Gunsway
	self endon("death");
	self endon("spawned");
	self endon("disconnect");
	
	horiz[1] = .26;
	horiz[2] = .26;
	horiz[3] = .25;
	horiz[4] = .25;
	horiz[5] = .25;
	horiz[6] = .25;
	horiz[7] = .25;
	horiz[8] = .25;
	horiz[9] = .25;
	horiz[10] = .25;
	horiz[11] = .25;
	horiz[12] = .15;
	horiz[13] = .13;
	vert[1] = 0.0;
	vert[2] = 0.025;
	vert[3] = 0.036;
	vert[4] = 0.037;
	vert[5] = 0.053;
	vert[6] = 0.072;
	vert[7] = 0.080;
	vert[8] = 0.100;
	vert[9] = 0.11;
	vert[10] = 0.15;
	vert[11] = 0.244;
	vert[12] = 0.238;
	vert[13] = 0.085;

	wait 2;
	i = 1;
	idir = 0;
	pshift = 0;
	yshift = 0;


	for(;;)
	{
		VMag = self.VaxisMag;
		YMag = self.YaxisMag;

		if(i >= 1 && i <= 13)
 		{
			pShift = horiz[i]*VMag;
			yShift = (0 - vert[i])*YMag;
		}
		else if(i >= 14 && i <= 26)
		{
			j = 14 - (i -13);
			pShift = (0 - horiz[j])*VMag;
			yShift = (0 - vert[j])*YMag;
		}
		else if(i >= 27 && i <= 39)
		{
			pShift = (0-horiz[i-26])*VMag;
			yShift = (vert[i-26])*YMag;
		}
		else if(i >= 40 && i <= 52)
		{
			j = 14 - (i -39);
			pShift = (horiz[j])*VMag;
			yShift = (vert[j])*YMag;
		}
		angles = self getplayerangles();
		self setPlayerAngles(angles + (pShift, yShift, 0));
		if(randomInt(50) == 0)
		{
			if(idir == 0) idir = 1;
			else idir = 0;
			i = i + 26;
		}
		if(idir == 0) i++;
		if(idir == 1) i--;
		if( i > 52) i = i - 52;
		if( i < 0) i = 52 - i;
		wait 0.05;
	}
}

shiftPlayerView( iDamage )
{
	if(iDamage == 0)
		return;
	// Make sure iDamage is between certain range
	if ( iDamage < 3 ) {
		iDamage = randomInt( 10 ) + 5;
	} else if ( iDamage > 45 ) {
		iDamage = 45;
	} else {
		iDamage = int( iDamage );
	}

	// Calculate how much the view will shift
	xShift = randomInt( iDamage ) - randomInt( iDamage );
	yShift = randomInt( iDamage ) - randomInt( iDamage );

	// Shift the player's view
	self setPlayerAngles( self.angles + (xShift, yShift, 0) );

	return;
}

/*-----------------------|
|	string related		 |
|-----------------------*/
// Trims left spaces from a string
trimLeft(string)
{
    index = 0;
    while(getSubStr(string, index, index + 1) == " " && index < string.size)
        index++;

    return getSubStr(string, index, string.size);
}

// Trims right spaces from a string
trimRight(string)
{
	index = string.size;
	while(getSubStr(string, index - 1, index) == " " && index > 0)
		index--;

	return getSubStr(string, 0, index);

}

// Trims all the spaces left and right from a string
trim(string)
{
	return (trimLeft(trimRight(string)));
}

vectostr(vec)
{
	return int(vec[0]) + "/" + int(vec[1]) + "/" + int(vec[2]);
}

strtovec(str)
{
	parts = strtok(str, "/");
	if (parts.size != 3)
		return (0,0,0);
	return (int(parts[0]), int(parts[1]), int(parts[2]));
}

CaesarShiftCipher(text, action)
{
	if(!isDefined(action))
		return text;
		
	signs = "!,#,$,%,&,(,),*,+,-,.,/,0,1,2,3,4,5,6,7,8,9,<,=,>,?,@,A,B,C,D,E,F,G,H,I,J,K,L,M,N,O,P,Q,R,S,T,U,V,W,X,Y,Z,[,\,],^,_,`,a,b,c,d,e,f,g,h,i,j,k,l,m,n,o,p,q,r,s,t,u,v,w,x,y,z,{,|,},~";
	signs = strToK(signs, ",");
		
	shift = 17;
	output = "";

	if(action == "encrypt")
	{
		for(i=0;i<text.size;i++)
		{
			newLetterIndex = undefined;
			for(j=0;j<signs.size;j++)
			{
				if(text[i] == signs[j])
				{
					newLetterIndex = (j + shift);
					break;						
				}
			}

			if(!isDefined(newLetterIndex))
				output = output + text[i];
			else
			{
				if(newLetterIndex >= signs.size)
					newLetterIndex -= signs.size;
				
				output += signs[newLetterIndex];
			}
		}
	}
	else
	{
		for(i=0;i<text.size;i++)
		{
			newLetterIndex = undefined;
			for(j=0;j<signs.size;j++)
			{
				if(text[i] == signs[j])
				{
					newLetterIndex = (j - shift);
					break;						
				}
			}

			if(!isDefined(newLetterIndex))
				output = output + text[i];
			else
			{
				if(newLetterIndex < 0)
					newLetterIndex += signs.size;
				
				output += signs[newLetterIndex];
			}
		}	
	}
	
	return output;
}

TableLookupInFile(fileName, columnSearch, stringSearch, columnReturn, isEncrypt)
{
	result = undefined;
		
	if(fs_testFile(fileName))
	{
		file = openFile(fileName, "read");
	
		if(file > 0)
		{
			line = "";
			while(1)
			{
				line = fReadLn(file);
				
				if(!isDefined(line) || line == "" || line == " ")
					break;
				
				if(isDefined(isEncrypt) && isEncrypt)
					line = CaesarShiftCipher(line, "decrypt");	
				
				content = strToK(line, ",");
				
				if(content.size > columnReturn)
				{
					if(content[columnSearch] == stringSearch)
					{
						result = content[columnReturn];
						break;
					}
				}
			}
		
			closeFile(file);
		}
	}
	
	return result;
}

splitAfterCharacters(string, n)
{
	tempArray = [];
	tempString = "";
	
	if(string.size > 1024)
	{
		while(string.size > n)
		{
			tempString = "";
			for(i=0;i<n;i++)
				tempString = tempString + string[i];
			
			tempArray[tempArray.size] = tempString;
			tempString = "";
			
			for(i=n;i<string.size;i++)
				tempString = tempString + string[i];

			string = tempString;
		}
		
		tempArray[tempArray.size] = tempString;
	}
	else
	{
		while(string.size > n)
		{
			tempArray[tempArray.size] = getSubStr(string, 0, n);
			string = getSubStr(string, n, string.size);
		}
	}
	
	return tempArray;
}

/*-----------------------|
|	effect related		 |
|-----------------------*/
add_effect(ref, file)
{
	if(!isDefined(level._effect))
		level._effect = [];

	level._effect[ref] = loadFx(file);
}

/*-----------------------|
|	language support	 |
|-----------------------*/
getPlayerLanguage()
{
	if(!isDefined(self.pers["language"]))
	{
		if(self getStat(2450) == 0)
			self setStat(2450, int(self GetUserinfo("loc_language")) + 1);
		
		self setPlayerLanguage();
	}

	return self.pers["language"];
}

setPlayerLanguage()
{
	switch(self getStat(2450))
	{
		case 14: self.pers["language"] = "HUNGARIAN"; break;		
		case 8: self.pers["language"] = "POLISH"; break;
		case 7: self.pers["language"] = "RUSSIAN"; break;
		case 5: self.pers["language"] = "SPANISH"; break;
		case 4: self.pers["language"] = "ITALIAN"; break;
		case 3: self.pers["language"] = "GERMAN"; break;
		case 2: self.pers["language"] = "FRENCH"; break;
		case 1:
		default: self.pers["language"] = "ENGLISH"; break;
	}
	
	self setClientDvar("r_language", self.pers["language"]);
}

getLocTextString(ref)
{
	language = undefined;
	if(isDefined(self) && isPlayer(self))
		language = self.pers["language"];
	
	if(!isDefined(language) || language == "")
	{
		language = getDvar("server_language");

		if(!isDefined(language) || language == "")
			language = "ENGLISH";
	}

	switch(language)
	{
		case "GERMAN":	return languages\german::findTranslation(ref);
		case "RUSSIAN":	return languages\russian::findTranslation(ref);

		//not existing yet - fall back to english
		//case "SPANISH":	return languages\spanish::findTranslation(ref);
		//case "FRENCH":	return languages\french::findTranslation(ref);
		//case "HUNGARIAN":	return languages\hungarian::findTranslation(ref);
		//case "ITALIAN":	return languages\italian::findTranslation(ref);
		//case "POLISH":	return languages\polish::findTranslation(ref);
		
		case "ENGLISH":
		default: return languages\english::findTranslation(ref);
	}
}

/*-----------------------|
|	date calculations	 |
|-----------------------*/
createDateArray(strDate, delimiter)
{
	if(isDefined(delimiter))
		array = strToK(strDate, delimiter);
	else
	{
		array = [];
		array[0] = getSubStr(strDate, 0, 3);
		array[1] = getSubStr(strDate, 4, 5);
		array[2] = getSubStr(strDate, 6, 7);
	}
	
	for(i=0;i<array.size;i++)
		array[i] = int(array[i]);
		
	return array;
}

dateToInt(year, month, day)
{
	if(month == 1 || month == 2)
	{
		year--;
		month += 12;
	}

	return 365*year + floor(year/4) - floor(year/100) + floor(year/400) + day + floor((153*month+8)/5);
}

dateDiffInDays(firstDate, secondDate)
{
	firstDateInDays = dateToInt(firstDate[0], firstDate[1], firstDate[2]);
	secondDateInDays = dateToInt(secondDate[0], secondDate[1], secondDate[2]);
	
	return (secondDateInDays - firstDateInDays);
}