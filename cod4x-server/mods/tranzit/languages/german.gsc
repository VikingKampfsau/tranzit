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
		case "CAREPACKAGE_CONTENT_NONE": return "Inhalt beschädigt!";
		case "CAREPACKAGE_UNABLE_TO_CALL": return "Kein CP verfügbar - sammle erst ein Ausgeworfenes";
		case "CRAFTABLE_CRAFTING_NO_PARTS": return "Du hast kein Teile für den Bau!";
		case "CRAFTABLE_OBJECT_PICKUP_FAIL_ALREADY_CARRY": return "Du trägst dieses Objekt bereits!";
		case "CRAFTABLE_OBJECT_PICKUP_FAIL_ALREADY_CARRY2": return "Du trägst bereits ein Objekt! \n Verwende oder lege es zuerst ab!";
		case "CRAFTABLE_PICKUP_FAIL_ALREADY_CARRY": return "Du trägst bereits ein Objekt!";
		case "CRAFTABLE_CRAFTING": return "Anbringen...";
		case "ERROR_MAP_NOT_WAYPOINTED": return "^1Map hat keine Waypoints!";
		case "GENERATOR_BAD_SPOT": return "Schlechte Stelle!";
		case "PACKAPUNCH_FAIL_BAD_WEAPON": return "^1Diese Waffe kann nicht verbessert werden!";
		case "PUNISHMENT_ELEVATOR": return "^1Bitte keine Elevators!";	
		case "FACEMASK_ALREADY_WEARING_DIFFERENT_TYPE": return "^1Du trägst bereits eine Maske!";		
		
		//these are used by huds so they are localized strings 
		case "BARRICADES_BLOCKER_OPEN": return &"^3[{+activate}] ^7um die Barrikade zu entfernen [^1&&1^7]";
		case "BARRICADES_DOOR_OPEN": return &"^3[{+activate}] ^7um die Tür zu öffnen [^1&&1^7]";
		case "BARRICADES_PLANK_REPAIR": return &"^3[{+activate}] ^7zum reparieren.";
		case "CAREPACKAGE_OPEN_PRESS_BUTTON": return &"^3[{+activate}] ^7um die Kiste zu öffnen [^1&&1^7]";
		case "CRAFTABLE_PICKUP_PRESS_USE": return &"^7Drücke ^3[{+activate}] ^7um das Teil aufzuheben.";
		case "CRAFTABLE_CRAFTING_PRESS_USE": return &"^7Hold ^3[{+activate}] ^7um das Teil anzubringen.";
		case "CRAFTABLE_OBJECT_PICKUP_PRESS_USE": return &"^7Drucke ^3&&1 ^7um dieses Objekt aufzuheben.";
		case "FRIDGE_GRAB_WEAPON": return &"^3[{+activate}] ^7um deine gespeicherte Waffe zu erhalten.";
		case "GENERATOR_DEPLOY_PRESS_BUTTON": return &"Drücke ^3[{+attack}] ^7um den Generator zu platzieren.";
		case "GENERATOR_PICKUP_PRESS_BUTTON": return &"^3[{+activate}] ^7um den Generator aufzuheben.";
		case "INTRO_LINE1": return &"Apocalypse";
		case "INTRO_LINE2": return &"Altay Mountains, Russia";
		case "LOCATION_HUD_POS": return &"Ort: &&1";
		case "LOCATION_HUD_POS_UNKNOWN": return &"Ort: Unbekannt";
		case "MISTERYBOX_OPEN_PRESS_BUTTON": return &"^3[{+activate}] ^7um die Box zu nutzen [^1&&1^7]";
		case "MONEY_OPEN_VAULT": return &"^3[{+activate}] ^7um auf dein Bankkonto zuzugreifen.";
		case "PACKAPUNCH_USE_PRESS_BUTTON": return &"^3[{+activate}] ^7um deine Waffe zu verbessern [^1&&1^7]";
		case "PERK_VENDING_BUY_SODA": return &"^3[{+activate}] ^7zum Kaufen von &&1";
		case "POWER_SWITCH_USE": return &"^3[{+activate}] ^7um den Strom einzuschalten.";
		case "READYUP_PRESS_BUTTON": return &"Drücke ^3[{+activate}] ^7zum bereitmachen.";
		case "READYUP_WAITING": return &"Warten bis alle Spieler bereit sind.";
		case "REVIVE_HEAL_PRESS_BUTTON": return &"Halte ^3[{+activate}] ^7um &&1^7 aufzuhelfen.";
		case "REVIVE_LAST_STAND": return &"^1Blutet aus &&1";
		case "SENTRYGUN_DEPLOY_PRESS_BUTTON": return &"Drücke ^3[{+attack}] ^7um das Sentry Turret aufzubauen.";
		case "SENTRYGUN_PICKUP_PRESS_BUTTON": return &"^3[{+activate}] ^7um das Sentry Turret abzubauen.";
		case "VEHICLE_START_PRESS_BUTTON": return &"^3[{+activate}] ^7um das Fahrzeug zu starten.";
		case "WALLWEAPON_BUY_AMMO": return &"^3[{+activate}] ^7um Munition zu kaufen [^1&&1^7]";
		case "WALLWEAPON_BUY_WEAPON": return &"^3[{+activate}] ^7zum Kaufen von &&1";
		case "FACEMASK_PICKUP_PRESS_USE": return &"^7Drücke ^3[{+activate}] ^7um die Maske aufzuheben.";
		case "GAME_OVER_SURVIVED_NO_ROUND": return &"Du hast keine Runde überlebt.";
		case "GAME_OVER_SURVIVED_SINGLE_ROUND": return &"Du hast 1 Runde überlebt.";
		case "GAME_OVER_SURVIVED_MULTIPLE_ROUNDS": return &"Du hast &&1 Runden überlebt.";
		case "MANTLE_HINT": return &"Drücken Sie ^3[{+gostand}]^7 für: ";
		
		//used by huds but NO localized strings because the are added with setText to a localized string
		case "PERK_QUICKREVIVE": return "Revive";
		case "PERK_TOMBSTONE": return "RIP";

		case "PERK_SPECIALGRENADE": return "Spezialgranaten x3";
		case "PERK_FRAGGRENADE": return "Splitter x 3";
		case "PERK_EXTRAAMMO": return "Schultergürtel";
		case "PERK_DETECTEXPLOSIVE": return "Sprengkommando";
		case "PERK_BULLETDAMAGE": return "Spezialfeuerkraft";
		case "PERK_ARMORVEST": return "Juggernaut";
		case "PERK_FASTRELOAD": return "Fingerfertigkeit";
		case "PERK_ROF": return "Doppelschuss";
		case "PERK_TWOPRIMARIES": return "Overkill";
		case "PERK_GPSJAMMER": return "Drohnenstörer";
		case "PERK_EXPLOSIVEDAMAGE": return "Überschallknall";
		case "PERK_LONGERSPRINT": return "Extrembedingungen";
		case "PERK_BULLETACCURACY": return "Ruhige Hand";
		case "PERK_PISTOLDEATH": return "Eliminator";
		case "PERK_GRENADEPULLDEATH": return "Martyrium";
		case "PERK_BULLETPENETRATION": return "Tiefenwirkung";
		case "PERK_HOLDBREATH": return "Eisenlunge";
		case "PERK_QUIETER": return "Totenstille";
		case "PERK_PARABOLIC": return "Lauschangriff";
		
		//nothing found - return empty strings
		//importand: when a localized string (&"EXAMPLE") is expected this will crash because we return a normal string
		default: return "";
	}
}