#include common_scripts\utility;
#include maps\mp\_utility;

#include scripts\_include;

init()
{
	game["tranzit"].weaponDrop = [];
	game["tranzit"].weaponDrop["curdrops"] = 0;
	game["tranzit"].weaponDrop["maxdrops"] = 10;
	game["tranzit"].weaponDrop["livetime"] = 300;
}

dropWeaponOnDeath()
{
	//drop the "best" weapon on death
	//what is the "best" weapon? strongest?
	//but isn't an auto rifle better than a sniper rifle?
	//for now drop the last used weapon
	weapon = self.lastUsedWeapon;
	if(!isDefined(weapon) || !self hasWeapon(weapon))
		weapon = self getCurrentWeapon();

	if(!isDropableWeapon(weapon))
		return;
	
	if(!self hasWeapon(weapon))
		return;
	
	if(!self AnyAmmoForWeaponModes(weapon))
		return;
	
	clipAmmo = self GetWeaponAmmoClip(weapon);
	if(clipAmmo <= 0)
		return;

	stockAmmo = self GetWeaponAmmoStock(weapon);
	stockMax = WeaponMaxAmmo(weapon);
	if(stockAmmo > stockMax)
		stockAmmo = stockMax;

	item = self dropItem(weapon);

	item ItemWeaponSetAmmo(clipAmmo, stockAmmo);
	//item maps\mp\gametypes\_weapons::itemRemoveAmmoFromAltModes();
	
	item.owner = self;
	
	item thread watchPickup();
	item thread deletePickupAfterAWhile();
}

dropWeaponOnResponse()
{
	if(game["tranzit"].weaponDrop["curdrops"] >= game["tranzit"].weaponDrop["maxdrops"])
		return;

	//drop the strongest weapon on death only
	//on manual call drop the current weapon
	weapon = self getCurrentWeapon();

	if(!isDropableWeapon(weapon))
		return;

	//no ammo at all
	if(!self AnyAmmoForWeaponModes(weapon))
	{
		self takeWeapon(weapon);
		return;
	}
	
	clipAmmo = self GetWeaponAmmoClip(weapon);
	stockAmmo = self GetWeaponAmmoStock(weapon);
	stockMax = WeaponMaxAmmo(weapon);
	if(stockAmmo > stockMax)
		stockAmmo = stockMax;
	
	item = self dropItem(weapon);
	item ItemWeaponSetAmmo(clipAmmo, stockAmmo);
	//item maps\mp\gametypes\_weapons::itemRemoveAmmoFromAltModes();
	
	item.owner = self;
	item.origin -= (0,0,-999999);
	item hide();
	
	//should this be done here or when the item is visible through item show() again?
	//let's keep it here and do some tests
	item thread watchPickup();
	
	//already start that here
	//in case we can spawn a physicsObject it would be good if it's deleted when thrown out of map
	item thread deletePickupAfterAWhile();
	
	//move the startpos for the throw a bit back to avoid throwing through walls
	offsetVec = self getTagOrigin("tag_weapon_right") - self.origin;
	forward = AnglesToForward(self getPlayerAngles());
	forwardOffset = vectorDot(offsetVec, forward);
	
	tracestartPos = self getTagOrigin("tag_weapon_right") - forward * abs(forwardOffset);
	traceEndPos = self getTagOrigin("tag_weapon_right");
	
	trace = bulletTrace(tracestartPos, traceEndPos, false, self);
	if(trace["fraction"] < 1) //arm is in a wall
	{
		origin = trace["position"];
		force = forward * 300 * trace["fraction"];
	}
	else
	{
		origin = traceEndPos;
		force = forward * 600;
	}
	
	angles = self getTagAngles("tag_weapon_right") + (RandomInt(15), RandomInt(15), RandomInt(15));
	model = getWeaponModel(weapon, 0);
	
	item.physObj = spawnPhysicsObject(model, origin, angles, force);
	
	//failed to create a physics model - delete the script_model and do the default weapon drop
	if(item.physObj.classname == "script_model")
	{
		item.physObj delete();
		item.origin += (0,0,-999999);
		item show();
		return;
	}
	
	item.physObj thread deleteOnParentRemoval(item);
	item.physObj maps\mp\gametypes\_weapons::waitTillNotMoving();
	
	item.origin = item.physObj.origin;
	item.angles = item.physObj.angles;
	item show();
	
	//reset the alive time
	item thread deletePickupAfterAWhile();
	
	item.physObj delete();
}

deleteOnParentRemoval(parent)
{
	self endon("death");
	
	while(isDefined(parent))
		wait .5;
	
	if(isDefined(self))
		self delete();
}

deletePickupAfterAWhile()
{
	self notify("deletePickupAfterAWhile_only_once");
	self endon("deletePickupAfterAWhile_only_once");

	self endon("death");
	
	wait game["tranzit"].weaponDrop["livetime"];

	if(isDefined(self.physObj))
		self.physObj delete();

	if(!isDefined(self))
		return;

	game["tranzit"].weaponDrop["curdrops"]--;

	self delete();
}

watchPickup()
{
	self endon("death");
	
	weapname = self maps\mp\gametypes\_weapons::getItemWeaponName();
	
	while(1)
	{
		self waittill( "trigger", player, droppedItem );
		
		//VIKING - I have no idea when this loop breaks but when the weapon is picked up or ammo is received then
		//'self endon("death")' fires and stops this function.
		//my guess is that the loop breaks (and is restarted a bit down) when not the full ammo is picked up from ground
		if ( isdefined( droppedItem ) )
			break;
			
		// otherwise, player merely acquired ammo and didn't pick this up
	}
		
	/#
	if ( getdvar("scr_dropdebug") == "1" )
		println( "picked up weapon: " + weapname + ", " + isdefined( self.ownersattacker ) );
	#/

	assert( isdefined( player.tookWeaponFrom ) );
	
	// make sure the owner information on the dropped item is preserved
	droppedWeaponName = droppedItem maps\mp\gametypes\_weapons::getItemWeaponName();
	if ( isdefined( player.tookWeaponFrom[ droppedWeaponName ] ) )
	{
		droppedItem.owner = player.tookWeaponFrom[ droppedWeaponName ];
		droppedItem.ownersattacker = player;
		player.tookWeaponFrom[ droppedWeaponName ] = undefined;
	}
	droppedItem thread watchPickup();
	
	// take owner information from self and put it onto player
	if ( isdefined( self.ownersattacker ) && self.ownersattacker == player )
	{
		player.tookWeaponFrom[ weapname ] = self.owner;
	}
	else
	{
		player.tookWeaponFrom[ weapname ] = undefined;
	}
}