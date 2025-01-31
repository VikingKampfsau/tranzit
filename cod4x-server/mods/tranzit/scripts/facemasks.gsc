#include scripts\_include;

init()
{
	precacheModel("viewmodel_hands_bare_nvg");
	precacheModel("face_accessories_gasmask");
	
	precacheShader("nightvision_overlay_goggles");
	precacheShader("hud_overlay_gasmask_0");
	precacheShader("hud_overlay_gasmask_1");
	precacheShader("hud_overlay_gasmask_2");
	precacheShader("hud_overlay_gasmask_3");
	precacheShader("hud_overlay_gasmask_4");
	precacheShader("hud_overlay_gasmask_5");

	thread createFacemaskPickups();
}

createFacemaskPickups()
{
	facemaskPickups = getEntArray("facemask", "targetname");
	
	if(!isDefined(facemaskPickups) || !facemaskPickups.size)
		return;
	
	for(i=0;i<facemaskPickups.size;i++)
	{
		visuals[0] = getEnt(facemaskPickups[i].target, "targetname");
		
		level.facemaskPickups[i] = maps\mp\gametypes\_gameobjects::createUseObject(game["defenders"], facemaskPickups[i], visuals, (0,0,64), false);
		level.facemaskPickups[i] maps\mp\gametypes\_gameobjects::allowUse("friendly");
		level.facemaskPickups[i] maps\mp\gametypes\_gameobjects::setUseTime(0);
		level.facemaskPickups[i] maps\mp\gametypes\_gameobjects::setUseHintText("FACEMASK_PICKUP_PRESS_USE");
		level.facemaskPickups[i] maps\mp\gametypes\_gameobjects::setVisibleTeam("friendly");
		
		level.facemaskPickups[i].onUse = ::onUsedCraftingtable;
		
		level.facemaskPickups[i].useWeapon = undefined;
	}
}

onUsedCraftingtable(player)
{
	player thread pickUpFaceMask(self.visuals[0].target);
}

pickUpFaceMask(type)
{
	self endon("disconnect");

	if(!isDefined(type) || (type != "nvg" && type != "gas"))
		return;

	if(isDefined(self.facemask.type) && self.facemask.type != type)
	{
		if(isDefined(self.facemask.active) && self.facemask.active)
		{
			self iPrintLnBold(self getLocTextString("FACEMASK_ALREADY_WEARING_DIFFERENT_TYPE"));
			return;
		}
	}

	self.facemask.type = type;
	self setClientDvar("facemask", type);
}

toggleFacemask()
{
	self endon("disconnect");
	
	if(!isDefined(self.facemask.type) || (self.facemask.type != "nvg" && self.facemask.type != "gas"))
		return;
		
	if(isDefined(self.isTogglingMask) && self.isTogglingMask)
		return;
	
	action = "takeoff";
	if(!isDefined(self.facemask.active) || !self.facemask.active)
		action = "puton";
	
	self.isTogglingMask = true;
	self playMaskAnim(action);
	self.isTogglingMask = false;
}

playMaskAnim(action)
{
	self endon("disconnect");
	
	if(!isDefined(action))
		action = "puton";
		
	self setViewModel("viewmodel_hands_bare_nvg");

	if(action == "puton")
	{
		self forceViewmodelAnimation("nvg_puton");

		if(isDefined(self.maskToggleBg))
			self.maskToggleBg destroy();

		self.maskToggleBg = newClientHudElem(self);
		self.maskToggleBg.sort = -1;
		self.maskToggleBg.alignX = "left";
		self.maskToggleBg.alignY = "top";
		self.maskToggleBg.x = 0;
		self.maskToggleBg.y = 0;
		self.maskToggleBg.horzAlign = "fullscreen";
		self.maskToggleBg.vertAlign = "fullscreen";
		self.maskToggleBg.foreground = false;
		self.maskToggleBg setShader("black", 640, 480);
		self.maskToggleBg.alpha = 0;
		self.maskToggleBg fadeOverTime(0.8);
		self.maskToggleBg.alpha = 1;
		wait 0.8; 
		self.maskToggleBg.alpha = 0;
		
		self.facemask.active = true;
		
		self thread updatePlayerVision();
		self thread	createMaskOverlay();
		
		if(!self hasAttached("face_accessories_gasmask"))
			self attach("face_accessories_gasmask", "j_head");
	}
	else
	{
		self notify("stop_mask_damage_monitor");
		
		self forceViewmodelAnimation("nvg_takeoff");
		
		self thread resetPlayerVision();
		
		if(isDefined(self.maskOverlay))
			self.maskOverlay destroy();
	
		if(isDefined(self.maskToggleBg))
			self.maskToggleBg destroy();
		
		self.maskToggleBg = newClientHudElem(self);
		self.maskToggleBg.sort = -1;
		self.maskToggleBg.alignX = "left";
		self.maskToggleBg.alignY = "top";
		self.maskToggleBg.x = 0;
		self.maskToggleBg.y = 0;
		self.maskToggleBg.horzAlign = "fullscreen";
		self.maskToggleBg.vertAlign = "fullscreen";
		self.maskToggleBg.foreground = false;
		self.maskToggleBg setShader("black", 640, 480);
		self.maskToggleBg.alpha = 1;
		self.maskToggleBg fadeOverTime(0.6);
		self.maskToggleBg.alpha = 0;
		wait 0.6;
		
		self.facemask.active = false;
		
		if(self hasAttached("face_accessories_gasmask"))
			self detach("face_accessories_gasmask", "j_head");
	}
	
	if(isDefined(self.maskToggleBg))
		self.maskToggleBg destroy();
	
	self setViewModel("viewmodel_hands_bare");
}

