#include scripts\_include;

init()
{
	precacheModel("zombie_vending_ammo");

	thread loadAmmoboxes();
}

loadAmmoboxes()
{
	level.ammoBoxes = getEntArray("ammobox", "targetname");
	
	//no ammoBoxes found - check for rotu map
	if(!isDefined(level.ammoBoxes) || !level.ammoBoxes.size)
	{
		wait 2;
		
		if(isDefined(level.rotuAmmoBoxName))
			level.ammoBoxes = getEntArray(level.rotuAmmoBoxName, "targetname");
	}

	//nothing found - return
	if(!isDefined(level.ammoBoxes) || !level.ammoBoxes.size)
		return;

	for(i=0;i<level.ammoBoxes.size;i++)
		level.ammoBoxes[i] thread initAmmoBox();
}

initAmmoBox()
{
	self endon("death");

	self setModel("zombie_vending_ammo");
	self hidePart("tag_ammobox_lid", self.model);
	
	if(!isDefined(self.lid))
	{
		self.lid = spawn("script_model", (0,0,0));
		self.lid setModel("zombie_vending_ammo");
	}
	
	self.lid.origin = self getTagOrigin("tag_ammobox_hinge");
	self.lid.angles = self.angles;
	
	self.lid hidePart("tag_crates", self.lid.model);
	self.lid hidePart("tag_ammobox", self.lid.model);
	self.lid hidePart("tag_ammobox_content", self.lid.model);
	self.lid hidePart("tag_ammobox_hinge", self.lid.model);
	self.lid showPart("tag_ammobox_lid", self.lid.model);
	self.lid unlink();
	
	self.isInUse = false;
	self.trigger = spawn("trigger_radius", self.origin, 0, 75, 50);
	
	while(isDefined(self.trigger))
	{
		self.trigger waittill("trigger", player);

		if(self.isInUse)
			continue;

		if(!player isReadyToUse())
			continue;

		player thread showTriggerUseHintMessage(self.trigger, player getLocTextString("MISTERYBOX_OPEN_PRESS_BUTTON"), scripts\money::getPrice("ammobox"));

		if(!player scripts\money::hasEnoughMoney("ammobox"))
			continue;

		if(player UseButtonPressed())
		{
			if(!player hasMaxAmmo())
			{
				self.isInUse = true;
				self.trigger.origin = self.origin - (0,0,10000);
				
				self thread sellAmmo(player);
			}
		}
	}
}

sellAmmo(player)
{
	self endon("death");

	player thread [[level.onXPEvent]]("ammobox");

	self ammoboxLidOpen();
	
	if(isDefined(player) && isAlive(player))
	{
		self ThrowOutAmmo(player.origin);

		if(isDefined(player) && isAlive(player))
		{
			player playSound("mp_bomb_defuse");
			player PlaySoundRef("full_ammo");
			player GiveAmmoForAllWeapons();
		}
	}

	wait .5;

	self ammoboxLidClose();
	
	self.isInUse = false;
	self.trigger.origin = self.origin;
}

ThrowOutAmmo(targetPos)
{
	self endon("death");

	targetPos = targetPos + (0,0,54);

	clipModel = spawn("script_model", (0,0,0));
	clipModel setModel("buildable_turret_ammo_box");
	clipModel.origin = self getTagOrigin("tag_ammobox_content");
	clipModel.angles = (0, randomInt(360), 0);

	totalTime = clipModel fake_physicslaunch(targetPos, 250);
	
	wait totalTime;
	
	if(isDefined(clipModel))
		clipModel delete();
}

ammoboxLidOpen()
{
	self endon("death");

	openAngle = -105;
	openTime = 0.7;

	self.lid RotateRoll(openAngle, openTime, (openTime * 0.5));

	playSoundAtPosition("open_chest", self.origin);
	
	wait openTime;
}

ammoboxLidClose()
{
	self endon("death");

	closeAngle = -105;
	closeTime = 0.3;

	self.lid RotateTo(self.angles, closeTime, (closeTime * 0.5));
	playSoundAtPosition("close_chest", self.origin);
	
	wait (closeTime + 0.05);
}