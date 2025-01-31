#include scripts\_include;

init()
{
	precacheShader("specialty_doublepoints_zombies");
	precacheShader("specialty_instakill_zombies");
	
	level.PowerUps = [];
	level.droppedPowerUps = [];
	level.zombiesNuked = false;

	initPowerUp("instakill", "zombie_powerups", 30);
	initPowerUp("doublepoints", "zombie_powerups", 30);
	initPowerUp("maxammo", "zombie_powerups", undefined);
	initPowerUp("nuke", "zombie_powerups", undefined);
	initPowerUp("carpenter", "zombie_powerups", undefined);
	
	add_effect("powerup_grab", "tranzit/powerup/powerup_grab");
	add_effect("powerup_grab_nuke", "tranzit/powerup/powerup_grab_nuke");
	add_effect("powerup_on", "tranzit/powerup/powerup_on");
	
	add_sound("ann_instakill", "ann_instakill");
	add_sound("ann_doublepoints", "ann_doublepoints");
	add_sound("ann_maxammo", "ann_maxammo");
	add_sound("ann_nuke", "ann_nuke");
	add_sound("ann_carpenter", "ann_carpenter");
	add_sound("spawn_powerup", "spawn_powerup");
	add_sound("spawn_powerup_loop", "spawn_powerup_loop");
	add_sound("powerup_grabbed", "powerup_grabbed");
	add_sound("nuked", "powerup_nuke");
	add_sound("full_ammo", "powerup_ammo");
	add_sound("insta_kill_end", "insta_kill_end");
	add_sound("double_point_end", "double_point_end");
	
	game["powerup_dropping"] = false;
	
	game["powerup_achieved"] = 0;
	game["powerup_achieved_max"] = 4;

	game["powerup_score_increment"] = 2000;
	game["powerup_score"] = game["powerup_score_increment"];
	
	game["powerup_instakill"] = false;
	game["powerup_instakill_timer"] = 0;
	
	game["powerup_doublepoints"] = false;
	game["powerup_doublepoints_timer"] = 0;
	
	thread powerup_hud_overlay();
	
	while(game["tranzit"].wave < 1)
		wait 1;
		
	game["powerup_score"] = int((level.players.size * game["tranzit"].score_start) + game["powerup_score_increment"]);
}

initPowerUp(name, model, timer)
{
	precacheModel(model);

	curEntry = level.PowerUps.size;
	level.PowerUps[curEntry] = spawnStruct();
	level.PowerUps[curEntry].id = curEntry;
	level.PowerUps[curEntry].name = name;
	level.PowerUps[curEntry].model = model;
	level.PowerUps[curEntry].timer = timer;
}

dropZombiePowerUp()
{
	// do not drop when there is already a drop in progress
	if(game["powerup_dropping"])
		return;

	// do not drop when zombie was killed with nuke (drop)
	if(level.zombiesNuked)
		return;

	// do not drop when max drops per round reached
	if(game["powerup_achieved"] >= game["powerup_achieved_max"])
		return;

	// do not drop outside the playable area
	if(!self scripts\maparea::isInPlayArea())
		return;

	score_total = 0;
	for(i=0;i<level.players.size;i++)
	{
		if(level.players[i]	isASurvivor())
			score_total += level.players[i].score;
	}
	
	if(score_total < game["powerup_score"])
		return;

	game["powerup_dropping"] = true;

	game["powerup_achieved"]++;
	game["powerup_score_increment"] *= 1.14;
	game["powerup_score"] = score_total + game["powerup_score_increment"];

	level.PowerUps = shuffleArray(level.PowerUps);
	random = level.PowerUps[0];
	
	powerup = spawn("script_model", self.origin + (0, 0, 40));
	powerup SetModel(random.model);
	powerup hidePowerupParts(random.name);
	powerup playLoopSoundRef("spawn_powerup_loop");
	
	playsoundatposition("spawn_powerup", powerup.origin);
	
	powerup.trigger = spawn("trigger_radius", powerup.origin - (0,0,75), 0, 20, 150);

	powerup thread rotateDroppedPowerUp();
	powerup thread deleteDroppedPowerUp();
	powerup thread createPowerupLight();
	
	game["powerup_dropping"] = false;
	
	while(isDefined(powerup.trigger))
	{
		powerup.trigger waittill("trigger", player);

		if(player isAZombie())
			continue;
		
		powerup stopLoopSound("spawn_powerup_loop");
		powerup.trigger delete();

		if(random.name != "nuke")
			playFx(level._effect["powerup_grab"], powerup.origin);
		else
			playFx(level._effect["powerup_grab_nuke"], powerup.origin);

		playsoundatposition("powerup_grabbed", powerup.origin);

		thread activateZombiePowerUp(random);
		break;
	}

	if(isDefined(powerup.light))
		powerup.light delete();

	if(isDefined(powerup))
		powerup delete();
}

