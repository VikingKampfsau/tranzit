#include maps\mp\_utility;
#include scripts\_include;

init()
{
	game["tranzit"].survivalStarted = false;

	game["tranzit"].wave = 0;
	game["tranzit"].waveStarted = false;
	game["tranzit"].specialWaveType = "";
	game["tranzit"].specialWaveCount = 0;
	game["tranzit"].nextSpecialWave = randomIntRange(5, 8);
	
	game["tranzit"].avagadroThisWave = false;
	game["tranzit"].avagadroWaveCount = 0;
	game["tranzit"].nextAvagadroWave = 999;
	
	game["tranzit"].playersReady = false;
	game["tranzit"].betweenRoundTime = 15;
	
	game["tranzit"].player_empty_hands = getWeaponFromCustomName("fists");
	game["tranzit"].player_start_weapon = "colt45_mp";
	game["tranzit"].player_amount_max = 4;
	
	game["tranzit"].zombie_spawn_delay = 1.8;
	game["tranzit"].zombie_health_increase = 100;
	game["tranzit"].zombie_health_increase_percent = 0.1;
	game["tranzit"].zombie_health_start = 100;
	game["tranzit"].zombie_max_ai = 24;
	game["tranzit"].zombie_ai_per_player = 6;

	game["tranzit"].avagadroReleased = false;
	game["tranzit"].avagadroIdleTime = 5.75;
	game["tranzit"].avagadroTeleportSpeed = 120;
	game["tranzit"].avagadroRangeDamage = 75;
	
	if(game["tranzit"].zombie_max_ai + game["tranzit"].player_amount_max > level.maxClients)
	{
		game["tranzit"].zombie_max_ai = (level.maxClients - game["tranzit"].player_amount_max);
		game["tranzit"].zombie_ai_per_player = int(game["tranzit"].zombie_max_ai / game["tranzit"].player_amount_max);
	}

	add_sound("start_of_game", "mx_splash_screen");
	add_sound("start_of_first_round", "mx_wave_1");
	add_sound("start_of_round", "round_start");
	add_sound("end_of_round", "round_over");
	add_sound("end_of_game", "mx_game_over");

	
	PrecacheShader("hud_chalk_1");
	PrecacheShader("hud_chalk_2");
	PrecacheShader("hud_chalk_3");
	PrecacheShader("hud_chalk_4");
	PrecacheShader("hud_chalk_5");
	
	level.chalk_hud1 = createWaveHud();
	level.chalk_hud2 = createWaveHud(64);
	
	level.maxAfkWaves = 3;
	
	level.dwarfsLeft = 0;
	level.zombiesSpawned = 0;
	level.zombie_health = game["tranzit"].zombie_health_start;
	
	//wait until the navmesh is read and the waypoints created
	for(i=0;i<30;i++)
	{
		wait 1;
		
		if(isDefined(level.wpAmount) && level.wpAmount > 0)
		{
			thread prepareWave();
			break;
		}
	}

	iPrintLnBold(getLocTextString("ERROR_MAP_NOT_WAYPOINTED"));
}

