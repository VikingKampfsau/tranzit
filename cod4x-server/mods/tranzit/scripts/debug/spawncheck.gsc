teleportBetweenZomSpawns()
{
	self endon("disconnect");

	if(!isDefined(level.teamSpawnPoints[game["attackers"]]) || !level.teamSpawnPoints[game["attackers"]].size)
	{
		iPrintLnBold("^1No zombie spawns in map!");
		return;
	}
	
	iPrintLnBold("^1Spawn check started!");
	
	while(1)
	{
		wait .05;
		
		if(self AttackButtonPressed())
		{
			while(self AttackButtonPressed())
				wait .05;
				
			self gotoNextZombieSpawnLocation(1);
		}
		
		if(self AdsButtonPressed())
		{
			while(self AdsButtonPressed())
				wait .05;
				
			self gotoNextZombieSpawnLocation(-1);
		}
		
		/*if(self FragButtonPressed())
		{
			while(self FragButtonPressed())
				wait .05;
		}
		
		if(self secondaryOffhandButtonPressed())
		{
			while(self FragButtonPressed())
				wait .05;
		}
		
		if(self meleeButtonPressed())
		{
			while(self meleeButtonPressed())
				wait .05;
		}*/
	}
}

gotoNextZombieSpawnLocation(dir)
{
	if(!isDefined(self.currentCheck))
		self.currentCheck = 0;

	self iPrintLnBold("Spawn: " + self.currentCheck + " at: " + level.teamSpawnPoints[game["attackers"]][self.currentCheck].origin);

	self setOrigin(level.teamSpawnPoints[game["attackers"]][self.currentCheck].origin);
	self.currentCheck += dir;
			
	if(self.currentCheck >= level.teamSpawnPoints[game["attackers"]].size)
		self.currentCheck = 0;
		
	if(self.currentCheck < 0)
		self.currentCheck = (level.teamSpawnPoints[game["attackers"]].size -1);
}