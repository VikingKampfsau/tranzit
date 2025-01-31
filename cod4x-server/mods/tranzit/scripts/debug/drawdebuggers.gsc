/* debugging lines flicker on the CoD4x and should be tested on a local client */

#include scripts\_include;

/*--------------------------------------------------------------------------|
|							Draw geometry									|
|--------------------------------------------------------------------------*/
drawDebugLine(start, end, color, alpha, duration)
{
	if(!isDefined(color))
		color = (1,0,0);
		
	if(!isDefined(alpha))
		alpha = 1;
		
	if(!isDefined(duration) || int(duration) < 1)
		duration = 1;

	line(start, end, color, alpha, false, int(duration));
}

drawDebugTriangle(area, stopPrev, color, alpha, duration)
{
	if(!isDefined(stopPrev) || stopPrev)
	{
		level notify("debug_navmesh_triangle");
		level endon("debug_navmesh_triangle");
	}

	A = area.edges[0]; 
	B = area.edges[1];
	C = area.edges[2];

	if(!isDefined(color))
		color = (1,0,0);
		
	if(!isDefined(alpha))
		alpha = 1;

	if(!isDefined(duration) || int(duration) < 1)
		duration = 1;
	
	line(A, B, color, alpha, false, int(duration));
	line(B, C, color, alpha, false, int(duration));
	line(C, A, color, alpha, false, int(duration));
}

drawDebugRectangle(area, stopPrev, color, alpha, duration)
{
	if(!isDefined(stopPrev) || stopPrev)
	{
		level notify("debug_navmesh_rectangle");
		level endon("debug_navmesh_rectangle");
	}

	A = area.edges[0];
	B = area.edges[2];
	C = area.edges[3];
	D = area.edges[1];

	if(!isDefined(color))
		color = (1,0,0);
		
	if(!isDefined(alpha))
		alpha = 1;
		
	if(!isDefined(duration) || int(duration) < 1)
		duration = 1;

	line(A, B, color, alpha, false, int(duration));
	line(B, C, color, alpha, false, int(duration));
	line(C, D, color, alpha, false, int(duration));
	line(D, A, color, alpha, false, int(duration));
}

drawDebugPoint(point, duration)
{
	if(!isDefined(duration) || int(duration) < 1)
		duration = 1;

	line(point, point + (0,0, 50), (0,0,1), 1, false, int(duration));
}

/*--------------------------------------------------------------------------|
|				Draw riot shield damage detection area						|
|--------------------------------------------------------------------------*/
DebugRiotShield(A, B, C, D, vPoint, SP, eAttacker, eInflictor, alpha, duration)
{
	self notify("riot_debug_line");
	self endon("riot_debug_line");

	weapon = eAttacker getEye()/*getTagOrigin("tag_weapon_left")*/;
	
	if(isDefined(eInflictor) && eInflictor != eAttacker)
		weapon = eInflictor getTagOrigin("tag_origin");
	
	if(!isDefined(duration) || int(duration) < 1)
		duration = 1;
	
	if(!isDefined(alpha))
		alpha = 1;
	
	line(A, B, (1,0,0), alpha, false, int(duration));
	line(B, C, (1,0,0), alpha, false, int(duration));
	line(C, D, (1,0,0), alpha, false, int(duration));
	line(D, A, (1,0,0), alpha, false, int(duration));
	line(vPoint, SP, (0,1,0), alpha, false, int(duration));
	line(vPoint, weapon, (0,0,1), false, alpha, false, int(duration));
}

/*--------------------------------------------------------------------------|
|				Draw zombie spawns, waypoints and path						|
|--------------------------------------------------------------------------*/
drawZombieSpawns()
{
	while(1)
	{
		wait .05;
	
		if(!level.players.size)
			continue;
			
		if(level.players[0] isASurvivor())
		{
			for(i=0;i<level.teamSpawnPoints[game["attackers"]].size;i++)
			{
				if(Distance2D(level.players[0].origin, level.teamSpawnPoints[game["attackers"]][i].origin) <= 3000)
				{
					start = level.teamSpawnPoints[game["attackers"]][i].origin;
					end = level.teamSpawnPoints[game["attackers"]][i].origin + (0,0,100);					
					line(start, end, (0,1,0));
				}
			}
		}
	}
}

