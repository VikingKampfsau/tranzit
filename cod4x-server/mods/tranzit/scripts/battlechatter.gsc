#include scripts\_include;

init()
{
	add_sound("dog_killstreak", "dog_killstreak");
	add_sound("dog_spawn", "dog_spawn");
	add_sound("feedback_ammo_low", "feedback_ammo_low");
	add_sound("feedback_ammo_out", "feedback_ammo_out");
	add_sound("feedback_close", "feedback_close");
	add_sound("feedback_dmg_close", "feedback_dmg_close");
	add_sound("feedback_kill_explo", "feedback_kill_explo");
	add_sound("feedback_kill_flame", "feedback_kill_flame");
	add_sound("feedback_kill_headd", "feedback_kill_headd");
	add_sound("feedback_killstreak", "feedback_killstreak");
	add_sound("gen_incoming", "gen_incoming");
	add_sound("gen_incoming_dog", "gen_incoming_dog");
	add_sound("gen_incoming_zomb", "gen_incoming_zomb");
	add_sound("gen_kill", "gen_kill");
	add_sound("gen_laugh", "gen_laugh");
	add_sound("gen_meteor", "gen_meteor");
	add_sound("gen_move", "gen_move");
	add_sound("gen_nomoney_box", "gen_nomoney_box");
	add_sound("gen_nomoney_perk", "gen_nomoney_perk");
	add_sound("gen_nomoney_weapon", "gen_nomoney_weapon");
	add_sound("gen_pain", "gen_pain");
	add_sound("gen_perk_dbltap", "gen_perk_dbltap");
	add_sound("gen_perk_jugga", "gen_perk_jugga");
	add_sound("gen_perk_revive", "gen_perk_revive");
	add_sound("gen_perk_speed", "gen_perk_speed");
	add_sound("gen_rebuild_board", "gen_rebuild_board");
	add_sound("gen_reload", "gen_reload");
	add_sound("gen_sigh", "gen_sigh");
	add_sound("gen_teamwork", "gen_teamwork");
	add_sound("gen_weappick", "gen_weappick");
	add_sound("perk_dbltap", "perk_dbltap");
	add_sound("perk_jugga", "perk_jugga");
	add_sound("perk_revive", "perk_revive");
	add_sound("perk_speed", "perk_speed");
	add_sound("powerup_ammo", "powerup_ammo");
	add_sound("powerup_double", "powerup_double");
	add_sound("powerup_insta", "powerup_insta");
	add_sound("powerup_nuke", "powerup_nuke");
	add_sound("revive_down_gen", "revive_down_gen");
	add_sound("revive_revived", "revive_revived");
	add_sound("special_box_move", "special_box_move");
	add_sound("special_melee_insta", "special_melee_insta");
	add_sound("weappick_crappy", "weappick_crappy");
	add_sound("weappick_flame", "weappick_flame");
	add_sound("weappick_mg", "weappick_mg");
	add_sound("weappick_raygun", "weappick_raygun");
	add_sound("weappick_shotgun", "weappick_shotgun");
	add_sound("weappick_sniper", "weappick_sniper");
	add_sound("weappick_sticky", "weappick_sticky");
	add_sound("weappick_tesla", "weappick_tesla");
}

monitorPlayerAmmo()
{
	self endon("disconnect");
	self endon("death");

	self thread reloadTracking();

	self.ammoLow = false;
	self.ammoOut = false;

	while(1)
	{
		wait .1;
	
		weap = self getCurrentWeapon();
			
		if(!isDefined(weap) || weap == "none")
			continue;
		
		if(weap == getWeaponFromCustomName("fists"))
			continue;
		
		if(weap == getWeaponFromCustomName("perksacola"))
			continue;
			
		if(weap == getWeaponFromCustomName("syrette"))
			continue;
			
		if(weap == getWeaponFromCustomName("knucklecrack"))
			continue;
			
		if(weap == getWeaponFromCustomName("knife"))
			continue;
			
		if(weap == getWeaponFromCustomName("katana"))
			continue;
			
		if(weap == getWeaponFromCustomName("player_death"))
			continue;
			
		if(weap == getWeaponFromCustomName("weapondrop"))
			continue;
			
		if(weap == getWeaponFromCustomName("player_dwarf_attacking"))
			continue;
			
		if(weap == getWeaponFromCustomName("location_selector"))
			continue;
			
		if(isDefined(self.actionSlotItem) && weap == self.actionSlotItem)
			continue;

		if(self isInLastStand())				
			continue;

		if(self GetAmmoCount(weap) > 10)
		{
			self.ammoLow = false;
			self.ammoOut = false;
		}
		else
		{
			if(self GetAmmoCount(weap) > 0 && !self.ammoLow)
			{
				if(!isOtherExplosive(weap) && !isHardpointWeapon(weap))
				{
					self.ammoLow = true;
					self thread shoutLowAmmo();
				}

				continue;
			}

			if(self GetAmmoCount(weap) == 0 && !self.ammoOut)
			{	
				self.ammoOut = true;
				self thread shoutNoAmmo(weap);	
				continue;
			}
		}
	}	
}

shoutLowAmmo()
{
	self playSoundRef("feedback_ammo_low");
}

shoutNoAmmo(weap)
{
	self endon( "disconnect" );

	// Let's pause here a couple of seconds to see if we're really out of ammo.
	// If you take a weapon, there's a second or two where your current weapon
	// will be set to no ammo while you switch to the new one.
	wait 2;

	curr_weap = self getCurrentWeapon();
	if(!isDefined(curr_weap) || curr_weap != weap || self GetAmmoCount(curr_weap) != 0)
		return;

	self playSoundRef("feedback_ammo_out");
}

reloadTracking()
{
	self endon("death");
	self endon("disconnect");

	while(1)
	{
		self waittill("reload_start");
		
		if(!randomInt(10) && level.playerCount["allies"] > 1)
			self playSoundRef("gen_reload");
	}
}