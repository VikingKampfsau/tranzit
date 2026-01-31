#include maps\mp\_utility;
#include maps\mp\gametypes\_hud_util;
#include common_scripts\utility;
#include scripts\_include;
#include scripts\debug\drawdebuggers;

init()
{
	level.airstrikefx = loadfx ("explosions/clusterbomb");
	level.mortareffect = loadfx ("explosions/artilleryExp_dirt_brown");
	level.bombstrike = loadfx ("explosions/wall_explosion_pm_a");
	
	level.fx_airstrike_afterburner = loadfx ("fire/jet_afterburner");
	level.fx_airstrike_contrail = loadfx ("smoke/jet_contrail");
	
	// airstrike danger area is the circle of radius artilleryDangerMaxRadius 
	// stretched by a factor of artilleryDangerOvalScale in the direction of the incoming airstrike,
	// moved by artilleryDangerForwardPush * artilleryDangerMaxRadius in the same direction.
	// use scr_airstrikedebug to visualize.
	
	level.artilleryDangerMaxRadius = 450;
	level.artilleryDangerMinRadius = 300;
	level.artilleryDangerForwardPush = 1.5;
	level.artilleryDangerOvalScale = 6.0;
	level.artilleryMapRange = level.artilleryDangerMinRadius * .3 + level.artilleryDangerMaxRadius * .7;
	level.artilleryDangerMaxRadiusSq = level.artilleryDangerMaxRadius * level.artilleryDangerMaxRadius;
	level.artilleryDangerCenters = [];
	
	level.planeFlySpeed = 7000;
	
	//napalm settings
	level.napalmSettings = spawnStruct();
	level.napalmSettings.fireDamageTo = "all"; //"all", "enemies"
	level.napalmSettings.fireDamage = 100;
	level.napalmSettings.fireDamageRadius = 100;
	level.napalmSettings.firespots = 10;
	level.napalmSettings.firelivetime = 20;
	level.napalmSettings.firefx = loadFx("fire/tank_fire_engine");
	level.napalmSettings.detonatefx = loadFx("explosions/aerial_explosion");
	level.napalmSettings.rocketTrailFx = loadfx("smoke/smoke_geotrail_hellfire");
}

useAirstrike(supportType, targetLocation, use_map_artillery_selector)
{
	if(!use_map_artillery_selector)
	{
		playSoundAtPosition("smokegrenade_explode_default", targetLocation);
		playFx(level._effect["smoke_location_marker"], targetLocation);
	}
	
	thread doArtillery(supportType, self, targetLocation);
}

doArtillery(supportType, owner, targetLocation)
{
	level.airstrikeInProgress = true;
	yaw = randomfloat(360);
	
	for(i=0;i<level.players.size;i++)
	{
		if(isAlive(level.players[i]) && level.players[i] isAsurvivor())
		{
			if(distance2d(level.players[i].origin, targetLocation) <= level.artilleryDangerMaxRadius * 1.25)
				level.players[i] iPrintLnBold(&"MP_WAR_AIRSTRIKE_INBOUND_NEAR_YOUR_POSITION");
		}
	}
	
	wait 2;

	if(!isDefined(owner))
	{
		level.airstrikeInProgress = undefined;
		return;
	}
	
	owner notify("begin_airstrike");
	
	dangerCenter = spawnstruct();
	dangerCenter.origin = targetLocation;
	dangerCenter.forward = anglesToForward((0,yaw,0));
	level.artilleryDangerCenters[level.artilleryDangerCenters.size] = dangerCenter;
	
	callStrike(supportType, owner, targetLocation, yaw);
	
	wait 8.5;
	
	found = false;
	newarray = [];
	for(i=0;i<level.artilleryDangerCenters.size;i++)
	{
		if(!found && level.artilleryDangerCenters[i].origin == targetLocation)
		{
			found = true;
			continue;
		}
		
		newarray[newarray.size] = level.artilleryDangerCenters[i];
	}
	assert(found);
	assert(newarray.size == level.artilleryDangerCenters.size - 1);
	level.artilleryDangerCenters = newarray;

	level.airstrikeInProgress = undefined;
}

