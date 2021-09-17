#include common_scripts\utility;
#include maps\mp\_utility;

#include scripts\_include;

/*----------------------------------------
I moved all necessary functions from the
spawnlogic.gsc into this gsc.
This will make it easier to apply changes
----------------------------------------*/
init()
{
	// start keeping track of deaths
	level.spawnlogic_deaths = [];
	
	// DEBUG
	level.spawnlogic_spawnkills = [];
	level.players = [];
	level.grenades = [];
	level.pipebombs = [];

	thread trackGrenades();
}

initCharacterSpawns()
{
	if(!isDefined(level.teamSpawnPoints))
	{
		level.teamSpawnPoints = [];
		level.teamSpawnPoints["axis"] = [];
		level.teamSpawnPoints["allies"] = [];
	}

	addSpawnPoints(game["attackers"]);
	addSpawnPoints(game["defenders"]);
	
	updateAvailableTeamSpawns();
}

//who knows if we ever need this
trackGrenades()
{
	while(1)
	{
		level.grenades = getentarray("grenade", "classname");
		wait .05;
	}
}

/*----------------------------------------
	calc & other subfunctions
----------------------------------------*/
findBoxCenter( mins, maxs )
{
	center = ( 0, 0, 0 );
	center = maxs - mins;
	center = ( center[0]/2, center[1]/2, center[2]/2 ) + mins;
	return center;
}

expandMins( mins, point )
{
	if ( mins[0] > point[0] )
		mins = ( point[0], mins[1], mins[2] );
	if ( mins[1] > point[1] )
		mins = ( mins[0], point[1], mins[2] );
	if ( mins[2] > point[2] )
		mins = ( mins[0], mins[1], point[2] );
	return mins;
}

expandMaxs( maxs, point )
{
	if ( maxs[0] < point[0] )
		maxs = ( point[0], maxs[1], maxs[2] );
	if ( maxs[1] < point[1] )
		maxs = ( maxs[0], point[1], maxs[2] );
	if ( maxs[2] < point[2] )
		maxs = ( maxs[0], maxs[1], point[2] );
	return maxs;
}

avoidSameSpawn(spawnpoints)
{
	prof_begin(" spawn_samespwn");

	if(!isDefined(self.lastspawnpoint))
		return;
	
	for(i=0;i<spawnpoints.size;i++)
	{
		if(spawnpoints[i] == self.lastspawnpoint) 
		{
			spawnpoints[i].weight -= 50000; // (half as bad as a likely spawn kill)
			break;
		}
	}
	
	prof_end(" spawn_samespwn");
}

avoidSpawnReuse(spawnpoints, teambased)
{
	prof_begin(" spawn_reuse");

	time = getTime();
	maxtime = 10*1000;
	maxdistSq = 800 * 800;

	for(i=0;i<spawnpoints.size;i++)
	{
		if(!isDefined(spawnpoints[i].lastspawnedplayer) || !isDefined(spawnpoints[i].lastspawntime) || !isalive(spawnpoints[i].lastspawnedplayer))
			continue;

		if(spawnpoints[i].lastspawnedplayer == self) 
			continue;
		
		if(teambased && spawnpoints[i].lastspawnedplayer.pers["team"] == self.pers["team"]) 
			continue;
		
		timepassed = time - spawnpoints[i].lastspawntime;
		if(timepassed >= maxtime)
			spawnpoints[i].lastspawnedplayer = undefined; // don't worry any more about this spawnpoint
		else
		{
			distSq = distanceSquared(spawnpoints[i].lastspawnedplayer.origin, spawnpoints[i].origin);
			if(distSq >= maxdistSq)
				spawnpoints[i].lastspawnedplayer = undefined; // don't worry any more about this spawnpoint
			else
			{
				worsen = 1000 * (1 - distSq/maxdistSq) * (1 - timepassed/maxtime);
				spawnpoints[i].weight -= worsen;
			}
		}
	}

	prof_end(" spawn_reuse");
}

