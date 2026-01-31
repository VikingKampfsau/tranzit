#include scripts\_include;

//create_spawnfile 0/1/2
//	1 -> convert the radiant spawns into csv
//	2 -> add the mapareas to an existing spawn csv of step 1

//create_navmesh 0/1
//	1 -> add the mapareas to an existing waypoint csv

//navmeshtool_cleanup 0/1/2
//	1 -> delete all temp files but dont move the output to the waypoints folder
//	2 -> delete all temp files and move the output to the waypoints folder
init()
{
	if(getDvarInt("developer") <= 0)
		return;

	//the default value to use when the spawn/waypoint is not inside a playarea
	//"0" will make the path calc loop through all existing waypoints
	//"999" maybe gets around this and the path calc will just loop through waypoints with this area value
	level.NoMapAreaValue = "999"; //"0";

	if(getDvar("navmeshtool_cleanup") == "")
		setDvar("navmeshtool_cleanup", 2);

	if( getDvarInt("create_spawnfile") > 0 )
	{
		if( getDvarInt("create_spawnfile") < 2 )
		{
			thread createSpawnFile();
			level waittill("navmeshtool_finished_createSpawnFile");
		}
		
		thread addMapAreaToSpawnFile(0);
		level waittill("navmeshtool_finished_addMapAreaToSpawnFile");
	}

	if( getDvarInt("create_navmesh") > 0 )
	{
		thread createWaypointFile();
		level waittill("navmeshtool_finished_createWaypointFile");
	}
	
	if( getDvarInt("create_spawnfile") > 0 || getDvarInt("create_navmesh") > 0 )
	{
		if( getDvarInt("navmeshtool_cleanup") > 0 )
			cleanupExportFolder();
		
		setDvar("create_spawnfile", 0);
		setDvar("create_navmesh", 0);		
	
		consolePrint("\n");
		consolePrint("\n");
		consolePrint("^2Navmesh/Spawn creation finished\n");
		consolePrint("Stopping server...\n");
		consolePrint("/quit\n");
		consolePrint("\n");
		consolePrint("\n");
	
		wait 3;
	
		exec("quit");
		
		wait 9999;
	}
}