drawWaypoint(waypoint, mantleAreaWp)
{
	waypointOrigin = getWpOrigin(Waypoint);
	waypointOrigin += (0,0,5);

	//childCount = getWpNeighbourCount(Waypoint);
	children = strToK(getWpNeighbours(Waypoint), " ");

	//waypoint is not linked
	//if(!isDefined(childCount) || childCount <= 0)
	if(!isDefined(children) || children.size <= 0)
	{
		consolePrint("waypoint has no children\n");
		line(waypointOrigin, waypointOrigin + (0,0,96), (1,0,0), 1, 1);
		return;
	}
	
	line(waypointOrigin, waypointOrigin + (0,0,96), (0,1,1), 1, 1);
	
	if(children.size > 0)
	{
		if(!isDefined(mantleAreaWp))
			consolePrint("children: " + getWpNeighbours(Waypoint) + "\n");
		else
			consolePrint("children: " + getWpNeighbours(Waypoint) + " center wp " + mantleAreaWp + "\n");
	}
	
	for(j=0;j<children.size;j++)
	{
		children[j] = int(children[j]);
		childOrigin = getWpOrigin(children[j]);

		if(!isDefined(childOrigin))
			continue;
		
		childOrigin += (0,0,5);

		line(waypointOrigin, childOrigin, (0,0,1), 1, 0, 1);
		line(childOrigin, childOrigin + (0,0,96), (0,1,1), 1, 0, 1);
	}
}

drawWaypoints()
{
	while(1)
	{
		wait .5;
	
		if(!level.players.size)
			continue;
	
		if(level.players[0] isASurvivor())
		{
			level.players[0].myWaypoint = getNearestWp(level.players[0].origin, 0);

			if(!isDefined(level.players[0].myWaypoint))
			{
				consolePrint("players current waypoint not found\n");
				continue;
			}

			waypointOrigin = getWpOrigin(level.players[0].myWaypoint);
			waypointOrigin += (0,0,5);

			//childCount = getWpNeighbourCount(level.players[0].myWaypoint);
			children = strToK(getWpNeighbours(level.players[0].myWaypoint), " ");

			//waypoint is not linked
			//if(!isDefined(childCount) || childCount <= 0)
			if(!isDefined(children) || children.size <= 0)
			{
				consolePrint("waypoint has no children\n");
				line(waypointOrigin, waypointOrigin + (0,0,96), (1,0,0), 1, 1);
				continue;
			}
			
			line(waypointOrigin, waypointOrigin + (0,0,96), (0,1,1), 1, 1);
			
			for(j=0;j<children.size;j++)
			{
				children[j] = int(children[j]);
			
				childOrigin = getWpOrigin(children[j]);

				if(!isDefined(childOrigin))
					continue;
				
				childOrigin += (0,0,5);

				line(waypointOrigin, childOrigin, (0,0,1), 1, 1);
				line(childOrigin, childOrigin + (0,0,96), (0,1,1), 1, 1);
				
				//let's draw the children of this child too
				//otherwise we have to move towards it to see it's connections
				//subChildCount = getWpNeighbourCount(children[j]);
				consolePrint("subChildrens of " + children[j] + ": " + getWpNeighbours(children[j]) + "\n");
				subChildren = strToK(getWpNeighbours(children[j]), " ");

				if(!isDefined(subChildren) || subChildren.size <= 0)
					continue;

				for(k=0;k<subChildren.size;k++)
				{
					subChildren[k] = int(subChildren[k]);
				
					if(subChildren[k] == children[j])
						continue;
				
					consolePrint(subChildren[k] + "\n");
				
					subChildOrigin = getWpOrigin(subChildren[k]);
					
					if(!isDefined(subChildOrigin))
						continue;
					
					consolePrint(subChildOrigin + "\n");
					
					subChildOrigin += (0,0,5);

					line(waypointOrigin, subChildOrigin, (0,0,1), 1, 1);
					line(subChildOrigin, subChildOrigin + (0,0,96), (0,1,1), 1, 1);
				}
			}
		}
	}
}

drawDebugPath(path, color, alpha, duration)
{
	if(!isDefined(color))
		color = (1,0,0);
		
	if(!isDefined(alpha))
		alpha = 1;
		
	if(!isDefined(duration) || int(duration) < 1)
		duration = 1;

	level notify("debug_navmesh_path" + color);
	level endon("debug_navmesh_path" + color);

	if(!isDefined(path))
	{
		iPrintLnBold("path undefined - nothing to draw");
		return;
	}
		
	iPrintLnBold("path size: " + path.size);
	
	if(path.size == 1)
	{
		line(path[0], path[0] + (0,0, 50), (0,1,0), alpha, false, int(duration));
		return;
	}
	
	for(i=0;i<path.size-1;i++)
		line(path[i], path[i+1], color, alpha, false, int(duration));
}