getBestWeightedSpawnpoint(spawnpoints)
{
	maxSightTracedSpawnpoints = 3;
	for(try=0;try<=maxSightTracedSpawnpoints;try++)
	{
		bestspawnpoints = [];
		bestweight = undefined;
		bestspawnpoint = undefined;
		for(i=0;i<spawnpoints.size;i++)
		{
			if(!isDefined(bestweight) || spawnpoints[i].weight > bestweight) 
			{
				if(positionWouldTelefrag(spawnpoints[i].origin))
					continue;
				
				bestspawnpoints = [];
				bestspawnpoints[0] = spawnpoints[i];
				bestweight = spawnpoints[i].weight;
			}
			else if(spawnpoints[i].weight == bestweight) 
			{
				if(positionWouldTelefrag(spawnpoints[i].origin))
					continue;
				
				bestspawnpoints[bestspawnpoints.size] = spawnpoints[i];
			}
		}
		
		if(bestspawnpoints.size <= 0)
			return undefined;
		
		// pick randomly from the available spawnpoints with the best weight
		bestspawnpoint = bestspawnpoints[randomint( bestspawnpoints.size )];
		
		if(try == maxSightTracedSpawnpoints)
			return bestspawnpoint;
		
		if(isDefined(bestspawnpoint.lastSightTraceTime) && bestspawnpoint.lastSightTraceTime == gettime())
			return bestspawnpoint;
		
		if(!lastMinuteSightTraces(bestspawnpoint))
			return bestspawnpoint;
		
		penalty = getLosPenalty();
		bestspawnpoint.weight -= penalty;
		bestspawnpoint.lastSightTraceTime = gettime();
	}
}

getAllAlliedAndEnemyPlayers()
{
	obj = spawnstruct();
	if(level.teambased)
	{
		if(self.pers["team"] == "allies")
		{
			obj.allies = level.alivePlayers["allies"];
			obj.enemies = level.alivePlayers["axis"];
		}
		else
		{
			assert( self.pers["team"] == "axis" );
			obj.allies = level.alivePlayers["axis"];
			obj.enemies = level.alivePlayers["allies"];
		}
	}
	else
	{
		obj.allies = [];
		obj.enemies = level.activePlayers;
	}
	
	return obj;
}

getAllOtherPlayers()
{
	aliveplayers = [];

	// Make a list of fully connected, non-spectating, alive players
	for(i=0;i<level.players.size;i++)
	{
		if(!isDefined(level.players[i]))
			continue;
		player = level.players[i];
		
		if(player.sessionstate != "playing" || player == self)
			continue;

		aliveplayers[aliveplayers.size] = player;
	}

	return aliveplayers;
}

getAllEnemyPlayers(team)
{
	aliveplayers = [];

	// Make a list of fully connected, non-spectating, alive players
	for(i=0;i<level.players.size;i++)
	{
		if(!isDefined(level.players[i]))
			continue;
		player = level.players[i];
		
		if(player.sessionstate != "playing" || player == self)
			continue;
			
		if(player.pers["team"] == self.pers["team"])
			continue;

		aliveplayers[aliveplayers.size] = player;
	}

	return aliveplayers;
}

getLosPenalty()
{
	return 100000;
}

lastMinuteSightTraces(spawnpoint)
{
	prof_begin(" spawn_lastminutesc");
	
	team = "all";
	if(level.teambased)
		team = getOtherTeam(self.pers["team"]);
	
	if(!isDefined(spawnpoint.nearbyPlayers))
		return false;
	
	closest = undefined;
	closestDistsq = undefined;
	secondClosest = undefined;
	secondClosestDistsq = undefined;
	for(i=0;i<spawnpoint.nearbyPlayers[team].size;i++)
	{
		player = spawnpoint.nearbyPlayers[team][i];
		
		if(!isDefined(player))
			continue;
		if(player.sessionstate != "playing")
			continue;
		if(player == self)
			continue;
		
		distsq = distanceSquared(spawnpoint.origin, player.origin);
		if(!isDefined(closest) || distsq < closestDistsq)
		{
			secondClosest = closest;
			secondClosestDistsq = closestDistsq;
			
			closest = player;
			closestDistSq = distsq;
		}
		else if(!isDefined(secondClosest) || distsq < secondClosestDistSq)
		{
			secondClosest = player;
			secondClosestDistSq = distsq;
		}
	}
	
	if(isDefined(closest))
	{
		if(bullettracepassed(closest.origin + (0,0,50), spawnpoint.sightTracePoint, false, undefined))
			return true;
	}
	
	if(isDefined(secondClosest))
	{
		if(bullettracepassed(secondClosest.origin + (0,0,50), spawnpoint.sightTracePoint, false, undefined) )
			return true;
	}
	
	return false;
}

