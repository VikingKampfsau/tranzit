#include maps\mp\_utility;
#include scripts\_include;

init()
{
	level.misteryWeapons = [];
	level.misteryBoxOpenings = 0;

	precacheModel("zombie_treasure_box");
	precacheModel("com_teddy_bear");

	add_effect("misterybox_location_light", "tranzit/misterybox/misterybox_location_light");
	
	add_sound("open_chest", "lid_open");
	add_sound("music_chest", "music_box");
	add_sound("close_chest", "lid_close");
	add_sound("box_poof", "whoosh");
	add_sound("box_byebye", "magicbox_full");

	add_weapon("flamethrower", "uzi_acog_mp");
	add_weapon("chainsaw", "skorpion_acog_mp");
	add_weapon("raygun", "briefcase_bomb_mp");
	add_weapon("raygun_ug", "briefcase_bomb_defuse_mp");
	add_weapon("minigun", "saw_grip_mp");
	add_weapon("knife", "airstrike_mp");
	add_weapon("wunderwaffe", "m1014_reflex_mp");
	add_weapon("emp_grenade", "uzi_reflex_mp");

	initMisteryWeapon("teddy");

	initMisteryWeapon("ak47_mp");
	initMisteryWeapon("ak74u_mp");
	initMisteryWeapon("barrett_mp");
	initMisteryWeapon("beretta_mp");
	initMisteryWeapon("colt45_mp");
	initMisteryWeapon("deserteagle_mp");
	initMisteryWeapon("dragunov_mp");
	initMisteryWeapon("g36c_mp");
	initMisteryWeapon("g3_mp");
	initMisteryWeapon("m1014_mp");
	initMisteryWeapon("m14_mp");
	initMisteryWeapon("m16_mp");
	initMisteryWeapon("m21_mp");
	initMisteryWeapon("m40a3_mp");
	initMisteryWeapon("m4_mp");
	initMisteryWeapon("m60e4_mp");
	initMisteryWeapon("mp44_mp");
	initMisteryWeapon("mp5_mp");
	initMisteryWeapon("p90_mp");
	initMisteryWeapon("remington700_mp");
	initMisteryWeapon("rpd_mp");
	initMisteryWeapon("rpg_mp");
	initMisteryWeapon("saw_mp");
	initMisteryWeapon("skorpion_mp");
	initMisteryWeapon("usp_mp");
	initMisteryWeapon("uzi_mp");
	initMisteryWeapon("winchester1200_mp");

	initMisteryWeapon(getWeaponFromCustomName("chainsaw"));
	initMisteryWeapon(getWeaponFromCustomName("emp_grenade"));
	initMisteryWeapon(getWeaponFromCustomName("flamethrower"));
	initMisteryWeapon(getWeaponFromCustomName("minigun"));
	initMisteryWeapon(getWeaponFromCustomName("knife"));
	initMisteryWeapon(getWeaponFromCustomName("raygun"));
	initMisteryWeapon(getWeaponFromCustomName("wunderwaffe"));
	
	// shuffle the array around, this gives a little more randomness then just the 'randomInt' on pulling a weapon
	for(i=0;i<level.misteryWeapons.size;i++)
	{
		random = randomInt(level.misteryWeapons.size);
		temp = level.misteryWeapons[i];
		level.misteryWeapons[i] = level.misteryWeapons[random];
		level.misteryWeapons[random] = temp;	
	}

	level.misteryBoxes = getEntArray("misterybox", "targetname");
	
	//no misteryBoxes found - check for rotu map
	if(!isDefined(level.misteryBoxes) || !level.misteryBoxes.size)
	{
		wait 2;
		
		if(isDefined(level.rotuMisteryBoxName))
		{
			level.misteryBoxIsRotu = true;
			level.misteryBoxes = getEntArray(level.rotuMisteryBoxName, "targetname");
		}
	}

	//nothing found - return
	if(!isDefined(level.misteryBoxes) || !level.misteryBoxes.size)
		return;
	
	for(i=0;i<level.misteryBoxes.size;i++)
	{
		if(level.misteryBoxes[i].model != "zombie_treasure_box")
			level.misteryBoxes[i].origin = level.misteryBoxes[i].origin + (0, -12, 17.5);
	
		level.misteryBoxes[i] setModel("zombie_treasure_box");
		level.misteryBoxes[i] hide();
	}
	
	level.misteryBoxPrev = getMisteryBoxInSpawnArea();
	
	thread startMisteryBox(1);
}

