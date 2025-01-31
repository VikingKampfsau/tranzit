init()
{
	level.messagefeed_startY = -68;

	if(!isDefined(level.messagefeed))
		level.messagefeed = [];

	for(i=0;i<level.messagefeed.size;i++)
	{
		if(isDefined(level.messagefeed[i]))
			level.messagefeed[i] destroy();
	}
	
	amount = 4;
	for(i=0;i<amount;i++)
	{
		level.messagefeed[i] = NewHudElem();
		level.messagefeed[i].font = "default";
		level.messagefeed[i].fontScale = 1.4;
		level.messagefeed[i].alignX = "left";
		level.messagefeed[i].alignY = "bottom";
		level.messagefeed[i].horzAlign = "left";
		level.messagefeed[i].vertAlign = "bottom";
		level.messagefeed[i].alpha = 0;
		level.messagefeed[i].sort = 1;
		level.messagefeed[i].x = 6;
		level.messagefeed[i].y = level.messagefeed_startY;
		level.messagefeed[i].archived = false;
		level.messagefeed[i].foreground = true;
		level.messagefeed[i].hidewheninmenu = true;
		level.messagefeed[i].id = i;
		level.messagefeed[i].timeLastChanged = i;
	}
}

//this should not be used to much since setText fills the configstring (engine) array
//according to cod4x this problem is fixed since September 12 2016 
writeToMessagefeed(locText, subValue, subString, subTimer, subPlayer)
{
	emptyLine = 0;
	lastChanged_temp = getTime();
	for(i=0;i<level.messagefeed.size;i++)
	{
		if(level.messagefeed[i].timeLastChanged < lastChanged_temp)
		{
			lastChanged_temp = level.messagefeed[i].timeLastChanged;
			emptyLine = i;
		}
	}
	
	level.messagefeed[emptyLine] notify("messagefeed_updates_this_line");
	level.messagefeed[emptyLine].y = level.messagefeed_startY;
	level.messagefeed[emptyLine].alpha = 0.9;
	level.messagefeed[emptyLine].label = locText;
	level.messagefeed[emptyLine].timeLastChanged = getTime();
	
	if(isDefined(subValue))
		level.messagefeed[emptyLine] setValue(subValue);

	if(isDefined(subString))
		level.messagefeed[emptyLine] setText(subString);
		
	if(isDefined(subTimer))
		level.messagefeed[emptyLine] setTimer(subTimer);
		
	if(isDefined(subPlayer))
		level.messagefeed[emptyLine] setPlayerNameString(subPlayer);

	level.messagefeed[emptyLine] thread cleanMessagefeedAfterTime();
	
	for(i=0;i<level.messagefeed.size;i++)
	{
		level.messagefeed[i] MoveOverTime(1);
		
		newPos = level.messagefeed[i].y - 15;
		if(newPos < (level.messagefeed_startY - level.messagefeed.size * 15))
			newPos = level.messagefeed_startY;
		
		level.messagefeed[i].y = newPos;
	}
}

cleanMessagefeedAfterTime()
{
	self endon("death");
	self endon("messagefeed_updates_this_line");

	wait 4;
	self FadeOverTime(1);
	self.alpha = 0;
	wait 1;
}