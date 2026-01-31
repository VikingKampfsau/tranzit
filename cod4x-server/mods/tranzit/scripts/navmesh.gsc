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
	level.wpAmount = 0;

	thread removeRadiantPathnodes();
	thread initWaypoints();
}

removeRadiantPathnodes()
{
	//this nodes are a leftover inside door/blocker prefabs
	//the map was compiled as sp map and the navmesh extracted with iw3xo
	//since the pathnodes are placed for the sp map compiler only we can safely remove them and free an entity slot
	entities = getEntArray();
	for(i=0;i<entities.size;i++)
	{
		if(isDefined(entities[i].classname) && entities[i].classname == "node_pathnode")
			entities[i] delete();
	}
}

initWaypoints()
{
	fileName =  "waypoints/"+ toLower(getDvar("mapname")) + "_waypoints.csv";
	fileNameLua = getDvar("fs_game") + "/" + fileName;

	//verify the file before import
	if(fs_testFile(fileName))
	{
		//consolePrint("^3file " + fileName + " exists\n");
	
		file = openFile(fileName, "read");
		if(file > 0)
		{
			//consolePrint("^3file opened for reading\n");
		
			verified = undefined;
			while(1)
			{
				line = fReadLn(file);
				
				//if undefined then we reached the end of file
				if(!isDefined(line))
				{
					consolePrint("^3waypoint file is empty\n");
					break;
				}

				if(isEmptyString(line))
				{
					//consolePrint("^3empty line\n");
					continue;
				}
					
				tokens = strTok(line, ",");
				if(tokens.size >= 4)
				{
					//consolePrint("^3columns: " + tokens.size + "\n");
				
					//one column is missing, could be map area info
					if(tokens.size == 4)
						verified = false;
					//with 5 columns the file might be correct
					else
						verified = true;

					break;
				}
			}
			
			closeFile(file);
			
			if(!isDefined(verified))
			{
				consolePrint("^1waypoint csv is not valid - aborting!\n");
				return;
			}
			else
			{
				if(!verified)
				{
					//consolePrint("^3adding missing areas\n");
					thread scripts\debug\navmeshtool::addMapAreaToWaypointFile();
					level waittill("navmeshtool_finished_addMapAreaToWaypointFile");
				}
				//else
				//	consolePrint("^3file complete\n");
			}
		}
	
		consolePrint("^3file action complete\n");

		level.wpAmount = loadWaypoints_Internal( fileNameLua );
	}
	
	//tranzit waypoints csv found and read
	if(isDefined(level.wpAmount) && level.wpAmount > 0)
	{
		//this is not necessary anymore - we compile path nodes in a sp map
		//so running the sp map and debugging the path nodes is way easier 
		//thread createGscWaypointFileForDebuggingOnLocalClient();
	
		//free the variable just in case we have a map with additional waypoints in gsc
		level.waypoints = undefined;
		return;
	}
	
	consolePrint("\n");
	
	//no tranzit waypoints csv in waypoints folder
	//check for rotu waypoints
	consolePrint("^1No tranZit WP csv found\n");
	//a gsc included in map and called by its scripts?
	consolePrint("^1Looking for build-in WP gsc\n");
	if(isDefined(level.waypoints))
	{
		consolePrint("^1Map build-in WP gsc found\n");
		//nothing to do here
	}
	//a csv included in map?
	else
	{
		consolePrint("^1No map build-in WP gsc found\n");
		consolePrint("^1Looking for map build-in WP csv\n");
		importWaypointsToArray();
	}
	
	//no build-in waypoints found
	if(!isDefined(level.waypoints))
	{
		//check for pezbot waypoints gsc in same place
		//-->
		consolePrint("^1No map build-in WP csv found\n");
		consolePrint("^1Looking for PezBots WP gsc call\n");
		waypoints\select_map::choose();
		
		//free the variable in case no waypoints were loaded
		if(!isDefined(level.waypoints) || level.waypoints.size <= 0)
		{
			level.waypoints = undefined;
			consolePrint("^1No PezBots WP call found\n");
			consolePrint("^1Looking for WP gsc\n");
		
			//is there a gsc/gsx in waypoints folder?
			if(fs_testFile("waypoints\\" + level.script + "_waypoints.gsc") || fs_testFile("waypoints\\" + level.script + "_waypoints.gsx"))
			{
				consolePrint("^1WP gsc found - updating PezBots WP gsc call\n");
			
				//update a fake file to be able to load the gsc
				file = openFile("waypoints/select_map.gsx", "write");

				if(file > 0)
				{
					fPrintLn(file, "choose()");
					fPrintLn(file, "{");
					fPrintLn(file, "\tlevel.waypointCount = 0;");
					fPrintLn(file, "\tlevel.waypoints = [];");
					fPrintLn(file, "\t");
					fPrintLn(file, "\tif(level.script == \"" + level.script +"\") { waypoints\\" + level.script + "_waypoints::load_waypoints(); return; }");
					fPrintLn(file, "}");

					closeFile(file);
					
					consolePrint("^1PezBots WP gsc call updated - restarting map\n");
					exec("map_restart"); //map_restart(false); default CoD4 function is just a fast_restart -> we need a full map restart to access the updated select_map.gsx!
				}
			}
			else
			{
				consolePrint("^1No WP gsc found\n");
			}
		}
	}
	//<--
	
	//map has build-in waypoints or a gsc/gsx in waypoints folder
	if(isDefined(level.waypoints))
	{
		//convert them to tranzit waypoint file (csv) for faster access
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
	
	if(level.waypoints.size <= 0)
		level.waypoints = undefined;
}

//important: lua arrays start with index 1 not 0
//so we have to increase the wp and child id by 1
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
				string = string + level.waypoints[i].children.size + ",";
			
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
				
				//consolePrint(wpID + "," + string + "\n");
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
	
		if(isDefined(path))
		{
			path = imProvePath(path);
			
			//i don't have the feeling that this changes anything
			//path = findEntryPoint(path);

			return path;
		}
	}
	
	return undefined;
}