initMisteryWeapon(weaponName)
{
	curEntry = level.misteryWeapons.size;
	level.misteryWeapons[curEntry] = spawnStruct();
	level.misteryWeapons[curEntry].weaponName = weaponName;
}

getMisteryBoxInSpawnArea()
{
	if(level.misteryBoxes.size > 1)
	{
		spawnPoints = getEntArray("mp_tdm_spawn_allies_start", "classname");
		area = scripts\maparea::getClosestMapArea(spawnPoints[0].origin);
		
		if(isDefined(area))
		{
			for(i=0;i<level.misteryBoxes.size;i++)
			{
				if(level.misteryBoxes[i] isTouching(area))
					return i;
			}
		}
	}
	
	return undefined;
}

startMisteryBox(delay)
{
	wait delay;

	random = randomInt(level.misteryBoxes.size);
	
	if(level.misteryBoxes.size > 1 && isDefined(level.misteryBoxPrev))
	{
		while(random == level.misteryBoxPrev)
			random = randomInt(level.misteryBoxes.size);
	}
	
	if(!isDefined(level.misteryBoxPrev))
		level.misteryBoxPrev = random;
	
	thread spawnMisteryBox(level.misteryBoxes[random]);
}

spawnMisteryBox(box)
{
	if(!isDefined(level.misteryBoxIsRotu) || !level.misteryBoxIsRotu)
	{
		if(!isDefined(box.lid))
		{
			box.lid = spawn("script_model", (0,0,0));
			box.lid setModel("zombie_treasure_box");
		}
		
		box.lid.origin = box.origin;
		box.lid.angles = box.angles;

		box.lid show();
		box.lid hidePart("tag_box", box.lid.model);
		box.lid unlink();
		
		box show();
		box hidePart("tag_lid", box.model);
	}
	
	box.isInUse = false;
	box.trigger = spawn("trigger_radius", box.origin, 0, 50, 50);

	if(!isDefined(box.skylight))
		box thread createBoxSkylight();
	
	while(isDefined(box.trigger))
	{
		box.trigger waittill("trigger", player);

		if(box.isInUse)
			continue;

		if(!player isReadyToUse())
			continue;

		player thread showTriggerUseHintMessage(box.trigger, player getLocTextString("MISTERYBOX_OPEN_PRESS_BUTTON"), scripts\money::getPrice("treasure_chest"));

		if(!player scripts\money::hasEnoughMoney("treasure_chest"))
			continue;

		if(player UseButtonPressed())
		{
			box.isInUse = true;
			thread doMisteryBox(box, player);
			player thread [[level.onXPEvent]]("treasure_chest");
		}
	}
}

doMisteryBox(box, player)
{
	level.misteryBoxOpenings++;

	if(!isDefined(level.misteryBoxIsRotu) || !level.misteryBoxIsRotu)
		box boxLidOpen();

	weaponModel = spawn("script_model", box getTagOrigin("tag_content"));
	weaponModel.angles = (0,(box.angles[1] + 90),0);
	weaponModel moveZ(55, 2.4);
	
	randomWeapon = undefined;
	for(i=0;i<45;i++)
	{
		randomWeapon = player calculateRandomWeapon();
		
		if(randomWeapon.weaponName != "teddy")
		{
			weaponModel setModel(getWeaponModel(randomWeapon.weaponName, 0));
			weaponModel.angles = (0,(box.angles[1] + 90),0);
		}
		else
		{
			weaponModel setModel("com_teddy_bear");
			weaponModel.angles = (0,(box.angles[1] + 180),0);
		}

		wait .1;
	}
	
	wait .15;
	
	if(randomWeapon.weaponName != "teddy")
	{
		randomWeapon thread makeMisteryWeaponGrabable(player, weaponModel);
		weaponModel thread deleteOverTime(7);
		
		while(isDefined(weaponModel))
			wait .05;
			
		box.isInUse = false;
		
		box playSoundRef("no_purchase");
		
		if(!isDefined(level.misteryBoxIsRotu) || !level.misteryBoxIsRotu)
			box boxLidClose();
	}
	else
	{
		box playSoundRef("box_byebye");
		box.trigger delete();
		
		wait 1;
		weaponModel moveZ(-55, .8);	
		wait .75;
		
		playfx(level._effect["entitiy_disappear"], box.origin);
		
		if(!isDefined(level.misteryBoxIsRotu) || !level.misteryBoxIsRotu)
		{
			box boxLidClose();
			box.lid linkTo(box);
		}
		
		weaponModel delete();
		
		if(isDefined(player))
			player thread [[level.onXPEvent]]("treasure_chest", undefined, -1);
		
		//move it up a bit and shake it
		box moveZ(20, 1);
		box vibrate((randomIntRange(25,50), randomIntRange(25,50), 0), 10, 0.5, 44 );
		wait 4;
		
		//show disappear fx and sound
		playfx(level._effect["entitiy_disappear"], box.origin);
		playfxontag(level._effect["emitter_rocks"], box, "tag_content");
		playsoundatposition("box_poof", box.origin);
		
		//move it into the sky
		box moveZ(5000, 4);
		wait 2;
		
		//and hide it
		if(!isDefined(level.misteryBoxIsRotu) || !level.misteryBoxIsRotu)
			box.lid hide();
		
		box hide();
		
		randomSurvivor = getRandomPlayer(game["defenders"]);
		randomSurvivor playSoundRef("special_box_move");
		
		//respawn at new pos
		thread startMisteryBox(60);
		return;
	}
}