/*----------------------------------------
	import, init and add spawns
----------------------------------------*/
addSpawnPoints(team)
{
	oldSpawnPoints = [];
	if(level.teamSpawnPoints[team].size)
		oldSpawnPoints = level.teamSpawnPoints[team];
	
	fileName =  "waypoints/"+ toLower(getDvar("mapname")) + "_spawns.csv";
	fileNameLua = getDvar( "fs_game" ) + "/" + fileName;
	
	level.teamSpawnPoints[team] = importTeamSpawns(team, fileNameLua);
	
	if(!isDefined(level.teamSpawnPoints[team]) || level.teamSpawnPoints[team].size <= 0)
	{
		consolePrint("^1No ^3'" + team + "'^1 spawns found - falling back to default spawn search!\n");
	
		if(team == game["attackers"])
			spawnPointName = "mp_dm_spawn";
		else
			spawnPointName = "mp_tdm_spawn";
	
		level.teamSpawnPoints[team] = getEntArray(spawnPointName, "classname");
		
		if(!isDefined(level.teamSpawnPoints[team]) || level.teamSpawnPoints[team].size <= 0)
		{
			consolePrint("^1No " + spawnPointName + " spawnpoints found in level!");
			maps\mp\gametypes\_callbacksetup::AbortLevel();
			wait 1; // so we don't try to abort more than once before the frame ends
			return;
		}
	}
	else
	{	
		for(i=0;i<level.teamSpawnPoints[team].size;i++)
		{
			tokens = strToK(level.teamSpawnPoints[team][i], ",");	
			origin = strToK(tokens[0], " ");
			origin = (float(origin[0]), float(origin[1]), float(origin[2]));
			scriptedGroup = tokens[1];
			maparea = int(tokens[2]);
			
			level.teamSpawnPoints[team][i] = SpawnStruct();
			level.teamSpawnPoints[team][i].origin = origin;
			level.teamSpawnPoints[team][i].angles = (0,0,0);
			level.teamSpawnPoints[team][i].targetname = scriptedGroup;
			level.teamSpawnPoints[team][i].area = maparea;
			level.teamSpawnPoints[team][i].team = team;
		}
	}
	
	if(!isDefined(level.spawnpoints))
		level.spawnpoints = [];
	
	for(i=0;i<level.teamSpawnPoints[team].size;i++)
	{
		spawnpoint = level.teamSpawnPoints[team][i];
		
		if(!isDefined(spawnpoint.inited))
		{
			spawnpoint spawnPointInit();
			level.spawnpoints[level.spawnpoints.size] = spawnpoint;
		}
	}
	
	for(i=0;i<oldSpawnPoints.size;i++)
	{
		origin = oldSpawnPoints[i].origin;
		
		// are these 2 lines necessary? we already did it in spawnPointInit
		level.spawnMins = expandMins(level.spawnMins, origin);
		level.spawnMaxs = expandMaxs(level.spawnMaxs, origin);
		
		level.teamSpawnPoints[team][level.teamSpawnPoints[team].size] = oldSpawnPoints[i];
	}
	
	consolePrint("Imported " + level.teamSpawnPoints[team].size + " " + team + " spawns\n");
}

spawnPointInit()
{
	spawnpoint = self;
	
	level.spawnMins = expandMins(level.spawnMins, spawnpoint.origin);
	level.spawnMaxs = expandMaxs(level.spawnMaxs, spawnpoint.origin);
	
	if(isEntity(spawnpoint))
	{
		spawnpoint placeSpawnpoint();
		spawnpoint.area = 0;
	}
	else
	{
		spawnpoint.origin = PlayerPhysicsTrace(spawnpoint.origin + (0,0,10), spawnpoint.origin - (0,0,2000));
		//spawnpoint.area = 0;
	}
	
	spawnpoint.forward = anglesToForward(spawnpoint.angles);
	spawnpoint.sightTracePoint = spawnpoint.origin + (0,0,50);
	
	spawnpoint.numPlayersAtLastUpdate = 0;
	spawnpoint.inited = true;
	spawnpoint.active = true;
	
	if(isDefined(spawnPoint.targetname) && isSubStr(spawnpoint.targetname, "scripted"))
		spawnpoint.active = false;
}

