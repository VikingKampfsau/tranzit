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
		case "PERK_VENDING_BUY_SODA": return &"^3[{+activate}] ^7����� �������� ����-�-���� [^1&&1^7]";
		case "POWER_SWITCH_USE": return &"^3[{+activate}] ^7����� �������� �������������.";
		case "READYUP_PRESS_BUTTON": return &"������� ^3[{+activate}] ^7��� ���������� � ���!";
		case "READYUP_WAITING": return &"�������, ����� ��� ������ ����� ������";
		case "REVIVE_HEAL_PRESS_BUTTON": return &"����������� ^3[{+activate}] ^7����� ��������� &&1^7.";
		case "REVIVE_LAST_STAND": return &"^1��������� ������, ����� �����: &&1";
		case "SENTRYGUN_DEPLOY_PRESS_BUTTON": return &"������� ^3[{+attack}] ^7����� ���������� ������.";
		case "SENTRYGUN_PICKUP_PRESS_BUTTON": return &"^3[{+activate}] ^7����� ������� ������";
		case "VEHICLE_START_PRESS_BUTTON": return &"^3[{+activate}] ^7����� ������� ���������.";
		case "WALLWEAPON_BUY_AMMO": return &"^3[{+activate}] ^7����� ������ ������� [^1&&1^7]";
		case "WALLWEAPON_BUY_WEAPON": return &"^3[{+activate}] ^7����� ������ ������ [^1&&1^7]";
		
		//nothing found - return empty strings
		//importand: when a localized string (&"EXAMPLE") is expected this will crash because we return a normal string
		default: return "";
	}
}