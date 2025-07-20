#include scripts\_include;

init()
{
	add_weapon("knucklecrack", "saw_reflex_mp", false);

	add_weapon("riotshield", "flash_grenade_mp", false);
	add_weapon("sentrygun", "artillery_mp", false);
	add_weapon("monkeybomb", "frag_grenade_short_mp", false);
	add_weapon("generator", "radar_mp", false);
	add_weapon("wavegun", "ak74u_reflex_mp", true);
	add_weapon("wavegun_ug", "ak74u_acog_mp", true);

	precacheShader("hud_icon_buildable_ammobox");
	precacheShader("hud_icon_buildable_mower");
	precacheShader("hud_icon_buildable_rpd");

	precacheShader("hud_icon_buildable_monkey");
	precacheShader("hud_icon_buildable_hat");
	precacheShader("hud_icon_buildable_tnt");

	precacheShader("hud_icon_generator");
	precacheShader("hud_icon_buildable_pipe");

	precacheShader("hud_icon_buildable_dolly");
	precacheShader("hud_icon_buildable_car_door");

	precacheShader("hud_icon_buildable_wavegun_pistol");
	precacheShader("hud_icon_buildable_wavegun_barrel");
	precacheShader("hud_icon_buildable_wavegun_clip");

	precacheShader("hud_icon_sentrygun_zm");
	precacheShader("hud_icon_monkey");
	precacheShader("hud_icon_generator");
	precacheShader("hud_icon_riot_shield_zm");

	precacheModel("buildable_turret_complete");
	precacheModel("buildable_monkeybomb_complete");
	precacheModel("buildable_generator_complete");
	precacheModel("buildable_riotshield_complete");
	precacheModel("buildable_wavegun_complete");

	level.craftingTime = 3;

	createBuildablePickups();
	createBuildableCraftingTables();
}

getPickupModels(type)
{
	models = [];
	switch(type)
	{
		case "sentrygun":
			models[0] = "buildable_turret_mower";
			models[1] = "buildable_turret_rpd";
			models[2] = "buildable_turret_ammo_box";
			break;
		case "monkeybomb":
			models[0] = "buildable_monkeybomb_hat";
			models[1] = "buildable_monkeybomb_monkey";
			models[2] = "buildable_monkeybomb_tnt";
			break;
		case "generator":
			models[0] = "buildable_generator_gascan";
			models[1] = "buildable_generator_generator";
			models[2] = "buildable_generator_pipe";
			break;
		case "riotshield":
			models[0] = "buildable_riotshield_dolly";
			models[1] = "buildable_riotshield_door";
			break;
		case "wavegun":
			models[0] = "buildable_wavegun_pistol";
			models[1] = "buildable_wavegun_barrel";
			models[2] = "buildable_wavegun_clip";
			break;
		default: 
			models[0] = "tag_origin";
			break;
	}
	
	return models;
}

getBaseTagForModelPart(model)
{
	switch(model)
	{
		case "buildable_turret_ammo_box": return "tag_ammo_box";
		case "buildable_turret_mower": return "tag_mower";
		case "buildable_turret_rpd": return "tag_rpd";
		
		case "buildable_monkeybomb_hat": return "j_hat";
		case "buildable_monkeybomb_monkey": return "tag_origin";
		case "buildable_monkeybomb_tnt": return "j_tnt";
		
		case "buildable_generator_gascan": return "j_gascan";
		case "buildable_generator_generator": return "j_generator";
		case "buildable_generator_pipe": return "j_pipe";
		
		case "buildable_riotshield_dolly": return "tag_dolly";
		case "buildable_riotshield_door": return "tag_door";
		
		case "buildable_wavegun_pistol": return "tag_weapon";
		case "buildable_wavegun_barrel": return "tag_barrel";
		case "buildable_wavegun_clip": return "tag_clip";
				
		case "buildable_turret_complete":
		case "buildable_monkeybomb_complete":
		case "buildable_generator_complete":
		case "buildable_riotshield_complete":
		case "buildable_wavegun_complete":
		default: return "tag_origin";
	}
}

