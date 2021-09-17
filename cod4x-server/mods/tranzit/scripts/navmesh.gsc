//comparison A* and Theta*
//example (image there is nothing blocking the way
//A* makes the bot stick to the path
//result:
//	Start x----WP
//				\
//				 WP__WP
//					 /
//				y___/
//			Target  WP
//
//Theta* also checks if there is nothing that could block the way
//result:
//	Start x
//		   \
//		    \
//			 y Target

#include scripts\_include;
#include scripts\debug\drawdebuggers;

init()
{
	fileName =  "waypoints/"+ toLower(getDvar("mapname")) + "_waypoints.csv";
	fileNameLua = getDvar( "fs_game" ) + "/" + fileName;

	level.wpAmount = loadWaypoints_Internal( fileNameLua );
	
	if(isDefined(level.wpAmount) && level.wpAmount > 0)
	{
		//free the variable just in case we have a map with waypoints in gsc
		level.waypoints = undefined;
		return;
	}
	
	//no waypoints found - check rotu waypoints
	if(isDefined(level.waypoints)) //gsc?
	{
		consolePrint("^1WP gsc found\n");
		//nothing to do right now
	}
	else //csv?
	{
		consolePrint("^1WP csv found\n");
		importWaypointsToArray();
	}
	
	if(isDefined(level.waypoints))
	{
		writeWaypointFileToHDD();

		//free the variable
		level.waypoints = undefined;
		level.wpAmount = loadWaypoints_Internal( fileNameLua );
	}
}

importWaypointsToArray()
{
	// workaround for maps with script waypoints, e.g stock maps
	if(isDefined(level.waypoints) && level.waypoints.size > 0)
		return;

	level.waypoints = [];
	level.waypointCount = 0;
	level.waypointLoops = 0;

	// create the full filepath for the waypoint csv file
	fileName =  "waypoints/"+ toLower(getDvar("mapname")) + "_wp.csv";

	// get the waypoint count, then get all the waypoint data
	level.waypointCount = int(tableLookup(fileName, 0, 0, 1));
	for(i=0; i<level.waypointCount; i++)
	{
		// create a struct for each waypoint
		waypoint = spawnStruct();
		
		// get the origin and seperate it into x, y and z values
		origin = tableLookup(fileName, 0, i+1, 1);
		orgToks = strtok(origin, " ");
		
		// convert the origin to a vector3
		waypoint.origin = (float(orgToks[0]), float(orgToks[1]), float(orgToks[2]));
		
		// save the waypoint into the waypoints array
		level.waypoints[i] = waypoint;
	}

	// go through all waypoints and link them
	for(i=0; i<level.waypointCount; i++)
	{
		waypoint = level.waypoints[i]; 
		
		// get the children waypoint IDs and seperate them
		strLnk = tableLookup(fileName, 0, i+1, 2);
		tokens = strTok(strLnk, " ");
		
		// set the waypoints children count
		waypoint.childCount = tokens.size;
		
		// add all the children as integers
		for(j=0; j<tokens.size; j++)
			waypoint.children[j] = int(tokens[j]);
	}
}

//important: lua arrays start with index 1 not 0
//so we have to increase the wp and childid by 1
writeWaypointFileToHDD()
{
	//loop through all waypoints to find unlinked (no children)
	badEntries = [];
	for(i=0;i<level.waypoints.size;i++)
	{
		if(!isDefined(level.waypoints[i].children) || !level.waypoints[i].children.size)
			badEntries[badEntries.size] = i;
	}

	//export to csv
	filePath = "waypoints/"+ toLower(getDvar("mapname")) + "_waypoints.csv";
	file = fs_fOpen(filePath, "write");

	if(file > 0)
	{
		for(i=0;i<level.waypoints.size;i++)
		{
			string = level.waypoints[i].origin[0] + " " + level.waypoints[i].origin[1] + " " + level.waypoints[i].origin[2] + ","; 
			
			if(isDefined(level.waypoints[i].children) && level.waypoints[i].children.size > 0)
			{
				for(j=0;j<level.waypoints[i].children.size;j++)
				{
					childID = level.waypoints[i].children[j] + 1;
					for(y=0;y<badEntries.size;y++)
					{
						if(childID > badEntries[y])
							childID--;
					}
					
					string = string + childID + " ";
				}
				
				wpID = i + 1;
				for(y=0;y<badEntries.size;y++)
				{
					if(wpID > badEntries[y])
						wpID--;
				}
				
				consolePrint(wpID + "," + string + "\n");
				printLn(wpID + "," + string);
				FS_WriteLine(file, wpID + "," + string);
			}
		}

		fs_fClose(file);
	}
}

