privateValueDebugHuds()
{
	self endon("disconnect");

	if(!isDefined(self.valueDebugHud))
		self.valueDebugHud = [];

	for(i=0;i<self.valueDebugHud.size;i++)
	{
		if(isDefined(self.valueDebugHud[i]))
			self.valueDebugHud[i] destroy();
	}
	
	amount = 3;

	for(i=0;i<amount;i++)
	{
		self.valueDebugHud[i] = NewClientHudElem(self);
		self.valueDebugHud[i].font = "default";
		self.valueDebugHud[i].fontScale = 1.4;
		self.valueDebugHud[i].alignX = "right";
		self.valueDebugHud[i].alignY = "top";
		self.valueDebugHud[i].horzAlign = "right";
		self.valueDebugHud[i].vertAlign = "top";
		self.valueDebugHud[i].alpha = 0.75;
		self.valueDebugHud[i].sort = 1;
		self.valueDebugHud[i].x = -6;
		self.valueDebugHud[i].y = 30 + 15*i;
		self.valueDebugHud[i].archived = false;
		self.valueDebugHud[i].foreground = true;
		self.valueDebugHud[i].hidewheninmenu = true;
		self.valueDebugHud[i].id = i;
	}
	
	self thread showPrivateValueDebugHud(amount);
}

showPrivateValueDebugHud(amount)
{
	self endon("disconnect");
	self endon("death");
	
	while(1)
	{
		wait .05;

		for(i=0;i<amount;i++)
		{
			switch(self.valueDebugHud[i].id)
			{
				case 0:
					value = self.isOnTruck;
					emptyLabel = &"^7On Truck: undefined";
					filledLabel = &"^7On Truck: &&1";
					break;
				
				case 1:
					value = self getPmFlag();
					emptyLabel = &"^7PM Flag: undefined";
					filledLabel = &"^7PM Flag: &&1";
					break;
					
				case 2:
					value = self getWeaponState();
					emptyLabel = &"^7WeaponState: undefined";
					filledLabel = &"^7WeaponState: &&1";
					break;

				default: continue;
			}
		
			if(!isDefined(value))
			{
				self.valueDebugHud[i].label = emptyLabel;
				continue;
			}
			
			self.valueDebugHud[i].label = filledLabel;

			if(isString(value))
				self.valueDebugHud[i] setText(value);
			else if(isInt(value) || isFloat(value))
				self.valueDebugHud[i] setValue(value);
		}
	}
}

globalValueDebugHuds()
{
	if(!isDefined(level.valueDebugHud))
		level.valueDebugHud = [];

	for(i=0;i<level.valueDebugHud.size;i++)
	{
		if(isDefined(level.valueDebugHud[i]))
			level.valueDebugHud[i] destroy();
	}
	
	amount = 5;

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
		
		level.valueDebugHud[i] thread showValueDebugHud(self);
	}
}

showValueDebugHud(player)
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
				
			case 4:
				value = player.lastDroppableWeapon;
				emptyLabel = &"^7Dropable: ^1none";
				filledLabel = &"^7Dropable: ^1&&1";
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