createPowerupLight()
{
	self.light = spawnFx(level._effect["powerup_on"], self getTagOrigin("tag_origin"));
	triggerFx(self.light, 0.1);
	
	while(isDefined(self.trigger))
		wait .1;
	
	if(isDefined(self.light))
		self.light delete();
}

hidePowerupParts(powerup)
{
	if(self.model != "zombie_powerups")
		return;
	
	if(powerup != "carpenter")
		self hidePart("tag_zombie_carpenter", self.model);
	
	if(powerup != "doublepoints")
		self hidePart("tag_zombie_doublepoints", self.model);
	
	if(powerup != "instakill")
		self hidePart("tag_zombie_instakill", self.model);
	
	if(powerup != "maxammo")
		self hidePart("tag_zombie_maxammo", self.model);
	
	if(powerup != "nuke")
		self hidePart("tag_zombie_nuke", self.model);
}

rotateDroppedPowerUp()
{
	self endon("death");

	while(1)
	{
		waittime = randomfloatrange(2.5, 5);
		yaw = RandomInt(360);
		
		if(yaw > 300)
			yaw = 300;
		else if(yaw < 60)
			yaw = 60;

		yaw = self.angles[1] + yaw;

		self rotateto((-60 + randomint(120), yaw, -45 + randomint(90)), waittime, waittime * 0.5, waittime * 0.5);
		wait randomfloat (waittime - 0.1);
	}
}

deleteDroppedPowerUp()
{
	self endon("death");

	wait 15;

	for(i=0;i<40;i++)
	{
		// hide and show
		if(i % 2)
			self hide();
		else
			self show();

		if(i < 15)
			wait 0.5;
		else if(i < 25)
			wait 0.25;
		else
			wait 0.1;
	}

	self.trigger delete();
	self delete();
}

activateZombiePowerUp(powerupStruct)
{
	switch(powerupStruct.name)
	{
		case "instakill":
		case "doublepoints": 
			game["powerup_" + powerupStruct.name] = true;
			thread startPowerUpCountdown(powerupStruct);
			break;
		
		case "maxammo":
		case "nuke":
		case "carpenter":
			thread applyPowerUpToEverything(powerupStruct.name);
			break;
		
		default: break;
	}
	
	thread playLocalSoundToAllPlayers("ann_" + powerupStruct.name);
	
	if(!randomint(4))
	{
		wait 3;
		
		randomSurvivor = getRandomPlayer(game["defenders"]);
		switch(powerupStruct.name)
		{
			case "instakill":
				randomSurvivor playSoundRef("powerup_insta");
				break;
				
			case "doublepoints": 
				randomSurvivor playSoundRef("powerup_double");
				break;
			
			case "maxammo":
				randomSurvivor playSoundRef("powerup_ammo");
				break;
				
			case "nuke":
				randomSurvivor playSoundRef("powerup_nuke");
				break;
			
			default: break;
		}
	}
}

applyPowerUpToEverything(type)
{
	if(type == "carpenter")
	{
		for(i=0;i<level.barricades.size;i++)
			level.barricades[i] thread scripts\barricades::restoreAllParts();
	
		for(i=0;i<level.players.size;i++)
		{
			if(level.players[i] isASurvivor())
			{
				level.players[i] thread [[level.onXPEvent]]("powerup_carpenter");
				continue;
			}
		}
	}
	else
	{
		randomSurvivor = getRandomPlayer(game["defenders"]);
	
		if(type == "maxammo")
		{
			randomSurvivor playSoundRef("full_ammo");
		
			for(i=0;i<level.players.size;i++)
			{
				if(level.players[i] isASurvivor())
					level.players[i] thread GiveAmmoForAllWeapons();
			}
		}
		else if(type == "nuke")
		{
			thread nukeBlockOtherDrops();
			thread killAllZombies("powerup_nuke");

			randomSurvivor playSoundRef("nuked");
		}
	}
}

