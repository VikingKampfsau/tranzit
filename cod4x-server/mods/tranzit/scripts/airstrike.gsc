#include maps\mp\_utility;
#include maps\mp\gametypes\_hud_util;
#include common_scripts\utility;
#include scripts\_include;

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
}

doArtillery(targetLocation, skyPos, owner)
{
	level.airstrikeInProgress = true;
	yaw = randomfloat(360);
	
	/*for(i=0;i<level.players.size;i++)
	{
		if(isAlive(level.players[i]) && level.players[i] isAsurvivor())
		{
			if(distance2d(level.players[i].origin, targetLocation) <= level.artilleryDangerMaxRadius * 1.25)
				level.players[i] iPrintLnBold(&"MP_WAR_AIRSTRIKE_INBOUND_NEAR_YOUR_POSITION");
		}
	}*/
	
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
	
	callStrike(owner, targetLocation, skyPos, yaw);
	
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

getFlyPath(skyPos, direction)
{
	radius = 99999999999;
	start = undefined;
	end = undefined;
	
	if(isDefined(direction))
	{
		start = BulletTrace(skyPos, skyPos + AnglesToForward(direction)*radius, false, undefined);
		end = BulletTrace(skyPos, skyPos - AnglesToForward(direction)*radius, false, undefined);
	}
	else
	{
		random = randomInt(360);
		for(i=random;i<(random+360);i++)
		{
			start = BulletTrace(skyPos, skyPos + AnglesToForward((0,i,0))*radius, false, undefined);
			end = BulletTrace(skyPos, skyPos - AnglesToForward((0,i,0))*radius, false, undefined);

			if(BulletTracePassed(start["position"], end["position"], false, undefined))
				break;
		}
	}
	
	path = [];
	if(isDefined(start["position"]) && isDefined(end["position"]))
	{
		path[0] = start["position"];
		path[1] = end["position"];
	}
	
	return path;
}

callStrike(owner, targetLocation, skyPos, yaw)
{	
	direction = (0, yaw, 0);
	planeHalfDistance = 24000;
	planeBombExplodeDistance = 1500;
	planeFlyHeight = 850;

	flypath = Getflypath(skyPos, direction);
	if(isDefined(flypath) && flypath.size >= 2)
		planeHalfDistance = int(planeHalfDistance/2 + Distance(flypath[0], flypath[1])/2);
	
	startPoint = skyPos + vector_scale(AnglesToForward(direction), planeHalfDistance *-1);
	endPoint = skyPos + vector_scale(AnglesToForward(direction), planeHalfDistance);
	
	// Make the plane fly by
	d = length(startPoint - endPoint);
	flyTime = (d/level.planeFlySpeed);
	
	// bomb explodes planeBombExplodeDistance after the plane passes the center
	d = abs(d/2 + planeBombExplodeDistance);
	bombTime = (d/level.planeFlySpeed);
	
	assert(flyTime > bombTime);
	
	owner endon("disconnect");
	
	level.airstrikeDamagedEnts = [];
	level.airStrikeDamagedEntsCount = 0;
	level.airStrikeDamagedEntsIndex = 0;

	for(i=1;i<=5;i++)
	{
		level thread doPlaneStrike(i, owner, targetLocation, startPoint, endPoint, bombTime, flyTime, direction);

		if(i % 2)
			wait 1;
	}
}

doPlaneStrike(planeID, owner, targetLocation, startPoint, endPoint, bombTime, flyTime, direction)
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
	thread callStrike_bombEffect(plane, bombTime-1, targetLocation, owner);
	
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

callStrike_bombEffect(plane, launchTime, targetLocation, owner)
{
	wait launchTime;
	
	playSoundAtPosition("veh_mig29_sonic_boom", plane.origin);
	
	bomb = spawn("script_model", plane.origin);
	bomb.angles = plane.angles;
	bomb setModel("projectile_cbu97_clusterbomb");
	bomb moveGravity(vector_scale(AnglesToForward(plane.angles), level.planeFlySpeed/1.5), 3.0);
	
	wait .85;
	bomb.killCamEnt = spawn("script_model", bomb.origin + (0,0,200));
	bomb.killCamEnt.angles = bomb.angles;
	bomb.killCamEnt thread deleteAfterTime(10);
	bomb.killCamEnt moveTo(bomb.killCamEnt.origin + vector_scale(AnglesToForward(plane.angles), 1000), 3.0);
	wait .15;

	newBomb = spawn("script_model", bomb.origin);
 	newBomb setModel("tag_origin");
  	newBomb.origin = bomb.origin;
  	newBomb.angles = VectorToAngles(targetLocation - newBomb.origin);

	bomb setModel("tag_origin");
	
	dropTime = (Distance(targetLocation, newBomb.origin)/level.planeFlySpeed/1.5);

	if(dropTime >= 0.5)
		wait (dropTime - 0.5);
	else
		wait dropTime;
	
	bombOrigin = newBomb.origin;
	bombAngles = newBomb.angles;
	playFxOnTag(level.airstrikefx, newBomb, "tag_origin");
	
	wait .5;
	repeat = 12;
	minAngles = 5;
	maxAngles = 55;
	angleDiff = (maxAngles - minAngles) / repeat;
	
	for(i=0;i<repeat;i++)
	{
		traceDir = anglesToForward(bombAngles + (maxAngles-(angleDiff * i),randomInt( 10 )-5,0));
		traceEnd = bombOrigin + vector_scale(traceDir, 10000);
		trace = bulletTrace(bombOrigin, traceEnd, false, undefined);
		
		traceHit = trace["position"];		
		thread losRadiusDamage(traceHit + (0,0,16), 512, 200, 30, owner, bomb);
	
		if(i%3 == 0)
		{
			playSoundAtPosition("artillery_impact", traceHit);
			playRumbleOnPosition("artillery_rumble", traceHit);
			earthquake(0.7, 0.75, traceHit, 1000);
		}
		
		wait .05;
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