/*
in cod:waw the upgrades are different and individual for every weapon.
to make it easier i upgrade wapons of the same class identically

Sadly CoD4 can not handle long strings so i had to build a work around
To use this code you have to replace all "\" in weaponfiles with a line split ("\n")
Then run this script and for the export replace all line splits "\n" with "\" again.
For hideTags and notetrackSoundMap the "\" that are too much have to be removed again
*/

#include scripts\_include;

init()
{
	if(getDvarInt("developer") <= 0)
		return;
		
	if(getDvarInt("create_weaponfiles") > 0 || getDvarInt("create_weaponindex") > 0)
	{
		level.weaponsToUpgrade = [];

		upgradeWeapon("ak47_mp");
		upgradeWeapon("ak74u_mp");
		upgradeWeapon("barrett_mp");
		upgradeWeapon("beretta_mp");
		upgradeWeapon("colt45_mp");
		upgradeWeapon("deserteagle_mp");
		upgradeWeapon("dragunov_mp");
		upgradeWeapon("g36c_mp");
		upgradeWeapon("g3_mp");
		upgradeWeapon("m1014_mp");
		upgradeWeapon("m14_mp");
		upgradeWeapon("m16_mp");
		upgradeWeapon("m21_mp");
		upgradeWeapon("m40a3_mp");
		upgradeWeapon("m4_mp");
		upgradeWeapon("m60e4_mp");
		upgradeWeapon("mp44_mp");
		upgradeWeapon("mp5_mp");
		upgradeWeapon("p90_mp");
		upgradeWeapon("remington700_mp");
		upgradeWeapon("rpd_mp");
		upgradeWeapon("rpg_mp");
		upgradeWeapon("saw_mp");
		upgradeWeapon("skorpion_mp");
		upgradeWeapon("usp_mp");
		upgradeWeapon("uzi_mp");
		upgradeWeapon("winchester1200_mp");

		justAddToUpgradeTable("airstrike_mp", "helicopter_mp"); //knife to katana

		if(getDvarInt("create_weaponfiles") > 0)
		{
			writeUpgradeTable();

			consolePrint("\n");
			consolePrint("\n");
			consolePrint("^2Weaponfile creation finished\n");
			consolePrint("Stopping server...\n");
			consolePrint("/quit\n");
			consolePrint("\n");
			consolePrint("\n");
		
			setDvar("create_weaponfiles", 0);
		
			wait 3;
		
			exec("quit");
			
			wait 9999;
		}
	}
}

justAddToUpgradeTable(baseWeapon, upgradedWeapon)
{
	curEntry = level.weaponsToUpgrade.size;
	level.weaponsToUpgrade[curEntry].baseWeapon = baseWeapon;
	level.weaponsToUpgrade[curEntry].upgradedWeapon = upgradedWeapon;
}

upgradeWeapon(weapon)
{
	weapon = getSubStr(weapon, 0, weapon.size-3);

	curEntry = level.weaponsToUpgrade.size;
	level.weaponsToUpgrade[curEntry] = spawnStruct();
	level.weaponsToUpgrade[curEntry].baseName = weapon;
	level.weaponsToUpgrade[curEntry].baseWeapon = weapon + "_mp";
	
	if(getDvarInt("create_weaponfiles") == 1)
	{
		content = readNormalWeaponFile(weapon);
	
		if(isDefined(content) && content.size > 0)
			writeUpgradedWeaponFile(curEntry, weapon, content);
	}
	else
	{
		switch(WeaponClass(weapon + "_mp"))
		{
			case "mg":		
			case "rifle":
				if(weapon == "mp44")
					weapon = "m4_gl_mp";
				else
					weapon = weapon + "_acog_mp";
				break;
			
			case "spread":	
				weapon = weapon + "_grip_mp";
				break;

			case "smg":		
			case "pistol":	
				if(weapon == "deserteagle")
					weapon = "deserteaglegold_mp";
				else
					weapon = weapon + "_silencer_mp";
				break;
			
			default:
				if(weapon == "rpg")
					weapon = "at4_mp";
				else
					weapon = weapon + "_mp";
					
				break;
		}

		level.weaponsToUpgrade[curEntry].upgradedWeapon = weapon;
	}
}