prepareWave()
{
	level endon("game_ended");

	if(game["tranzit"].wave > 0)
	{
		if(game["tranzit"].wave == game["tranzit"].nextSpecialWave)
		{
			game["tranzit"].nextSpecialWave = game["tranzit"].wave + randomIntRange(5, 8);
			game["tranzit"].specialWaveType = getRandomSpecialWave();
			game["tranzit"].specialWaveCount++;
		}
	
		game["tranzit"].avagadroThisWave = false;
		if(game["tranzit"].wave == game["tranzit"].nextAvagadroWave || (game["tranzit"].avagadroWaveCount <= 0 && game["tranzit"].powerEnabled))
		{
			game["tranzit"].nextAvagadroWave = game["tranzit"].wave + randomIntRange(4, 10);
			game["tranzit"].avagadroThisWave = true; 
			game["tranzit"].avagadroWaveCount++;
		}

		wait game["tranzit"].betweenRoundTime;
		
		if(game["tranzit"].specialWaveType == "dogs")
		{
			playSoundToAllPlayers("mx_dark_sting");
		
			wait 2;
		
			randomCallout = randomInt(10);
			randomSurvivor = getRandomPlayer(game["defenders"]);
			
			if(isDefined(randomSurvivor))
			{
				if(randomCallout == 0)
					randomSurvivor playSoundRef("dog_spawn");
				else if(randomCallout == 1)
					randomSurvivor playSoundRef("dog_killstreak");
				else if(randomCallout == 2)
					randomSurvivor playSoundRef("gen_incoming_dog");
			}
		}
		else
		{
			randomCallout = randomInt(10);
			randomSurvivor = getRandomPlayer(game["defenders"]);
			
			if(isDefined(randomSurvivor))
			{
				if(randomCallout == 0)
					randomSurvivor playSoundRef("gen_incoming");
				else if(randomCallout == 1)
					randomSurvivor playSoundRef("gen_incoming_zomb");
				else if(randomCallout == 2)
					randomSurvivor playSoundRef("gen_laugh");
			}
		}
	}
	else
	{
		thread scripts\readyup::waitForPlayerStartPermission();

		while(!game["tranzit"].playersReady)
			wait .5;
			
		wait game["tranzit"].betweenRoundTime / 5;
		playSoundToAllPlayers("start_of_game");
		wait game["tranzit"].betweenRoundTime / 3;
		
		if(level.playerCount["allies"] > 1)
		{
			randomSurvivor = getRandomPlayer(game["defenders"]);
			randomSurvivor playSoundRef("gen_teamwork");
		}
		
		logPrint("\nplayers ready - starting game\n");
	}
	
	game["tranzit"].wave++;	
	game["powerup_achieved"] = 0;

	chalk_one_up();
	thread zombieOutbreak();
	thread monitorHumanWipeOut();
	thread scripts\ambient::setAmbient("amb_spooky");
	thread scripts\rank::checkForPlayerRankups();
}

monitorHumanWipeOut()
{
	level endon("game_ended");
	
	if(isDefined(game["tranzit"].survivalStarted) && game["tranzit"].survivalStarted)
		return;
		
	game["tranzit"].survivalStarted = true;
	
	while(1)
	{
		if(level.aliveCount["allies"] <= 0)
		{
			logPrint("\ngame end from revive - all players are down\n");
			thread scripts\waves::endGame();
			return;
		}
		
		wait .5;
	}
}

getRandomSpecialWave()
{
	if(game["tranzit"].wave < 15)
		return "dogs";
	
	random = randomInt(100);
	if(random <= 75)
		return "dogs";
	else
		return "quads";
}

