#include scripts\_include;

//create_spawnfile 0/1	
//	1 -> convert the radiant spawns into csv
//	2 -> add the mapareas to an existing spawn csv of step 1

//create_navmesh 0/1/2/3
//	1 -> move the mesh to the ground and save it into a new map file
//	2 -> convert the radiant mesh into csv
//	3 -> build the waypoint csv from an existing output of step 2
//	4 -> add the mapareas to an existing waypoint csv of step 3

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

	if(getDvarFloat("create_navmesh_rectside") <= 0)
		setDvar("create_navmesh_rectside", 500);

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
		updateZValueInMapFile = false;
		if( getDvarInt("create_navmesh") == 1 )
			updateZValueInMapFile = true;
		
		if( getDvarInt("create_navmesh") < 3 )
		{
			thread createNavMeshFile(updateZValueInMapFile);
			level waittill("navmeshtool_finished_createNavMeshFile");
		}

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
	wait .1; //used to makes sure the notify/waittill works

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
					break;
		
				//search for "origin", "classname" or "targetname"
				while( isSubStr(string, "origin") || isSubStr(string, "classname") || isSubStr(string, "targetname") )
				{
					printLn( "Found potential spawn at line " + curLineNum + ", reading." );
					
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
					if( string == "}" )
					{
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
			
			printLn( "Read " + curLineNum + " lines." );
		
			fs_fClose(file);
		
			//export to csv
			filePath = "navmeshtool/export/" + level.script + "_spawns.csv.tmp";
			file = fs_fOpen(filePath, "write");

			if( file > 0 )
			{
				//printLn( "id,team,origin,group,maparea" );
				//FS_WriteLine( file, "id,team,origin,group,maparea" );
			
				for( i=0; i<spawns.size; i++ )
				{
					spawn = spawns[i];
					string = spawn.team + "," + spawn.origin + "," + spawn.group; 
					
					printLn( i + "," + string );
					FS_WriteLine( file, i + "," + string );
				}

				//printLn( "spawns," + i );
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
	wait .1; //used to makes sure the notify/waittill works

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
				if(pointInGeometry(point, level.mapAreas[i], true))
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
		else if(outputFile <= 0)
			consolePrint("^1outputFile not found - aborting\n");
	}
	
	level notify("navmeshtool_finished_addMapAreaToSpawnFile");
}

createNavMeshFile(updateZValueInMapFile)
{
	wait .1; //used to makes sure the notify/waittill works

	shapes = [];		// array with all shapes in the map file

	//import *.map file
	filePath = "navmeshtool/import/" + level.script + "_navmesh.map";
	if(!fs_testFile(filePath))
	{
		consolePrint( "Could not import file - aborting\n" );
		level notify("navmeshtool_finished_createNavMeshFile");
		return;
	}
	else
	{
		fileExport = undefined;
		if(updateZValueInMapFile)
		{
			fileExport = fs_fOpen( filePath + "_grounded.map", "write" );
			
			if(fileExport <= 0)
			{
				consolePrint( "Could not create updated map file - aborting\n" );
				level notify("navmeshtool_finished_createNavMeshFile");
				return;
			}
		}
	
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
					break;

				if(updateZValueInMapFile)
					FS_WriteLine( fileExport, string );
				
				//search for "mesh", every mesh is one navhmesh shape to process
				if( isSubStr(string, "mesh") )
				{
					printLn( "Found new shape at line " + curLineNum + ", reading." );
					
					// setup a variable for the new shape
					shape = [];		// the new shape data
					
					// continue to read the file
					while(1)
					{
						// read the next line
						newline = fs_ReadLine(file);
						curLineNum++;

						// make sure there actually is a line
						if( !isDefined(newline) )
						{
							consolePrint( "End of file during mesh block - aborting!\n" );
							level notify("navmeshtool_finished_createNavMeshFile");
							return;
						}
					
						// skip empty lines
						if( newline == "" || newline == " " )
							continue;
					
						// trim off leading and trailing spaces
						newline = trim(newline);
						
						// check if the mesh section is over
						if( getSubStr(newline, 0, 1) == "}" )
						{
							if(updateZValueInMapFile)
								FS_WriteLine( fileExport, newline );
						
							printLn( "Read full shape, moving on." );
							break;		// leave the while(1)
						}
						else if( getSubStr(newline, 1, 2) == "v" )
						{
							// split the line up
							toks = strTok( newline, " " );
							// make sure the part we care about is present
							if( isDefined(toks) && isDefined(toks[1]) && isDefined(toks[2]) && isDefined(toks[3]) )
							{
								// NOTE
								// toks[0] = "v"
								// toks[1] = x
								// toks[2] = y
								// toks[3] = z
								// all others are irrelevant
							
								// make a new point from the given data
								point = (float(toks[1]), float(toks[2]), float(toks[3]));
								
								if(updateZValueInMapFile)
								{
									ground = BulletTrace(point + (0,0,5), point - (0,0,5000), false, undefined);
									
									if(isDefined(ground["position"]))
										toks[3] = ground["position"][2] + 5;
									
									updatedZLine = "";
									for(u=0;u<toks.size;u++)
										updatedZLine = updatedZLine + toks[u] + " ";
									
									FS_WriteLine( fileExport, updatedZLine );
								}
								
								// filter dummy points, aka points that are too close together
								is_dummy = false;
								for( i=0; i<shape.size; i++ )
								{
									// check every point already in the shape against the new one
									if( shape[i] == point )
									{
										consolePrint( "Skipping dummy at " + point + "\n" );
										is_dummy = true;
										break;
									}
								}
								
								// save valid points to the shape
								if( !is_dummy )
									shape[shape.size] = point;
							}
							else
							{
								consolePrint( "Line " + curLineNum + " is invalid - aborting!\n" );
								level notify("navmeshtool_finished_createNavMeshFile");
								return;
							}
						}
						else
						{
							if(updateZValueInMapFile)
								FS_WriteLine( fileExport, "  " + newline );
						}
						// NOTE all other lines aren't relevant for us, we care about } and v
					}	// while(1)
					
					// save the shape into our global array
					shapes[shapes.size] = shape;
				}
			}	// while(1)
			
			printLn( "Read " + curLineNum + " lines." );
		
			fs_fClose(file);
			
			if(updateZValueInMapFile)
			{
				fs_fClose(fileExport);
				level notify("navmeshtool_finished_createNavMeshFile");
				return;
			}
			
			//export to csv
			filePath = "navmeshtool/export/" + level.script + "_navmesh.csv";
			file = fs_fOpen(filePath, "write");

			if( file > 0 )
			{
				printLn( "id,verts" );
				FS_WriteLine( file, "id,verts" );
			
				for( i=0; i<shapes.size; i++ )
				{
					shape = shapes[i];
					string = shape[0][0] + " " + shape[0][1] + " " + shape[0][2];
					for( j=1; j<shape.size; j++ )
						string = string + ";" + shape[j][0] + " " + shape[j][1] + " " + shape[j][2];
					
					printLn( i + "," + string );
					FS_WriteLine( file, i + "," + string );
				}

				printLn( "navmesh," + i );
				FS_WriteLine( file, "navmesh," + i );

				fs_fClose(file);
			}
			else
			{
				consolePrint( "Could not export file - aborting\n" );
				level notify("navmeshtool_finished_createNavMeshFile");
				return;
			}
		}
	}
	
	level notify("navmeshtool_finished_createNavMeshFile");
}

