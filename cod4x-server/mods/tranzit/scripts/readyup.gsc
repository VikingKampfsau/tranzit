#include maps\mp\_utility;
#include maps\mp\gametypes\_hud_util;
#include scripts\_include;

init()
{
	//ready-up
	precacheStatusIcon("compassping_enemy");
	precacheStatusIcon("compassping_friendlyfiring_mp");
	
	level.afkdelay = 60;
}

waitForPlayerStartPermission()
{
	while(!isDefined(level.playerCount) || !level.playerCount["allies"])
		wait .1;

	thread createReadyupTextHud();

	readyCount = 0;
	remainingTime = level.afkdelay;
	
	matchStartTimer = createReadyupTimer();
	matchStartTimer setTimer(remainingTime);

	while(!game["tranzit"].playersReady)
	{
		wait .1;
		
		remainingTime -= 0.1;
		
		if(remainingTime < 0)
			remainingTime = 0;
		
		if(!level.playerCount["allies"])
		{
			remainingTime = level.afkdelay;
			matchStartTimer setTimer(remainingTime);
		}

		readyCount = 0;
		survivors = [];
		for(i=0;i<level.players.size;i++)
		{
			level.players[i] ShowScoreBoard();
			level.players[i] disableWeapons();
			level.players[i] freezeControls(true);
			
			//new player that just connected
			if(!isDefined(level.players[i].isReady))
			{
				level.players[i].isReady = false;

				if(remainingTime <= 0 && level.playerCount["allies"] > 1)
				{
					level.players[i].isReady = true;
					level.players[i] thread [[level.spectator]]();
					
					level.players[i] openMenu(game["menu_team"]);
				}
				else
				{
					level.players[i] thread waitForReadyupStatusChange();
					level.players[i] thread showUseHintMessage(level.players[i] getLocTextString("READYUP_PRESS_BUTTON"), "use");
				}
				
				continue;
			}

			//player is ready
			if(level.players[i].isReady)
			{
				readyCount++;
			
				level.players[i].statusicon = "compassping_friendlyfiring_mp";
				level.players[i] thread showUseHintMessage(game["strings"]["waiting_for_teams"], undefined);
			}
			//player is not ready yet
			else
			{
				//player is a spectator (did not joint a team yet)
				if(level.players[i].pers["team"] == "spectator")
				{
					level.players[i].statusicon = "";
				
					//if(remainingTime <= 0)						
						level.players[i] openMenu(game["menu_team"]);
				}
				//not a spectator - tell him how to ready-up
				else
				{
					level.players[i].statusicon = "compassping_enemy";
				
					level.players[i] thread waitForReadyupStatusChange();
					level.players[i] thread showUseHintMessage(level.players[i] getLocTextString("READYUP_PRESS_BUTTON"), "use");
					
					if(remainingTime <= 0)
						level.players[i] thread [[level.spectator]]();
				}	
			}			
		}
		
		survivors = GetPlayersInTeam(game["defenders"]);
		if(level.players.size > 0 && readyCount > 0 && readyCount >= survivors.size)
			break;
	}
	
	matchStartTimer destroyElem();
	
	for(i=0;i<level.players.size;i++)
	{
		level.players[i].canDoCombat = true;
		level.players[i].statusicon = "";
		
		level.players[i] enableWeapons();
		level.players[i] freezeControls(false);
		level.players[i] clearLowerHintMessage();
		level.players[i] deleteUseHintMessages();
	}
	
	game["tranzit"].playersReady = true;
}

waitForReadyupStatusChange()
{
	self endon("disconnect");
	
	//only allow one instance
	self notify("readyup_monitor");
	self endon("readyup_monitor");
	
	if(self isABot())
		return;
	
	while(1)
	{
		if(!isDefined(self.pers["team"]) || self.pers["team"] == "none")
			continue;
		
		if(self useButtonPressed())
		{
			self.isReady = !self.isReady;
			
			while(self useButtonPressed())
				wait .05;
		}
		
		wait .05;
	}
}

createReadyupTextHud()
{
	visionSetNaked( "mpIntro", 0 );
	
	matchStartText = createServerFontString( "objective", 1.5 );
	matchStartText setPoint( "CENTER", "CENTER", 0, -20 );
	matchStartText.sort = 1001;
	matchStartText.label = getLocTextString("READYUP_WAITING");
	matchStartText.foreground = false;
	matchStartText.hidewheninmenu = true;
	
	while(!game["tranzit"].playersReady)
		wait .05;
	
	matchStartText FadeOverTime(2);
	matchStartText.alpha = 0;
	wait 2;

	visionSetNaked( getDvar( "mapname" ), 2.0 );
	
	matchStartText.label = &"All players are ready!";
	matchStartText FadeOverTime(2);
	matchStartText.alpha = 1;
	wait 2;
	
	wait 3;

	matchStartText FadeOverTime(2);
	matchStartText.alpha = 0;
	wait 2;
	
	matchStartText destroyElem();
}

createReadyupTimer()
{
	matchStartTimer = createServerTimer( "objective", 1.4 );
	matchStartTimer setPoint( "CENTER", "CENTER", 0, 25 );
	matchStartTimer.sort = 1001;
	matchStartTimer.foreground = false;
	matchStartTimer.hideWhenInMenu = true;
	matchStartTimer.color = (1, 0.5, 0);
	
	return matchStartTimer;
}