zombieOutbreak()
{
	level endon("game_ended");

	if(game["tranzit"].wave <= 1)
		level.zombie_health = game["tranzit"].zombie_health_start;
	else
	{
		if(game["tranzit"].specialWaveType == "")
		{
			if(game["tranzit"].wave < 7)
				level.zombie_health = int(game["tranzit"].zombie_health_start + (game["tranzit"].zombie_health_increase * (game["tranzit"].wave -1))); 
			else
			{
				level.zombie_health = int(game["tranzit"].zombie_health_start + (game["tranzit"].zombie_health_increase * (7 -1))); 
				level.zombie_health = int(level.zombie_health * pow(1+(game["tranzit"].zombie_health_increase_percent), (game["tranzit"].wave -7))); 
			}
		}
		else
		{
			level.zombie_health = 400 * game["tranzit"].specialWaveCount;
			
			if(game["tranzit"].specialWaveCount > 1)
				level.zombie_health += 100;

			if(level.zombie_health > 1700)
				level.zombie_health = 1700;
		}
	}

	level.dwarfsLeft = 0;
	level.zombiesSpawned = 0;
	level.zombiesTotalForWave = getZombieAmountForWave();
	level.zombiesLeftInWave = level.zombiesTotalForWave;

	//consolePrint("calc " + level.zombiesSpawned + " / " + level.zombiesTotalForWave + "\n");

	//first check if there are enough zombies
	//otherwise let some bots connect
	
	if(level.playerCount["allies"] == 0)
		botRequirement = game["tranzit"].zombie_ai_per_player;
	else
		botRequirement = game["tranzit"].zombie_ai_per_player * level.playerCount["allies"];
	
	if(botRequirement > level.zombiesTotalForWave)
		botRequirement = level.zombiesTotalForWave;
	
	if(botRequirement > game["tranzit"].zombie_max_ai)
		botRequirement = game["tranzit"].zombie_max_ai;
	
	//might be better to let em join one by one
	//but we will see during tests
	if(level.playerCount["axis"] < botRequirement)
	{
		botRequirement = botRequirement - level.playerCount["axis"];
		setDvar("scr_testclients", botRequirement);
		
		//consolePrint("^1not enough bots online - joining new bots \n");
		
		level waittill("connected");
		wait 1;
	}

	//redo this every wave just in case new bots joined the server
	zombie = [];
	for(i=0;i<level.players.size;i++)
	{
		if(level.players[i] isAZombie())
		{
			//exec("undercover " + level.players[i] getEntityNumber() + " 1");
	
			zombie[zombie.size] = level.players[i];
			level.players[i].pers["lives"] = 2;
			continue;
		}
		
		if(level.players[i] isASurvivor())
		{
			level.players[i].afkWaves = 0;
			level.players[i].pers["lives"] = 0;
			continue;
		}
		
		if(game["tranzit"].wave > 1)
		{
			level.players[i].afkWaves++;
			
			if(level.players[i].afkWaves >= level.maxAfkWaves)
				exec("kick " + level.players[i] getEntityNumber() + " You appear to be AFK.");
		}
	}
	
	//add some new zombies that are not part of the zombie array to use them for wasteland dwarfs
	//->
	//total free server slots (always assume the allies are full!)
	remainingSlots = int(level.maxClients - game["tranzit"].player_amount_max - level.playerCount["axis"]);
	//consolePrint("^1calculated free slots: " + remainingSlots + "\n");
	
	//add new zombies when free slots, but when max zombie amount is not reached yet only!
	if(remainingSlots > 0 && level.playerCount["axis"] < game["tranzit"].zombie_max_ai)
	{
		//consolePrint("^1filling empty slots (" + remainingSlots + ") with ");
	
		remainingSlots = game["tranzit"].zombie_max_ai - level.playerCount["axis"];
	
		//max dwarf count is the max player count
		if(remainingSlots > game["tranzit"].player_amount_max)
			remainingSlots = game["tranzit"].player_amount_max;
	
		//consolePrint(remainingSlots + " new bots \n");
		setDvar("scr_testclients", remainingSlots);
		
		level waittill("connected");
		wait 1;
	}
	//<-

	//consolePrint("^1waiting for chalk to increase \n");

	if(game["tranzit"].wave > 1)
		level waittill("round_chalk_done");
	
	game["tranzit"].waveStarted = true;
	
	if(game["tranzit"].specialWaveType == "dogs")
		playSoundToAllPlayers("ann_dog_start");

	//consolePrint("^1starting wave and spawning zombies \n");

	avagadroID = undefined;
	if(game["tranzit"].avagadroReleased && game["tranzit"].avagadroThisWave)
	{
		avagadroID = randomInt(level.zombiesTotalForWave) + 1;
		
		if(avagadroID == level.zombiesTotalForWave)
			avagadroID--;
	}

	zombiesCanSpawn = true;
	while(zombiesCanSpawn)
	{
		for(i=0;i<zombie.size;i++)
		{
			if(!game["tranzit"].waveStarted)
			{
				//consolePrint("^1waveStarted false - aborting zombie spawning \n");
				zombiesCanSpawn = false;
			}
			
			if(level.zombiesSpawned >= level.zombiesTotalForWave)
			{
				//consolePrint("^1max zoms reached - aborting zombie spawning \n");
				zombiesCanSpawn = false;
			}

			if(!zombiesCanSpawn)
				break;

			if(isAlive(zombie[i]))
				continue;

			//consolePrint("spawn zombie \n");
			zombie[i].pers["lives"] = 2;
			
			if(!isDefined(avagadroID) || avagadroID != level.zombiesSpawned)
				zombie[i] thread [[level.spawnPlayer]]();
			else
			{
				zombie[i] thread [[level.spawnPlayer]]("avagadro");
				avagadroID = undefined;
			}		

			wait game["tranzit"].zombie_spawn_delay;
		}
		
		wait .05;
	}
	
	//consolePrint("stop spawn: " + level.zombiesSpawned + "/" + level.zombiesTotalForWave + "\n");
	
	for(i=0;i<zombie.size;i++)
	{
		if(isDefined(zombie[i]))
			zombie[i].pers["lives"] = 0;
	}
}