//disable spawns in blocked areas until the area is opened - like the bunker tunnel at mp_forsaken_world
toggleSpawnGroup(groupName, newStatus)
{
	self notify("toggleSpawnGroup");
	self endon("toggleSpawnGroup");

	for(i=0;i<level.spawnpoints.size;i++)
	{
		if(isSubStr(level.spawnpoints[i].targetname, groupName))
		{
			if(!isDefined(newStatus))
				level.spawnpoints[i].active = !level.spawnpoints[i].active;
			else
			{
				if(level.spawnpoints[i].active != newStatus)
					level.spawnpoints[i].active = newStatus;
			}
		}
	}
	
	thread updateAvailableTeamSpawns();
}

updateAvailableTeamSpawns()
{
	self notify("updateAvailableTeamSpawns");
	self endon("updateAvailableTeamSpawns");

	zombieSpawns = [];
	survivorSpawns = [];
	for(i=0;i<level.spawnpoints.size;i++)
	{
		if(!isDefined(level.spawnpoints[i].team))
			continue;
			
		if(!isDefined(level.spawnpoints[i].active))
			continue;
	
		if(level.spawnpoints[i].active)
		{
			if(level.spawnpoints[i].team == game["attackers"])
				zombieSpawns[zombieSpawns.size] = level.spawnpoints[i];
			else if(level.spawnpoints[i].team == game["defenders"])
				survivorSpawns[survivorSpawns.size] = level.spawnpoints[i];
		}
	}

	level.teamSpawnPoints[game["attackers"]] = zombieSpawns;
	level.teamSpawnPoints[game["defenders"]] = survivorSpawns;
}

/*----------------------------------------
	find spawns
----------------------------------------*/
getTeamSpawnPoints(team)
{
	return level.teamSpawnPoints[team];
}

//spawn in a random spawn
getSpawnpoint_Random(spawnpoints)
{
	//There are no valid spawnpoints in the map
	if(!isdefined(spawnpoints))
		return undefined;

	//randomize order
	for(i=0;i<spawnpoints.size;i++)
	{
		j = randomInt(spawnpoints.size);
		spawnpoint = spawnpoints[i];
		spawnpoints[i] = spawnpoints[j];
		spawnpoints[j] = spawnpoint;
	}
	
	return getSpawnpoint_Final(spawnpoints, false);
}

//spawn zombies close to any player
getSpawnpoint_Zombies(spawnpoints)
{
	//There are no valid spawnpoints in the map
	if(!isDefined(spawnpoints))
		return undefined;
	
	for(i=0;i<spawnpoints.size;i++)
		spawnpoints[i].weight = 0;
	
	minDist = 90;
	maxDist = 800;

	//aliveplayers = getAllOtherPlayers();
	aliveplayers = getAllEnemyPlayers();
	
	possibleSpawns = [];
	if(aliveplayers.size > 0)
	{
		for(i=0;i<spawnpoints.size;i++)
		{
			useableSpawn = false;
		
			for(j=0;j<aliveplayers.size;j++)
			{
				dist = distance(spawnpoints[i].origin, aliveplayers[j].origin);
				
				//never spawn next to a player
				if(dist < minDist)
					break;

				//do not use this spawn when it's far away from ALL players
				if(dist > maxDist)
					continue;

				//great - this spawn is in range of at least one player
				useableSpawn = true;
			}
			
			if(useableSpawn)
			{
				//randomize the weight to make sure not all dead zombies spawn at the same spot
				spawnpoints[i].weight = randomIntRange(1,100);
				
				possibleSpawns[possibleSpawns.size] = spawnpoints[i];
			}
		}
	}
	
	if(possibleSpawns.size <= 0)
		return undefined;

	spawnpoints = possibleSpawns;
	
	return getSpawnpoint_Final(spawnpoints);
}

//respawn a dead player close to an other player (good for screecher)
getSpawnpoint_NearPos(spawnpoints, pos)
{
	// There are no valid spawnpoints in the map
	if(!isDefined(spawnpoints))
		return undefined;
	
	prof_begin("basic_spawnlogic");	
	prof_begin(" getteams");
	prof_end(" getteams");	
	
	prof_begin(" sumdists");
	prof_end(" sumdists");	
	
	prof_end("basic_spawnlogic");

	prof_begin("complex_spawnlogic");	
	prof_end("complex_spawnlogic");

	spawnpoint = getClosest(pos, spawnpoints);
	
	if(isDefined(spawnpoint))
		return spawnpoint;
	
	return undefined;
}