callStrike(supportType, owner, targetLocation, yaw)
{
	direction = (0, yaw, 0);
	planeHalfDistance = 24000;
	planeBombExplodeDistance = 1500;
	planeFlyHeight = 850;

	startPoint = targetLocation + (0,0,planeFlyHeight) + vector_scale(AnglesToForward(direction), planeHalfDistance *-1);
	endPoint = targetLocation + (0,0,planeFlyHeight) + vector_scale(AnglesToForward(direction), planeHalfDistance);

/*
Stock CoD4
	// Make the plane fly by
	d = length(startPoint - endPoint);
	flyTime = (d/level.planeFlySpeed);
	
	// bomb explodes planeBombExplodeDistance after the plane passes the center
	d = abs(d/2 + planeBombExplodeDistance);
	bombLaunchTime = (d/level.planeFlySpeed);
	
result ---> flyTime: 6,85714 bombLaunchTime: 3,64286"
*/

/*
My Code for dynamic height
*/
	//find the sky height of the map
	skyCalc = getSkyHeight(targetLocation, true);
	MapSkyPos = skyCalc[0];
	targetLocation = skyCalc[1];
	
	/*if(!isDefined(MapSkyPos) || (targetLocation[2] + planeFlyHeight) >= MapSkyPos[2])
	{
		if(!isDefined(MapSkyPos)) iPrintLnBold("MapSkyPos undefined");
		if((targetLocation[2] + planeFlyHeight) >= MapSkyPos[2])
			iPrintLnBold("MapSkyPos out of skybox. Skypos[2]: " + MapSkyPos[2] + " TargetPos[2]:" + targetLocation[2]);
	}*/
	
	if(isDefined(MapSkyPos) && (targetLocation[2] + planeFlyHeight) < MapSkyPos[2])
	{
		//iPrintLnBold("found bottom of skybox at: " + MapSkyPos[2]); //backlot bottom = 2304
	
		//check if a higher planeFlyHeight is possible
		//(CoD4 is at 850 which is not high enough but the sky in shipment is at 2400+ which is way to high)
		clearPath = true;
		testHeight = planeFlyHeight;
		for(i=1;i<int((MapSkyPos[2]-planeFlyHeight-targetLocation[2])/100);i++)
		{
			startPoint = targetLocation + (0,0,testHeight) + vector_scale(AnglesToForward(direction), planeHalfDistance *-1);
			endPoint = targetLocation + (0,0,testHeight) + vector_scale(AnglesToForward(direction), planeHalfDistance);
		
			trace = BulletTrace(startPoint, endPoint, false, undefined);
			
			//trace has hit anything
			if(trace["fraction"] < 1)
			{
				//ignore anything that has no 'real' surface (like the sides of the skybox)
				if(isDefined(trace["surfaceType"]) && trace["surfaceType"] != "default")
					clearPath = false;
			}
			
			//already outside the skybox
			if((targetLocation[2] + testHeight) >= MapSkyPos[2])
				clearPath = false;

			if(!clearPath)
				break;
				
			testHeight += 100;
		}
		
		testHeight -= 100;
		if(testHeight > planeFlyHeight)
			planeFlyHeight = testHeight;
		
		//iPrintLnBold("planeFlyHeight: " + planeFlyHeight);
		startPoint = targetLocation + (0,0,planeFlyHeight) - vector_scale(AnglesToForward(direction), planeHalfDistance);
		endPoint = targetLocation + (0,0,planeFlyHeight) + vector_scale(AnglesToForward(direction), planeHalfDistance);
	}

	// Make the plane fly by
	d = length(startPoint - endPoint);
	flyTime = (d/level.planeFlySpeed);
	
	bombFallTime = sqrt(2*planeFlyHeight/getDvarFloat("g_gravity"));
	bombFallDist = (level.planeFlySpeed/3)*bombFallTime;
	
	d = abs(d/2);
	d -= bombFallDist;
	bombLaunchTime = (d/level.planeFlySpeed);

	drawDebugLine(targetLocation, targetLocation + (0,0,planeFlyHeight), (1,0,0), 1, 600); //targetLocation up to the sky
	drawDebugLine(startPoint, startPoint + AnglesToForward(direction)*d, (0,1,0), 1, 600); //path untile the bomb launch
	drawDebugLine(startPoint + AnglesToForward(direction)*d, startPoint + AnglesToForward(direction)*(d+bombFallDist), (0,0,1), 1, 600); //distance from bomb launch to targetLocation

	//move the spawnpoint of the plance closer to the damage center
	//this will fix the visual trail of the bomb AND keeps the position/time of the bomb drop
	startPoint = startPoint + vector_scale(AnglesToForward(direction), planeBombExplodeDistance);
/**/

	assert(flyTime > bombLaunchTime);
	
	owner endon("disconnect");
	
	level.airstrikeDamagedEnts = [];
	level.airStrikeDamagedEntsCount = 0;
	level.airStrikeDamagedEntsIndex = 0;

	planes = 1;
	if(supportType == "airstrike")
		planes = 3;

	for(i=1;i<=planes;i++)
	{
		level thread doPlaneStrike(i, owner, targetLocation, startPoint, endPoint, bombLaunchTime, bombFallTime, flyTime, direction, supportType, planeFlyHeight);

		if(i % 2)
			wait 1;
	}
}

