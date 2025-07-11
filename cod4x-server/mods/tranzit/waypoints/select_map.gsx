choose()
{
	level.waypointCount = 0;
	level.waypoints = [];
	
	if(level.script == "mp_strike") { waypoints\mp_strike_waypoints::load_waypoints(); return; }
}
