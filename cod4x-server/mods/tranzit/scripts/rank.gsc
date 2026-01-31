#include scripts\_include;

init()
{
	initRank(0, 0, 0);
	initRank(1, 10, 4);
	initRank(2, 20, 4);
	initRank(3, 30, 4);
	initRank(4, 40, 4);
	
	precacheStatusIcon("hud_chalk_1");
	precacheStatusIcon("hud_chalk_2");
	precacheStatusIcon("hud_chalk_3");
	precacheStatusIcon("hud_chalk_4");
	precacheStatusIcon("hud_chalk_5");
}

initRank(rankId, rankUpRoundGoal, rankUpnoDownGames)
{
	if(!isDefined(game["tranzit"].playerRank))
		game["tranzit"].playerRank = [];

	game["tranzit"].playerRank[rankId] = spawnStruct();
	game["tranzit"].playerRank[rankId].rankUpRounds = rankUpRoundGoal;
	game["tranzit"].playerRank[rankId].rankUpNoDowns = rankUpnoDownGames;
}

calcPlayerRank()
{
	self endon("disconnect");
	
	if(isDefined(self.pers["isBot"]) && !self.pers["isBot"])
		return;
	
	currentDate = createDateArray(TimeToString(getRealTime(), 0, "%Y-%m-%d"), "-");
	playerOfflineDays = self getOfflineDays(currentDate);
	playerTallyMarks = self getZombieRankTallyMarks(playerOfflineDays);
	playerZombieRank = self getZombieRank(playerOfflineDays);
	playerIsAddicted = false;
	
	if(playerTallyMarks >= 5)
		playerIsAddicted = true;
	
	if(playerTallyMarks > 0)
		self.statusIcon = "hud_icon_zombietallymarks_" + playerTallyMarks;
	
	self.zombieRank = playerZombieRank;
	self.zombieRankCounts = self getStat(2443);
	
	if(game["debug"]["status"] && game["debug"]["playerRank"])
	{
		consolePrint("currentDate: " + TimeToString(getRealTime(), 0, "%Y-%m-%d") + "\n");
		consolePrint("player: " + self.name + "\n");
		consolePrint("playerOfflineDays: " + playerOfflineDays + "\n");
		consolePrint("playerTallyMarks: " + playerTallyMarks + "\n");
		consolePrint("playerZombieRank: " + playerZombieRank + "\n");
		consolePrint("playerIsAddicted: " + playerIsAddicted + "\n");
	}
	
	self setRank(playerZombieRank, playerIsAddicted);
	self setStat(2440, playerZombieRank);
	self setStat(2442, playerTallyMarks);
	self setStat(2326, playerIsAddicted);
	
	self updateLastSeenValue(currentDate);
}

updateLastSeenValue(date)
{
	if(isDefined(date))
		self setStat(2441, int(date[0] + "" + date[1] + "" + date[2]));
}

getZombieRank(playerOfflineDays)
{
	playerRank = self getStat(2440);
		
	if(playerRank > 0 && playerOfflineDays > 0)
	{
		rankLoss = 0;
		if(playerOfflineDays > 7 && playerOfflineDays <= 14)
			rankLoss = 1;
		else if(playerOfflineDays > 14 && playerOfflineDays <= 21)
			rankLoss = 2;
		else if(playerOfflineDays > 21 && playerOfflineDays <= 28)
			rankLoss = 3;
		else if(playerOfflineDays > 28)
			rankLoss = 4;

		playerRank -= rankLoss;
		
		if(playerRank < 0)
			playerRank = 0;
	}

	return playerRank;
}

getZombieRankTallyMarks(playerOfflineDays)
{
	playerTallyMarks = self getStat(2442);
	
	//player is still playing - or playing at the same day
	if(playerOfflineDays <= 0)
	{
		//do nothing
	}
	//player took a break
	else
	{
		//a day only - increase tally marks
		if(playerOfflineDays == 1)
			playerTallyMarks++;
		//more than a day - remove the tally marks
		else
			playerTallyMarks = 0;
	}
	
	if(playerTallyMarks > 5)
		playerTallyMarks = 5;

	return playerTallyMarks;
}

getOfflineDays(currentDate)
{
	if(!isDefined(currentDate))
		return 0;

	playerlastSeen = self getStat(2441);

	if(playerlastSeen <= 0)
		playerlastSeen = currentDate;
	else
		playerlastSeen = createDateArray("" + playerlastSeen);
	
	playerOfflineDays = dateDiffInDays(currentDate, playerlastSeen);
	
	return playerOfflineDays;
}

rankUpPlayer()
{
	//self iPrintLnBold("rank up!");

	maxRank = int(tableLookup("mp/rankTable.csv", 0, "maxrank", 1));
	currentRank = self getStat(2440);
	
	if(currentRank == maxRank)
		return;
	
	playerZombieRank = currentRank + 1;
	playerTallyMarks = self getStat(2442);
	playerIsAddicted = false;
	
	if(playerTallyMarks >= 5)
		playerIsAddicted = true;
	
	self setRank(playerZombieRank, playerIsAddicted);
	self setStat(2440, playerZombieRank);
	self setStat(2326, playerIsAddicted);
	self setRankCounts(0);
}

setRankCounts(value)
{
	//self iPrintLnBold("self.zombieRankCounts reset!");

	self.zombieRankCounts = value;
	
	self setStat(2443, value);
}

increaseRankCounts()
{
	//self iPrintLnBold("self.zombieRankCounts increased");

	self.zombieRankCounts++;
	
	self setStat(2443, self.zombieRankCounts);
}

checkForPlayerRankups()
{
	//iPrintLnBold("check for rank ups");

	rankUpRound = false;
	curRankToIncrease = undefined;
	for(i=0;i<game["tranzit"].playerRank.size;i++)
	{
		if(game["tranzit"].wave == game["tranzit"].playerRank[i].rankUpRounds)
		{
			rankUpRound = true;
			curRankToIncrease = (i - 1);
			break;
		}
	}

	if(!rankUpRound || !isDefined(curRankToIncrease))
	{
		//iPrintLnBold("check aborted");
		return;
	}

	for(i=0;i<level.players.size;i++)
	{
		if(!level.players[i] isASurvivor())
		{
			//level.players[i] iPrintLnBold("you are not a survivor");
			continue;
		}
			
		if(level.players[i].zombieRank != curRankToIncrease)
		{
			//level.players[i] iPrintLnBold("your rank does not match the wave: " + level.players[i].zombieRank + " / " + curRankToIncrease);
			continue;
		}
			
		if(level.players[i].pers["downs"] > 0)
		{
			//level.players[i] iPrintLnBold("you can not rank up, you already died");
			continue;
		}
			
		level.players[i] increaseRankCounts();
		
		if(level.players[i].zombieRankCounts >= game["tranzit"].playerRank[curRankToIncrease +1].rankUpNoDowns)
			level.players[i] rankUpPlayer();
	}
}