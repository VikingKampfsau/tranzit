#include scripts\_include;

init()
{
	initMenu("bankaccount", true);
	initMenu("language", true);
	initMenu("rotu_shop", true);
	initMenu("popup_tutorial_credits", true);
	initMenu("clientcmd", true);
	initMenu("weapondrop", false);
	initMenu("facemask", false);
	
	// once there is a hook to hide the default scoreboard set this to 0
	setDvar("ui_showStockScoreboard", 0); 
}

initMenu(name, precache)
{
	if(!isDefined(precache))
		precache = true;

	game["menu_" + name] = name;
	precacheMenu(game["menu_" + name]);
}

onMenuResponse(menu, response)
{
	self endon("disconnect");
	
	if(level.gameEnded)
		return;

	if(menu == game["menu_bankaccount"])
	{
		switch(response)
		{
			case "deposit":
			case "withdraw":
				self.bankTransferType = response;
				break;
			
			case "bank_pressed_10000":
			case "bank_pressed_07500":
			case "bank_pressed_05000":
			case "bank_pressed_02500":
			case "bank_pressed_01000":
			case "bank_pressed_00500":
			case "bank_pressed_00250":
			case "bank_pressed_00100":
				self scripts\money::transferMoneyWithBankAccount(self.bankTransferType, getSubStr(response, response.size - 5, response.size));
				break;
				
			case "bank_closed":
				self.bankAccountBalance = undefined;
				break;

			default: break;
		}
		
		return;
	}
	
	if(menu == "scoreboard")
	{
		if(response == "show_tranzit_scoreboard")
		{
			survivors = GetPlayersInTeam(game["defenders"]);
		
			self setClientDvar("ui_showStockScoreboard", getDvarInt("ui_showStockScoreboard"));
		
			/* default scoreboard  -> no need to send additional data */
			if(getDvarInt("ui_showStockScoreboard"))
				return;
		
			/* type 1: looks like the scoreboard in waw			
			//player is alone - clear the other scores
			if(!isDefined(survivors) || survivors.size <= 1)
			{
				self setClientDvars("tranzit_scoreboard_line_1_name", "",
									"tranzit_scoreboard_line_2_name", "",
									"tranzit_scoreboard_line_3_name", "");
				return;
			}
			
			//player is not alone - get the other scores
			scores = [];
			for(i=0;i<survivors.size;i++)
			{
				if(survivors[i] == self)
					continue;
					
				entryNo = scores.size;
				scores[entryNo]["name"] = survivors[i].name;
				scores[entryNo]["score"] = survivors[i] getStat(2400);
				scores[entryNo]["kills"] = survivors[i].pers["kills"];
				scores[entryNo]["downs"] = survivors[i].pers["downs"];
				scores[entryNo]["revives"] = survivors[i].pers["revives"];
				scores[entryNo]["headshots"] = survivors[i].pers["headshots"];
			}
			
			//server is not full - fill the remaining scores with empty values
			//just to make sure no old values are stored in the dvars
			if(scores.size < 3)
			{
				for(i=scores.size;i<=3;i++)
				{
					scores[i]["name"] = "";
					scores[i]["score"] = "";
					scores[i]["kills"] = "";
					scores[i]["downs"] = "";
					scores[i]["revives"] = "";
					scores[i]["headshots"] = "";
				}
			}
			
			//send the data to the client
			self setClientDvars("tranzit_scoreboard_line_1_name", scores[0]["name"],
								"tranzit_scoreboard_line_1_score", scores[0]["score"],
								"tranzit_scoreboard_line_1_kills", scores[0]["kills"],
								"tranzit_scoreboard_line_1_downs", scores[0]["downs"],
								"tranzit_scoreboard_line_1_revives", scores[0]["revives"],
								"tranzit_scoreboard_line_1_headshots", scores[0]["headshots"],
								"tranzit_scoreboard_line_2_name", scores[1]["name"],
								"tranzit_scoreboard_line_2_score", scores[1]["score"],
								"tranzit_scoreboard_line_2_kills", scores[1]["kills"],
								"tranzit_scoreboard_line_2_downs", scores[1]["downs"],
								"tranzit_scoreboard_line_2_revives", scores[1]["revives"],
								"tranzit_scoreboard_line_2_headshots", scores[1]["headshots"],
								"tranzit_scoreboard_line_3_name", scores[2]["name"],
								"tranzit_scoreboard_line_3_score", scores[2]["score"],
								"tranzit_scoreboard_line_3_kills", scores[2]["kills"],
								"tranzit_scoreboard_line_3_downs", scores[2]["downs"],
								"tranzit_scoreboard_line_3_revives", scores[2]["revives"],
								"tranzit_scoreboard_line_3_headshots", scores[2]["headshots"]);
								
			*/
			
			/* type 2: show detailed info about all survivors */
			dvars = []; values = [];
			dvars[dvars.size] = "playerinfo_total_players";
			values[values.size] = survivors.size;

			for(i=0;i<survivors.size;i++)
			{
				//primary weapon image
				dvars[dvars.size] = "playerinfo_"+i+"_weapon_primary";				
				if(!isDefined(survivors[i].pers["primaryWeapon"]) || survivors[i].pers["primaryWeapon"] == game["tranzit"].player_empty_hands)
					values[values.size] = "";
				else
				{
					if(getSubStr(survivors[i].pers["primaryWeapon"], survivors[i].pers["primaryWeapon"].size - 3, survivors[i].pers["primaryWeapon"].size) == "_mp")
						values[values.size] = getSubStr(survivors[i].pers["primaryWeapon"], 0, survivors[i].pers["primaryWeapon"].size - 3);
				}
				
				//secondary weapon image
				dvars[dvars.size] = "playerinfo_"+i+"_weapon_secondary"; 
				if(!isDefined(survivors[i].pers["secondaryWeapon"]) || survivors[i].pers["secondaryWeapon"] == game["tranzit"].player_empty_hands)
					values[values.size] = "";
				else
				{
					if(getSubStr(survivors[i].pers["secondaryWeapon"], survivors[i].pers["secondaryWeapon"].size - 3, survivors[i].pers["secondaryWeapon"].size) == "_mp")
						values[values.size] = getSubStr(survivors[i].pers["secondaryWeapon"], 0, survivors[i].pers["secondaryWeapon"].size - 3);
				}
				
				//third weapon image (usually crafted on a table)
				dvars[dvars.size] = "playerinfo_"+i+"_weapon_equipment";
				if(!isDefined(survivors[i].actionSlotWeapon) || survivors[i].actionSlotWeapon == game["tranzit"].player_empty_hands)
					values[values.size] = "";
				else
				{
					if(getSubStr(survivors[i].actionSlotWeapon, survivors[i].actionSlotWeapon.size - 3, survivors[i].actionSlotWeapon.size) == "_mp")
						values[values.size] = getSubStr(survivors[i].actionSlotWeapon, 0, survivors[i].actionSlotWeapon.size - 3);
				}

				//perk  images
				for(j=0;j<survivors[i].perk_hud.size;j++)
				{
					if(j > 4) break;

					dvars[dvars.size] = "playerinfo_"+i+"_perk_"+int(j+1);
					
					if(!isDefined(survivors[i].perk_hud[j].perk))
						values[values.size] = "";
					else
						values[values.size] = survivors[i].perk_hud[j].perk;
				}
				
				//image of the player model
				dvars[dvars.size] = "playerinfo_"+i+"_model";
				switch(survivors[i].model)
				{
					case "body_complete_mp_russian_farmer": values[values.size] = "animated_player_preview_farmer_0" + randomIntRange(1, 3); break;
					case "body_complete_mp_vip": values[values.size] = "animated_player_preview_vip_0" + randomIntRange(1, 3); break;
					case "body_complete_mp_zakhaev": values[values.size] = "animated_player_preview_zakhaev_0" + randomIntRange(1, 3); break;
					case "body_complete_mp_zakhaevs_son_coup": values[values.size] = "animated_player_preview_zakhaev_son_0" + randomIntRange(1, 3); break;
					
					case "body_mp_vip_pres":
					default: values[values.size] = ""; break;
				}
				
				if(survivors[i] != self)
				{
					//name
					dvars[dvars.size] = "playerinfo_"+i+"_name";
					values[values.size] = survivors[i].name;
					// money
					dvars[dvars.size] = "playerinfo_"+i+"_money";
					values[values.size] = survivors[i] getStat(2400);
					//rank
					dvars[dvars.size] = "playerinfo_"+i+"_rank";
					values[values.size] = survivors[i] getStat(2440);
					// addicted
					dvars[dvars.size] = "playerinfo_"+i+"_prestige";
					values[values.size] = survivors[i] getStat(2326);
					// kills
					dvars[dvars.size] = "playerinfo_"+i+"_kills";
					values[values.size] = survivors[i] getStat(2401);
					// accuracy
					dvars[dvars.size] = "playerinfo_"+i+"_accuracy";
					values[values.size] = survivors[i] getStat(2325);
					// activity
					dvars[dvars.size] = "playerinfo_"+i+"_timeplayed";
					values[values.size] = survivors[i] getStat(2311) + survivors[i] getStat(2312) + survivors[i] getStat(2313);
				}
			}
			
			self thread setClientDvarsDelayed(dvars, values, "scoreboardUpdate");
			
			//make sure smashing the scoreboard button does not
			//reinvoke the scoreboard update for a bit
			wait 1;
		}
		
		return;
	}
	
	if(menu == game["menu_rotu_shop"])
	{
		if(!isDefined(level.vendingMachines) || level.vendingMachines[0].content != "rotu_shop")
			return;
	
		switch(response)
		{
			case "ammo":
				if(!self hasMaxAmmo())
				{
					if(self scripts\money::hasEnoughMoney("ammobox"))
					{
						self thread [[level.onXPEvent]]("ammobox");
						self playSound("mp_bomb_defuse");
						self PlaySoundRef("full_ammo");
						self GiveAmmoForAllWeapons();
					}
				}
				break;
			
			case "frag_grenades":
				if(!self hasMaxAmmoForWeapon("frag_grenade_mp"))
				{
					if(self scripts\money::hasEnoughMoney("wallweapon_frag_grenade"))
					{
						self thread [[level.onXPEvent]]("wallweapon_frag_grenade");
						self giveNewWeapon("frag_grenade_mp");
					}
				}
				break;
				
			case "specialty_rof":
			case "specialty_armorvest":
			case "perk_quickrevive":
			case "specialty_fastreload":
				if(!self scripts\perks::hasZombiePerk(response))
				{
					if(self scripts\money::hasEnoughMoney(response))
					{
						self thread [[level.onXPEvent]](response);
						self scripts\perks::shoutOutPerk(response);
						self scripts\perks::setZombiePerk(response);
					}
				}
				break;

			default: break;
		}
		
		return;
	}
	
	//Switch Language
	if(menu == game["menu_language"] && isSubStr(response, "language_"))
	{
		language = GetSubStr(response, 9, response.size);

		switch(language)
		{
			case "FRENCH":		self setStat(2450, 2); break;
			case "GERMAN":		self setStat(2450, 3); break;
			case "ITALIAN":		self setStat(2450, 4); break;
			case "SPANISH":		self setStat(2450, 5); break;
			case "RUSSIAN":		self setStat(2450, 7); break;
			case "POLISH":		self setStat(2450, 8); break;
			case "HUNGARIAN":	self setStat(2450, 14); break;
			case "ENGLISH":
			default:	self setStat(2450, 1); break;
		}
		
		self setPlayerLanguage();
		return;
	}
	
	//Weapondrop
	if(menu == game["menu_weapondrop"] && response == "weapondrop")
	{
		self scripts\weapondrop::dropWeaponOnResponse();
		return;
	}
	
	//Facemask (nvg and gas)
	if(menu == game["menu_facemask"] && response == "toggle_facemask")
	{
		self thread scripts\facemasks::toggleFacemask();
		return;
	}
}