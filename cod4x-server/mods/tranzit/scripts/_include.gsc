/*-----------------------|
|	debug related		 |
|-----------------------*/
initDebugVar(name, value)
{
	if(!game["debug"]["status"])
		game["debug"][name] = 0;
	else
		game["debug"][name] = value;
}

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

pointInTrigger(point, trigger)
{
	entity = spawn("script_origin", point);
	
	if(entity isTouching(trigger))
	{
		entity delete();
		return true;
	}
		
	entity delete();
	return false;
}

pointInBox(x, Box, height)
{
	//the object is not trigger - we have to do some math
	//https://math.stackexchange.com/questions/1472049/check-if-a-point-is-inside-a-rectangular-shaped-area-3d
	//
	//visualized
	//     P6---------P7
	//    /|         /|
	//   / |        / |
	//  /  |   x   /  |
	//  P5-|-------P8 |
	//  |  P2______|__P3
	//  |  /       |  /
	//	| /        | /
	//  |/         |/
	//  P1---------P4
	//
	// point x lies within the box when the three following constraints are respected:
    // The dot product u.x is between u.P1 and u.P2
    // The dot product v.x is between v.P1 and v.P4
    // The dot product w.x is between w.P1 and w.P5	x = self.origin;

	Box.P[5] = Box.P[1] + (0, 0, Box.height);
	Box.P[6] = Box.P[2] + (0, 0, Box.height);
	Box.P[7] = Box.P[3] + (0, 0, Box.height);
	Box.P[8] = Box.P[4] + (0, 0, Box.height);
	
	u = Box.P[1] - Box.P[2];
	uDOTP1 = vectorDot(u, Box.P[1]);
	uDOTx = vectorDot(u, x); 
	uDOTP2 = vectorDot(u, Box.P[2]);
	
	if((uDOTP1 < uDOTx && uDOTx < uDOTP2) || (uDOTP1 > uDOTx && uDOTx > uDOTP2))
	{
		v = Box.P[1] - Box.P[4];
		vDOTP1 = vectorDot(v, Box.P[1]);
		vDOTx = vectorDot(v, x);
		vDOTP4 = vectorDot(v, Box.P[4]);
		
		if((vDOTP1 < vDOTx && vDOTx < vDOTP4) || (vDOTP1 > vDOTx && vDOTx > vDOTP4))
		{
			//this can fail when the box is rotated by pitch
			//w = Box.P[1] - Box.P[5];
			//wDOTP1 = vectorDot(w, Box.P[1]);
			//wDOTx = vectorDot(w, x);
			//wDOTP5 = vectorDot(w, Box.P[5]);
			//iPrintLnBold("wDOTP1 " + wDOTP1 + " wDOTx " + wDOTx + " wDOTP5 " + wDOTP5);
			//if((wDOTP1 < wDOTx && wDOTx < wDOTP5) || (wDOTP1 > wDOTx && wDOTx > wDOTP5))
			//{
			//	iPrintLnBold("passed check 3");
			//	return true;
			//}
			
			//to be save checks against all corners should be performed
			for(i=1;i<=4;i++)
			{
				Pb = Box.P[i]; //PBottom
				Pu = Box.P[4+i]; //PUp
			
				w = Pb - Pu;
				wDOTPb = vectorDot(w, Pb);
				wDOTx = vectorDot(w, x);
				wDOTPu = vectorDot(w, Pu);
				
				if((wDOTPb < wDOTx && wDOTx < wDOTPu) || (wDOTPb > wDOTx && wDOTx > wDOTPu))
					return true;
			}
		}
	}
	
	return false;
}

DegToRad(degrees)
{
	pi = 3.14159265359;
	radians = degrees * pi / 180;
	
	return radians;
}

// Gives the result as an angle between -X and X
AngleClamp(angle, X)
{
	angleFrac = angle / 360.0;
	angle = ( angleFrac - floor( angleFrac ) ) * 360.0;
	if( angle > X )
		return angle - 360.0;
	return angle;
}

