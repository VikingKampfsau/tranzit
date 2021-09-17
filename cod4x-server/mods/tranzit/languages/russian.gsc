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
		case "CAREPACKAGE_CONTENT_NONE": return "Содержимое было сломано";
		case "CAREPACKAGE_UNABLE_TO_CALL": return "Нет свободных ящиков - сначала соберите существующий";
		case "CRAFTABLE_CRAFTING_NO_PARTS": return "У вас нет деталей для строения!";
		case "CRAFTABLE_OBJECT_PICKUP_FAIL_ALREADY_CARRY": return "Вы уже носите этот созданный предмет!";
		case "CRAFTABLE_OBJECT_PICKUP_FAIL_ALREADY_CARRY2": return "Вы уже носите созданный предмет! \n Используйте или бросьте его первым!";
		case "CRAFTABLE_PICKUP_FAIL_ALREADY_CARRY": return "Вы уже несете предмет!";
		case "CRAFTABLE_CRAFTING": return "Строится...";
		case "ERROR_MAP_NOT_WAYPOINTED": return "^1На карте нет путевых точек!";
		case "GENERATOR_BAD_SPOT": return "Недопустимое место!";
		case "PACKAPUNCH_FAIL_BAD_WEAPON": return "^1Нельзя модернизировать это оружие!";
		case "PUNISHMENT_ELEVATOR": return "^1Пожалуйста, не используйте лифт!";		
		
		//these are used by huds so they are localized strings 
		case "BARRICADES_BLOCKER_OPEN": return &"^3[{+activate}] ^7убрать баррикаду [^1&&1^7]";
		case "BARRICADES_DOOR_OPEN": return &"^3[{+activate}] ^7чтобы открыть дверь [^1&&1^7]";
		case "BARRICADES_PLANK_REPAIR": return &"^3[{+activate}] ^7чтобы починить баррикаду.";
		case "CAREPACKAGE_OPEN_PRESS_BUTTON": return &"^3[{+activate}] ^7чтобы открыть ящик [^1&&1^7]";
		case "CRAFTABLE_PICKUP_PRESS_USE": return &"^7Нажмите ^3[{+activate}] ^7чтобы забрать эту часть.";
		case "CRAFTABLE_CRAFTING_PRESS_USE": return &"^7Удерживайте ^3[{+activate}] ^7чтобы добавить свою часть.";
		case "CRAFTABLE_OBJECT_PICKUP_PRESS_USE": return &"^7Нажмите ^3&&1 ^7чтобы поднять этот предмет.";
		case "FRIDGE_GRAB_WEAPON": return &"^3[{+activate}] ^7чтобы получить ваше хранимое оружие.";
		case "GENERATOR_DEPLOY_PRESS_BUTTON": return &"Нажмите ^3[{+attack}] ^7чтобы развернуть Генератор.";
		case "GENERATOR_PICKUP_PRESS_BUTTON": return &"^3[{+activate}] ^7чтобы забрать Генератор";
		case "INTRO_LINE1": return &"Апокалипсис";
		case "INTRO_LINE2": return &"Алтайские горы, Россия";
		case "LOCATION_HUD_POS": return &"Локация: &&1";
		case "LOCATION_HUD_POS_UNKNOWN": return &"Локация: Неизвестно";
		case "MISTERYBOX_OPEN_PRESS_BUTTON": return &"^3[{+activate}] ^7чтобы использовать коробку [^1&&1^7]";
		case "MONEY_OPEN_VAULT": return &"^3[{+activate}] ^7чтобы открыть свой банковский счет.";
		case "PACKAPUNCH_USE_PRESS_BUTTON": return &"^3[{+activate}] ^7чтобы обновить свое оружие [^1&&1^7]";
		case "PERK_VENDING_BUY_SODA": return &"^3[{+activate}] ^7чтобы получить перк-а-колу [^1&&1^7]";
		case "POWER_SWITCH_USE": return &"^3[{+activate}] ^7чтобы включить электричество.";
		case "READYUP_PRESS_BUTTON": return &"Нажмите ^3[{+activate}] ^7для готовности к бою!";
		case "READYUP_WAITING": return &"Ожидаем, когда все игроки будут готовы";
		case "REVIVE_HEAL_PRESS_BUTTON": return &"Удерживайте ^3[{+activate}] ^7чтобы возродить &&1^7.";
		case "REVIVE_LAST_STAND": return &"^1Истекаете кровью, умрёте через: &&1";
		case "SENTRYGUN_DEPLOY_PRESS_BUTTON": return &"Нажмите ^3[{+attack}] ^7чтобы развернуть Турель.";
		case "SENTRYGUN_PICKUP_PRESS_BUTTON": return &"^3[{+activate}] ^7чтобы забрать Турель";
		case "VEHICLE_START_PRESS_BUTTON": return &"^3[{+activate}] ^7чтобы завести транспорт.";
		case "WALLWEAPON_BUY_AMMO": return &"^3[{+activate}] ^7чтобы купить патроны [^1&&1^7]";
		case "WALLWEAPON_BUY_WEAPON": return &"^3[{+activate}] ^7чтобы купить оружие [^1&&1^7]";
		
		//nothing found - return empty strings
		//importand: when a localized string (&"EXAMPLE") is expected this will crash because we return a normal string
		default: return "";
	}
}