//respawn a dead player close to his squad
getSpawnpoint_NearTeam(spawnpoints, spawnAtTeam)
{
	// There are no valid spawnpoints in the map
	if(!isDefined(spawnpoints))
		return undefined;

	prof_begin("basic_spawnlogic");
	prof_begin(" getteams");

	if(!isDefined(spawnAtTeam))
		spawnAtTeam = self.pers["team"];
	
	myTeam = spawnAtTeam;
	enemyTeam = getOtherTeam(myTeam);

	prof_end(" getteams");

	combatAreas = [];
	for(i=0;i<level.alivePlayers[myTeam].size;i++)
	{
		if(isDefined(level.alivePlayers[myTeam][i].myAreaLocation) && level.alivePlayers[myTeam][i].myAreaLocation != 999)
			combatAreas[combatAreas.size] = level.alivePlayers[myTeam][i].myAreaLocation;
	}
	
	spawnArea = undefined;
	if(combatAreas.size > 0)
		spawnArea = combatAreas[randomInt(combatAreas.size)];
	else
	{
		if(myTeam == game["defenders"])
			spawnArea = 1;
		else
		{	
			// There are no valid spawnpoints in the map
			if(!isDefined(spawnpoints))
				return undefined;
			
			spawnPoints = level.teamSpawnPoints[enemyTeam];			
			return getSpawnpoint_Zombies(spawnPoints);
		}
	}
		
	prof_begin(" sumdists");

	tempSpawns = [];
	for(i=0;i<spawnpoints.size;i++)
	{
		spawnpoints[i].weight = 0;

		if(!isDefined(spawnpoints[i].numPlayersAtLastUpdate))
			spawnpoints[i].numPlayersAtLastUpdate = 0;
		
		if(!isDefined(spawnpoints[i].area) || spawnpoints[i].area != spawnArea)
			continue;
			
		tempSpawns[tempSpawns.size] = spawnpoints[i];
	}
	
	if(tempSpawns.size > 0)
		spawnpoints = tempSpawns;

	for(i=0;i<spawnpoints.size;i++)
	{
		if(spawnpoints[i].numPlayersAtLastUpdate == 0)
			spawnpoints[i].weight = 0;
		else
		{
			alliedDistanceWeight = 2;
			allyDistSum = spawnpoints[i].distSum[myTeam];
			enemyDistSum = spawnpoints[i].distSum[enemyTeam];
			
			//high enemy distance is good, hight friendly distance is bad
			spawnpoints[i].weight = (enemyDistSum - alliedDistanceWeight*allyDistSum) / spawnpoints[i].numPlayersAtLastUpdate;
		}
	}
	
	prof_end(" sumdists");
	prof_end("basic_spawnlogic");

	prof_begin("complex_spawnlogic");
	
	avoidSameSpawn(spawnpoints);
	avoidSpawnReuse(spawnpoints, true);
	
	prof_end("complex_spawnlogic");
	
	return getSpawnpoint_Final(spawnpoints);
}

// selects a spawnpoint, preferring ones with heigher weights (or toward the beginning of the array if no weights).
// also does final things like setting self.lastspawnpoint to the one chosen.
// this takes care of avoiding telefragging, so it doesn't have to be considered by any other function.
getSpawnpoint_Final(spawnpoints, useweights)
{
	prof_begin( " spawn_final" );
	
	bestspawnpoint = undefined;
	
	if(!isDefined(spawnpoints) || spawnpoints.size <= 0)
		return undefined;
	
	if(!isDefined(useweights))
		useweights = true;
	
	if(useweights)
	{
		//choose spawnpoint with best weight
		//(if a tie, choose randomly from the best)
		bestspawnpoint = getBestWeightedSpawnpoint(spawnpoints);
	}
	else
	{
		//no weights. prefer spawnpoints toward beginning of array
		for(i=0;i<spawnpoints.size;i++)
		{
			if(isDefined(self.lastspawnpoint) && self.lastspawnpoint == spawnpoints[i])
				continue;
			
			if(positionWouldTelefrag(spawnpoints[i].origin))
				continue;
			
			bestspawnpoint = spawnpoints[i];
			break;
		}
		
		if(!isDefined(bestspawnpoint))
		{
			//Couldn't find a useable spawnpoint. All spawnpoints either telefragged or were our last spawnpoint
			//Our only hope is our last spawnpoint - unless it too will telefrag...
			if(isDefined(self.lastspawnpoint) && !positionWouldTelefrag(self.lastspawnpoint.origin))
			{
				//(make sure our last spawnpoint is in the valid array of spawnpoints to use)
				for(i=0;i<spawnpoints.size;i++)
				{
					if(spawnpoints[i] == self.lastspawnpoint)
					{
						bestspawnpoint = spawnpoints[i];
						break;
					}
				}
			}
		}
	}
	
	if(!isDefined(bestspawnpoint))
	{
		//couldn't find a useable spawnpoint! all will telefrag.
		if(!useweights)
			bestspawnpoint = spawnpoints[0];
		else
		{
			// at this point, forget about weights. just take a random one.
			bestspawnpoint = spawnpoints[randomint(spawnpoints.size)];
		}
	}
	
	time = getTime();
	
	self.lastspawnpoint = bestspawnpoint;
	self.lastspawntime = time;
	bestspawnpoint.lastspawnedplayer = self;
	bestspawnpoint.lastspawntime = time;
	
	prof_end( " spawn_final" );

	return bestspawnpoint;
}

