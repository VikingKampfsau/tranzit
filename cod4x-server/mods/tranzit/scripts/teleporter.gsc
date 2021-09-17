#include scripts\_include;

init()
{
	add_effect("transporter_ambient", "tranzit/teleporter/transporter_ambient");
	add_effect("transporter_beam", "tranzit/teleporter/transporter_beam");
	add_effect("transporter_pad_start", "tranzit/teleporter/transporter_pad_start");
	add_effect("transporter_start", "tranzit/teleporter/transporter_start");
	add_effect("transporter_flashback", "tranzit/teleporter/transporter_flashback");
	
	add_sound("beam_fx", "beam_fx");
	add_sound("beam_fx_front", "beam_fx_front");
	add_sound("beam_fx_link", "beam_fx_link");
	add_sound("mach_warm_l", "mach_warm_l");
	add_sound("mach_warm_r", "mach_warm_r");
	add_sound("mach_button", "mach_button");
	add_sound("teleport_flashback", "teleport_flashback");
	add_sound("teleport_flashback_in", "teleport_flashback_in");
	add_sound("teleport_flashback_out", "teleport_flashback_out");
	add_sound("top_spark", "top_spark");
	add_sound("tele_cooldown", "tele_cooldown");
	add_sound("tele_warmup", "tele_warmup");
}

teleportPlayer(targetPos, targetAngles, stationary)
{
	self endon("disconnect");
	self endon("death");

	if(!isDefined(stationary))
		stationary = false;

	//put the player in god mode
	self.godmode = true;
	
	//freeze the player
	self disableWeapons();
	self freezeControls(true);

	startPos = self.origin;

	//start the teleporter
	if(stationary)
	{
		if(isDefined(level.teleporterFxEnt))
			level.teleporterFxEnt delete();
			
		level.teleporterFxEnt = spawn("script_model", startPos);
		level.teleporterFxEnt setModel("tag_origin");
	
		level.teleporterFxEnt playSoundRef("mach_button");
		wait .7;	
		level.teleporterFxEnt playSoundRef("mach_warm_l");
		level.teleporterFxEnt playSoundRef("mach_warm_r");
		wait 2.5;
		level.teleporterFxEnt playSoundRef("tele_warmup");
		wait 2;
	}

	//link the teleporter pad
	PlayFx(level._effect["transporter_pad_start"], startPos);
	wait 2;

	//spawn an ent and link the player to it
	teleEnt = spawn("script_model", startPos);
	teleEnt setModel("tag_origin");
	teleEnt.angles = self.angles + (0,0,-90);
	self linkTo(teleEnt);
	wait .05;

	//start the teleport fx process
	self playSoundRef("top_spark");
	wait .8;
	self playSoundRef("beam_fx_link");
	PlayFxOnTag(level._effect["transporter_ambient"], teleEnt, "tag_origin");
	wait 2.7;

	//start the beam process
	PlayFx(level._effect["transporter_beam"], startPos);
	wait 1;
	
	//beam the player into space
	self hide(); 
	self unlink();
	teleEnt.origin = self getEye() + (0,0,20) + AnglesToForward(self getPlayerAngles())*65;
	self linkTo(teleEnt);
	teleEnt.origin = (0,0,-2000); //self setOrigin(targetPos);

	//leave an empty fx at startpos
	PlayFx(level._effect["transporter_start"], startPos);
	
	//start the flashback
	PlayFxOnTag(level._effect["transporter_flashback"], teleEnt, "tag_origin");
	self playSoundRef("teleport_flashback_in");
	wait 1.5;
	self playSoundRef("teleport_flashback");
	wait 3;
	self playSoundRef("teleport_flashback_out");
	wait .5;
	
	//beam the player to the final pos
	self show();
	self unlink();
	teleEnt delete();
	self setOrigin(targetPos);
	self playSoundRef("beam_fx");
	
	if(isDefined(targetAngles))
		self setPlayerAngles(targetAngles);	
		
	//remove godmode
	self.godmode = false;
	
	//unfreeze the player
	self enableWeapons();
	self freezeControls(false);
	
	if(stationary)
	{
		if(isDefined(level.teleporterFxEnt))
			level.teleporterFxEnt playSoundRef("tele_cooldown");
	}
}