calculateRandomWeapon()
{
	self endon("disconnect");
	self endon("death");

	random = randomInt(level.misteryWeapons.size);
	weapon = level.misteryWeapons[random];
	
	while(self hasWeapon(weapon.weaponName) || (level.misteryBoxOpenings <= 4 && weapon.weaponName == "teddy"))
	{
		random = randomInt(level.misteryWeapons.size);
		weapon = level.misteryWeapons[random];
	}

	return weapon;
}

makeMisteryWeaponGrabable(grabber, weaponModel)
{
	weaponModel endon("death");
	
	weaponModel.trigger = spawn("trigger_radius", weaponModel.origin, 0, 50, 50);
	
	while(isDefined(weaponModel.trigger))
	{
		weaponModel.trigger waittill("trigger", player);

		if(!isDefined(grabber) || !isPlayer(grabber))
			return;

		if(player != grabber)
			continue;

		if(!player isReadyToUse())
			continue;

		if(player UseButtonPressed())
		{
			while(player UseButtonPressed())
				wait .05;
		
			randomShout = randomInt(8);
			if(randomShout == 0)
				player playSoundRef("gen_weappick");
			else if(randomShout == 1)
			{
				switch(WeaponClass(self.weaponName))
				{
					case "mg":		player playSoundRef("weappick_mg");			break;
					case "spread":	player playSoundRef("weappick_shotgun");	break;
					case "rifle":	player playSoundRef("weappick_sniper");		break;
					case "grenade":	player playSoundRef("weappick_sticky");		break;
					case "pistol":
					default:		player playSoundRef("weappick_crappy");		break;
				}
			}

			player giveNewWeapon(self.weaponName);
			break;
		}
	}
	
	weaponModel playSoundRef("buy_item");
	weaponModel hide();
	wait .1;
	weaponModel delete();
}

deleteOverTime(time)
{
	self endon("death");
	
	wait (time - 1.5);
	self moveZ(-55, 1.5);	
	wait 1.5;
	
	self delete();
}

boxLidOpen()
{
	openAngle = 105;
	openTime = 0.5;

	self.lid RotatePitch(openAngle, openTime, (openTime * 0.5));

	playSoundAtPosition("open_chest", self.origin);
	playSoundAtPosition("music_chest", self.origin);
}

boxLidClose()
{
	closeAngle = -105;
	closeTime = 0.5;

	self.lid RotateTo(self.angles, closeTime, (closeTime * 0.5));
	playSoundAtPosition("close_chest", self.origin);
	
	wait (closeTime + 0.05);
}

createBoxSkylight()
{
	self endon("death");

	self.skylight = spawnFx(level._effect["misterybox_location_light"], self getTagOrigin("tag_content"));
	triggerFx(self.skylight, 0.1);
	
	while(isDefined(self.trigger))
		wait .1;
	
	self.skylight delete();
}