nukeBlockOtherDrops()
{
	level.zombiesNuked = true;
	wait 10;
	level.zombiesNuked = false;
}

startPowerUpCountdown(powerupStruct)
{
	level notify("powerup_timer");
	level endon("powerup_timer");
	
	if(powerupStruct.name == "instakill")
		game["powerup_instakill_timer"] = powerupStruct.timer;
	else
		game["powerup_doublepoints_timer"] = powerupStruct.timer;
	
	while(game["powerup_instakill_timer"] > 0 || game["powerup_doublepoints_timer"] > 0)
	{
		wait 1;
		
		game["powerup_instakill_timer"]--;
		game["powerup_doublepoints_timer"]--;
		
		if(game["powerup_instakill_timer"] <= 0)
		{
			if(game["powerup_instakill"])
				playLocalSoundToAllPlayers("insta_kill_end");
		
			game["powerup_instakill_timer"] = 0;
			game["powerup_instakill"] = false;
		}
		
		if(game["powerup_doublepoints_timer"] <= 0)
		{
			if(game["powerup_doublepoints"])
				playLocalSoundToAllPlayers("double_point_end");
		
			game["powerup_doublepoints_timer"] = 0;
			game["powerup_doublepoints"] = false;
		}

		if(game["powerup_instakill_timer"] == 0 && game["powerup_doublepoints_timer"] == 0)
			break;
	}
}

powerup_hud_overlay()
{
	level.powerup_hud = [];

	for(i=0;i<2;i++)
	{
		level.powerup_hud[i] = newHudElem();
		level.powerup_hud[i].foreground = true; 
		level.powerup_hud[i].sort = 2; 
		level.powerup_hud[i].hidewheninmenu = false; 
		level.powerup_hud[i].alignX = "center"; 
		level.powerup_hud[i].alignY = "bottom";
		level.powerup_hud[i].horzAlign = "center"; 
		level.powerup_hud[i].vertAlign = "bottom";
		level.powerup_hud[i].x = -32 + (i * 15); 
		level.powerup_hud[i].y = level.powerup_hud[i].y - 35; //-35;
		level.powerup_hud[i].alpha = 0.8;
	}

	shader_2x = "specialty_doublepoints_zombies";
	shader_insta = "specialty_instakill_zombies";

	while(1)
	{
		if(game["powerup_instakill_timer"] < 5)
		{
			wait(0.1);		
			level.powerup_hud[1].alpha = 0;
			wait(0.1);
		}
		else if(game["powerup_instakill_timer"] < 10)
		{
			wait(0.2);
			level.powerup_hud[1].alpha = 0;
			wait(0.18);
		}
		
		if(game["powerup_doublepoints_timer"] < 5)
		{
			wait(0.1);	
			level.powerup_hud[0].alpha = 0;
			wait(0.1);
		}
		else if(game["powerup_doublepoints_timer"] < 10)
		{
			wait(0.2);
			level.powerup_hud[0].alpha = 0;
			wait(0.18);
		}
		
		if(game["powerup_doublepoints"] && game["powerup_instakill"])
		{
			level.powerup_hud[0].x = -24;
			level.powerup_hud[1].x = 24;
			level.powerup_hud[0].alpha = 1;
			level.powerup_hud[1].alpha = 1;
			level.powerup_hud[0] setshader(shader_2x, 32, 32);
			level.powerup_hud[1] setshader(shader_insta, 32, 32);
		}
		else if(game["powerup_doublepoints"] && !game["powerup_instakill"])
		{
			level.powerup_hud[0].x = 0; 
			level.powerup_hud[0] setshader(shader_2x, 32, 32);
			level.powerup_hud[1].alpha = 0;
			level.powerup_hud[0].alpha = 1;
		}
		else if(game["powerup_instakill"] && !game["powerup_doublepoints"])
		{

			level.powerup_hud[1].x = 0; 
			level.powerup_hud[1] setshader(shader_insta, 32, 32);
			level.powerup_hud[0].alpha = 0;
			level.powerup_hud[1].alpha = 1;
		}
		else
		{
			level.powerup_hud[1].alpha = 0;
			level.powerup_hud[0].alpha = 0;
		}

		wait(0.01);
	}
}