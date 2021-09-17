valueDebugHuds()
{
	if(!isDefined(level.valueDebugHud))
		level.valueDebugHud = [];

	for(i=0;i<level.valueDebugHud.size;i++)
	{
		if(isDefined(level.valueDebugHud[i]))
			level.valueDebugHud[i] destroy();
	}
	
	amount = 4;

	for(i=0;i<amount;i++)
	{
		level.valueDebugHud[i] = NewHudElem();
		level.valueDebugHud[i].font = "default";
		level.valueDebugHud[i].fontScale = 1.4;
		level.valueDebugHud[i].alignX = "left";
		level.valueDebugHud[i].alignY = "top";
		level.valueDebugHud[i].horzAlign = "left";
		level.valueDebugHud[i].vertAlign = "top";
		level.valueDebugHud[i].alpha = 0.75;
		level.valueDebugHud[i].sort = 1;
		level.valueDebugHud[i].x = 6;
		level.valueDebugHud[i].y = 30 + 15*i;
		level.valueDebugHud[i].archived = false;
		level.valueDebugHud[i].foreground = true;
		level.valueDebugHud[i].hidewheninmenu = true;
		level.valueDebugHud[i].id = i;
		
		level.valueDebugHud[i] thread showValueDebugHud();
	}
}

showValueDebugHud()
{
	self endon("death");
	
	while(1)
	{
		wait .1;

		switch(self.id)
		{
			case 0:
				value = level.zombiesTotalForWave;
				emptyLabel = &"^7Zoms for wave: ^1unknown";
				filledLabel = &"^7Zoms for wave: ^1&&1";
				break;

			case 1:
				value = level.zombiesLeftInWave;
				emptyLabel = &"^7Zoms left: ^10";
				filledLabel = &"^7Zoms left: ^1&&1";
				break;
				
			case 2:
				value = level.zombiesSpawned;
				emptyLabel = &"^7Zoms spawned: ^10";
				filledLabel = &"^7Zoms spawned: ^1&&1";
				break;

			case 3:
				value = level.dwarfsLeft;
				emptyLabel = &"^7Dwarfs alive: ^10";
				filledLabel = &"^7Dwarfs alive: ^1&&1";
				break;

			default: return;
		}
	
		if(!isDefined(value))
		{
			self.label = emptyLabel;
			continue;
		}
		
		self.label = filledLabel;

		if(isString(value))
			self setText(value);
		else if(isInt(value) || isFloat(value))
			self setValue(value);
	}
}