getCarryIconFromModel(model)
{
	switch(model)
	{
		case "buildable_turret_ammo_box": return "hud_icon_buildable_ammobox";
		case "buildable_turret_mower": return "hud_icon_buildable_mower";
		case "buildable_turret_rpd": return "hud_icon_buildable_rpd";
		
		case "buildable_monkeybomb_hat": return "hud_icon_buildable_hat";
		case "buildable_monkeybomb_monkey": return "hud_icon_buildable_monkey";
		case "buildable_monkeybomb_tnt": return "hud_icon_buildable_tnt";
		
		case "buildable_generator_gascan": return "hud_icon_generator";
		case "buildable_generator_generator": return "hud_icon_generator";
		case "buildable_generator_pipe": return "hud_icon_buildable_pipe";
		
		case "buildable_riotshield_dolly": return "hud_icon_buildable_dolly";
		case "buildable_riotshield_door": return "hud_icon_buildable_car_door";
		
		case "buildable_wavegun_pistol": return "hud_icon_buildable_wavegun_pistol";
		case "buildable_wavegun_barrel": return "hud_icon_buildable_wavegun_barrel";
		case "buildable_wavegun_clip": return "hud_icon_buildable_wavegun_clip";
		
		case "buildable_turret_complete": return "hud_icon_sentrygun_zm";
		case "buildable_monkeybomb_complete": return "hud_icon_monkey";
		case "buildable_generator_complete": return "hud_icon_generator";
		case "buildable_riotshield_complete": return "hud_icon_riot_shield_zm";
		
		default: return "";
	}
}

createBuildablePickups()
{
	level.buildables = [];
	possibleBuildables = [];
	buildable_parts = getEntArray("buildable_part", "targetname");
	
	if(!isDefined(buildable_parts) || !buildable_parts.size)
		return;
	
	for(i=0;i<buildable_parts.size;i++)
	{
		visuals[0] = getEnt(buildable_parts[i].target, "targetname");
	
		level.buildables[i] = maps\mp\gametypes\_gameobjects::createCarryObject(game["defenders"], buildable_parts[i], visuals, (0,0,32), false);
		level.buildables[i] maps\mp\gametypes\_gameobjects::allowCarry("friendly");
		level.buildables[i] maps\mp\gametypes\_gameobjects::setVisibleTeam("friendly");
		level.buildables[i] maps\mp\gametypes\_gameobjects::setUseHintText("CRAFTABLE_PICKUP_PRESS_USE");
		level.buildables[i] maps\mp\gametypes\_gameobjects::enableObject();
		level.buildables[i].allowWeapons = true;
		level.buildables[i].partType = visuals[0].target;
		//level.buildables[i].onPickupFailed = ::onPartPickupFailed;
		
		if(!isDefined(possibleBuildables[level.buildables[i].partType]))
			possibleBuildables[level.buildables[i].partType] = [];
		
		possibleBuildables[level.buildables[i].partType][possibleBuildables[level.buildables[i].partType].size] = level.buildables[i];
	}
	
	curType = strToK("sentrygun,monkeybomb,generator,riotshield,wavegun", ",");
	
	//loop through all of them and randomize the activation
	for(i=0;i<curType.size;i++)
	{
		if(!isDefined(possibleBuildables[curType[i]]) || possibleBuildables[curType[i]].size <= 0)
			continue;
	
		backup = possibleBuildables[curType[i]];
	
		possibleBuildables[curType[i]] = shuffleArray(possibleBuildables[curType[i]]);
		buildablePickupModels = getPickupModels(curType[i]);
		
		for(j=0;j<possibleBuildables[curType[i]].size;j++)
		{
			//consolePrint(curType[i] + " part " + j + " (" + possibleBuildables[curType[i]][j].visuals[0].model + ") at " + possibleBuildables[curType[i]][j].visuals[0].origin + "\n");
		
			if(j >= buildablePickupModels.size)
				possibleBuildables[curType[i]][j].visuals[0] setModel(buildablePickupModels[0]);
			else
			{
				possibleBuildables[curType[i]][j].visuals[0] setModel(buildablePickupModels[j]);
				
				//restore the correct angle for the new model
				for(k=0;k<backup.size;k++)
				{
					//consolePrint(possibleBuildables[curType[i]][j].visuals[0].model + " " + backup[k].visuals[0].model +"\n");
				
					if(possibleBuildables[curType[i]][j].visuals[0].model == backup[k].visuals[0].model)
					{
						//consolePrint("changing angle for " + backup[k].visuals[0].model + " from " + possibleBuildables[curType[i]][j].visuals[0].angles + " to " + backup[k].visuals[0].angles +"\n");
						possibleBuildables[curType[i]][j].visuals[0].angles = backup[k].visuals[0].angles;
						break;
					}
				}
			}
			
			possibleBuildables[curType[i]][j] maps\mp\gametypes\_gameobjects::setCarryIcon(getCarryIconFromModel(possibleBuildables[curType[i]][j].visuals[0].model));
		
			if(j >= buildablePickupModels.size)
				possibleBuildables[curType[i]][j] maps\mp\gametypes\_gameobjects::disableObject();
		}
	}
}

