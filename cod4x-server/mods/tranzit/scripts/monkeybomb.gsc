#include scripts\_include;

init()
{
	add_sound("monkey_jingle", "monk_jingle");
	add_sound("monkey_explo_vox", "monkey_explo_vox");

	add_effect("monkeybomb_groundPop", "impacts/brickimpact_em2");
	//add_effect("monkeybomb_devileyes", "misc/aircraft_light_cockpit_red");
	add_effect("monkeybomb_devileyes", "tranzit/zombie/human_eye_glow");
}

zombieCloseToMonkeyBomb()
{
	self endon("disconnect");
	self endon("death");

	grenades = getEntArray("grenade", "classname");
	for(i=0;i<grenades.size;i++)
	{
		if(Distance(self.origin, grenades[i].origin) > 1000)
			continue;
	
		if(isDefined(grenades[i].attractsZombies) && grenades[i].attractsZombies)
		{
			if(self isInMonkeyBombRadius(grenades[i]))
				return grenades[i].fake_monkey;
		}
	}
	
	return undefined;
}

isInMonkeyBombRadius(grenade)
{
	if(!isDefined(grenade.fake_monkey))
		return false;

	if(Distance(self.origin, grenade.fake_monkey.origin) > 1536)
		return false;
	
	if(self damageConeTrace(grenade.fake_monkey.origin, grenade.fake_monkey) <= 0)
		return false;
	
	return true;
}

startMonkeyBomb()
{
	self endon("death");

	self waitTillNotMoving();
	
	self.fake_monkey = spawn("script_model", self.origin);
	self.fake_monkey.parent = self;
	self.fake_monkey.angles = self.angles;
	self.fake_monkey setModel(self.model);	
	self.fake_monkey playLoopSoundRef("monkey_jingle");
	
	playFxOnTag(level._effect["monkeybomb_devileyes"], self.fake_monkey, "j_eye_l");
	playFxOnTag(level._effect["monkeybomb_devileyes"], self.fake_monkey, "j_eye_r");
	
	self.originalOrigin = self.origin;
	self.origin = self.origin - (0,0,10000);
	self hide();
	
	self.attractsZombies = true;
	
	modelHeight = 16;
	jumpSpeed = 130;
	dropSpeed = 200;
	totalTime = 0;

	for(i=1;i<=7;i++)
	{
		jumpHeight = RandomIntRange(20, 35);

		trace = BulletTrace(self.fake_monkey.origin,  self.fake_monkey.origin + (0,0,jumpHeight + modelHeight), false, self.fake_monkey);
		
		if(trace["fraction"] != 1)
		{
			blockedJumpHeight = Distance(self.fake_monkey.origin, trace["position"]) - modelHeight;
			
			if(blockedJumpHeight <= modelHeight)
			{
				wait 1;
				continue;
			}
			
			jumpHeight = blockedJumpHeight;
		}

		jumpTime = jumpHeight / jumpSpeed;
		dropTime = jumpHeight / dropSpeed;
		
		PlayFX(level._effect["monkeybomb_groundPop"], self.fake_monkey.origin + (0,0,10));
		
		self.fake_monkey MoveTo(self.fake_monkey.origin + (0,0,jumpHeight), jumpTime, 0, jumpTime * 0.8);
		self.fake_monkey waittill("movedone");

		wait .1;

		self.fake_monkey MoveTo(self.fake_monkey.origin - (0, 0, jumpHeight), dropTime, dropTime * 0.5);
		self.fake_monkey waittill("movedone");
		
		totalTime = totalTime + jumpTime + dropTime + 0.1;
		
		if(totalTime >= 7)
			break;
		
		wait 1;
	}

	self.fake_monkey stopLoopSound("monkey_jingle");
	self.fake_monkey delete();
	
	self.origin = self.originalOrigin;
	self show();

	wait 0.3;
	self playSoundRef("monkey_explo_vox");
	wait 1.3;

	self detonate();
}

waitTillNotMoving()
{
	prevorigin = self.origin;
	while(1)
	{
		wait .15;
		if ( self.origin == prevorigin )
			break;
		prevorigin = self.origin;
	}
}