readNormalWeaponFile(weapon)
{
	fileName = "weaponupgradetool/import/" + weapon + "_mp";
	content = [];
	lineSplit = [];
	line = "";
	
	if(fs_testFile(fileName))
	{
		file = openFile(fileName, "read");
		
		if(file > 0)
		{
			while(1)
			{
				line = fReadLn(file);
				
				if(!isDefined(line))
					break;

				if(line == "")
					line = " ";

				content[content.size] = line;
			}
			
			closeFile(file);
		}
	}
	
	return content;
}

writeUpgradedWeaponFile(curEntry, weapon, content)
{
	class = WeaponClass(weapon + "_mp");
	switch(WeaponClass(weapon + "_mp"))
	{
		case "mg":		
		case "rifle":
			if(weapon == "mp44")
				weapon = "_mp44_upgraded";
			else
				weapon = weapon + "_acog_mp";
			break;
		
		case "spread":	
			weapon = weapon + "_grip_mp";
			break;

		case "smg":		
		case "pistol":	
			if(weapon == "deserteagle")
				weapon = "deserteaglegold_mp";
			else
				weapon = weapon + "_silencer_mp";
			break;
		
		default:
			if(weapon == "rpg")
				weapon = "at4_mp";
			else
				weapon = weapon + "_mp";
				
			break;
	}

	level.weaponsToUpgrade[curEntry].upgradedWeapon = weapon;
	fileName = "weaponupgradetool/export/" + weapon;

	file = openFile(fileName, "write");
	
	if(file > 0)
	{
		fireType = "";
	
		for(i=0;i<content.size;i++)
		{
			content[i] = "" + content[i];
			switch(content[i])
			{
				case "damage":
				case "minDamage":
				{
					switch(class)
					{
						case "pistol":			content[i+1] = int(float(content[i+1]) *3); break;
						case "mg":				content[i+1] = int(float(content[i+1]) *2.3); break;
						case "smg":				content[i+1] = int(float(content[i+1]) *2.66); break;
						case "spread":			content[i+1] = int(float(content[i+1]) *2.67); break;
						case "rifle":			content[i+1] = int(float(content[i+1]) *2.5); break;
						case "rocketlauncher":	content[i+1] = int(float(content[i+1]) *2.66); break;
						default: break;
					}
						
					break;
				}
				
				case "locHelmet":
				case "locHead":
				case "locNeck":
				{
					switch(class)
					{
						case "pistol":			content[i+1] = float(content[i+1]) *2; break;
						case "mg":				content[i+1] = float(content[i+1]) *1.16; break;
						case "smg":				content[i+1] = float(content[i+1]) *1.25; break;
						case "spread":			content[i+1] = float(content[i+1]) *1; break;
						case "rifle":			content[i+1] = float(content[i+1]) *1.25; break;
						case "rocketlauncher":	content[i+1] = float(content[i+1]) *1; break;
						default: break;
					}
						
					break;
				}
				
				case "locTorsoUpper":
				{
					switch(class)
					{
						case "pistol":			content[i+1] = float(content[i+1]) *1.37; break;
						case "mg":				content[i+1] = float(content[i+1]) *1; break;
						case "smg":				content[i+1] = float(content[i+1]) *1; break;
						case "spread":			content[i+1] = float(content[i+1]) *1; break;
						case "rifle":			content[i+1] = float(content[i+1]) *1.33; break;
						case "rocketlauncher":	content[i+1] = float(content[i+1]) *1; break;
						default: break;
					}
						
					break;
				}
				
				case "fireTime":
				{
					switch(class)
					{
						case "pistol":			content[i+1] = float(content[i+1]) *1; break;
						case "mg":				content[i+1] = float(content[i+1]) *1.4; break;
						case "smg":				content[i+1] = float(content[i+1]) *1.23; break;
						case "spread":			content[i+1] = float(content[i+1]) *1; break;
						case "rifle":			content[i+1] = float(content[i+1]) *1.27; break;
						case "rocketlauncher":	content[i+1] = float(content[i+1]) *8.6; break;
						default: break;
					}
						
					break;
				}
				
				//Segmented reload - Add more bullets per sequence
				case "reloadAmmoAdd":
				case "reloadStartAdd":
				{
					switch(class)
					{
						case "spread":			content[i+1] = int(float(content[i+1]) *2); break;
						case "pistol":
						case "mg":
						case "smg":
						case "rifle":
						case "rocketlauncher":
						default: break;
					}
						
					break;
				}
				
				case "maxAmmo":
				case "startAmmo":
				{
					updatedStock = false;
					
					switch(class)
					{
						case "pistol":			updatedStock = true; content[i+1] = int(float(content[i+1]) *1); break;
						case "mg":				updatedStock = true; content[i+1] = int(float(content[i+1]) *1.5); break;
						case "smg":				updatedStock = true; content[i+1] = int(float(content[i+1]) *1.25); break;
						case "spread":			updatedStock = true; content[i+1] = int(float(content[i+1]) *1.5); break;
						case "rifle":			updatedStock = true; content[i+1] = int(float(content[i+1]) *1.66); break;
						case "rocketlauncher":	updatedStock = true; content[i+1] = int(float(content[i+1]) *2); break;
						default: break;
					}
					
					if(updatedStock && isSubStr(fireType, "Burst"))
					{
						while(content[i+1] % 3 != 0)
							content[i+1]++;
					}
						
					break;
				}
				
				case "clipSize":
				{
					updatedClip = false;
				
					switch(class)
					{
						case "pistol":			updatedClip = true; content[i+1] = int(float(content[i+1]) *1); break;
						case "mg":				updatedClip = true; content[i+1] = int(float(content[i+1]) *1); break;
						case "smg":				updatedClip = true; content[i+1] = int(float(content[i+1]) *2); break;
						case "spread":			updatedClip = true; content[i+1] = int(float(content[i+1]) *1.67); break;
						case "rifle":			updatedClip = true; content[i+1] = int(float(content[i+1]) *2); break;
						case "rocketlauncher":	updatedClip = true; content[i+1] = int(float(content[i+1]) *3); break;
						default: break;
					}
					
					if(updatedClip && isSubStr(fireType, "Burst"))
					{
						while(content[i+1] % 3 != 0)
							content[i+1]++;
					}
						
					break;
				}
				
				case "dropAmmoMin":
				case "dropAmmoMax":
				{
					if(isSubStr(fireType, "Burst"))
						content[i+1] = 3;
	
					break;
				}
				
				case "fireType":
				{
					switch(class)
					{
						case "pistol":			content[i+1] = "3-Round Burst"; fireType = content[i+1]; break;
						case "rocketlauncher":	content[i+1] = "Full Auto"; fireType = content[i+1]; break;
						case "mg":
						case "smg":
						case "spread":
						case "rifle":
							if(weapon == "g3_acog_mp" || weapon == "m4_acog_mp" || weapon == "m14_acog_mp")
								content[i+1] = "Full Auto";
							
							fireType = content[i+1];
							break;
						default: break;
					}
						
					break;
				}
				
				case "fireSound":
				{
					content[i+1] = "weap_fire_ubershot";
					break;
				}
				
				case "fireSoundPlayer":
				{
					content[i+1] = "weap_fire_ubershot_plr";
					break;
				}
				
				case "viewFlashEffect":
				case "worldFlashEffect":
				{
					if(class == "spread")
						content[i+1] = "tranzit/muzzleflash/shotgunflash_ug";
					else
						content[i+1] = "tranzit/muzzleflash/standardflashview_ug";
						
					break;
				}
				
				case "gunModel":
				{
					if(weapon == "beretta_silencer_mp")
						content[i+1] = "viewmodel_beretta_hibana_mp";
					else if(weapon == "usp_silencer_mp")
						content[i+1] = "viewmodel_usp_spectrum_mp";
					else if(weapon == "colt45_silencer_mp")
						content[i+1] = "viewmodel_colt1911_white";
					else if(weapon == "deserteaglegold_mp")
						content[i+1] = "viewmodel_desert_eagle_gold_mp";
					else
						content[i+1] = content[i+1] + "_stagger";
					
					break;
				}
				
				case "clipName":
				{
					content[i+1] = content[i+1] + "_upgrade";
					break;
				}
			}
			
			if(content[i] == " ")
				content[i] = "";
			
			fPrintLn(file, content[i]);
		}

		closeFile(file);
	}
}

writeUpgradeTable()
{
	fileName = "packapunch/weaponupgrades.csv";
	file = openFile(fileName, "write");
	
	if(file > 0)
	{
		for(i=0;i<level.weaponsToUpgrade.size;i++)
			fPrintLn(file, level.weaponsToUpgrade[i].baseWeapon + "," + level.weaponsToUpgrade[i].upgradedWeapon);

		closeFile(file);
	}
}