onPartPickupFailed(player)
{
	player iPrintLnBold(player getLocTextString("CRAFTABLE_PICKUP_FAIL_ALREADY_CARRY"));
}

createBuildableCraftingTables()
{
	level.craftingTables = [];
	craftingTables = getEntArray("craftingTable", "targetname");
	
	if(!isDefined(craftingTables) || !craftingTables.size)
		return;
	
	for(i=0;i<craftingTables.size;i++)
	{
		visuals[0] = getEnt(craftingTables[i].target, "targetname");
		
		level.craftingTables[i] = maps\mp\gametypes\_gameobjects::createUseObject(game["defenders"], craftingTables[i], visuals, (0,0,64), false);
		level.craftingTables[i] maps\mp\gametypes\_gameobjects::allowUse("friendly");
		level.craftingTables[i] maps\mp\gametypes\_gameobjects::setUseTime(level.craftingTime);
		level.craftingTables[i] maps\mp\gametypes\_gameobjects::setUseText("CRAFTABLE_CRAFTING");
		level.craftingTables[i] maps\mp\gametypes\_gameobjects::setUseHintText("CRAFTABLE_CRAFTING_PRESS_USE");
		level.craftingTables[i] maps\mp\gametypes\_gameobjects::setVisibleTeam("friendly");
		
		level.craftingTables[i].onCantUse = ::onCantUseCraftingtable;
		level.craftingTables[i].onBeginUse = ::onBeginUseCraftingtable;
		level.craftingTables[i].onUse = ::onUsedCraftingtable;
		
		level.craftingTables[i].useWeapon = getWeaponFromCustomName("knucklecrack"); //undefined;
		level.craftingTables[i].crafted_parts = 0;
		level.craftingTables[i].partType = visuals[0].target;
		
		level.craftingTables[i].debugTxt = "craftingTables";
		
		for(j=0;j<level.buildables.size;j++)
		{
			if(level.buildables[j].partType == level.craftingTables[i].partType)
				level.craftingTables[i] maps\mp\gametypes\_gameobjects::setKeyObject(level.buildables[j]);
		}
	}
}

onCantUseCraftingtable(player)
{
	player iPrintLnBold(player getLocTextString("CRAFTABLE_CRAFTING_NO_PARTS"));
}

onBeginUseCraftingtable(player)
{
	player playSound("mp_bomb_plant");
	
	/*knucklecrackWeapon = getWeaponFromCustomName("knucklecrack");
	self giveWeapon(knucklecrackWeapon);
	self giveMaxAmmo(knucklecrackWeapon);
	self SwitchToNewWeapon(knucklecrackWeapon, .05);
	wait 2.1; //raise anim time
	player takeWeapon(knucklecrackWeapon);
	player SwitchToPreviousWeapon();*/
}

onUsedCraftingtable(player)
{
	//finished crafting
	self.crafted_parts++;
	
	thread scripts\statistics::incStatisticValue("parts_found", 2410, 1);
	
	//spawn full model on the table
	if(!isDefined(self.craftedPartModel))
		self.craftedPartModel = [];
	
	newId = self.craftedPartModel.size;
	self.craftedPartModel[newId] = spawn("script_model", self.visuals[0] getTagOrigin("tag_table_content"));
	self.craftedPartModel[newId].angles = self.visuals[0].angles;
	
	if(self.partType == "sentrygun")
		self.craftedPartModel[newId] setModel("buildable_turret_complete");
	else
		self.craftedPartModel[newId] setModel("buildable_" + self.partType + "_complete");
	
	//get the name of the tag of the part the player wants to add
	partBaseTag = getBaseTagForModelPart(player.carryObject.visuals[0].model);
	self.craftedPartModel[newId].origin = self.craftedPartModel[newId] getTagOrigin(partBaseTag);
	
	//reset the model and use the one the player added
	self.craftedPartModel[newId] setModel(player.carryObject.visuals[0].model);
	
	//take the carryObject from the player
	carryObject = player.carryObject;
	carryObject maps\mp\gametypes\_gameobjects::allowCarry("none");
	carryObject maps\mp\gametypes\_gameobjects::setVisibleTeam("none");
	carryObject maps\mp\gametypes\_gameobjects::setDropped();
	carryObject maps\mp\gametypes\_gameobjects::disableObject();
	carryObject maps\mp\gametypes\_gameobjects::setModelVisibility(false);
	
	modelParts = getPickupModels(carryObject.partType);
	if(self.crafted_parts >= modelParts.size)
		self thread createCraftedWeaponPickup();
}	

