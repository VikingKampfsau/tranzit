local vertices = {}
local tempFileArray = {}
local filepath = nil
local filename = nil
local waypointCount = 0

Plugin_ScrAddFunction("lua_createNavMeshFile")
Plugin_ScrAddFunction("lua_copyFile")

------------------------
-- local functions
------------------------

function isint(n)
  return n==math.floor(n)
end

--[[local function split(source, delimiters)
	local tempArray = {}
	for str in string.gmatch(source, '([^' .. delimiters .. ']+)') do
		table.insert(tempArray, str)
	end

	return tempArray
end]]--

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

local function VectorLengthSquared(vec3)

	return ((vec3[1] * vec3[1]) + (vec3[2] * vec3[2]) + (vec3[3] * vec3[3]))
end

local function VectorAdd(v1, v2)
  	
	local vec3 = {}
	vec3[1] = v1[1] + v2[1]
	vec3[2] = v1[2] + v2[2]
	vec3[3] = v1[3] + v2[3]
	return vec3
end

local function VectorSubtract(v1, v2)

	local vec3 = {}
	vec3[1] = v1[1] - v2[1]
	vec3[2] = v1[2] - v2[2]
	vec3[3] = v1[3] - v2[3]
	return vec3
end

local function Vec3DistanceSq(v1, v2)

	local vec3 = VectorSubtract(v1, v2)
	return VectorLengthSquared(vec3)
end

local function dist_between(v1, v2)

	--return Vec3DistanceSq(v1, v2)
	return math.sqrt(Vec3DistanceSq(v1, v2))
end

local function getTriangleCenterPos(edges)
	local calc = VectorAdd(edges[1], edges[2])
	calc = VectorAdd(calc, edges[3])

	local center = calc
	center[1] = center[1] / 3
	center[2] = center[2] / 3
	center[3] = center[3] / 3

	return center
end

local function getRectangleCenterPos(edges)
	local calc = VectorAdd(edges[1], edges[2])
	calc = VectorAdd(calc, edges[3])
	calc = VectorAdd(calc, edges[4])

	local center = calc
	center[1] = center[1] / 4
	center[2] = center[2] / 4
	center[3] = center[3] / 4

	return center
end

function collectVertexNeighbourInfo(index)

	local result = nil

	-- triangle max 3 neighbours
	-- rectangle max 4 neighbours
	if(vertices[index].nghbrCount == 0) then
		Plugin_Printf("ERROR: Vertex " .. index .. " at (" .. vertices[index].origin[1] .. ", " .. vertices[index].origin[2] .. ", " .. vertices[index].origin[3] .. ") has no neighbours\n -> Check your source file or increase the dvar <create_navmesh_rectside> if the rectside is bigger than the current dvar value. \n")
	end
	
	local temp = ""

	for i=1, vertices[index].nghbrCount, 1 do
		if i == 1 then
			temp = vertices[index].nghbr[i].wpIdx
		else
			temp = temp .. " " .. vertices[index].nghbr[i].wpIdx
		end
	end

	result = "," .. temp

	return result
end

------------------------
-- core functions
------------------------

local function init_vertex(input, curEntry)

	--Plugin_Printf("curEntry is: " .. curEntry .. " \n")

	-- first cut of the array index --
	input = split(input, ",")

	--Plugin_Printf("input is: " .. input[1] .. " \n")
	
	-- fecth the 3 (or 4) origins of the vertices --
	local tempArray = split(input[2], ";")
	
	-- prepare the global array --
	vertices[curEntry] = {}
	vertices[curEntry].wpIdx = curEntry -- 1 --the table in file starts counting from 0 so -1
	vertices[curEntry].edges = {}
	vertices[curEntry].nghbr = {}
	vertices[curEntry].nghbrCount = 0
	
	-- collect origins of the edges --
	for i=1, #tempArray, 1 do
		local newTempArray = split(tempArray[i], " ")
		vertices[curEntry].edges[i] = {tonumber(newTempArray[1]), tonumber(newTempArray[2]), tonumber(newTempArray[3])}

		--Plugin_Printf("Edge found at " .. vertices[curEntry].edges[i][1] .. ", " .. vertices[curEntry].edges[i][2] .. ", " .. vertices[curEntry].edges[i][3] .. "\n")
	end

	-- check the geo type --
	local isTriangle = false
	
	-- if this geo has 3 edges only it's a triangle and there are no further checks to perform
	if #vertices[curEntry].edges == 3 then
		isTriangle = true
	end

	-- 2of4 edges are identical = triangle, 4 different edges = rectangle --
	if not isTriangle then
		for i=1, #vertices[curEntry].edges, 1 do
			for j=#vertices[curEntry].edges, 1, -1 do
				if j == i then
					break
				end
					
				if vertices[curEntry].edges[i] == vertices[curEntry].edges[j] then
					isTriangle = true
					break
				end
			end
		end
	end

	-- set the geo type and fetch the center pos --
	if isTriangle then
		--Plugin_Printf("Geo is a trianlge \n") 

		vertices[curEntry].type = "triangle"
		vertices[curEntry].origin = getTriangleCenterPos(vertices[curEntry].edges)
	else
		--Plugin_Printf("Geo is a rectanlge \n")

		vertices[curEntry].type = "rectangle"
		vertices[curEntry].origin = getRectangleCenterPos(vertices[curEntry].edges)
	end

	-- finish the function and increase the current array index
	curEntry = curEntry + 1