getZombieAmountForWave()
{
	max = game["tranzit"].zombie_max_ai;
	multiplier = game["tranzit"].wave / 5;
	
	if(multiplier < 1)
		multiplier = 1;

	// After round 10, exponentially have more AI attack the player
	if(game["tranzit"].wave >= 10)
		multiplier *= (game["tranzit"].wave * 0.15);

	if(level.playerCount["allies"] == 1)
		max += int((0.5 * game["tranzit"].zombie_ai_per_player)* multiplier); 
	else
		max += int(((level.playerCount["allies"] - 1)* game["tranzit"].zombie_ai_per_player)* multiplier); 

	switch(game["tranzit"].wave)
	{
		case 0:
		case 1: max = int(max * 0.2); break;
		case 2: max = int(max * 0.4); break;
		case 3: max = int(max * 0.6); break;
		case 4: max = int(max * 0.8); break;
		default: break;
	}

	if(game["tranzit"].specialWaveType != "")
	{
		if(max > game["tranzit"].zombie_max_ai)
			max = game["tranzit"].zombie_max_ai;
	}

	return max;
}

endWave()
{
	if(!game["tranzit"].waveStarted)
		return;
	
	game["tranzit"].waveStarted = false;
	
	thread scripts\ambient::stopAmbient();
	
	if(game["tranzit"].specialWaveType == "")
		playSoundToAllPlayers("end_of_round");
	else
	{
		game["tranzit"].specialWaveType = "";
	
		if(game["tranzit"].specialWaveType == "dogs")
			playSoundToAllPlayers("mx_dog_end");
	}
	
	thread prepareWave();
	thread chalk_round_hint();
}

endGame()
{
	// return if already ending via host quit or victory
	if(game["state"] == "postgame" || level.gameEnded)
		return;

	visionSetNaked("mpOutro", 2.0);
	
	game["state"] = "postgame";
	level.gameEndTime = getTime();
	level.gameEnded = true;
	level.inGracePeriod = false;
	level notify("game_ended");
	
	setGameEndTime(0);

	maps\mp\gametypes\_globallogic::updatePlacement();	
	setdvar("g_deadChat", 1);
	
	// freeze players
	players = level.players;
	for(index = 0; index < players.size; index++)
	{
		player = players[index];
		
		player thread maps\mp\gametypes\_globallogic::roundEndDoF(4.0);
		
		player maps\mp\gametypes\_globallogic::freezePlayerForRoundEnd();
		player maps\mp\gametypes\_globallogic::freeGameplayHudElems();
		
		player setClientDvars("ui_hud_hardcore", 1,
							   "cg_drawSpectatorMessages", 0,
							   "g_compassShowEnemies", 0,
							   "cg_everyoneHearsEveryone", 1);
		
		if(!isDefined(player.pers["team"])|| player.pers["team"] == "spectator")
		{
			player [[level.spawnIntermission]]();
			player closeMenu();
			player closeInGameMenu();
		}
		
		if(isDefined(player.possibleZombieRankCountReset) && player.possibleZombieRankCountReset)
		{
			//self iPrintLnBOld("might reset zombieRankCounts part 2");
		
			if(player.pers["downs"] > 1 || (player.pers["downs"] == 1 && game["tranzit"].wave < game["tranzit"].playerRank[player.zombieRank].rankUpRounds))
				player scripts\rank::setRankCounts(0);
		}
	}
	
	wait 2;
	
	playSoundToAllPlayers("end_of_game");
	
	wait level.postRoundTime;
	
	removeAllTestClients();
	
	level.intermission = true;
	
	//regain players array since some might've disconnected during the wait above
	players = level.players;
	for(index = 0; index < players.size; index++)
	{
		player = players[index];
		
		player closeMenu();
		player closeInGameMenu();
		player notify("reset_outcome");
		player [[level.spawnIntermission]]();
		player setClientDvars(	"ui_hud_hardcore", 0,
								"ui_showStockScoreboard", 1,
								"g_scriptMainMenu", game["menu_eog_main"]);
	}
	
	logString("game ended");
	wait getDvarFloat("scr_show_unlock_wait");
	
	thread maps\mp\gametypes\_globallogic::timeLimitClock_Intermission(getDvarFloat("scr_intermission_time"));
	wait getDvarFloat("scr_intermission_time");
	
	exitLevel(false);
}