atan2(y, x)
{
	pi = 3.14159265359;

	// atan2 is an invalid operation when x = 0 and y = 0, but this method does not return errors.
	a = 0;

	if(x > 0)
		a = atan(y/x);
	else if(x < 0 && y >= 0)
		a = atan(y/x) + pi;
	else if(x < 0 && y < 0)
		a = atan(y/x) - pi;
	else if(x == 0 && y > 0)
		a = pi/2;
	else if(x == 0 && y < 0)
		a = 0-pi/2;

	return a;
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
	level endon("game_will_end");
	
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

showTriggerUseHintMessage(trigger, locText, subValue, subString, subTimer, subShader, ratio)
{
	self endon("disconnect");

	if(isDefined(subShader))
		self thread showTriggerUseHintImage(subShader, ratio);

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
		
	if(isDefined(self.triggerUseHintImage))
		self.triggerUseHintImage destroy();
}

deleteUseHintMessages(normal, triggerBased)
{
	self endon("disconnect");

	if(!isDefined(normal)) normal = true;
	if(!isDefined(triggerBased)) triggerBased = true;

	if(normal && isDefined(self.useHintText))
		self.useHintText destroy();
	
	if(triggerBased)
	{
		if(isDefined(self.triggerUseHintText))
			self.triggerUseHintText destroy();
			
		if(isDefined(self.triggerUseHintImage))
			self.triggerUseHintImage destroy();
	}
}

showTriggerUseHintImage(subShader, ratio)
{
	if(isDefined(self.triggerUseHintImage))
		return;

	if(!isDefined(ratio))
		ratio = "1:1";

	ratio = strToK(ratio, ":");
	
	self.triggerUseHintImage = newClientHudElem(self);
	self.triggerUseHintImage.alignX = "center";
	self.triggerUseHintImage.alignY = "middle";
	self.triggerUseHintImage.horzalign = "center";
	self.triggerUseHintImage.vertalign = "middle";
	self.triggerUseHintImage.sort = 1;
	self.triggerUseHintImage.alpha = 1;
	self.triggerUseHintImage.x = 0; //0-(32*int(ratio[1]))/2
	self.triggerUseHintImage.y = 86;
	self.triggerUseHintImage.archived = false;
	self.triggerUseHintImage.hidewheninmenu = true;
	self.triggerUseHintImage SetShader(subShader, 32*int(ratio[0]), 32*int(ratio[1]));
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

getHudDisplayname(string, sourceType)
{
	if(!isDefined(sourceType))
		sourceType = "";

	string = StrRepl(string, "_", " ");
	tokens = strToK(string, " ");

	name = "";
	for(i=0;i<tokens.size;i++)
	{
		if(isDefined(tokens[i]) && tokens[i] != "")
		{
			if(sourceType == "weapon")
			{
				if(toLower(tokens[i]) == "ug")
					tokens[i] = "(upgraded)";
			}
			else if(sourceType == "map")
			{
				if(toLower(tokens[i]) == "mp")
					continue;
			}
		
			tokens[i] = toUpper(getSubStr(tokens[i], 0, 1)) + getSubStr(tokens[i], 1, tokens[i].size);
			name = name + tokens[i] + " ";
		}
	}

	return name;
}

replacePlaceholders(input, replacements)
{
	if(!isDefined(input))
	{
		//consolePrint("input undefined");
		return;
	}
		
	if(!isDefined(replacements) || !replacements.size)
	{
		//consolePrint("replacements undefined");
		return;
	}

	string = input;
	if(isLocString(input))
		string = locStringToString(input);

	if(!isString(string))
	{
		//consolePrint("string is not a string or locString");
		return;
	}
		
	for(i=0;i<replacements.size;i++)
	{
		if(isSubStr(string, "&&"+int(i+1)))	
			string = StrRepl(string, "&&"+int(i+1), replacements[i]);
		else
			string = string + replacements[i];
	}
	
	return string;
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

modelHasTag(model, tag)
{
	/*
	parts = getNumParts(model);

	for(i=0;i<parts;i++)
	{
		if(getPartName(model, i) == tag)
		{
			//iPrintLnBold("model '" + model + "' has tag '" + tag + "' 1\n");
			return true;
		}
	}
	
	//iPrintLnBold("model '" + model + "' has tag '" + tag + "' 0\n");
	return false;
	*/
	
	//added a plugin - that's faster
	//iPrintLnBold("model '" + model + "' has tag '" + tag + "' " + xmodelHasBone(model, tag) + "\n");
	return xmodelHasBone(model, tag);
}

/*-----------------------|
|	player related		 |
|-----------------------*/
playermodelHasTag(tag)
{
	self endon("disconnect");

	models = [];
	models[models.size] = self.model;
	
	for(j=0;j<self getAttachSize();j++)
		models[models.size] = self getAttachModelName(j);

	for(k=0;k<models.size;k++)
	{
		if(modelHasTag(models[k], tag))
			return true;
	}
	
	return false;
}

GetUniquePlayerID()
{
	guid = self GetGuid();
	
	if(!isDefined(guid) || guid == "")
		guid = self GetPlayerID();
		
	if(!isDefined(guid))
		return "";
		
	return guid;
}

getPlayer(value, executor)
{
	if(isDefined(value) && value.size > 0)
	{
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

			if(isDefined(executor) && isPlayer(executor))
			{
				if(counter == 0)
					exec("tell " + executor getEntityNumber() + " ^1NO PLAYER FOUND");
				else
					exec("tell " + executor getEntityNumber() + " ^1MULTIPLE PLAYERS FOUND");
			}
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

isInSameTeamAs(player)
{
	if(isDefined(player) && isPlayer(player))
	{
		if(isDefined(self.pers["team"]) && isDefined(player.pers["team"]))
		{
			if(self.pers["team"] == player.pers["team"])
				return true;
		}
	}
		
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

isReadyToUse(hasToBeSurvivor, hasToBeOnGround)
{
	if(!isDefined(hasToBeSurvivor))
		hasToBeSurvivor = true;
		
	if(!isDefined(hasToBeOnGround))
		hasToBeOnGround = true;

	if(hasToBeSurvivor && !self isASurvivor())
		return false;
		
	if(self isInLastStand())
		return false;
		
	if(self isReviving())
		return false;
		
	if(self isFridging())
		return false;
		
	if(hasToBeOnGround && !self isOnGround())
		return false;
		
	if(self isMantling() || (isDefined(self.mantleInVehicle) && self.mantleInVehicle))
		return false;
		
	return true;
}

isFridging()
{
	if(!isDefined(self.fridging))
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
	
	self.lastUsedWeapon = self checkCurrentWeaponUseability();
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
	
		if(isHardpointWeapon(self.weapons[i]))
		{
			self giveActionslotWeapon("hardpoint", self.weapons[i]);
			continue;
		}

		self giveWeapon(self.weapons[i]);
		
		if(isAGrenade(self.weapons[i]))
			self switchToOffhand(self.weapons[i]);
		else
		{
			if(isOtherExplosive(self.weapons[i]))
				self giveActionslotWeapon("weapon", self.weapons[i]);
		
			if(self.pers["primaryWeapon"] == "none")
				self.pers["primaryWeapon"] = self.weapons[i];

			if(self.pers["secondaryWeapon"] == "none")
				self.pers["secondaryWeapon"] = self.weapons[i];
		}
	
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
	
	if(isDefined(self.lastUsedWeapon) && self HasWeapon(self.lastUsedWeapon))
	{
		self SwitchToWeapon(self.lastUsedWeapon);
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

giveNewWeapon(newWeapon, noWeaponSwitch, keepHands, ammoClip, ammoStock)
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
			
			if(!isDefined(slot))
				return false;
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
	
		if(!isDefined(ammoClip) && !isDefined(ammoStock))
			self giveMaxAmmo(newWeapon);
		else
		{
			if(isDefined(ammoClip))
				self setWeaponAmmoClip(newWeapon, ammoClip);
			
			if(isDefined(ammoStock))
				self setWeaponAmmoStock(newWeapon, ammoStock);
		}
		
		if(!isDefined(noWeaponSwitch) || !noWeaponSwitch)
			self switchToNewWeapon(newWeapon, .05);
	}
	
	return true;
}

killAllZombies(survivorReward)
{
	for(i=0;i<level.players.size;i++)
	{
		if(level.players[i] isAZombie() && isAlive(level.players[i]))
		{
			level.players[i] thread [[level.callbackPlayerDamage]](level.players[i], level.players[i], level.players[i].health + 666, 0, "MOD_RIFLE_BULLET", "ak47_mp", self.origin, VectorToAngles(self.origin - self.origin), "head", 0, "forced zombie suicide");
			
			//if there are any erros about no free die handlers a wait .05 shoule be added here
			//even when all zombies are alive (game["tranzit"].zombie_max_ai = 24;) this function will kill them all within 1,2 seconds
			
			continue;
		}
		
		if(level.players[i] isASurvivor() && isDefined(survivorReward))
		{
			level.players[i] thread [[level.onXPEvent]](survivorReward);
			continue;
		}
	}
}

killAllSurvivorsInLastStand()
{
	for(i=0;i<level.players.size;i++)
	{
		level.players[i] setClientDvar("cg_thirdpersonRange", 10);
	
		if(level.players[i] isASurvivor() && level.players[i] isInLastStand())
			level.players[i] suicide();
	}
}

execClientCommand(cmd)
{
	/*
	available commands:
	"attack" -> shoot once
	"reload"
	"melee"
	"smoke"
	"frag"
	"toggleads"
	"gocrouch"
	"goprone"
	"reconnect"
	"disconnect"
	"quit"	
	"record"
	"stoprecord"
	"attack_start" -> hold attack button until "attack_end" is called
	"attack_end"
	"sprint_start" -> hold sprint button until "sprint_end" is called
	"sprint_end"
	"leanleft_start" -> lean left until "leanleft_end" is called
	"leanleft_end"
	"leanright_start" -> lean right until "leanleft_end" is called
	"leanright_end"
	"holdbreath_start" -> hold breath until "holdbreath_end" is called
	"holdbreath_end"
	*/

	self setClientDvar("clientcmd", cmd);
	self openMenu("clientcmd");
}

setClientDvarsDelayed(dvars, values, cancelString)
{
	self notify(cancelString);
	self endon(cancelString);

	//validate the input data
	for(i=0;i<dvars.size;i++)
	{
		if(!isDefined(dvars[i]))
			dvars[i] = "scoreboard_error";
		
		if(!isDefined(values[i]))
			values[i] = "error";
	}

	processed = 0;
	while((dvars.size - processed) >= 3)
	{
		/*
		self iPrintLnBold("sending 3 dvars, remaining: " + (dvars.size - processed) % 3);
		self iPrintLnBold(dvars[processed] + " " + values[processed]);
		self iPrintLnBold(dvars[processed+1] + " " + values[processed+1]);
		self iPrintLnBold(dvars[processed+2] + " " + values[processed+2]);
		*/
		
		self setClientDvars(dvars[processed], values[processed], dvars[processed+1], values[processed+1], dvars[processed+2], values[processed+2]);
		waittillframeend;
		processed += 3;
	}
	
	while((dvars.size - processed) >= 2)
	{
		/*
		self iPrintLnBold("sending 2 dvars, remaining: " + (dvars.size - processed) % 2);
		self iPrintLnBold(dvars[processed] + " " + values[processed]);
		self iPrintLnBold(dvars[processed+1] + " " + values[processed+1]);
		*/
		
		self setClientDvars(dvars[processed], values[processed], dvars[processed+1], values[processed+1]);
		waittillframeend;
		processed += 2;
	}
	
	if((dvars.size - processed) > 0)
	{
		/*
		self iPrintLnBold("sending single dvar");
		self iPrintLnBold(dvars[processed] + " " + values[processed]);
		*/
		
		self setClientDvar(dvars[processed], values[processed]);
	}
	
	//self iPrintLnBold("received " + dvars.size + " processed " + processed);
}

/*-----------------------|
|	weapon related		 |
|-----------------------*/
add_weapon(ref, weapon, isDropable)
{
	if(!isDefined(isDropable))
		isDropable = false;

	if(!isDefined(level.tranzitWeapon))
		level.tranzitWeapon = []; 

	curEntry = level.tranzitWeapon.size;
	level.tranzitWeapon[curEntry] = spawnStruct();
	level.tranzitWeapon[curEntry].name = ref;
	level.tranzitWeapon[curEntry].weapon = weapon;
	level.tranzitWeapon[curEntry].isDropable = isDropable;
	level.tranzitWeapon[curEntry].displayName = getHudDisplayname(ref, "weapon");
	
	weaponName = getSubStr(weapon, 0, weapon.size - 3);
	level.tranzitWeapon[curEntry].image = tablelookup("mp/weaponTable.csv", 1, weaponName, 3);
	
	if(weaponClass(weapon) == "pistol")
		level.tranzitWeapon[curEntry].imageRatio = "1:1";
	else
		level.tranzitWeapon[curEntry].imageRatio = "2:2";
	/*
	if(weaponClass(weapon) == "grenade")
		level.tranzitWeapon[curEntry].imageRatio = "1:1";
	else if(weaponClass(weapon) == "pistol")
		level.tranzitWeapon[curEntry].imageRatio = "1:1";
	else if(weaponClass(weapon) == "mg")
		level.tranzitWeapon[curEntry].imageRatio = "2:1";
	else if(weaponClass(weapon) == "smg")
		level.tranzitWeapon[curEntry].imageRatio = "2:1";
	else
		level.tranzitWeapon[curEntry].imageRatio = "4:1";
	*/
	
	precacheItem(weapon);
}

isCustomWeapon(weapon)
{
	for(i=0;i<level.tranzitWeapon.size;i++)
	{
		if(level.tranzitWeapon[i].weapon == weapon)
			return level.tranzitWeapon[i].name;
	}
	
	return "noCustomWeapon";
}

getCustomWeaponArrayElemFromCustomName(name)
{
	for(i=0;i<level.tranzitWeapon.size;i++)
	{
		if(level.tranzitWeapon[i].name == name)
			return level.tranzitWeapon[i];
	}
	
	return "noCustomWeapon";
}

getWeaponFromCustomName(name)
{
	for(i=0;i<level.tranzitWeapon.size;i++)
	{
		if(level.tranzitWeapon[i].name == name)
			return level.tranzitWeapon[i].weapon;
	}
	
	return "noCustomWeapon";
}

checkCurrentWeaponUseability()
{
	self endon("death");
	self endon("disconnect");

	curWeapon = self GetCurrentWeapon();

	/*if(curWeapon == getWeaponFromCustomName("syrette"))
		return undefined;
	
	if(curWeapon == getWeaponFromCustomName("sentrygun"))
		return undefined;
	
	if(curWeapon == getWeaponFromCustomName("monkeybomb"))
		return undefined;
	
	if(curWeapon == getWeaponFromCustomName("generator"))
		return undefined;
	
	if(curWeapon == getWeaponFromCustomName("perksacola"))
		return undefined;
	
	if(curWeapon == getWeaponFromCustomName("location_selector"))
		return undefined;
	
	if(curWeapon == getWeaponFromCustomName("player_dwarf_attacking"))
		return undefined;

	return curWeapon;*/
		
	if(isDropableWeapon(curWeapon))
		return curWeapon;
	
	return undefined;
}

isDropableWeapon(weapon)
{
	if(!isDefined(weapon))
		return false;

	customWeaponName = isCustomWeapon(weapon);
	if(customWeaponName != "noCustomWeapon")
		return getCustomWeaponArrayElemFromCustomName(customWeaponName).isDropable;

	if(weapon == "none")
		return false;

	if(isSubStr(weapon, "_grenade_"))
		return false;

	return true;
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

isSniper(weapon)
{
	if(isSubStr(weapon, "m40a3_"))
		return true;
	if(isSubStr(weapon, "dragunov_"))
		return true;
	if(isSubStr(weapon, "remington700_"))
		return true;
	if(isSubStr(weapon, "barrett_"))
		return true;

	return false;
}

isAGrenade(weapon)
{
	//return isSubStr(weapon, "_grenade_");

	if(WeaponClass(weapon) == "grenade")
		return true;

	return false;
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
	if(isSubStr(weapon, "at4_mp"))
		return true;

	return false;
}

isHardpointWeapon(weapon)
{
	if(weapon == getWeaponFromCustomName("location_selector"))
		return true;

	return false;
}

isTurret(weapon)
{
	return isSubStr(weapon, "_bipod_");
}

isCraftedWeapon(weapon)
{
	if(weapon == getWeaponFromCustomName("riotshield"))
		return true;
	if(weapon == getWeaponFromCustomName("sentrygun"))
		return true;
	if(weapon == getWeaponFromCustomName("monkeybomb"))
		return true;
	if(weapon == getWeaponFromCustomName("generator"))
		return true;
	if(weapon == getWeaponFromCustomName("wavegun"))
		return true;
		
	return false;
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

fake_physicslaunch_over_time( target_pos, time )
{
	start_pos = self.origin; 
	
	///////// Math Section
	// Reverse the gravity so it's negative, you could change the gravity
	// by just putting a number in there, but if you keep the dvar, then the
	// user will see it change.
	gravity = GetDvarInt( "g_gravity" ) * -1; 

	delta = target_pos - start_pos; 
	drop = 0.5 * gravity *( time * time ); 
	
	velocity = ( ( delta[0] / time ), ( delta[1] / time ), ( delta[2] - drop ) / time ); 
	///////// End Math Section

	self MoveGravity( velocity, time );
}

//from ow mod - no idea what it does
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

//this push is using the damage function
//advantage: can throw the player up if needed
//disadvantage: shows a damage indicator on the screen
pushPlayer(pushingEnt, direction, pushes, pushZoms, killZoms)
{
	self endon("disconnect");
	self endon("death");

	if(!isDefined(direction))
		direction = 1;

	if(!isDefined(pushZoms))
		pushZoms = true;
		
	if(!isDefined(killZoms))
		killZoms = true;

	if(self isAZombie() && !pushZoms)
	{
		if(killZoms)
		{
			vDir = vectorNormalize(self.origin - pushingEnt.origin);
			self thread [[level.callbackPlayerDamage]](pushingEnt, self, self.health + 666, 0, "MOD_CRUSH", "none", self.origin, vDir, "none", 0, "pushed by vehicle");
		}

		return;
	}
	
	power = 1000;
	for(i=0;i<pushes;i++)
	{
		health = self.health;
		self.health += power;

		//direction 1 -> push away from pushingEnt
		//direction -1 -> pull towards pushingEnt
		vDir = vectorNormalize(self.origin - pushingEnt.origin) * direction;
		dist = 10; //Distance(self.origin, pushingEnt.origin);

		if(!isAlive(self))
			break;

		//no [[level.callbackPlayerDamage]] here, we need the full damage - not reduced by armorVest/juggernaut
		self iPrintLnBold("vehicle push - heavy");
		self finishPlayerDamage(pushingEnt, self, power, 0, "MOD_PROJECTILE", "none", pushingEnt.origin, self.origin - pushingEnt.origin, "none", 0);

		self.health = health;
		self setNormalHealth(self.health);
	}
}

//this push fakes player movement
//advantage: no damage indicator on the screen
//disadvantage: can not push the player upwards
pushPlayer2D(pushFromEnt, insideCheckerEnt, checkerEntIsTouchable, direction, strength)
{
	self endon("disconnect");
	self endon("death");

	if(!isDefined(direction))
		direction = "forward";
		
	if(!isDefined(strength))
		strength = 200;

	if(!isDefined(checkerEntIsTouchable))
		checkerEntIsTouchable = true;

	forward = AnglesToForward(pushFromEnt.angles);
	if(direction == "back")
		forward = AnglesToForward(pushFromEnt.angles) * -1;
	else if(direction == "right")
		forward = AnglesToRight(pushFromEnt.angles);
	else if(direction == "left")
		forward = AnglesToRight(pushFromEnt.angles) * -1;

	if(self IsTouching(pushFromEnt))
	{
		if((checkerEntIsTouchable && self IsTouching(insideCheckerEnt)) || (!checkerEntIsTouchable && Distance(self.origin, insideCheckerEnt.origin) < Distance(pushFromEnt.origin, insideCheckerEnt.origin)))
			self SetVelocity(forward * strength * -1);
		else
			self SetVelocity(forward * strength);
	}
}

/*-----------------------|
|	string related		 |
|-----------------------*/
//Check if a string is empty or contains spaces only
isEmptyString(string)
{
	if(string == "")
		return true;
		
	if(getSubStr(string, 0, 2) == "//")
		return true;
		
	if(string == "\t" || string == "\r" || string == "\n")
		return true;
		
	index = 0;
	while(getSubStr(string, index, index + 1) == " " && index < string.size)
		index++;
	
	return (index >= string.size);
}

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

resetVision(transition)
{
	if(!isDefined(transition))
		transition = 0;

	visionSetNaked(getDvar("mapname"), transition);
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
	{
		array = strToK(strDate, delimiter);
		
		if(array[0].size < 4) array[0] = "0" + array[0];
		if(array[0].size < 4) array[0] = "2" + array[0];
		if(array[1].size < 2) array[1] = "0" + array[1];
		if(array[2].size < 2) array[2] = "0" + array[2];
	}
	else
	{
		array = [];
		array[0] = getSubStr(strDate, 0, 4);
		array[1] = getSubStr(strDate, 4, 6);
		array[2] = getSubStr(strDate, 6, 8);
	}

	return array;
}

dateToInt(year, month, day, hour, minute, second)
{
	//cod4x getRealTime() starts on 01/01/2012
	year -= 2012;

	if(month == 1 || month == 2)
	{
		year--;
		month += 12;
	}

	int = 365*year + floor(year/4) - floor(year/100) + floor(year/400);
	int += floor((153*month+8)/5);
	int += day;

	if(isDefined(hour))
	{
		int *= 24;
		int += hour;
	}
	
	if(isDefined(minute))
	{
		int *= 60;
		int += minute;
	}
	
	if(isDefined(second))
	{
		int *= 60;
		int += second;
	}
	
	return int;
}

dateDiffInDays(firstDate, secondDate)
{
	firstDateInDays = dateToInt(int(firstDate[0]), int(firstDate[1]), int(firstDate[2]));
	secondDateInDays = dateToInt(int(secondDate[0]), int(secondDate[1]), int(secondDate[2]));
	
	return (secondDateInDays - firstDateInDays);
}

millisecondsAsTime(milliseconds)
{
	return secondsAsTime(milliseconds / 1000);
}

secondsAsTime(seconds)
{
	time = spawnStruct();
	
	time.days = floor(seconds / (24*sqr(60)));
	seconds -= (time.days * 24*sqr(60));
	
	time.hours = floor(seconds / sqr(60));
	seconds -= (time.hours * sqr(60));
	
	time.minutes = floor(seconds / 60);
	seconds -= (time.minutes * 60);
	
	time.seconds = int(seconds);
	
	return time;
}

/*-----------------------|
|		map related		 |
|-----------------------*/
getMapType(mapName)
{
	//tranzit has a vehicle and a vehicle path
	if((isDefined(getEnt("tranzit_vehicle", "targetname")) || isDefined(getEnt("tranzit_vehicle_temp", "targetname"))) && isDefined(getEnt("tranzit_start", "targetname")))
		return "tranzit";

	//rotu has places to regain ammo (ammostock) and weapon shops (weaponupgrade)
	ammostocks = getEntArray("ammostock", "targetname");
	weaponupgrades = getEntArray("weaponupgrade", "targetname");
	if((isDefined(ammostocks) && ammostocks.size > 0) || (isDefined(weaponupgrades) && weaponupgrades.size > 0))
		return "rotu";

	return "default";
}

//if called with a groundPos then groundPos must have free space upwards
GetSkyHeight(groundPos, returnFixedGroundPos)
{
	start = undefined;

	//if the map has a compass use the corners to calculate the height
	//the corners are in the corners of the skybox - it should be save to use them
	minimapCorners = getEntArray("minimap_corner", "targetname");
	if(isDefined(minimapCorners) && minimapCorners.size > 0)
	{
		start = minimapCorners[0].origin;
		for(i=1;i<minimapCorners.size;i++)
		{
			if(minimapCorners[i].origin[2] >= start[2])
				start = minimapCorners[i].origin;
		}
	}

	//if the map has a heli flypath use it to calculate the height
	//the helicopter is circling in a free space - it should be save to use it
	if(!isDefined(start))
	{
		heli_loop_starts = getEntArray("heli_loop_start", "targetname");
		if(isDefined(heli_loop_starts) && heli_loop_starts.size > 0)
		{
			start = heli_loop_starts[0].origin;
			for(i=1;i<heli_loop_starts.size;i++)
			{
				if(heli_loop_starts[i].origin[2] >= start[2])
					start = heli_loop_starts[i].origin;
			}
		}
	}
	
	//nothing found - use the groundPos
	if(!isDefined(start))
	{
		if(isDefined(groundPos))
			start = groundPos;
		else
		{
			returnFixedGroundPos = false;
			trace = BulletTrace(level.mapCenter + (0,0,100000), level.mapCenter, false, undefined);
			start = trace["position"] - (0,0,10); //make sure the next upwards trace will hit again
		}
	}
	
	MapSkyPos = start;
	trace = BulletTrace(start, start + (0,0,10000), false, undefined);
	//skybox found - Update MapSkyPos
	if(isDefined(trace["surfacetype"]) && trace["surfacetype"] == "default")
		MapSkyPos = getSkyBoxBrushThickness(trace);
	
	//iPrintLnBold("Sky: " + MapSkyPos[2]);
	
	if(!isDefined(returnFixedGroundPos) || !returnFixedGroundPos)
		return MapSkyPos;

	groundPos = BulletTrace(groundPos + (0,0,MapSkyPos[2]), groundPos, false, undefined)["position"];
	//iPrintLnBold("Fixed groundPos: " + groundPos[2]);
		
	array[0] = MapSkyPos;
	array[1] = groundPos;

	return array;
}

getSkyBoxBrushThickness(trace)
{
	tempPos = trace["position"];
	for(i=0;i<200 && isDefined(trace["surfacetype"]) && trace["surfacetype"] == "default"; i++)
	{
		trace = BulletTrace(trace["position"] - (0,0,10), trace["position"] - (0,0,20), false, undefined);
		if(!isDefined(trace["surfacetype"]) || trace["surfacetype"] != "default")
			break;

		tempPos = trace["position"];
	}
	
	tempPos -= (0,0,1);
	return tempPos;
}