createSpawnFile()
{
	wait .1; //used to make sure the notify/waittill works

	spawns = [];		// array with all spawns in the map file
	spawn = undefined;

	//import *.map file
	filePath = "navmeshtool/import/" + level.script + "_spawns.map";
	if(!fs_testFile(filePath))
	{
		consolePrint( "Could not import file - aborting\n" );
		level notify("navmeshtool_finished_createSpawnFile");
		return;
	}
	else
	{
		file = fs_fOpen( filePath, "read" );
		if(file > 0)
		{
			// count the number of lines we've read
			curLineNum = 0;
			while(1)
			{
				ResetTimeout();
			
				string = fs_ReadLine(file);
				curLineNum++;
				
				//if undefined then we reached the end of file
				if( !isDefined(string) )
				{
					//consolePrint("EOF\n");
					break;
				}
		
				//search for "origin", "classname" or "targetname"
				while( isSubStr(string, "origin") || isSubStr(string, "classname") || isSubStr(string, "targetname") )
				{
					//consolePrint("Found potential spawn at line " + curLineNum + ", reading.\n");
					
					// setup a variable for the new spawn entry
					if(!isDefined(spawn))
					{
						spawn = spawnStruct();		// the new spawn data
						spawn.origin = undefined;
						spawn.team = undefined;
						spawn.group = undefined;
					}

					// split the line up
					toks = strTok( string, " " );
					if( isSubStr(string, "origin") )
					{
						// NOTE
						// toks[0] = "origin"
						// toks[1] = the origin vector x
						// toks[2] = the origin vector y
						// toks[3] = the origin vector z
						// all others are irrelevant
						
						if(toks.size < 4)
							continue;

						spawn.origin = (toks[1] + " " + toks[2] + " " + toks[3]);
						spawn.origin = getSubStr(spawn.origin, 1 , spawn.origin.size-1);
						spawn.origin = StrRepl(spawn.origin, "\"", "");
					}
					else if( isSubStr(string, "targetname") )
					{
						// NOTE
						// toks[0] = "targetname"
						// toks[1] = targetname like "scripted_tunnel_spawn"
						// all others are irrelevant

						spawn.group = toks[1];
					}
					else if( isSubStr(string, "classname") )
					{
						// NOTE
						// toks[0] = "classname"
						// toks[1] = spawn type like "mp_dm_spawn"
						// all others are irrelevant

						if(isSubStr(toks[1], "mp_dm_spawn"))
							spawn.team = "axis"; //zombie
						else if(isSubStr(toks[1], "mp_tdm_spawn"))
							spawn.team = "allies"; //survivor
						else
							break; //not an entity we can import for spawning
					}
			
					// read the next line
					string = fs_ReadLine(file);
					curLineNum++;

					// make sure there actually is a line
					if( !isDefined(string) )
					{
						consolePrint( "End of file during entity block - aborting!\n" );
						level notify("navmeshtool_finished_createSpawnFile");
						return;
					}
			
					//skip empty lines
					while( string == "" || string == " " )
					{
						// read the next line
						string = fs_ReadLine(file);
						curLineNum++;

						// make sure there actually is a line
						if( !isDefined(string) )
						{
							consolePrint( "End of file during entity block - aborting!\n" );
							level notify("navmeshtool_finished_createSpawnFile");
							return;
						}
						
						// trim off leading and trailing spaces
						string = trim(string);
					}

					//end of entity
					if( string == "}" || string == "}\r")
					{
						//consolePrint( "Found eof entity at line " + curLineNum + ".\n" );
					
						if( !isDefined(spawn.group) )
							spawn.group = " ";
						
						if( isDefined(spawn.team) && isDefined(spawn.origin) )
						{
							spawns[spawns.size] = spawn;
							spawn = undefined;
						}
							
						break;
					}

				}//while(isSubStr())
			}// while(1)
			
			consolePrint( "Read " + curLineNum + " lines - found " + spawns.size + " spawns.\n" );
		
			fs_fClose(file);
		
			//export to csv
			filePath = "navmeshtool/export/" + level.script + "_spawns.csv.tmp";
			file = fs_fOpen(filePath, "write");

			if( file > 0 )
			{
				consolePrint( "id,team,origin,group,maparea\n" );
				//FS_WriteLine( file, "id,team,origin,group,maparea" );
			
				for( i=0; i<spawns.size; i++ )
				{
					spawn = spawns[i];
					string = spawn.team + "," + spawn.origin + "," + spawn.group; 
					
					consolePrint( i + "," + string + "\n");
					FS_WriteLine( file, i + "," + string );
				}

				//consolePrint( "spawns," + i + "\n" );
				//FS_WriteLine( file, "spawns," + i );

				fs_fClose(file);
			}
			else
			{
				consolePrint( "Could not export file - aborting\n" );
				level notify("navmeshtool_finished_createSpawnFile");
				return;
			}
		}
		
		level notify("navmeshtool_finished_createSpawnFile");
	}
}

addMapAreaToSpawnFile(startAtLineNo)
{
	wait .1; //used to make sure the notify/waittill works

	if(!isDefined(startAtLineNo))
		startAtLineNo = 0;

	filePath = "navmeshtool/export/" + level.script + "_spawns.csv";
	inputFile = openFile(filePath + ".tmp", "read");
	
	if(startAtLineNo > 0)
		outputFile = openFile(filePath, "append");
	else
	{
		consolePrint("Adding maparea to spawn file\n");

		if(!isDefined(level.mapAreas) || !level.mapAreas.size)
		{
			consolePrint("^1No mapAreas defined yet - aborting\n");
			level notify("navmeshtool_finished_addMapAreaToSpawnFile");
			return;
		}
	
		outputFile = openFile(filePath, "write");
	}
	
	if(inputFile > 0 && outputFile > 0)
	{
		line = "";
		curLineNum = 0;
	
		if(startAtLineNo > 0)
		{
			for(i=0;i<startAtLineNo;i++)
			{
				line = fReadLn(inputFile);
				curLineNum++;
			}
		}
	
		while(1)
		{
			//have to do this to avoid hitting the var limit
			//during the tests i was able to run up to 9.000
			//so 5000 should be fine to use
			if((curLineNum - startAtLineNo) >= 5000)
			{
				thread addMapAreaToSpawnFile(curLineNum);
				break;
			}
		
			line = fReadLn(inputFile);
			curLineNum++;
			
			if(!isDefined(line) || line == "" || line == " ")
				break;

			maparea = level.NoMapAreaValue;

			point = strTok(line, ",")[2];
			point = strTok(point, " ");
			point = (float(point[0]), float(point[1]), float(point[2]));
			
			for(i=0;i<level.mapAreas.size;i++)
			{
				if(pointInTrigger(point, level.mapAreas[i]))
				{
					maparea = level.mapAreas[i].spawner_id;
					break;
				}
			}
	
			FS_WriteLine(outputFile, line + "," + maparea);
		}
		
		closeFile(inputFile);
		closeFile(outputFile);
	}
	else
	{
		if(inputFile <= 0)
			consolePrint("^1inputFile not found - aborting\n");
		else
			closeFile(inputFile);

		if(outputFile <= 0)
			consolePrint("^1outputFile not found - aborting\n");
		else
			closeFile(outputFile );

	}
	
	level notify("navmeshtool_finished_addMapAreaToSpawnFile");
}

