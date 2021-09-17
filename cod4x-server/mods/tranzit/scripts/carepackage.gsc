#include maps\mp\_utility;
#include common_scripts\utility;
#include scripts\_include;

init()
{
	precacheModel("vehicle_blackhawk");
	precacheModel("com_plasticcase_green_big");

	add_effect("carepackage_smoke", "tranzit/misc/carepackage_smoke");
	add_effect("carepackage_light", "tranzit/misc/carepackage_light");

	level.crateOwnerUseTime = 2;
	level.crateNonOwnerUseTime = 4;
	
	level.totalcps = 0;
	level.maximumcps = 6;
	level.cp_content = [];

	AddToPackage("airstrike_mp", "Airstrike", 50);
	
	AddToPackage("instakill", "Insta-Kill", 10);
	AddToPackage("doublepoints", "x2 Points", 10);
	AddToPackage("maxammo", "Ammo", 10);
	AddToPackage("nuke", "Nuke", 10);
	AddToPackage("carpenter", "Carpenter", 10);
}

AddToPackage(weapon, hinttxt, chance)
{
	struct = spawnstruct();
	struct.weapon = weapon;
	struct.hinttxt = hinttxt;
	struct.chance = chance;
	
	level.cp_content[level.cp_content.size] = struct;
}

spawnSupplyHeli(targetLocation, skyPos, owner)
{
	flypath = Getflypath(skyPos);
	
	if(!isDefined(flypath) || flypath.size < 2)
		return;
	
	level.CpChopper = spawnHelicopter(owner, flypath[0], vectortoangles(vectornormalize(flypath[1] - flypath[0])), "blackhawk_mp", "vehicle_blackhawk");
	level.CpChopper playLoopSound("mp_cobra_helicopter");
	level.CpChopper SetDamageStage(3);
	level.CpChopper.owner = owner;

	level.CpChopper thread CallSupplyHeli(skyPos, flypath[1], targetLocation);
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

CallSupplyHeli(flyPoint, leavePoint, dropPoint)
{
	self endon("death");
	
	self clearTargetYaw();
	self clearGoalYaw();
	self setspeed(90, 40);	
	self setyawspeed(75, 45, 45);
	self setmaxpitchroll(15, 15);
	self setneargoalnotifydist(200);
	self setturningability(0.9);
	self setvehgoalpos(flyPoint, 0);

	self waittillmatch("goal");
	
	self setvehgoalpos(leavePoint, 0);
	self thread DropCarePackage(dropPoint);
	
	self waittillmatch("goal");
	
	self stopLoopSound();
	self hide();
	wait .1;
	self delete();
}

getDropOrigin(dropPoint, carepackage)
{
	trace = BulletTrace(carepackage.origin, dropPoint, false, carepackage);
/*	
	//trace passed - nothing to collide with
	if(trace["fraction"] >= 1)
		return trace;
		
	//trace did not pass
	
	if(isDefined(trace["entity"]))
	{
		//consolePrint("cp trace hit ent of class: " + trace["entity"].classname + "\n");
		return trace;
	}
	
	if(isDefined(trace["surfacetype"]))
	{
		//consolePrint("cp trace hit surface of type " + trace["surfacetype"] + "\n");
		return trace;
	}
*/	
	return trace;
}

DropCarePackage(dropPoint)
{
	level.totalcps++;

	carepackage = spawn("script_model", (self.origin[0], self.origin[1], self.origin[2]-130));
	carepackage SetModel("com_plasticcase_green_big");
	
	carepackage.angles = (0, randomInt(360), 0);
	carepackage.type = "carepackage";
	carepackage.owner = self.owner;

	dropPoint = getDropOrigin(dropPoint, carepackage);
	
	carepackage.blocker = [];
	carepackage.blocker[0] = spawn("trigger_radius", carepackage.origin, 0, 32, 35);
	carepackage.blocker[1] = spawn("trigger_radius", carepackage.origin + vectorscale(anglesToRight(self.angles), 32), 0, 32, 35);
	carepackage.blocker[2] = spawn("trigger_radius", carepackage.origin + vectorscale(anglesToRight(self.angles), -32), 0, 32, 35);
	
	for(i=0;i<carepackage.blocker.size;i++)
	{
		carepackage.blocker[i] thread ForceOrigin(undefined, carepackage);
		carepackage.blocker[i] thread DontBlockBots();
	}

	carepackage.deathtrigger = spawn("trigger_radius", carepackage.origin, 0, 50, 1);
	carepackage.deathtrigger thread ForceOrigin(undefined, carepackage);
	carepackage.deathtrigger thread MakeDeadly(carepackage);

	carepackage.fxEnt = spawn("script_model", carepackage.origin + (0,0,40));
	carepackage.fxEnt setModel("tag_origin");
	carepackage.fxEnt linkTo(carepackage);

	wait .05;

	playFxOnTag(level._effect["carepackage_light"], carepackage.fxEnt, "tag_origin");

	carepackage MoveTo(dropPoint["position"], 0.1 + abs(Distance(dropPoint["position"], carepackage.origin)/800));
	carepackage waittill("movedone");

	playFxOnTag(level._effect["carepackage_smoke"], carepackage.fxEnt, "tag_origin");

	carepackage.deathtrigger delete();

	for(i=0;i<carepackage.blocker.size;i++)
		carepackage.blocker[i] setContents(1);
	
	carepackage Bounce(dropPoint);
	
	carepackage.trigger = spawn("trigger_radius", carepackage.origin - (0,0,40), 0, 100, 80);
	carepackage.content = CalculateContent();
		
	if(isDefined(self.owner))
		carepackage thread crateUseThinkOwner();

	carepackage thread crateUseThink(self.owner);
}

ForceOrigin(prevorigin, entity)
{
	self endon("death");

	while(1)
	{
		if(isDefined(prevorigin) && self.origin != prevorigin)
			self.origin = prevorigin;
		else if(isDefined(entity) && self.origin != entity.origin)
			self.origin = entity.origin;
		
		wait .05;
	}
}

DontBlockBots()
{
	self endon("death");

	while(1)
	{
		self waittill("trigger", player);
		
		if(player isAZombie())
			player thread scripts\zombies::botJump();
	}
}

MakeDeadly(eInflictor)
{
	self endon("death");

	while(1)
	{
		self waittill("trigger", player);
		
		if(player isASurvivor())
		{
			player SetOrigin(player.origin + (0,0,40));
			continue;
		}
		
		player finishPlayerDamage(eInflictor, eInflictor.owner, player.health, 0, "MOD_SUICIDE", "none", self.origin, VectorToAngles(player.origin - self.origin), "none", 0);
	}
}

Bounce(dropPoint)
{
	self endon("death");
	
	/*BounceTargets[0][0] = 32;
	BounceTargets[0][1] = 0.4;
	BounceTargets[0][2] = 0;
	BounceTargets[0][3] = 0.4;

	BounceTargets[1][0] = -32;
	BounceTargets[1][1] = 0.425;
	BounceTargets[1][2] = 0.425;
	BounceTargets[1][3] = 0;

	BounceTargets[2][0] = 0.16;
	BounceTargets[2][1] = 0.25;
	BounceTargets[2][2] = 0;
	BounceTargets[2][3] = 0.25;

	BounceTargets[3][0] = -0.16;
	BounceTargets[3][1] = 0.275;
	BounceTargets[3][2] = 0.275;
	BounceTargets[3][3] = 0;
	
	type = dropPoint["surfacetype"];
	for(i=0;i<BounceTargets.size;i++)
	{
		self PlaySound("grenade_bounce_" + type);
		self MoveZ(BounceTargets[i][0], BounceTargets[i][1], BounceTargets[i][2], BounceTargets[i][3]);
		wait BounceTargets[i][1];
	}*/
	
	for(i=1;i<=4;i++)
	{
		speed = 150;
		offset = (0,0,0);
		
		if((i/2) != int(i/2))
			offset = (0,0,32/i);
	
		time = fake_physicslaunch(dropPoint["position"] + offset, speed);
		wait time;
	}
}

CalculateContent()
{
	random = RandomInt(100);
	parent = 0;
	
	for(i=0;i<level.cp_content.size;i++)
	{
		next = parent + level.cp_content[i].chance;
	
		if(random >= parent && random < next)
			return level.cp_content[i];
		
		parent = next;
	}
	
	return level.cp_content[0];
}

crateUseThink(owner)
{
	while(isDefined(self))
	{
		self.trigger waittill("trigger", player);
		
		if(!isAlive(player))
			continue;
			
		if(!player isOnGround())
			continue;

		if(!player isReadyToUse())
			continue;
		
		if(isDefined(self.owner) && self.owner == player)
			continue;
		
		useEnt = self spawnUseEnt();
		result = useEnt useHoldThink(player, level.crateNonOwnerUseTime);
		
		if(isDefined(useEnt))
			useEnt Delete();

		if(result)
		{
			player GivePackageContent(self);
			break;
		}
	}
}

crateUseThinkOwner() 
{
	while(isDefined(self))
	{
		self.trigger waittill("trigger", player);

		player thread showTriggerUseHintMessage(self.trigger, player getLocTextString("CAREPACKAGE_OPEN_PRESS_BUTTON"), undefined, self.content.hinttxt);

		if(!isDefined(self.owner))
			break;
		
		if(!isAlive(player))
			continue;
			
		if(!player isOnGround())
			continue;

		if(player != self.owner)
			continue;
	
		if(!player isReadyToUse())
			continue;

		result = self useHoldThink(player, level.crateOwnerUseTime);

		if(result)
		{
			player GivePackageContent(self);
			break;
		}
	}
}

useHoldThink(player, useTime) 
{
	player freezeControls(true);
	player disableWeapons();
	self.curProgress = 0;
	self.inUse = true;
	self.useRate = 0;
	self.useTime = useTime;

	result = useHoldThinkLoop(player);
	
	if(isDefined(player) && isAlive(player))
	{
		player enableWeapons();
		player freezeControls(false);
	}
	
	if(isDefined(self))
		self.inUse = false;
	
	if(isdefined(result) && result)
		return true;
	
	return false;
}

useHoldThinkLoop(player)
{
	level endon("game_ended");

	player.IsOpeningCrate = true;
	
	while(isDefined(self) && isAlive(player) && player useButtonPressed() && self.curProgress < self.useTime)
	{
		player thread personalUseBar(self);
	
		self.curProgress += self.useRate*0.05;
		self.useRate = 1;

		if(self.curProgress >= self.useTime)
		{
			self.inUse = false;
			player.IsOpeningCrate = undefined;
			return isAlive(player);
		}
	wait .05;
	}
	
	player.IsOpeningCrate = undefined;
	
	return false;
}

personalUseBar(object) 
{
	self endon("disconnect");
	
	if(isDefined(self.useBar))
		return;
	
	self.useBar = self maps\mp\gametypes\_hud_util::createBar((1,1,1), 128, 8);
	self.useBar maps\mp\gametypes\_hud_util::setPoint("CENTER", 0, 0, 0);

	lastRate = -1;
	while(isAlive(self) && isDefined(object) && object.inUse && !level.gameEnded)
	{
		if(lastRate != object.useRate)
		{
			if(object.curProgress > object.useTime)
				object.curProgress = object.useTime;

			self.useBar maps\mp\gametypes\_hud_util::updateBar(object.curProgress/object.useTime, 1/object.useTime);

			if(!object.useRate)
				self.useBar maps\mp\gametypes\_hud_util::hideElem();
			else
				self.useBar maps\mp\gametypes\_hud_util::showElem();
		}

		lastRate = object.useRate;
		wait .05;
	}
	
	self.useBar maps\mp\gametypes\_hud_util::destroyElem();
}

spawnUseEnt()
{
	useEnt = spawn("script_origin", self.origin);
	useEnt.curProgress = 0;
	useEnt.inUse = false;
	useEnt.useRate = 0;
	useEnt.useTime = 0;
	useEnt.owner = self;
	
	useEnt thread useEntOwnerDeathWaiter(self);
	return useEnt;
}

useEntOwnerDeathWaiter(owner)
{
	self endon("death");
	owner waittill("death");
	
	self delete();
}

GivePackageContent(carepackage)
{
	self endon("death");
	self endon("disconnect");
	
	for(i=0;i<carepackage.blocker.size;i++)
		carepackage.blocker[i] delete();
		
	carepackage.trigger delete();
	carepackage.fxEnt delete();
	carepackage delete();
	
	level.totalcps--;
	
	newWeapon = carepackage.content.weapon;
	
	if(!isDefined(newWeapon))
	{
		self iPrintLnBold(self getLocTextString("CAREPACKAGE_CONTENT_NONE"));
		return;
	}
	
	for(i=0;i<level.PowerUps.size;i++)
	{
		if(newWeapon == level.PowerUps[i].name)
		{
			thread scripts\zombie_drops::activateZombiePowerUp(level.PowerUps[i]);
			return;
		}
	}

	if(getSubStr(newWeapon, newWeapon.size - 3, newWeapon.size) != "_mp")
		newWeapon = newWeapon + "_mp";

	if(isOtherExplosive(newWeapon) && self hasActionSlotWeapon("weapon"))
	{
		if(self.actionSlotWeapon != newWeapon)
		{
			self iPrintLnBold(self getLocTextString("CAREPACKAGE_CONTENT_NONE"));
			return;
		}
	}
	
	if(isHardpointWeapon(newWeapon) && self hasActionSlotWeapon("hardpoint"))
	{
		if(self.actionSlotHardpoint != newWeapon)
		{
			self iPrintLnBold(self getLocTextString("CAREPACKAGE_CONTENT_NONE"));
			return;
		}
	}

	if(self hasWeapon(newWeapon))
	{
		self giveMaxAmmo(newWeapon);
		return;
	}

	self giveNewWeapon(newWeapon);

	return;
}