end

function create_neighbours(meshSide)
	Plugin_Printf("Connecting meshes - This can take some time.\n")
	
	local progress = 0
	local sharedEdges = 0

	-- create neighbours --
	for i=1, #vertices, 1 do
		progress = (100*i / #vertices)
		if isint(progress) then
			Plugin_Printf("Progress: "..progress.." percent\n")
		end

		--Plugin_Printf("i is: " .. i .. " \n")

		for j=1, #vertices, 1 do
			if j == i then
				goto skip_this_neighbour_creation
			end
	
			if dist_between(vertices[i].origin, vertices[j].origin) <= (meshSide*1.1) then --mid rectangle to mid triangle is *0,82 (rect to rect *1) but let's stay safe and use a bigger value
				--Plugin_Printf("dist vertx " .. i .. " to " .. j .. " " .. dist_between(vertices[i].origin, vertices[j].origin) .. "\n")
				sharedEdges = 0
				for k=1, #vertices[i].edges, 1 do
					for l=1, #vertices[j].edges, 1 do
						if dist_between(vertices[i].edges[k], vertices[j].edges[l]) < 2 then --depending on the rounding of radiant values i stick with 2
							sharedEdges = sharedEdges + 1
			
							-- if they share two edges then they are neighbours --
							if sharedEdges >= 2 then
								vertices[i].nghbrCount = vertices[i].nghbrCount + 1
								vertices[i].nghbr[vertices[i].nghbrCount] = vertices[j]

								--vertices[j].nghbrCount = vertices[j].nghbrCount + 1
								--vertices[j].nghbr[vertices[j].nghbrCount] = vertices[i]
								
								--Plugin_Printf("neighbour for " .. i .. "found at: " .. j .. "\n")	
	
								-- neighbour found so no further check required
								goto skip_this_neighbour_creation
							end
						end
					end
				end
			end
			
			::skip_this_neighbour_creation::
		end

		--Plugin_Printf(i.." has " .. #vertices[i].edges .. " edges \n")
		--Plugin_Printf(i.." has " .. vertices[i].nghbrCount .. " neighbours \n")
	end

	-- write them to a new file
	Plugin_Printf("Exporting result to " .. filepath .. filename .. "_waypoints.csv.tmp\n")
	local file = io.open(filepath .. filename .. "_waypoints.csv.tmp", "w")	
	
	if file then
		for i=1, #tempFileArray, 1 do
			local lineAppend = collectVertexNeighbourInfo(i)
			
			if lineAppend then
				--Plugin_Printf("lineAppend ".. lineAppend .. "\n")
				waypointCount = waypointCount + 1
				file:write(waypointCount..",".. vertices[i].origin[1] .. " ".. vertices[i].origin[2] .. " " .. vertices[i].origin[3] .. lineAppend, "\n")
			end
		end

		file:close()	
	else
		Plugin_Scr_Error("Could not write export file " .. filepath .. filename .. "_waypoints.csv.tmp\n")
		return
	end

end

function lua_createNavMeshFile()
	local counter = 1

	-- read the csv and create the mesh --	
	filepath = Plugin_Scr_GetString(0)
	filename = Plugin_Scr_GetString(1)
	local file = io.open(filepath..filename.."_navmesh.csv", "r")
	
	Plugin_Printf("Looking for navmesh file in: " .. filepath .. "\n")

	if file then
		for line in file:lines() do
			if string.find(line, ";") == nil then
				goto skip_line_import
			end
		
			--Plugin_Printf("Counter is: " .. counter .. " \n")
			--Plugin_Printf("Line is: " .. line .. " \n")
		
			init_vertex(line, counter)
			tempFileArray[counter] = line
			counter = counter + 1
			
			::skip_line_import::
		end
		
		file:close()	
	else
		Plugin_Scr_Error("Navmesh file not found or not readable.\n")
		return
	end

	Plugin_Printf("Navmesh file found and read.\n")

	local meshSide = Plugin_Scr_GetFloat(2)
	create_neighbours(meshSide)

	Plugin_Printf("Navmesh imported and " .. waypointCount .. " waypoints created.\n")
end

function lua_copyFile()
	pathSource = Plugin_Scr_GetString(0)
	pathTarget = Plugin_Scr_GetString(1)

	local fileSource = io.open(pathSource, "r")
	local fileTarget = io.open(pathTarget, "w")

	if fileSource then
		Plugin_Printf("^1fileSource file found and read.\n")
	else
		Plugin_Scr_Error("Failed to read file: "..pathSource.."\n")
	end
	if fileTarget then
		Plugin_Printf("^1fileTarget file found and read.\n")
	else
		Plugin_Scr_Error("Failed to write file: "..pathTarget.."\n")
	end

	if (fileSource and fileTarget) then
		for line in fileSource:lines() do
			fileTarget:write(line, "\n")
		end
		
		fileSource:close()
		fileTarget:close()
	else
		Plugin_Scr_Error("Failed to copy file: "..pathSource.." to "..pathTarget.."\n")
		return
	end
end
