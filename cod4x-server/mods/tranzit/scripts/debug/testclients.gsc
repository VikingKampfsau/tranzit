init()
{
	thread addTestClients();
}

addTestClients()
{
	level endon("game_ended");
	level endon("game_will_end");

	for(;;)
	{
		if(getdvarInt("scr_testclients") > 0)
			break;

		wait 1;
	}

	testclients = getdvarInt("scr_testclients");
	setDvar( "scr_testclients", 0 );
	
	for(i = 0; i < testclients; i++)
	{
		ent[i] = addtestclient();

		if (!isDefined(ent[i])) 
		{
			println("Could not add test clients");
			break;
		}
			
		ent[i].pers["isBot"] = true;
		ent[i].pers["isTestclient"] = true;
		ent[i] thread TestClientJoin();
	}
	
	thread addTestClients();
}

TestClientJoin()
{
	level endon("game_ended");
	level endon("game_will_end");

	self endon("disconnect");

	while(!isDefined(self.pers["team"]))
		wait .05;

	self notify("menuresponse", game["menu_team"], "axis");
	wait .5;

	self.isReady = true;
}