createCraftedWeaponPickup()
{
	thread scripts\statistics::incStatisticValue("items_crafted", 2411, 1);

	self maps\mp\gametypes\_gameobjects::disableObject();

	wait .1;

	if(!isDefined(level.craftedWeaponPickup))
		level.craftedWeaponPickup = [];
	
	newId = level.craftedWeaponPickup.size;
	trigger = self.trigger;
	visuals = self.craftedPartModel;
	
	level.craftedWeaponPickup[newId] = maps\mp\gametypes\_gameobjects::createUseObject(game["defenders"], trigger, visuals, (0,0,64), false);
	level.craftedWeaponPickup[newId] maps\mp\gametypes\_gameobjects::setModelVisibility(true);
	level.craftedWeaponPickup[newId] maps\mp\gametypes\_gameobjects::setVisibleTeam("friendly");
	level.craftedWeaponPickup[newId] maps\mp\gametypes\_gameobjects::allowUse("friendly");
	level.craftedWeaponPickup[newId] maps\mp\gametypes\_gameobjects::setUseHintText("CRAFTABLE_OBJECT_PICKUP_PRESS_USE");
	level.craftedWeaponPickup[newId] maps\mp\gametypes\_gameobjects::setUseTime(0);
	level.craftedWeaponPickup[newId] maps\mp\gametypes\_gameobjects::setUseText("");
	level.craftedWeaponPickup[newId] maps\mp\gametypes\_gameobjects::enableObject();

	level.craftedWeaponPickup[newId].onBeginUse = ::onBeginUseCraftedWeaponPickup;
	level.craftedWeaponPickup[newId].onUse = ::onUsedCraftedWeaponPickup;
	
	level.craftedWeaponPickup[newId].craftedItem = getWeaponFromCustomName(self.partType);
	level.craftedWeaponPickup[newId].partType = self.partType;
	
	level.craftedWeaponPickup[newId].debugTxt = "craftedWeaponPickup";
}

onBeginUseCraftedWeaponPickup(player)
{
	//player playSound("mp_bomb_plant");
}

onUsedCraftedWeaponPickup( player )
{
	if(isDefined(player.actionSlotItem))
	{
		if(player.actionSlotItem == self.craftedItem)
			player iPrintLnBold(player getLocTextString("CRAFTABLE_OBJECT_PICKUP_FAIL_ALREADY_CARRY"));
		else
		{
			if(player GetAmmoCount(player.actionSlotItem) > 0)
				player iPrintLnBold(player getLocTextString("CRAFTABLE_OBJECT_PICKUP_FAIL_ALREADY_CARRY2"));
			else
			{
				thread reactivateCraftedWeaponPickup(player.actionSlotItem);
				player takeActionSlotWeapon("craftable");
			}
		}
		
		return;
	}
	
	player giveActionslotWeapon("craftable", self.craftedItem, 1);
	player playSound("weap_pickup");
	
	if(self.partType != "monkeybomb")
	{
		self maps\mp\gametypes\_gameobjects::disableObject();
		
		if(self.partType == "riotshield")
			player.riotShieldHealth = level.riotShieldHealth;
	}
}

reactivateCraftedWeaponPickup(crushedItem)
{
	for(i=0;i<level.craftedWeaponPickup.size;i++)
	{
		if(level.craftedWeaponPickup[i].craftedItem == crushedItem)
		{
			level.craftedWeaponPickup[i] maps\mp\gametypes\_gameobjects::enableObject();
			break;
		}
	}
}