createMaskOverlay()
{
	self endon("disconnect");
	self endon("death");

	if(isDefined(self.maskOverlay))
		self.maskOverlay destroy();

	self.maskOverlay = newClientHudElem(self);
	self.maskOverlay.sort = -1;
	self.maskOverlay.alignX = "left";
	self.maskOverlay.alignY = "top";
	self.maskOverlay.x = 0;
	self.maskOverlay.y = 0;
	self.maskOverlay.horzAlign = "fullscreen";
	self.maskOverlay.vertAlign = "fullscreen";
	self.maskOverlay.foreground = false;
	self.maskOverlay.alpha = 1;

	if(!isDefined(self.facemask.damageState))
		self.facemask.damageState = 0;

	if(self.facemask.type == "nvg")
	{
		self.facemask.damageState = 0;
		self.maskOverlay setShader("nightvision_overlay_goggles", 640, 480);
	}
	else if(self.facemask.type == "gas")
	{
		self.maskOverlay setShader("hud_overlay_gasmask_" + self.facemask.damageState, 640, 480);
		self thread monitorMaskDamage();
	}
}

monitorMaskDamage()
{
	self endon("disconnect");
	self endon("death");

	self notify("stop_mask_damage_monitor");
	self endon("stop_mask_damage_monitor");

	if(!self.facemask.active)
		return;

	while(self.facemask.active)
	{
		self waittill("damage", amount, attacker, vDir, vPoint, sMeansOfDeath);
	
		if(isPlayer(attacker))
		{
			//do not inflict damage from self or team, unless it's explosive damage
			if(attacker isInSameTeamAs(self) || attacker == self)
			{
				if(!isDefined(sMeansOfDeath))
					continue;
			
				if(!isSubStr(sMeansOfDeath, "MOD_EXPLOSIVE") && !isSubStr(sMeansOfDeath, "MOD_PROJECTILE"))
					continue;
			}
			
			self.facemask.damageState++;
			
			if(self.facemask.type == "gas")
			{
				if(self.facemask.damageState <= 5)
					self.maskOverlay setShader("hud_overlay_gasmask_" + self.facemask.damageState, 640, 480);
				else
				{
					self.facemask.active = false;
					self.facemask.damageState = undefined;
				}
			}
		}
	}

	if(isDefined(self.maskOverlay))
		self.maskOverlay destroy();
		
	if(self hasAttached("face_accessories_gasmask"))
		self detach("face_accessories_gasmask", "j_head");
		
	self setClientDvar("facemask", "");
}

resetPlayerVision()
{
	self endon("disconnect");

	if(isDefined(self.facemask))
	{
		//removed sounds from weapon file to make it not play for gas masks
		//so this is required
		if(self.facemask.type == "nvg")
			self playLocalSound("item_nightvision_power_off");
		else if(self.facemask.type == "gas")
			self playLocalSound("nightvision_remove_plr_default");
	}

	self setClientDvars(
		"r_filmTweakInvert", 0,
		"r_filmTweakBrightness", 0,
		"r_filmTweakDarkTint", "1.8 1.8 2",
		"r_filmtweakLighttint", "0.8 0.8 1",
		"r_filmTweakContrast", 1.2,
		"r_filmTweakDesaturation", 0,
		"r_filmTweakenable", 1,
		"r_FilmUseTweaks", 1);
}

updatePlayerVision()
{
	self endon("disconnect");

	if(self.facemask.type == "nvg")
	{
		//removed sounds from weapon file to make it not play for gas masks
		//so this is required
		self playLocalSound("item_nightvision_power_on");
	
		self setClientDvars(
			"r_FilmTweakInvert", "0",
			"r_FilmTweakBrightness", "0.26",
			"r_FilmTweakDarktint", "0 1.54321 0.000226783",
			"r_FilmTweakLighttint", "1.5797 1.9992 2.0000", 
			"r_FilmTweakContrast", "1.63",
			"r_FilmTweakDesaturation", "1",
			"r_FilmTweakEnable", "1",
			"r_FilmUseTweaks", "1");
	}
	else if(self.facemask.type == "gas")
	{
		self playLocalSound("nightvision_wear_plr_default");
	}
}