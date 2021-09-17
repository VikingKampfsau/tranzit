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