#include scripts\_include;

init()
{
	game["tranzit"].score = [];
	game["tranzit"].score_start = 500;
	game["tranzit"].score_latejoiner = 1500;

	//rewards
	game["tranzit"].score["kill"] = 50;
	game["tranzit"].score["damage"] = 5;
	game["tranzit"].score["melee"] = 80;
	game["tranzit"].score["bonus_headshot"] = 50;
	game["tranzit"].score["bonus_neckshot"] = 20;
	game["tranzit"].score["bonus_torsoshot"] = 10;
	game["tranzit"].score["powerup_nuke"] = 400;
	game["tranzit"].score["powerup_carpenter"] = 1000;	
	game["tranzit"].score["barricade_repair_single"] = 10;
	
	//costs
	game["tranzit"].score["suicide"] = -400;
	game["tranzit"].score["ammobox"] = -1750;
	game["tranzit"].score["laststand"] = -300;
	game["tranzit"].score["packapunch"] = -5000;
	game["tranzit"].score["treasure_chest"] = -950;
	game["tranzit"].score["perk_doubletap"] = -2000;
	game["tranzit"].score["perk_juggernaut"] = -2000;
	game["tranzit"].score["perk_fastreload"] = -3000;
	game["tranzit"].score["perk_quickrevive"] = -1500;
	game["tranzit"].score["perk_tombstone"] = -1500;
	game["tranzit"].score["barricade_open_door"] = -1000;
	
	game["tranzit"].score["specialty_rof"] = game["tranzit"].score["perk_doubletap"];
	game["tranzit"].score["specialty_armorvest"] = game["tranzit"].score["perk_juggernaut"];
	game["tranzit"].score["specialty_fastreload"] = game["tranzit"].score["perk_fastreload"];

	//for wallweapon see wallweapons.gsc
	
	add_sound("buy_item", "buy_generic");
	add_sound("no_purchase", "no_cha_ching");
	
	thread loadBankAccounts();
}

loadBankAccounts()
{
	level.bankaccounts = getEntArray("bankaccount", "targetname");
		
	//loop through all bankaccounts and create the trigger
	for(i=0;i<level.bankaccounts.size;i++)
		level.bankaccounts[i] thread initBankAccount();
}

initBankAccount()
{
	self endon("death");
	
	self.trigger = spawn("trigger_radius", self.origin - (0,0,25), 0, 64, 80);
	
	while(1)
	{
		self.trigger waittill("trigger", player);
		
		if(!player isReadyToUse())
			continue;
		
		player thread showTriggerUseHintMessage(self.trigger, player getLocTextString("MONEY_OPEN_VAULT")
);
		
		if(player UseButtonPressed() && (!isDefined(player.banking) || !player.banking))
			player thread openBankAccount();
	}
	
	self.trigger delete();
}

openBankAccount()
{
	self endon("disconnect");
	self endon("death");
	
	timeStamp = TimeToString(getRealTime(), 0, "%Y-%m-%d");
	
	self.banking = true;
	self.bankDetails = self checkBankAccountBalance();

	if(self.bankDetails.size < 5)
	{
		for(i=self.bankDetails.size;i<5;i++)
			self.bankDetails[i] = strToK(" ; ", ";");
	}
	
	self.bankAccountBalance = int(self.bankDetails[0][1]);
	
	self setClientDvars("bankmenu_date", timeStamp, 
						"bankmenu_balance", self.bankAccountBalance,
						"bankmenu_transfer_left_1", self.bankDetails[1][0],
						"bankmenu_transfer_right_1", self.bankDetails[1][1], 
						"bankmenu_transfer_left_2", self.bankDetails[2][0],
						"bankmenu_transfer_right_2", self.bankDetails[2][1], 
						"bankmenu_transfer_left_3", self.bankDetails[3][0],
						"bankmenu_transfer_right_3", self.bankDetails[3][1], 
						"bankmenu_transfer_left_4", self.bankDetails[4][0],
						"bankmenu_transfer_right_4", self.bankDetails[4][1]);
	
	self openMenu(game["menu_bankaccount"]);
	
	self.banking = false;
}

