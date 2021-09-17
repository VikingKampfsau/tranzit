warnLastPlayer()
{
	self endon("death");
	self endon("disconnect");
	
	fullHealthTime = 0;
	interval = .05;
	
	while(1)
	{
		if ( self.health != self.maxhealth )
			fullHealthTime = 0;
		else
			fullHealthTime += interval;
		
		wait interval;
		
		if (self.health == self.maxhealth && fullHealthTime >= 3)
			break;
	}
	
	self maps\mp\gametypes\_globallogic::leaderDialogOnPlayer( "last_alive" );
	self maps\mp\gametypes\_missions::lastManSD();
}