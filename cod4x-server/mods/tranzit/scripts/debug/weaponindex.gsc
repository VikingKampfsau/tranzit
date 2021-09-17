/*
this file generates an csv file which lists all custom
weapons and the name of the weaponfile they use.
*/

#include scripts\_include;

init()
{
	if(getDvarInt("developer") <= 0)
		return;
		
	if(getDvarInt("create_weaponindex") > 0)
	{
		writeIndexFile();

		consolePrint("\n");
		consolePrint("\n");
		consolePrint("^2Weapon Index creation finished\n");
		consolePrint("Stopping server...\n");
		consolePrint("/quit\n");
		consolePrint("\n");
		consolePrint("\n");
	
		setDvar("create_weaponindex", 0);
	
		wait 3;
	
		exec("quit");
		
		wait 9999;
	}
}

writeIndexFile()
{
	//give the other scripts some time to fill the weapon array
	wait 1;
	
	if(!isDefined(level.tranzitWeapon) || !level.tranzitWeapon.size)
		return;
		
	fileName = "readme/weapons.txt";
	file = openFile(fileName, "write");
	
	if(file > 0)
	{
		fPrintLn(file, "Custom Weapon, Filename");

		for(i=0;i<level.tranzitWeapon.size;i++)
			fPrintLn(file, level.tranzitWeapon[i].name + ", " + level.tranzitWeapon[i].weapon);

		fPrintLn(file, "\n");
		fPrintLn(file, "Upgraded Weapon, Filename");

		for(i=0;i<level.weaponsToUpgrade.size;i++)
			fPrintLn(file, level.weaponsToUpgrade[i].baseName + ", " + level.weaponsToUpgrade[i].upgradedWeapon);
		
		closeFile(file);
	}
}