checkBankAccountBalance()
{
	account = "player_storages/money/" + self.guid + ".csv";
	lines = [];
	line = "";
	
	if(fs_testFile(account))
	{
		file = openFile(account, "read");
		
		if(file > 0)
		{
			while(1)
			{
				line = fReadLn(file);
				
				if(!isDefined(line) || line == "" || line == " ")
					break;
				
				line = CaesarShiftCipher(line, "decrypt");	
				lines[lines.size] = strToK(line, ";");
			}
			
			closeFile(file);
		}
	}
	
	return lines;
}

transferMoneyWithBankAccount(action, amount)
{
	self endon("disconnect");
	self endon("death");

	//if this is undefined then the action was invoced through console (not the open menu)
	if(!isDefined(self.bankAccountBalance))
		return;

	if(!isDefined(action) || !isDefined(amount))
		return;

	amount = int(amount);
	file = openFile("player_storages/money/" + self.guid + ".csv", "write");
	
	if(file > 0)
	{
		if(action == "deposit")
		{
			curMoney = self getStat(2400);
			
			if(curMoney <= 0)
			{
				closeFile(file);
				return;
			}
			
			if(amount > curMoney)
				amount = curMoney;
		
			self.bankAccountBalance += amount;
			self thread [[level.onXPEvent]](undefined, int(amount), -1);
		}
		else
		{
			if(self.bankAccountBalance <= 0)
			{
				closeFile(file);
				return;
			}
				
			if(amount > self.bankAccountBalance)
				amount = self.bankAccountBalance;
		
			self.bankAccountBalance -= amount;
			self thread [[level.onXPEvent]](undefined, int(amount), 1);
		}

		timeStamp = TimeToString(getRealTime(), 0, "%Y-%m-%d");

		self.bankDetails[0][0] = "Balance";
		self.bankDetails[0][1] = self.bankAccountBalance;

		for(i=self.bankDetails.size;i>=1;i--)
		{
			if(i >= 2)
				self.bankDetails[i] = self.bankDetails[i-1];
			else 
			{
				self.bankDetails[i][0] = timeStamp;
				
				if(action == "deposit")
					self.bankDetails[i][1] = amount;
				else
					self.bankDetails[i][1] = amount * -1;
			}
		}
		
		for(i=0;i<5;i++)
		{
			if(!isDefined(self.bankDetails[i]))
				self.bankDetails[i] = strToK(" ; ", ";");
			else
			{
				fPrintLn(file, CaesarShiftCipher(self.bankDetails[i][0] + ";" + self.bankDetails[i][1], "encrypt"));
				//consolePrint("writing to file: " + self.bankDetails[i][0] + ";" + self.bankDetails[i][1] + "\n");
			}
		}
		
		self setClientDvars("bankmenu_date", timeStamp, 
							"bankmenu_balance", self.bankAccountBalance,
							"bankmenu_transfer_left_1", self.bankDetails[1][0],
							"bankmenu_transfer_right_1", self.bankDetails[1][1], 
							"bankmenu_transfer_left_2", self.bankDetails[2][0],
							"bankmenu_transfer_right_2", self.bankDetails[2][1], 
							"bankmenu_transfer_left_3", self.bankDetails[3][0],
							"bankmenu_transfer_right_3", self.bankDetails[3][1], 
							"bankmenu_transfer_left_4", self.bankDetails[4][0],
							"bankmenu_transfer_right_4", self.bankDetails[4][1]);
							
		closeFile(file);
	}
	
	wait .5;
}

checkRegisteredEvent(event)
{
	if(isDefined(game["tranzit"].score[event]))
		return game["tranzit"].score[event];
		
	if(isDefined(game["tranzit"].score["bonus_" + event]))
		return game["tranzit"].score["bonus_" + event];
		
	if(isDefined(game["tranzit"].score["perk_" + event]))
		return game["tranzit"].score["perk_" + event];
		
	if(isDefined(game["tranzit"].score["specialty_" + event]))
		return game["tranzit"].score["specialty_" + event];
		
	if(isDefined(game["tranzit"].score["barricade_" + event]))
		return game["tranzit"].score["barricade_" + event];
		
	return undefined;
}