doPlaneStrike(planeID, owner, targetLocation, startPoint, endPoint, bombLaunchTime, bombFallTime, flyTime, direction, supportType, planeFlyHeight)
{
	if(!isDefined(owner)) 
		return;

	if(planeID == 1)
		planeOffset = 0;
	else
	{
		if(planeID % 2)
			planeOffset = 450 * (planeID-1);
		else
			planeOffset = -450 * (planeID-2);
	}
	
	startPoint -= vector_scale(AnglesToRight(direction), planeOffset);
	startPoint -= vector_scale(AnglesToForward(direction), abs(planeOffset));
	endPoint   -= vector_scale(AnglesToRight(direction), planeOffset);
	endPoint   -= vector_scale(AnglesToForward(direction), abs(planeOffset));
	
	// Spawn the plane
	plane = spawnplane(owner, "script_model", startPoint);
	plane setModel("vehicle_mig29_desert");
	plane.angles = direction;
	
	plane moveTo(endPoint, flyTime, 0, 0);

	plane thread playPlaneFx();
	plane thread playPlaneSound(targetLocation);
	thread callStrike_bombEffect(plane, bombLaunchTime, bombFallTime, owner, supportType, targetLocation, supportType, planeFlyHeight);
	
	// Delete the plane after its flyby
	wait flyTime;
	
	plane stopLoopSound();
	
	wait 1;
	plane notify( "delete" );
	plane delete();
}

playPlaneFx()
{
	self endon("death");

	playFxOnTag(level.fx_airstrike_afterburner, self, "tag_engine_right");
	playFxOnTag(level.fx_airstrike_afterburner, self, "tag_engine_left");
	playFxOnTag(level.fx_airstrike_contrail, self, "tag_right_wingtip");
	playFxOnTag(level.fx_airstrike_contrail, self, "tag_left_wingtip");
}

playPlaneSound(targetLocation)
{
	self endon("death");

	self playLoopSound("veh_mig29_dist_loop");
	
	while(!targetisclose(self.origin, targetLocation))
		wait .05;
	
	self stopLoopSound();
	self playLoopSound("veh_mig29_close_loop");
	
	while(targetisclose(self.origin, targetLocation))
		wait .05;
		
	self stopLoopSound();
	self playLoopSound("veh_mig29_dist_loop");
}

targetisclose(planePos, targetLocation)
{
	if(distance2d(planePos, targetLocation) <= 3000)
		return true;
		
	return false;
}