imProvePath(path)
{
	if(path.size == 1)
		return path;

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
			else if(CharacterPhysicsTrace(false, curWpOrigin, nextWpOrigin) == nextWpOrigin)
			{
				//consolePrint(nextPos + " is a free way - might skip this\n");
				prevTraceWorked = true;
				
				//do i need that?
				//only skip it when there is no hole (like roof at loading area)
				loops = int(Distance2d(curWpOrigin, nextWpOrigin) / 20);
				for(j=1;j<=loops;j++)
				{
					forward = VectorNormalize(nextWpOrigin - curWpOrigin);
					if(BulletTracePassed(curWpOrigin + anglesToForward(forward)*20*j, curWpOrigin - (0,0,50) + anglesToForward(forward)*20*j, false, undefined))
					{
						prevTraceWorked = false;
						break;
					}
				}
				
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

findEntryPoint(path)
{
	offset = (0,0,5);

	tempPath = [];
	tempPath[0] = path[path.size -1];

	for(nextPos = (path.size -1); nextPos>=0; nextPos--)
	{
		nextWpOrigin = getWpOrigin(path[nextPos]) + offset;
	
		if(CharacterPhysicsTrace(false, self.origin, nextWpOrigin) == nextWpOrigin)
		{
			tempPath[tempPath.size] = path[nextPos];
			break;
		}
		
		tempPath[tempPath.size] = path[nextPos];
	}
	
	return tempPath;
}

/* for debugging on a local client instead of a server */
createGscWaypointFileForDebuggingOnLocalClient()
{
	consolePrint("^3converting waypoint csv to gsc\n");

	entryNo = 0;
	exportArea = 2;
	maxWpId = 4995;

	importFileName =  "waypoints/" + level.script + "_waypoints.csv";
	exportFileName = "waypoints/" + level.script + "_waypoints.gsc";

	if(fs_testFile(importFileName))
	{
		importFile = openFile(importFileName, "read");
		exportFile = openFile(exportFileName, "write");
		
		if(importFile <= 0)
		{
			consolePrint("^3could not open import file for reading\n");
			return;
		}
		
		if(exportFile <= 0)
		{
			consolePrint("^3could not open export file for writing\n");
			return;
		}

		consolePrint("^3importFile opened for reading\n");
		consolePrint("^3exportFile opened for writing\n");

		FS_WriteLine(exportFile, "load_waypoints()");
		FS_WriteLine(exportFile, "{");
	
		while(1)
		{
			importLine = fReadLn(importFile);
			
			//if undefined then we reached the end of file
			if(!isDefined(importLine))
			{
				consolePrint("^3file is empty\n");
				break;
			}

			if(isEmptyString(importLine))
			{
				consolePrint("^3empty line\n");
				continue;
			}
				
			tokens = strTok(importLine, ",");
			if(tokens.size >= 4)
			{
				waypointData = spawnstruct();
				waypointData.id = int(tokens[0]);
				waypointData.origin = strTok(tokens[1], " ");
				waypointData.childCount = int(tokens[2]);
				
				//skip unlinked waypoints
				if(!isDefined(waypointData.childCount) || waypointData.childCount <= 0)
					continue;
				
				waypointData.children = strTok(tokens[3], " ");
				waypointData.area = int(tokens[4]);
				
				if(exportArea <= 0 || waypointData.area == exportArea)
				{
					FS_WriteLine(exportFile, "    level.waypoints[" + entryNo + "] = spawnstruct();");
					FS_WriteLine(exportFile, "    level.waypoints[" + entryNo + "].id = " + waypointData.id + ";");
					FS_WriteLine(exportFile, "    level.waypoints[" + entryNo + "].area = " + waypointData.area + ";");
					FS_WriteLine(exportFile, "    level.waypoints[" + entryNo + "].origin = " + "(" + waypointData.origin[0] + ", " + waypointData.origin[1] + ", " + waypointData.origin[2] + ");");		
					
					childNo = 0;
					for(c=0;c<waypointData.childCount;c++)
					{
						waypointData.children[c] = int(waypointData.children[c]);
						if(waypointData.children[c] > maxWpId)
							continue;
						
						//if we export a certain area only:
						//check if the child is in the same area, otherwise the waypoint info is not found
						//since we can not write ALL waypoints into an arry (var overflow) we have to receive the additional info from lua
						childArea = getWpArea(waypointData.children[c]);
						//consolePrint("getting area for wp " + waypointData.children[c] + ": " + childArea + "\n");
						
						if(exportArea > 0 && isDefined(childArea) && childArea == exportArea)
						{
							FS_WriteLine(exportFile, "    level.waypoints[" + entryNo + "].children[" + childNo + "] = " + waypointData.children[c] + ";");
						
							childNo++;
						}
					}
					
					FS_WriteLine(exportFile, "    level.waypoints[" + entryNo + "].childCount = " + childNo + ";");
					
					entryNo++; 
				}
			}
		}

		FS_WriteLine(exportFile, " ");
		FS_WriteLine(exportFile, "    level.waypointCount = level.waypoints.size;");
		FS_WriteLine(exportFile, "}");

		consolePrint("Waypoints converted\n");
		
		closeFile(importFile);
		closeFile(exportFile);
		
		consolePrint("^3import and export file closed\n");
	}
}