createWaveHud(x)
{
	if(!isDefined(x))
		x = 0;

	hud = NewHudElem();
	hud.alignX = "left"; 
	hud.alignY = "bottom";
	hud.horzAlign = "left"; 
	hud.vertAlign = "bottom";
	hud.color = (0.423, 0.004, 0);
	hud.foreground = true; 
	hud.hidewheninmenu = false; 
	hud.sort = 1; 
	hud.alpha = 0;
	hud.x = x; 

	hud SetShader("hud_chalk_1", 64, 64);

	return hud;
}

chalk_one_up()
{
	intro = false;
	if(game["tranzit"].wave == 1)
		intro = true;

	round = undefined;	
	if(intro)
	{
		round = NewHudElem();
		round.alignX = "center"; 
		round.alignY = "bottom";
		round.horzAlign = "center"; 
		round.vertAlign = "bottom";
		round.fontscale = 2;
		round.color = (1, 1, 1);
		round.x = 0;
		round.y = -265;
		round.foreground = true; 
		round.hidewheninmenu = false; 
		round.sort = 1; 
		round.label = &"^1ROUND";
		
		round.alpha = 0;
		round FadeOverTime(1);
		round.alpha = 1;
		
		wait 1;
		
		round FadeOverTime(3);
		round.color = (0.423, 0.004, 0);
	}

	hud = undefined;
	if(game["tranzit"].wave < 6 || game["tranzit"].wave > 10)
	{
		hud = level.chalk_hud1;
		hud.fontscale = 3.2;
	}
	else if(game["tranzit"].wave < 11)
		hud = level.chalk_hud2;

	if(intro)
	{
		hud.alpha = 0;
		hud.horzAlign = "center";
		hud.x = -5;
		hud.y = -200;
	}

	hud FadeOverTime(0.5);
	hud.alpha = 0;

	if(game["tranzit"].wave == 11 && isDefined(level.chalk_hud2))
	{
		level.chalk_hud2 FadeOverTime(0.5);
		level.chalk_hud2.alpha = 0;
	}

	wait 0.5;

	//setmusicstate("round_begin");
	playSoundToAllPlayers("start_of_round");

	if(game["tranzit"].wave == 11 && isDefined(level.chalk_hud2))
		level.chalk_hud2 destroy();

	if(game["tranzit"].wave > 10)
	{
		hud.x = 10;
		hud SetValue(game["tranzit"].wave);
	}

	hud FadeOverTime(0.5);
	hud.alpha = 1;

	if(intro)
	{
		wait 3;

		if(isDefined(round))
		{
			round FadeOverTime(1);
			round.alpha = 0;
		}

		wait 0.25;

		hud MoveOverTime(1.75);
		hud.horzAlign = "left";
		hud.y = 0;
		wait 2;

		if(isDefined(round))
			round destroy();
	}

	if(game["tranzit"].wave > 10)
		return;
	
	if(game["tranzit"].wave > 5)
		hud SetShader("hud_chalk_" + (game["tranzit"].wave - 5), 64, 64);
	else if(game["tranzit"].wave > 1)
		hud SetShader("hud_chalk_" + game["tranzit"].wave, 64, 64);
}

chalk_round_hint()
{
	huds = [];
	huds[huds.size] = level.chalk_hud1;

	if(game["tranzit"].wave > 5 && game["tranzit"].wave < 11)
		huds[huds.size] = level.chalk_hud2;

	time = game["tranzit"].betweenRoundTime;
	for(i = 0; i < huds.size; i++)
	{
		huds[i] FadeOverTime(time * 0.25);
		huds[i].color = (1, 1, 1);
	}
	
	//setmusicstate("round_end");
	
	wait (time * 0.25);

	// Pulse
	fade_time = 0.5;
	steps = (time * 0.5)/ fade_time;
	for(q = 0; q < steps; q++)
	{
		for(i = 0; i < huds.size; i++)
		{
			if(!isDefined(huds[i]))
				continue;

			huds[i] FadeOverTime(fade_time);
			huds[i].alpha = 0;
		}

		wait fade_time;

		for(i = 0; i < huds.size; i++)
		{
			if(!isDefined(huds[i]))
				continue;

			huds[i] FadeOverTime(fade_time);
			huds[i].alpha = 1;		
		}

		wait fade_time;
	}

	for(i = 0; i < huds.size; i++)
	{
		if(!isDefined(huds[i]))
			continue;

		huds[i] FadeOverTime(time * 0.25);
		huds[i].color = (0.423, 0.004, 0);
		huds[i].alpha = 1;
	}
	
	wait (time * 0.25);
	
	level notify("round_chalk_done");
}