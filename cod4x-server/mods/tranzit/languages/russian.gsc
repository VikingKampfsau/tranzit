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
		case "CAREPACKAGE_CONTENT_NONE": return "���������� ���� �������";
		case "CAREPACKAGE_UNABLE_TO_CALL": return "��� ��������� ������ - ������� �������� ������������";
		case "CRAFTABLE_CRAFTING_NO_PARTS": return "� ��� ��� ������� ��� ��������!";
		case "CRAFTABLE_OBJECT_PICKUP_FAIL_ALREADY_CARRY": return "�� ��� ������ ���� ��������� �������!";
		case "CRAFTABLE_OBJECT_PICKUP_FAIL_ALREADY_CARRY2": return "�� ��� ������ ��������� �������! \n ����������� ��� ������� ��� ������!";
		case "CRAFTABLE_PICKUP_FAIL_ALREADY_CARRY": return "�� ��� ������ �������!";
		case "CRAFTABLE_CRAFTING": return "��������...";
		case "ERROR_MAP_NOT_WAYPOINTED": return "^1�� ����� ��� ������� �����!";
		case "GENERATOR_BAD_SPOT": return "������������ �����!";
		case "PACKAPUNCH_FAIL_BAD_WEAPON": return "^1������ ��������������� ��� ������!";
		case "PUNISHMENT_ELEVATOR": return "^1����������, �� ����������� ����!";	
		case "FACEMASK_ALREADY_WEARING_DIFFERENT_TYPE": return "�� ��� � �����!";
		
		//these are used by huds so they are localized strings 
		case "BARRICADES_BLOCKER_OPEN": return &"^3[{+activate}] ^7������ ��������� [^1&&1^7]";
		case "BARRICADES_DOOR_OPEN": return &"^3[{+activate}] ^7����� ������� ����� [^1&&1^7]";
		case "BARRICADES_PLANK_REPAIR": return &"^3[{+activate}] ^7����� �������� ���������.";
		case "CAREPACKAGE_OPEN_PRESS_BUTTON": return &"^3[{+activate}] ^7����� ������� ���� [^1&&1^7]";
		case "CRAFTABLE_PICKUP_PRESS_USE": return &"^7������� ^3[{+activate}] ^7����� ������� ��� �����.";
		case "CRAFTABLE_CRAFTING_PRESS_USE": return &"^7����������� ^3[{+activate}] ^7����� �������� ���� �����.";
		case "CRAFTABLE_OBJECT_PICKUP_PRESS_USE": return &"^7������� ^3&&1 ^7����� ������� ���� �������.";
		case "FRIDGE_GRAB_WEAPON": return &"^3[{+activate}] ^7����� �������� ���� �������� ������.";
		case "GENERATOR_DEPLOY_PRESS_BUTTON": return &"������� ^3[{+attack}] ^7����� ���������� ���������.";
		case "GENERATOR_PICKUP_PRESS_BUTTON": return &"^3[{+activate}] ^7����� ������� ���������";
		case "INTRO_LINE1": return &"�����������";
		case "INTRO_LINE2": return &"��������� ����, ������";
		case "LOCATION_HUD_POS": return &"�������: &&1";
		case "LOCATION_HUD_POS_UNKNOWN": return &"�������: ����������";
		case "MISTERYBOX_OPEN_PRESS_BUTTON": return &"^3[{+activate}] ^7����� ������������ ������� [^1&&1^7]";
		case "MONEY_OPEN_VAULT": return &"^3[{+activate}] ^7����� ������� ���� ���������� ����.";
		case "PACKAPUNCH_USE_PRESS_BUTTON": return &"^3[{+activate}] ^7����� �������� ���� ������ [^1&&1^7]";
		case "PERK_VENDING_BUY_SODA": return &"^3[{+activate}] ^7����� ������ &&1";
		case "POWER_SWITCH_USE": return &"^3[{+activate}] ^7����� �������� �������������.";
		case "READYUP_PRESS_BUTTON": return &"������� ^3[{+activate}] ^7��� ���������� � ���!";
		case "READYUP_WAITING": return &"�������, ����� ��� ������ ����� ������";
		case "REVIVE_HEAL_PRESS_BUTTON": return &"����������� ^3[{+activate}] ^7����� ��������� &&1^7.";
		case "REVIVE_LAST_STAND": return &"^1��������� ������, ����� ����� &&1";
		case "SENTRYGUN_DEPLOY_PRESS_BUTTON": return &"������� ^3[{+attack}] ^7����� ���������� ������.";
		case "SENTRYGUN_PICKUP_PRESS_BUTTON": return &"^3[{+activate}] ^7����� ������� ������";
		case "VEHICLE_START_PRESS_BUTTON": return &"^3[{+activate}] ^7����� ������� ���������.";
		case "WALLWEAPON_BUY_AMMO": return &"^3[{+activate}] ^7����� ������ ������� [^1&&1^7]";
		case "WALLWEAPON_BUY_WEAPON": return &"^3[{+activate}] ^7����� ������ ������ &&1";
		case "FACEMASK_PICKUP_PRESS_USE": return &"^7������� ^3[{+activate}] ^7��������� �����.";
		case "GAME_OVER_SURVIVED_NO_ROUND": return &"�� �� �������� �� ������ ������.";
		case "GAME_OVER_SURVIVED_SINGLE_ROUND": return &"�� �������� ���� �����.";
		case "GAME_OVER_SURVIVED_MULTIPLE_ROUNDS": return &"�� �������� &&1 �������.";
		case "MANTLE_HINT": return &"������� ^3[{+gostand}]^7 �����: ";
		
		//used by huds but NO localized strings because the are added with setText to a localized string
		case "PERK_QUICKREVIVE": return "Revive";
		case "PERK_TOMBSTONE": return "RIP";

		case "PERK_SPECIALGRENADE": return "������ ������� x3";
		case "PERK_FRAGGRENADE": return "���������� x 3";
		case "PERK_EXTRAAMMO": return "���������";
		case "PERK_DETECTEXPLOSIVE": return "�������� �������";
		case "PERK_BULLETDAMAGE": return "������� ����";
		case "PERK_ARMORVEST": return "�����������";
		case "PERK_FASTRELOAD": return "�������� ���";
		case "PERK_ROF": return "������� �������";
		case "PERK_TWOPRIMARIES": return "�������";
		case "PERK_GPSJAMMER": return "��������� �����";
		case "PERK_EXPLOSIVEDAMAGE": return "������� �����";
		case "PERK_LONGERSPRINT": return "������������� ����������";
		case "PERK_BULLETACCURACY": return "����������� ������";
		case "PERK_PISTOLDEATH": return "��������� �������";
		case "PERK_GRENADEPULLDEATH": return "�������";
		case "PERK_BULLETPENETRATION": return "����������� ����";
		case "PERK_HOLDBREATH": return "�������� ������";
		case "PERK_QUIETER": return "������� ������";
		case "PERK_PARABOLIC": return "�������������";
		
		//nothing found - return empty strings
		//importand: when a localized string (&"EXAMPLE") is expected this will crash because we return a normal string
		default: return "";
	}
}