callStrike_bombEffect(plane, launchTime, bombFallTime, owner, supportType, targetLocation, supportType, planeFlyHeight)
{
	//iPrintLnBold("launchTime: " + launchTime);
	//iPrintLnBold("bombFallTime: " + bombFallTime);

	wait launchTime;

	playSoundAtPosition("veh_mig29_sonic_boom", plane.origin);
	
	//this is the bomb falling into the targetLocation
	//it's used for calculations and playing the split fx only
	bomb = spawn("script_model", plane.origin);
	bomb.angles = plane.angles;
	bomb setModel("projectile_cbu97_clusterbomb");
	bomb moveGravity(AnglesToForward(bomb.angles)*(level.planeFlySpeed/3), bombFallTime);
	
	wait .8;
	bomb.killCamEnt = spawn("script_model", bomb.origin + (0,0,200));
	bomb.killCamEnt.angles = bomb.angles;
	bomb.killCamEnt thread deleteAfterTime(10);
	bomb.killCamEnt moveTo(bomb.killCamEnt.origin + vector_scale(AnglesToForward(plane.angles), 1000), 3.0);
	wait .15; 

	//calculate additional wait because: higher planeFlyHeight -> higher wait
	//bombFallTime - 1.45774 (stock bombFallTime from height 850) - previous waits after launch 
	if((bombFallTime - 1.45774 - (0.05 + 0.8 + 0.15)) > 0)
		wait (bombFallTime - 1.45774 - (0.05 + 0.8 + 0.15));

	newBomb = spawn("script_model", bomb.origin);
 	newBomb setModel("tag_origin");
  	newBomb.origin = bomb.origin;
  	newBomb.angles = bomb.angles;

/* precalculate the damage areas */
	bombOrigin = newBomb.origin;
	bombAngles = newBomb.angles;

	repeat = 12;
	minAngles = 5;
	maxAngles = 55;
	angleDiff = (maxAngles - minAngles) / repeat;

	traceHit = undefined;
	damageArea = [];
	for(i=0;i<repeat;i++)
	{
		randomYaw = randomInt(10)-5;
		traceDir = anglesToForward(bombAngles + (maxAngles-(angleDiff * i), randomYaw, 0));
		traceEnd = bombOrigin + vector_scale(traceDir, 10000);
		trace = bulletTrace(bombOrigin, traceEnd, false, undefined);
	
		if(i%3 == 0)
		{
			entryNo = damageArea.size;
			damageArea[entryNo] = spawnStruct();
			damageArea[entryNo].origin = trace["position"];
			damageArea[entryNo].angles = bombAngles + (0, randomYaw, 0);
		}
	}
/**/

	if(supportType == "napalm")
	{
		//additional bombs falling into the damageCenters
		//they are used to play trail fx only
		bomb.particles = [];
		for(i=0;i<damageArea.size;i++)
		{
			bomb.particles[i] = spawn("script_model", bomb.origin);
			bomb.particles[i].angles = bomb.angles;
			bomb.particles[i] setModel("tag_origin");
			
			bomb.particles[i].fallHeight = (bombOrigin[2] - targetLocation[2]);
			bomb.particles[i].fallTime = sqrt(2*bomb.particles[i].fallHeight/getDvarFloat("g_gravity"));
			
			if(bomb.particles[i].fallTime < 0.35)
				bomb.particles[i].fallTime = 0.35;
			
			bomb.particles[i].fallDist = Distance2D(bombOrigin, damageArea[i].origin);
			bomb.particles[i].fallSpeed = bomb.particles[i].fallDist/bomb.particles[i].fallTime;
			
			bomb.particles[i] moveGravity(AnglesToForward(damageArea[i].angles)*bomb.particles[i].fallSpeed, bomb.particles[i].fallTime -0.05);
		}
	}

	wait 0.05;
	bomb setModel("tag_origin");
	
	playFxOnTag(level.airstrikefx, newBomb, "tag_origin");

	//use the precalculated damage areas to finally deal damage
	if(supportType != "napalm")
	{
		for(i=0;i<damageArea.size;i++)
			thread doDamgeInDamageArea(bombOrigin, damageArea[i].origin, bomb, supportType, owner);
	}
	else
	{
		for(i=0;i<bomb.particles.size;i++)
			playFxonTag(level.napalmSettings.rocketTrailFx, bomb.particles[i], "tag_origin");

		for(i=0;i<damageArea.size;i++)
			thread doDamgeInDamageArea(bombOrigin, damageArea[i].origin, bomb.particles[i], supportType, owner);
	}

	wait 5;	
	newBomb delete();
	bomb delete();
}