createWaypointFile(startAtLineNo)
{
	wait .1; //used to makes sure the notify/waittill works

	if(!isDefined(startAtLineNo))
		startAtLineNo = 0;

	filePath = "navmeshtool/export/" + level.script + "_waypoints.csv";
	
	if(startAtLineNo > 0)
		outputFile = openFile(filePath, "append");
	else
	{
		if( getDvarInt("create_navmesh") < 4 )
		{
			filePath = getDvar("fs_homepath") + "/" + getDvar("fs_game") + "/" + "navmeshtool/export/";
			lua_createNavMeshFile(filePath, level.script, getDvarFloat("create_navmesh_rectside"));
			
			//the game can not access the created "_waypoints.csv.tmp" from lua
			//so restart this function
			setDvar("create_navmesh", 4);
			thread createWaypointFile(0);
			return;
		}

		consolePrint("Adding maparea to waypointfile\n");

		if(!isDefined(level.mapAreas) || !level.mapAreas.size)
		{
			consolePrint("^1No mapAreas defined yet - aborting\n");
			level notify("navmeshtool_finished_createWaypointFile");
			return;
		}
	
		outputFile = openFile(filePath, "write");
	}
	
	inputFile = openFile(filePath + ".tmp", "read");

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
			
			if(!isDefined(line) || line == "" || line == " ")
				break;

			maparea = level.NoMapAreaValue;

			point = strTok(line, ",")[1];
			point = strTok(point, " ");
			point = (float(point[0]), float(point[1]), float(point[2]));
			
			for(i=0;i<level.mapAreas.size;i++)
			{
				if(pointInGeometry(point, level.mapAreas[i], true))
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
		else if(outputFile <= 0)
			consolePrint("^1outputFile not found - aborting\n");
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
		sourceFile = getDvar("fs_homepath") + "/" + getDvar("fs_game") + "/" + exportPath + fileName[i];
		targetFile = getDvar("fs_homepath") + "/" + getDvar("fs_game") + "/" + waypointPath + fileName[i];
		tempFile = sourceFile + ".tmp";
		
		if( getDvarInt("navmeshtool_cleanup") == 2 )
			lua_copyFile(sourceFile, targetFile);
			
		if(fs_testFile(sourceFile))
			FS_Remove(sourceFile);
			
		if(fs_testFile(tempFile))
			FS_Remove(tempFile);
	}
}