/*----------------------------------------
	monitor spawns and update their values
----------------------------------------*/
/*----------------------------------------
BACKLOT:
- 18 mp_dm_spawn
- 18 mp_tdm_spawn
- 8 mp_tdm_spawn_axis_start
- 12 mp_tdm_spawn_allies_start
--> 56
--> spawns * waitStep = loopTime
--> 56 * 0.05 = 2.8 seconds

FORSAKEN_WORLD:
(values might change during development)
- 683 mp_dm_spawn
- 18 mp_tdm_spawn
--> 701
--> spawns * waitStep = loopTime
--> 701 * 0.05 = 35.05 seconds

RESULT: we have to speed up the loop
----------------------------------------*/
spawnPerFrameUpdate()
{
	spawnpointindex = 0;	
	while(1)
	{
		//wait .05;
		//with the subloop to speed up the main loop we can use a higher wait
		wait 3;
		
		prof_begin("spawn_sight_checks");
		
		if(!isDefined(level.spawnPoints))
			return;
		
		//spawnpointindex = (spawnpointindex + 1) % level.spawnPoints.size;
		for(spawnpointindex = 0; spawnpointindex < level.spawnPoints.size; spawnpointindex++) //subloop to speed up the main loop
		{
			spawnpoint = level.spawnPoints[spawnpointindex];
			
			if(level.teambased)
			{
				spawnpoint.sights["axis"] = 0;
				spawnpoint.sights["allies"] = 0;
				
				spawnpoint.nearbyPlayers["axis"] = [];
				spawnpoint.nearbyPlayers["allies"] = [];
			}
			else
			{
				spawnpoint.sights = 0;
				spawnpoint.nearbyPlayers["all"] = [];
			}
			
			spawnpoint.distSum["all"] = 0;
			spawnpoint.distSum["allies"] = 0;
			spawnpoint.distSum["axis"] = 0;
			
			spawnpointdir = spawnpoint.forward;		
			spawnpoint.numPlayersAtLastUpdate = 0;
			
			for(i=0;i<level.players.size;i++)
			{
				player = level.players[i];
				
				if(player.sessionstate != "playing")
					continue;
				
				diff = player.origin - spawnpoint.origin;
				dist = length( diff ); // needs to be actual distance for distSum value
				
				team = "all";
				if(level.teambased)
					team = player.pers["team"];
				
				if(dist < 1024)
					spawnpoint.nearbyPlayers[team][spawnpoint.nearbyPlayers[team].size] = player;
				
				spawnpoint.distSum[team] += dist;
				spawnpoint.numPlayersAtLastUpdate++;
				
				pdir = anglestoforward(player.angles);
				if(vectordot(spawnpointdir, diff) < 0 && vectordot(pdir, diff) > 0)
					continue; // player and spawnpoint are looking in opposite directions
				
				//do sight check
				losExists = bullettracepassed(player.origin + (0,0,50), spawnpoint.sightTracePoint, false, undefined);
				
				spawnpoint.lastSightTraceTime = gettime();
				
				if(losExists)
				{
					if(level.teamBased)
						spawnpoint.sights[player.pers["team"]]++;
					else
						spawnpoint.sights++;
				}
			}
		}//subloop
		
		prof_end("spawn_sight_checks");
	}
}