deleteAfterTime(time)
{
	self endon("death");
	wait time;	
	self delete();
}

doDamgeInDamageArea(bombOrigin, damageArea, bombParticle, supportType, owner)
{
	drawDebugLine(bombOrigin, damageArea, (1,1,1), 1, 600); //damageCenter up to the sky
	drawDebugLine(damageArea, damageArea + (0,0,bombOrigin[2]), (1,1,1), 1, 600); //damageCenter up to the sky

	playSoundAtPosition("artillery_impact", damageArea);
	playRumbleOnPosition("artillery_rumble", damageArea);
	earthquake(0.7, 0.75, damageArea, 1000);
	
	if(supportType != "napalm")
		thread losRadiusDamage(damageArea + (0,0,16), 512, 200, 30, owner, bombParticle); //targetpos, radius, maxdamage, mindamage, player causing damage, entity that player used to cause damage
	else
		thread spawnNapalmFireGroup(damageArea, bombParticle, owner);
}

losRadiusDamage(pos, radius, max, min, owner, eInflictor)
{
	ents = maps\mp\gametypes\_weapons::getDamageableEnts(pos, radius, true);
	for(i=0;i<ents.size;i++)
	{
		if(ents[i].entity == self)
			continue;
		
		dist = distance(pos, ents[i].damageCenter);
		
		if(ents[i].isPlayer)
		{
			// check if there is a path to this entity 130 units above his feet. if not, they're probably indoors
			indoors = !maps\mp\gametypes\_weapons::weaponDamageTracePassed(ents[i].entity.origin, ents[i].entity.origin + (0,0,130), 0, undefined);
			if(!indoors)
			{
				indoors = !maps\mp\gametypes\_weapons::weaponDamageTracePassed( ents[i].entity.origin + (0,0,130), pos + (0,0,130 - 16), 0, undefined );
				if(indoors)
				{
					// give them a distance advantage for being indoors.
					dist *= 4;
					if(dist > radius)
						continue;
				}
			}
		}

		ents[i].damage = int(max + (min-max)*dist/radius);
		ents[i].pos = pos;
		ents[i].damageOwner = owner;
		ents[i].eInflictor = eInflictor;
		level.airStrikeDamagedEnts[level.airStrikeDamagedEntsCount] = ents[i];
		level.airStrikeDamagedEntsCount++;
	}
	
	thread airstrikeDamageEntsThread();
}


airstrikeDamageEntsThread()
{
	self notify("airstrikeDamageEntsThread");
	self endon("airstrikeDamageEntsThread");

	for( ; level.airstrikeDamagedEntsIndex < level.airstrikeDamagedEntsCount; level.airstrikeDamagedEntsIndex++ )
	{
		if(!isDefined(level.airstrikeDamagedEnts[level.airstrikeDamagedEntsIndex]))
			continue;

		ent = level.airstrikeDamagedEnts[level.airstrikeDamagedEntsIndex];
		
		if(!isDefined(ent.entity))
			continue; 
			
		if(!ent.isPlayer || isAlive(ent.entity))
		{
			ent maps\mp\gametypes\_weapons::damageEnt(
				ent.eInflictor, // eInflictor = the entity that causes the damage (e.g. a claymore)
				ent.damageOwner, // eAttacker = the player that is attacking
				ent.damage, // iDamage = the amount of damage to do
				"MOD_PROJECTILE_SPLASH", // sMeansOfDeath = string specifying the method of death (e.g. "MOD_PROJECTILE_SPLASH")
				"c4_mp", // sWeapon = string specifying the weapon used (e.g. "claymore_mp")
				ent.pos, // damagepos = the position damage is coming from
				vectornormalize(ent.damageCenter - ent.pos) // damagedir = the direction damage is moving in
			);			

			level.airstrikeDamagedEnts[level.airstrikeDamagedEntsIndex] = undefined;
			
			if(ent.isPlayer)
				wait .05;
		}
		else
		{
			level.airstrikeDamagedEnts[level.airstrikeDamagedEntsIndex] = undefined;
		}
	}
}