getPrice(event)
{
	value = checkRegisteredEvent(event);
	
	if(!isDefined(value) || value == 0)
		return 0;
		
	return abs(value);
}

hasEnoughMoney(event)
{
	self endon("disconnect");
	
	require = scripts\money::getPrice(event);

	if(self.pers["score"] < abs(require))
		return false;
		
	return true;
}

onMoneyEvent(event, amount, multiplier)
{
	if(!isDefined(event) && !isDefined(amount))
		return;
		
	value = undefined;
	if(isDefined(event))
		value = checkRegisteredEvent(event);

	if(isDefined(amount) && (!isDefined(value) || value == 0))
		value = amount;

	if(!isDefined(value) || value == 0)
		return;

	surpressSound = false;
	if(isDefined(event) && (event == "laststand" || event == "suicide"))
		surpressSound = true;

	if(isDefined(multiplier))
		value *= multiplier;
		
	value = int(value);
		
	if(value > 0)
		self gainMoney(value);
	else
		self wasteMoney(value, surpressSound);
}

gainMoney(amount)
{
	if(game["powerup_doublepoints"])
		amount *= 2;

	self.pers["score"] += amount;
	self.pers["score"] = int(self.pers["score"]);
	self.score = self.pers["score"];
	self.amount = self.score; //rotu
	
	self setStat(2400, self.pers["score"]);
	self notify("update_playerscore_hud");
	
	self thread moneyChangeHud(amount);
}

wasteMoney(amount, surpressSound)
{
	self.pers["score"] -= abs(amount);
	self.pers["score"] = int(self.pers["score"]);
	self.score = self.pers["score"];
	self.amount = self.score; //rotu

	self setStat(2400, self.pers["score"]);
	self notify("update_playerscore_hud");
	
	if(!isDefined(surpressSound) || !surpressSound)
		self playSoundRef("buy_item");
		
	self thread moneyChangeHud(amount);
}

moneyChangeHud(amount)
{
	self endon("disconnect");
	
	//Copied from rotu
	// START: Collection of upgradeamount
	if(!isDefined(self.upgradeHudamount))
		self.upgradeHudamount = 0;
	
	// We collect all upgradeamount we gain during two server frames, so we don't display
	// too many upgradepoint increases/decreases on the player's screen, resulting in some of them not being displayed
	self.upgradeHudamount += amount;
	old = self.upgradeHudamount;
	wait 0.05;
	
	if(self.upgradeHudamount != old)
		return;
	// END: Collection of upgradeamount
	
	amount = int(self.upgradeHudamount);
	self.upgradeHudamount = 0;

	moneyChange = newClientHudElem(self);
	moneyChange.font = "objective";
	moneyChange.fontscale = 1.4;
	moneyChange.alignX = "right";
	moneyChange.alignY = "middle";
	moneyChange.horzAlign = "right";
	moneyChange.vertAlign = "bottom";
	moneyChange.alpha = 1;
	moneyChange.sort = 1;
	moneyChange.x = -100; // Location from hud.menu
	moneyChange.y = -74; // Location from hud.menu
	moneyChange.archived = true;
	moneyChange.foreground = true;
	moneyChange.hidewheninmenu = true;
	
	if(amount > 0)
	{
		moneyChange.color = (0.9, 0.9, 0);
		moneyChange.label = &"MP_PLUS"; //SCRIPT_PLUS_DOLLAR
		
		thread scripts\statistics::incStatisticValue("money_gained", 2415, amount);
	}
	else
	{
		moneyChange.color = (0.423, 0.004, 0);
		moneyChange.label = &"&&1"; //SCRIPT_DOLLAR
		
		thread scripts\statistics::incStatisticValue("money_lost", 2416, abs(amount));
	}
	
	moneyChange setValue(amount);
	
	moneyChange moveOverTime(0.5);
	moneyChange.x -= (20 + RandomInt(40)); 
	moneyChange.y -= (-15 + RandomInt(30)); 
	
	wait(0.25);

	moneyChange fadeOverTime(0.25); 
	moneyChange.alpha = 0; 
	
	wait(0.25);

	moneyChange destroy(); 
}