createWaypointFile(startAtLineNo)
{
	wait .1; //used to make sure the notify/waittill works

	if(!isDefined(startAtLineNo))
		startAtLineNo = 0;

	importFilePath = "navmeshtool/import/" + level.script + "_waypoints.csv";
	exportFilePath = "navmeshtool/export/" + level.script + "_waypoints.csv";
	
	if(startAtLineNo > 0)
		outputFile = openFile(exportFilePath, "append");
	else
	{
		consolePrint("createWaypointFile: Adding maparea to waypoint file\n");

		if(!isDefined(level.mapAreas) || !level.mapAreas.size)
		{
			consolePrint("^1No mapAreas defined yet - aborting\n");
			level notify("navmeshtool_finished_createWaypointFile");
			return;
		}
	
		outputFile = openFile(exportFilePath, "write");
	}
	
	inputFile = openFile(importFilePath, "read");

	if(inputFile > 0 && outputFile > 0)
	{
		line = "";
		curLineNum = 0;
	
		if(startAtLineNo > 0)
		{
			for(i=0;i<startAtLineNo;i++)
			{
				line = fReadLn(inputFile);
				curLineNum++;
			}
		}
	
		while(1)
		{
			ResetTimeout();
		
			//have to do this to avoid hitting the var limit
			//during the tests i was able to run up to 9.000
			//so 5000 should be fine to use
			if((curLineNum - startAtLineNo) >= 5000)
			{
				thread createWaypointFile(curLineNum);
				break;
			}
		
			line = fReadLn(inputFile);
			curLineNum++;
			
			//if undefined then we reached the end of file
			if(!isDefined(line))
				break;

			line = StrRepl(line, "\r", ""); 

			if(isEmptyString(line))
				continue;

			maparea = level.NoMapAreaValue;

			point = strTok(line, ",")[1];
			point = strTok(point, " ");
			point = (float(point[0]), float(point[1]), float(point[2]));
			
			for(i=0;i<level.mapAreas.size;i++)
			{
				if(pointInTrigger(point, level.mapAreas[i]))
				{
					maparea = level.mapAreas[i].spawner_id;
					break;
				}
			}
	
			FS_WriteLine(outputFile, line + "," + maparea);
		}
		
		closeFile(inputFile);
		closeFile(outputFile);
	}
	else
	{
		if(inputFile <= 0)
			consolePrint("^1inputFile '" + importFilePath + "' not found - aborting\n");
		else if(outputFile <= 0)
			consolePrint("^1outputFile '" + exportFilePath + "' not found - aborting\n");
	}
	
	level notify("navmeshtool_finished_createWaypointFile");
}

cleanupExportFolder()
{
	wait 2; //give the server a bit of time to finish writing the files

	exportPath = "navmeshtool/export/";
	waypointPath = "waypoints/";
	
	fileName[0] = level.script + "_spawns.csv";
	fileName[1] = level.script + "_waypoints.csv";
	
	for(i=0;i<fileName.size;i++)
	{
		sourceFile = exportPath + fileName[i];
		targetFile = waypointPath + fileName[i];
		tempFile = sourceFile + ".tmp";
		
		if(getDvarInt("navmeshtool_cleanup") == 2)
		{
			if(fs_testFile(sourceFile))
			{
				consolePrint("copy '" + sourceFile + "' to '" + targetFile + "'\n");
				lua_copyFile(getDvar("fs_homepath") + "/" + getDvar("fs_game") + "/" + sourceFile, getDvar("fs_homepath") + "/" + getDvar("fs_game") + "/" + targetFile);
			}
		}
			
		if(fs_testFile(sourceFile))
		{
			consolePrint("deleting sourceFile '" + sourceFile + "'\n");
			FS_Remove(sourceFile);
		}
			
		if(fs_testFile(tempFile))
		{
			consolePrint("deleting tempFile '" + tempFile + "'\n");
			FS_Remove(tempFile);
		}
	}
}