//napalm logic
spawnNapalmFireGroup(damageArea, bombParticle, owner)
{
	//wait for the explosion fx
	wait bombParticle.fallTime - 0.1;
	playFx(level.napalmSettings.detonatefx, bombParticle.origin);
	wait 0.05;
	//remove the trail fx
	bombParticle delete();
	wait 0.25;

	firePlace = [];
	for(i=0;i<level.napalmSettings.firespots;i++)
	{
		randomPos = damageArea + AnglesToForward((0,randomIntRange(-360,360),0))*randomIntRange(-250,250);
		randomPos = bulletTrace(randomPos+(0,0,500),randomPos-(0,0,500),false,undefined)["position"];

		if(!isDefined(randomPos))
		{
			i--;
			continue;
		}

		firePlace[i] = spawnFire(randomPos, owner);
		
		//randomize the creation of each fire spot
		wait randomFloatRange(0.05, 0.13);
	}
	
	wait level.napalmSettings.firelivetime;
	
	for(i=0;i<firePlace.size;i++)
	{
		if(isDefined(firePlace[i]))
			firePlace[i] notify("death");
			
		//randomize the removal of each fire spot
		wait randomFloatRange(0.05, 0.13);
	}
}

spawnFire(location, owner)
{
	fire = spawnStruct();
	fire.owner = owner;
	fire.angles = (0,0,0);
	fire.origin = location;
	
	fire.killCamEnt = spawn("script_model", fire.origin /*+ (0,0,200)*/);
	fire.killCamEnt.angles = fire.angles;
	fire.killCamEnt thread deleteAfterTime(level.napalmSettings.firelivetime + 3);
	
	fire thread spawnFireFx();
	fire thread makeFireDeadly();
	
	return fire;
}

spawnFireFx()
{
	self endon("death");

	while(isDefined(self))
	{
		playFx(level.napalmSettings.firefx, self.origin);
		wait 2.8;
	}
}

makeFireDeadly()
{
	self endon("death");
	
	while(isDefined(self))
	{
		for(i=0;i<level.players.size;i++)
		{
			if(level.napalmSettings.fireDamageTo == "all" || (isDefined(self.owner) && level.players[i].pers["team"] != self.owner.pers["team"]))
			{
				if(Distance(self.origin, level.players[i].origin) <= level.napalmSettings.fireDamageRadius)
					level.players[i] thread burnPlayer(self);
			}
		}
		
		wait 1;
	}
}

burnPlayer(firePlace)
{
	self endon("disconnect");
	self endon("death");
	
	if(isDefined(self.isNapalmBurning) && self.isNapalmBurning)
		return;
	
	self.isNapalmBurning = true;
	
	eInflictor = firePlace.killCamEnt;
	if(!isDefined(eInflictor))
		eInflictor = self;
	
	owner = firePlace.owner;
	if(!isDefined(owner))
		owner = self;
	
	if(isAlive(self))
	{
		self [[level.callbackPlayerDamage]](eInflictor, owner, level.napalmSettings.fireDamage, 0, "MOD_SUICIDE", "none", self.origin, VectorToAngles(eInflictor.origin - self.origin), "none", 0, "airstriked");
		wait randomFloatRange(0.33, 0.66);
	}
	
	self.isNapalmBurning = false;
}