/*----------------------------------------
			spawn the client
----------------------------------------*/
spawnPlayer(zombieType, zomTarget)
{
	prof_begin( "spawnPlayer_preUTS" );

	self endon("disconnect");
	self endon("joined_spectators");
	self notify("spawned");
	self notify("end_respawn");

	self maps\mp\gametypes\_globallogic::setSpawnVariables();
	self clearLowerHintMessage();

	self.sessionteam = self.team;
	hadSpawned = self.hasSpawned;

	self.sessionstate = "playing";
	self.spectatorclient = -1;
	self.killcamentity = -1;
	self.archivetime = 0;
	self.psoffsettime = 0;
	self.statusicon = "";
	self.friendlydamage = undefined;
	self.hasSpawned = true;
	self.spawnTime = getTime();
	self.afk = false;
	self.lastStand = undefined;

	if(self.pers["lives"])
		self.pers["lives"]--;
	
	self.canDoCombat = false;
	if(game["tranzit"].wave > 0)
		self.canDoCombat = true;

	if(!self.wasAliveAtMatchStart)
	{
		acceptablePassedTime = 20;
		if(level.timeLimit > 0 && acceptablePassedTime < level.timeLimit * 60 / 4)
			acceptablePassedTime = level.timeLimit * 60 / 4;
		
		if(level.inGracePeriod || maps\mp\gametypes\_globallogic::getTimePassed() < acceptablePassedTime * 1000)
			self.wasAliveAtMatchStart = true;
	}
	
	self thread doPlayerSpawning(zombieType, zomTarget);

	prof_end( "spawnPlayer_preUTS" );

	level thread maps\mp\gametypes\_globallogic::updateTeamStatus();
	
	prof_begin( "spawnPlayer_postUTS" );
	
	self freezeControls(false);
	self enableWeapons();
	
	//our first spawn - just in case we need to do sth
	if(!hadSpawned)
	{
		self thread scripts\introscreen::createIntroLines(); 
	}
	
	prof_end( "spawnPlayer_postUTS" );

	self deleteUseHintMessages();

	if(self isAZombie())
		self thread scripts\zombies::spawnZombie(zombieType, zomTarget);
	else if(self isASurvivor())
		self thread scripts\survivors::spawnSurvivor();
	
	waittillframeend;
	self notify( "spawned_player" );

	self logstring( "S " + self.origin[0] + " " + self.origin[1] + " " + self.origin[2] );

	if(game["state"] == "postgame")
	{
		assert( !level.intermission );
		// We're in the victory screen, but before intermission
		self maps\mp\gametypes\_globallogic::freezePlayerForRoundEnd();
	}
}

doPlayerSpawning(zombieType, zomTarget)
{
	spawnPoints = level.teamSpawnPoints[self.pers["team"]];
	assert(spawnPoints.size);
	
	if(self.pers["team"] == game["attackers"])
	{
		if(isDefined(zomTarget))
			spawnPoint = getSpawnpoint_NearPos(spawnPoints, zomTarget.origin);
		else
			spawnPoint = getSpawnpoint_Zombies(spawnPoints);
	}
	else
	{
		if(!game["tranzit"].playersReady || game["tranzit"].wave <= 1)
			spawnPoints = getEntArray("mp_tdm_spawn_allies_start", "classname");
	
		spawnPoint = getSpawnpoint_NearTeam(spawnPoints);
	}

	if(!isDefined(spawnPoint))
		return;

	self spawn(spawnpoint.origin, spawnpoint.angles);
	self.myAreaLocation = spawnPoint.area;

	level notify("spawned_player");
}

//this is used when the player was already playing but died
spawnClient(timeAlreadyPassed)
{
	assert(isDefined(self.team));
	assert(isDefined(self.class));
	
	//zombies are manually spawned in wave
	if(self isAZombie())
		return;
	
	if(self isASurvivor())
	{
		currentorigin =	self.origin;
		currentangles =	self.angles;
		
		setLowerHintMessage(game["strings"]["spawn_next_round"], 60);
		self thread	[[level.spawnSpectator]]( currentorigin	+ (0, 0, 60), currentangles	);
	}
	
	if(isDefined(self.waitingToRespawn) && self.waitingToRespawn)
		return;
	
	self.waitingToRespawn = true;
	self waitAndSpawnClient();

	if(isDefined(self))
		self.waitingToRespawn = false;
}

waitAndSpawnClient()
{
	self endon("disconnect");
	self endon("end_respawn");
	self endon("game_ended");

	if(self isASurvivor())
	{
		while(game["tranzit"].waveStarted)
			wait .05;
	}

	self.waitingToRespawn = false;
	self clearLowerHintMessage();
	
	self thread	[[level.spawnPlayer]]();
}