//this is not part of the navmesh which is generated from terrain info
//but is required when the navhmesh is generated with pathnodes
addMapAreaToWaypointFile(startAtLineNo)
{
	if(!isDefined(startAtLineNo))
		startAtLineNo = 0;

	filePath = "waypoints/"+ toLower(getDvar("mapname")) + "_waypoints.csv";
	
	sourceFile = getDvar("fs_homepath") + "/" + getDvar("fs_game") + "/" + filePath;
	tempFile = getDvar("fs_homepath") + "/" + getDvar("fs_game") + "/" + filePath + ".tmp";
	
	if(startAtLineNo > 0)
	{
		outputFile = openFile(filePath, "append");
		consolePrint("addMapAreaToWaypointFile: Adding maparea to waypoint file (appending)\n");
	}
	else
	{
		lua_copyFile(sourceFile, tempFile);
	
		consolePrint("addMapAreaToWaypointFile: Adding maparea to waypoint file\n");

		if(!isDefined(level.mapAreas) || !level.mapAreas.size)
		{
			consolePrint("^1No mapAreas defined yet - aborting\n");
			wait .1; //used to make sure the notify/waittill works
			level notify("navmeshtool_finished_addMapAreaToWaypointFile");
			return;
		}
	
		outputFile = openFile(filePath, "write");
	}
	
	curLineNum = 0;
	inputFile = openFile(filePath + ".tmp", "read");
	
	if(inputFile > 0 && outputFile > 0)
	{
		line = "";
		if(startAtLineNo > 0)
		{
			for(i=0;i<startAtLineNo;i++)
			{
				line = fReadLn(inputFile);
				curLineNum++;
			}
		}
	
		while(1)
		{
			//have to do this to avoid hitting the var limit
			//during the tests i was able to run up to 9.000
			//so 5000 should be fine to use
			if((curLineNum - startAtLineNo) >= 5000)
			{
				closeFile(inputFile);
				closeFile(outputFile);

				thread addMapAreaToWaypointFile(curLineNum);
				return;
			}
		
			line = fReadLn(inputFile);
			curLineNum++;
			
			//if undefined then we reached the end of file
			if(!isDefined(line))
			{
				consolePrint("EOF at " + curLineNum + "\n");
				break;
			}

			if(isEmptyString(line))
				continue;

			line = StrRepl(line, "\r", "");
			line = StrRepl(line, "\n", "");

			maparea = level.NoMapAreaValue;

			tokens = strTok(line, ",");

			point = tokens[1];
			point = strTok(point, " ");
			point = (float(point[0]), float(point[1]), float(point[2]));
			
			for(i=0;i<level.mapAreas.size;i++)
			{
				if(pointInTrigger(point, level.mapAreas[i]))
				{
					maparea = level.mapAreas[i].spawner_id;
					break;
				}
			}
			
			consolePrint(line + "\n");
			
			childCount = tokens[2];
			if(int(childCount))
				newLine = line + ", " + maparea;
			else
			{
				consolePrint("^1WP " + tokens[0] + " has no children!\n");
				newLine = line + ", " + tokens[0] + ", " + maparea;
			}
				
			newLine = StrRepl(newLine, ",,", ",");
			
			FS_WriteLine(outputFile, newLine);
		}
		
		closeFile(inputFile);
		closeFile(outputFile);
	}
	else
	{
		if(inputFile <= 0)
			consolePrint("^1inputFile not found - aborting\n");
		else if(outputFile <= 0)
			consolePrint("^1outputFile not found - aborting\n");
	}
	
	if(fs_testFile(tempFile))
		FS_Remove(tempFile);
	
	wait .1; //used to make sure the notify/waittill works
	level notify("navmeshtool_finished_addMapAreaToWaypointFile");
}