PathfindingAlgorithm(startWp, goalWp)
{
	if(isDefined(startWp) && isDefined(goalWp))
	{
		pathReturnSize =  1; //0 = next step, 1 = full path (used in this mod)
		pathReturnType =  0; //0 = wpId (used in this mod), 1 = wpOrigin
		path = AStarSearch(startWp, goalWp, pathReturnSize, pathReturnType);
	
		if(isDefined(path) && path.size > 1)
		{
			// for path debugging
			if(isDefined(self.debugMyPath) && self.debugMyPath)
			{
				//thread drawDebugPath(path, (1,0,0), 1, 999);
				//self.debugMyPath = false;
			
				/*for(i=0;i<path.size;i++)
				{
					if(pathReturnType)
						consolePrint(i + ": " + path[i] + "\n");
					else
						consolePrint(i + ": " + path[i] + " = " + getWpOrigin(path[i]) + "\n");
				}*/
			}
		
			path = imProvePath(path);

			return path;
		}
	}
	
	return undefined;
}

imProvePath(path)
{
	/*consolePrint("old:\n");
	for(i=0;i<path.size;i++)
		consolePrint(i + ": " + path[i] + "\n");*/
	
	offset = (0,0,5);

	tempPath = [];
	tempPath[0] = path[path.size -1];

	for(curPos = (path.size -1); curPos>=0; curPos--)
	{
		prevTraceWorked = false;
		for(nextPos = (curPos -1); nextPos>=0; nextPos--)
		{
			//consolePrint(curPos + " -> " + nextPos + "\n");

			curWpOrigin = getWpOrigin(path[curPos]) + offset;
			nextWpOrigin = getWpOrigin(path[nextPos]) + offset;

			if(barricadeInPath(nextWpOrigin))
			{
				//consolePrint(nextPos + " is a barricade - skip this\n");
				
				prevTraceWorked = true;
				continue;
			}
			else if(PlayerPhysicsTrace(curWpOrigin, nextWpOrigin) == nextWpOrigin)
			{
				//consolePrint(nextPos + " is a free way - skip this\n");
				
				prevTraceWorked = true;
				continue;
			}			
			else
			{
				if(prevTraceWorked)
				{
					nextPos++;
					curPos = nextPos + 1;
				}

				tempPath[tempPath.size] = path[nextPos];
				
				//consolePrint(nextPos + " saved; curPos increased: " + curPos + "\n");
				break;
			}
		}
		
		if(nextPos < 0)
		{
			//consolePrint("nextPos is the path start - break\n");
			
			if(tempPath[tempPath.size -1] != path[0])
				tempPath[tempPath.size] = path[0];

			break;
		}
	}
	
	tempPath = reverseArray(tempPath);
	
	/*consolePrint("new:\n");
	for(i=0;i<tempPath.size;i++)
		consolePrint("newPath[newPath.size] = " + tempPath[i] + "; //i + : " + tempPath[i] + "\n");*/
	
	return tempPath;
}

barricadeInPath(waypointPos)
{
	if(isDefined(waypointPos) && isDefined(level.barricades))
	{
		for(i=0;i<level.barricades.size;i++)
		{
			if(Distance2d(waypointPos, level.barricades[i].origin) < 20 && abs(level.barricades[i].origin[2] - waypointPos[2]) <= 75)
				return true;
		}
	}

	return false;
}