/*---------------------------------------------------------------------------
|///////////////////////////////////////////////////////////////////////////|
|///\  \/////////  ///|  |//|  |///  ///|  |//|   \////|  |//|          |///|
|////\  \///////  ////|  |//|  |//  ////|  |//|    \///|  |//|  ________|///|
|/////\  \/////  /////|  |//|  |/  /////|  |//|  \  \//|  |//|  |///////////|
|//////\  \///  //////|  |//|     //////|  |//|  |\  \/|  |//|  |//|    |///|
|///////\  \/  ///////|  |//|     \/////|  |//|  |/\  \|  |//|  |//|_   |///|
|////////\    ////////|  |//|  |\  \////|  |//|  |//\  \  |//|  |////|  |///|
|/////////\  /////////|  |//|  |/\  \///|  |//|  |///\    |//|          |///|
|//////////\//////////|__|//|__|//\__\//|__|//|__|////\___|//|__________|///|
|///////////////////////////////////////////////////////////////////////////|
|---------------------------------------------------------------------------|
| Here are the translations for textes used in scripts (.gsc and .gsx files)|
| only. You are free to change them - just keep any eye on the syntax. Some |
| textes contain placeholders (&&1), do not delete these placeholders.		|
|																			|
| Textes used in menus and stringtables are hardcoded in a localized file,	|
| they are not changeable.													|
|--------------------------------------------------------------------------*/

//<player> is optional
//<player> getLocTextString("EXAMPLE")

findTranslation(ref)
{
	switch(ref)
	{
		//these are not used by huds so they are no localized strings
		case "CAREPACKAGE_CONTENT_NONE": return "Content was broken!";
		case "CAREPACKAGE_UNABLE_TO_CALL": return "No free crates - collect an existing first";
		case "CRAFTABLE_CRAFTING_NO_PARTS": return "You have no parts for crafting!";
		case "CRAFTABLE_OBJECT_PICKUP_FAIL_ALREADY_CARRY": return "You already carry this crafted object!";
		case "CRAFTABLE_OBJECT_PICKUP_FAIL_ALREADY_CARRY2": return "You already carry a crafted object! \n Use or drop it first!";
		case "CRAFTABLE_PICKUP_FAIL_ALREADY_CARRY": return "You already carry an object!";
		case "CRAFTABLE_CRAFTING": return "Crafting...";
		case "ERROR_MAP_NOT_WAYPOINTED": return "^1Map has no waypoints!";
		case "GENERATOR_BAD_SPOT": return "Bad spot!";
		case "PACKAPUNCH_FAIL_BAD_WEAPON": return "^1Can not upgrade this weapon!";
		case "PUNISHMENT_ELEVATOR": return "^1Please do not elevate!";		
		
		//these are used by huds so they are localized strings 
		case "BARRICADES_BLOCKER_OPEN": return &"^3[{+activate}] ^7to remove barricade [^1&&1^7]";
		case "BARRICADES_DOOR_OPEN": return &"^3[{+activate}] ^7to open door [^1&&1^7]";
		case "BARRICADES_PLANK_REPAIR": return &"^3[{+activate}] ^7to repair it.";
		case "CAREPACKAGE_OPEN_PRESS_BUTTON": return &"^3[{+activate}] ^7to open the crate [^1&&1^7]";
		case "CRAFTABLE_PICKUP_PRESS_USE": return &"^7Press ^3[{+activate}] ^7to pickup that part.";
		case "CRAFTABLE_CRAFTING_PRESS_USE": return &"^7Hold ^3[{+activate}] ^7to add your part.";
		case "CRAFTABLE_OBJECT_PICKUP_PRESS_USE": return &"^7Press ^3&&1 ^7to pickup that object.";
		case "FRIDGE_GRAB_WEAPON": return &"^3[{+activate}] ^7to receive your stored weapon.";
		case "GENERATOR_DEPLOY_PRESS_BUTTON": return &"Press ^3[{+attack}] ^7to deploy the Generator.";
		case "GENERATOR_PICKUP_PRESS_BUTTON": return &"^3[{+activate}] ^7to pickup the Generator";
		case "INTRO_LINE1": return &"Apocalypse";
		case "INTRO_LINE2": return &"Altay Mountains, Russia";
		case "LOCATION_HUD_POS": return &"Location: &&1";
		case "LOCATION_HUD_POS_UNKNOWN": return &"Location: Unknown";
		case "MISTERYBOX_OPEN_PRESS_BUTTON": return &"^3[{+activate}] ^7to use the box [^1&&1^7]";
		case "MONEY_OPEN_VAULT": return &"^3[{+activate}] ^7to open your bank account.";
		case "PACKAPUNCH_USE_PRESS_BUTTON": return &"^3[{+activate}] ^7to upgrade your weapon [^1&&1^7]";
		case "PERK_VENDING_BUY_SODA": return &"^3[{+activate}] ^7to get a soda [^1&&1^7]";
		case "POWER_SWITCH_USE": return &"^3[{+activate}] ^7to activate the power.";
		case "READYUP_PRESS_BUTTON": return &"Press ^3[{+activate}] ^7to Ready-Up!";
		case "READYUP_WAITING": return &"Waiting for all players to Ready-Up";
		case "REVIVE_HEAL_PRESS_BUTTON": return &"Hold ^3[{+activate}] ^7to revive &&1^7.";
		case "REVIVE_LAST_STAND": return &"^1Bleeding out: &&1";
		case "SENTRYGUN_DEPLOY_PRESS_BUTTON": return &"Press ^3[{+attack}] ^7to deploy the Sentry.";
		case "SENTRYGUN_PICKUP_PRESS_BUTTON": return &"^3[{+activate}] ^7to pickup the Sentry";
		case "VEHICLE_START_PRESS_BUTTON": return &"^3[{+activate}] ^7to start the vehicle.";
		case "WALLWEAPON_BUY_AMMO": return &"^3[{+activate}] ^7to buy ammo [^1&&1^7]";
		case "WALLWEAPON_BUY_WEAPON": return &"^3[{+activate}] ^7to buy weapon [^1&&1^7]";
		
		//nothing found - return empty strings
		//importand: when a localized string (&"EXAMPLE") is expected this will crash because we return a normal string
		default: return "";
	}
}