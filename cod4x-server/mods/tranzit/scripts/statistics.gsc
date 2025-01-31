#include scripts\_include;

init()
{
	game["tranzit"].statistics = [];

	initStatInfo("parts_found", 2410, 0);
	initStatInfo("items_crafted", 2411, 0);
	initStatInfo("drunken_beers", 2412, 0);
	initStatInfo("misteryboxes_used", 2413, 0);
	initStatInfo("misteryboxes_lost", 2414, 0);
	initStatInfo("money_gained", 2415, 0);
	initStatInfo("money_wasted", 2416, 0);
	initStatInfo("zombies_killed", 2417, 0);
	initStatInfo("screechers_killed", 2418, 0);
	initStatInfo("bullets_fired", 2419, 0);
}

initStatInfo(name, stat, defaultValue)
{
	entryNo = game["tranzit"].statistics.size;
	game["tranzit"].statistics[entryNo] = spawnStruct();
	game["tranzit"].statistics[entryNo].name = name;
	game["tranzit"].statistics[entryNo].stat = stat;
	game["tranzit"].statistics[entryNo].value = defaultValue;
}

getStatisticValue(name, stat)
{
	if(!isDefined(name) && !isDefined(stat))
		return 0;

	for(i=0;i<game["tranzit"].statistics.size;i++)
	{
		if((isDefined(name) && name == game["tranzit"].statistics[i].name) || (isDefined(stat) && stat == game["tranzit"].statistics[i].stat))
			return game["tranzit"].statistics[i].value;
	}
	
	return 0;
}

incStatisticValue(name, stat, inc)
{
	if(!isDefined(name) && !isDefined(stat))
		return;

	if(!isDefined(inc))
		return;

	for(i=0;i<game["tranzit"].statistics.size;i++)
	{
		if((isDefined(name) && name == game["tranzit"].statistics[i].name) || (isDefined(stat) && stat == game["tranzit"].statistics[i].stat))
		{
			game["tranzit"].statistics[i].value += inc;
			thread setStatForAllPlayers(game["tranzit"].statistics[i].name, game["tranzit"].statistics[i].stat, game["tranzit"].statistics[i].value);
			break;
		}
	}
}

setStatForAllPlayers(name, stat, value)
{
	if(!isDefined(name) && !isDefined(stat))
		return;
		
	if(!isDefined(value))
		return;
	
	value = int(value);
	
	//update the current stored value
	for(i=0;i<game["tranzit"].statistics.size;i++)
	{
		if((isDefined(name) && name == game["tranzit"].statistics[i].name) || (isDefined(stat) && stat == game["tranzit"].statistics[i].stat))
		{
			game["tranzit"].statistics[i].value = value;
			stat = game["tranzit"].statistics[i].stat;
			break;
		}
	}

	for(i=0;i<level.players.size;i++)
	{
		if(!level.players[i] isASurvivor())
			continue;
	
		level.players[i] setStat(stat, value);
	}
}

receiveStatistics()
{
	self endon("disconnect");

	for(i=0;i<game["tranzit"].statistics.size;i++)
		self setStat(game["tranzit"].statistics[i].stat, game["tranzit"].statistics[i].value);
}