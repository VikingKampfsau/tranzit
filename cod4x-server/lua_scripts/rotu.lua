local astar = require ( "lua_scripts.astar" )

Plugin_ScrAddFunction ( "loadWaypoints_Internal" )
Plugin_ScrAddFunction ( "getNearestWp" )
Plugin_ScrAddFunction ( "getWpOrigin" )
Plugin_ScrAddFunction ( "addWpNeighbour" )
Plugin_ScrAddFunction ( "AStarSearch" )
Plugin_ScrAddFunction ( "importTeamSpawns" )
Plugin_ScrAddFunction ( "consolePrint" )

Plugin_AddCommand ( "cache_debug", 0 )

function split(str, pattern)
    -- Splits string into a table
    --
    -- str: string to split
    -- pattern: pattern to use for splitting
    local out = {}
    local i = 1
    local split_start, split_end = string.find(str, pattern, i)
    while split_start do
        out[#out + 1] = string.sub(str, i, split_start - 1)
        i = split_end + 1
        split_start, split_end = string.find(str, pattern, i)
    end
    out[#out + 1] = string.sub(str, i)
    return out
end

function consolePrint ()
	local string = Plugin_Scr_GetString ( 0 )
	Plugin_Printf(string)
end

function importTeamSpawns ()
	local team = Plugin_Scr_GetString ( 0 )
	local filepath = Plugin_Scr_GetString ( 1 )
	
	spawns = {}
	handle, err = io.open ( filepath )
	
	if err then
		return nil
	end

	local file = io.open(filepath, "r")
		
	Plugin_Printf("Looking for spawn file in: " .. filepath .. "\n")

	if file then
		Plugin_Scr_MakeArray()		--create spawns array

		for line in file:lines() do
			--Plugin_Printf("Line: " .. line .. " \n")
		
			local input = split(line, ",")
			if(#input >= 3) then
				if(input[2] == team) then
					--origin = split(input[3], " ")
					--Plugin_Scr_AddVector(origin) 	--prepare the origin for the array
					
					if(#input == 3) then
						Plugin_Scr_AddString(input[3])
					end
					if(#input == 4) then
						Plugin_Scr_AddString(input[3] .. "," .. input[4])
					end
					if(#input == 5) then
						Plugin_Scr_AddString(input[3] .. "," .. input[4] .. "," .. input[5])
					end

					Plugin_Scr_AddArray()	--save the value in the array
				end
			end
		end
		
		file:close()
	else
		Plugin_Scr_Error("Spawn file not found or not readable.\n")
		return
	end
end

function getNearestWp ()
	local vec3 = Plugin_Scr_GetVector ( 0 )
	local area = Plugin_Scr_GetInt ( 1 )
	
	if area <= 0 then
		area = nil
	end
	
	local nearestNode = astar.getNearestWp ( vec3, area )
	
	-- for gsc stored waypoints:
	--nearestNode = nearestNode - 1
	Plugin_Scr_AddInt ( nearestNode )
end

function getWpOrigin ()
	local nodeID = Plugin_Scr_GetInt ( 0 )
		
	-- for gsc stored waypoints:
	--nodeID = nodeID - 1
	
	Plugin_Scr_AddVector ( nodes[nodeID].origin )
end

function addWpNeighbour ()
	local nodeID = Plugin_Scr_GetInt ( 0 )
	local nghbrID = Plugin_Scr_GetInt ( 1 )
		
	-- for gsc stored waypoints:
	--nodeID = nodeID - 1
	--nghbrID = nghbrID - 1
	
	local exist = false

	for i=1, #nodes[nodeID].children, 1 do
		if nodes[nodeID].children[i] == nghbrID then
			exist = true
		end
	end

	if not exist then
		table.insert ( nodes[nodeID].children, nghbrID )
	end
end

function AStarSearch ()
	local start = Plugin_Scr_GetInt ( 0 )
	local goal = Plugin_Scr_GetInt ( 1 )
	local returnsize = Plugin_Scr_GetInt ( 2 )
	local returntype = Plugin_Scr_GetInt ( 3 )

	-- for gsc stored waypoints:
	--start = start + 1
	--goal = goal + 1

	local result = astar.path ( start, goal, returnsize )

	--Plugin_Printf("start " .. start .."\n")
	--Plugin_Printf("goal " .. goal .."\n\n")

	if not result then
		Plugin_Printf ( "AStarSearch: Unable to find path from WP ".. start .." to ".. goal .."\n" )
		Plugin_Scr_AddUndefined()
	else
		if returnsize <= 0 or type(result) == "number" then
			-- for gsc stored waypoints:
			--result = result - 1

			--Plugin_Printf("step " .. result .."\n")

			if returntype <= 0 then
				Plugin_Scr_AddInt(nodes[result].id)
			else
				Plugin_Scr_MakeArray()		--create path array
				Plugin_Scr_AddVector(nodes[result].origin) 	--prepare the origin for the array
				Plugin_Scr_AddArray()	--save the value in the array
			end
		else
			Plugin_Scr_MakeArray()		--create path array
			
			for i=2, #result, 1 do
				local resultID = result[i].id
				local resultIDRadiant = result[i].id + 1

				-- for gsc stored waypoints:
				--resultID = resultID - 1

				if returntype <= 0 then
					Plugin_Scr_AddInt(nodes[resultID].id)	--prepare the wpId for the array
				else
					Plugin_Scr_AddVector(nodes[resultID].origin)	--prepare the origin for the array
				end
				
				Plugin_Scr_AddArray()	--save the value in the array

				--Plugin_Printf("substep " .. resultID .. "\n")
			end
		end
	end
end

function loadWaypoints_Internal ()
	local filepath = Plugin_Scr_GetString ( 0 )
	local waypoints = astar.loadWaypoints ( filepath )
	
	if not waypoints then
		Plugin_Printf ( "loadWaypoints_Internal: Unable to load waypoint csv\n" )
		Plugin_Scr_AddInt ( 0 )
	else
		Plugin_Printf ( "loadWaypoints_Internal: " ..#waypoints.. " waypoints imported\n" )
		Plugin_Scr_AddInt ( #waypoints )
	end
end

function cache_debug ()
	local num = astar.cacheDebug ()
	Plugin_Printf ( "There are " .. num .. " cached paths\n" )
end
