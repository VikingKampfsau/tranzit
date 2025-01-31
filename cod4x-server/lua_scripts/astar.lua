-- ======================================================================
-- Copyright (c) 2012 RapidFire Studio Limited 
-- All Rights Reserved. 
-- http://www.rapidfirestudio.com

-- Permission is hereby granted, free of charge, to any person obtaining
-- a copy of this software and associated documentation files (the
-- "Software"), to deal in the Software without restriction, including
-- without limitation the rights to use, copy, modify, merge, publish,
-- distribute, sublicense, and/or sell copies of the Software, and to
-- permit persons to whom the Software is furnished to do so, subject to
-- the following conditions:

-- The above copyright notice and this permission notice shall be
-- included in all copies or substantial portions of the Software.

-- THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
-- EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
-- MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
-- IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
-- CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
-- TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
-- SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
-- ======================================================================

local astar = {}

----------------------------------------------------------------
-- global variables
----------------------------------------------------------------

nodes = nil
playarea_nodes = nil

----------------------------------------------------------------
-- local variables
----------------------------------------------------------------

local INF = 1/0
local cachedPaths = nil
--local nodes = nil
local cachedNum = 0

----------------------------------------------------------------
-- local functions
----------------------------------------------------------------

local function VectorLengthSquared ( vec3 )

	return ( ( vec3 [ 1 ] * vec3 [ 1 ] ) + ( vec3 [ 2 ] * vec3 [ 2 ] ) + ( vec3 [ 3 ] * vec3 [ 3 ] ) )
end

local function VectorSubtract ( v1, v2 )

	local vec3 = {}
	vec3 [ 1 ] = v1 [ 1 ] - v2 [ 1 ]
	vec3 [ 2 ] = v1 [ 2 ] - v2 [ 2 ]
	vec3 [ 3 ] = v1 [ 3 ] - v2 [ 3 ]
	return vec3
end

local function Vec3DistanceSq ( v1, v2 )

	local vec3 = VectorSubtract ( v1, v2 )
	return VectorLengthSquared ( vec3 )
end

local function dist_between ( nodeA, nodeB )

	return Vec3DistanceSq ( nodeA.origin, nodeB.origin )
end

local function heuristic_cost_estimate ( nodeA, nodeB )

	return Vec3DistanceSq ( nodeA.origin, nodeB.origin )
end

local function lowest_f_score ( set, f_score )

	local lowest, bestNode = INF, nil
	for _, node in ipairs ( set ) do
		local score = f_score [ node ]
		if score < lowest then
			lowest, bestNode = score, node
		end
	end
	return bestNode
end


local function neighbor_nodes ( theNode )

	local neighbors = {}
	for _, nodenum in ipairs ( theNode.children ) do
			table.insert ( neighbors, nodes [ nodenum ] )
	end
	return neighbors
end

local function not_in ( set, theNode )

	for _, node in ipairs ( set ) do
		if node == theNode then return false end
	end
	return true
end

local function remove_node ( set, theNode )

	for i, node in ipairs ( set ) do
		if node == theNode then 
			set [ i ] = set [ #set ]
			set [ #set ] = nil
			break
		end
	end	
end

local function unwind_path ( flat_path, map, current_node )

	if map [ current_node ] then
		table.insert ( flat_path, 1, map [ current_node ] ) 
		return unwind_path ( flat_path, map, map [ current_node ] )
	else
		return flat_path
	end
end

local function strtok ( inputstr, sep )

	local t = {}
	for str in string.gmatch ( inputstr, "([^"..sep.."]+)" ) do
		table.insert ( t, str )
	end
	return t
end

local function buildNodes ( tokens )

	local protonode = {}
	protonode.id = tonumber ( tokens[ 1 ] [ 1 ] )
	protonode.origin = {}
	protonode.children = {}
	
	for _, org in ipairs ( tokens [ 2 ] ) do
		table.insert ( protonode.origin, tonumber ( org ) )
	end
	
	protonode.linkedChildAmount = tonumber ( tokens[ 3 ] [ 1 ] )
	
	for _, child in ipairs ( tokens [ 4 ] ) do
		local realchild = tonumber ( child )
		
		-- for gsc stored waypoints:
		--realchild = realchild + 1

		if realchild ~= protonode.id then
			table.insert ( protonode.children, realchild )
		end
	end
	
	if tokens[ 5 ] == nil then
		protonode.area = 999
	else
		protonode.area = tonumber ( tokens[ 5 ] [ 1 ] )
	end
	
	table.insert ( nodes, protonode )
end

local function buildPlayareaNodes ( )
	for _, node in ipairs ( nodes ) do
		if node.area > 0 then
			table.insert ( playarea_nodes[node.area], node )
		end
	end
end

local function clearAll ()

	nodes, cachedPaths = nil, nil
	cachedNum = 0
	
	collectgarbage()
	collectgarbage()
end

----------------------------------------------------------------
-- pathfinding functions
----------------------------------------------------------------

local function a_star ( start, goal )

	local closedset = {}
	local openset = { start }
	local came_from = {}

	local g_score, f_score = {}, {}
	g_score [ start ] = 0
	f_score [ start ] = heuristic_cost_estimate ( start, goal )

	local current = nil
	while #openset > 0 do
	
		current = lowest_f_score ( openset, f_score )
		if current == goal then
			local path = unwind_path ( {}, came_from, goal )
			table.insert ( path, goal )
			return path
		end

		remove_node ( openset, current )		
		table.insert ( closedset, current )
		
		local neighbors = neighbor_nodes ( current )
		for _, neighbor in ipairs ( neighbors ) do 
			if not_in ( closedset, neighbor ) then
			
				local tentative_g_score = g_score [ current ] + dist_between ( current, neighbor )
				 
				if not_in ( openset, neighbor ) or tentative_g_score < g_score [ neighbor ] then 
					came_from 	[ neighbor ] = current
					g_score 	[ neighbor ] = tentative_g_score
					f_score 	[ neighbor ] = g_score [ neighbor ] + heuristic_cost_estimate ( neighbor, goal )
					if not_in ( openset, neighbor ) then
						table.insert ( openset, neighbor )
					end
				end
			end
		end
	end

	--if current then
	--	Plugin_Printf("path from " .. start.id .. " (" .. start.origin[1] .. ", " .. start.origin[2] .. ", " .. start.origin[3] .. ")\nto " .. goal.id .. " (" .. goal.origin[1] .. ", " .. goal.origin[2] .. ", " .. goal.origin[3] .. ")\nfailed at: " .. current.id .. " (" .. current.origin[1] .. ", " .. current.origin[2] .. ", " .. current.origin[3] .. ")\n\n")
	--end

	return nil -- no valid path
end

----------------------------------------------------------------
-- exposed functions
----------------------------------------------------------------

function astar.cacheDebug ()

	return cachedNum
end

function astar.path ( start, goal, returnsize )

	--[[local isCached = 1
	if not cachedPaths [ start ] then
		cachedPaths [ start ] = {}
		isCached = nil
	elseif cachedPaths [ start ] [ goal ] then
		Plugin_Printf("path return 1\n")
		return cachedPaths [ start ] [ goal ]
	end
	
	-- Check for cached children of start node
	for _, child in ipairs ( nodes [ start ].children ) do
		if cachedPaths [ child ] and cachedPaths [ child ] [ goal ] then
			Plugin_Printf("path return 2\n")
			return child
		end
	end
	
	-- Check for cached children of goal node
	if isCached then 
		for _, child in ipairs ( nodes [ goal ].children ) do
			if cachedPaths [ start ] [ child ] then
				Plugin_Printf("path return 3\n")
				return cachedPaths [ start ] [ child ]
			end
		end
	end]]--

	local resPath = a_star ( nodes[ start ], nodes[ goal ] )
	if not resPath then
		--Plugin_Printf("path return 4\n")
		return nil
	end
	
	--[[local paths = {}
	for _, node in ipairs ( resPath ) do
		table.insert ( paths, node.id )
	end
	
	for i, id in ipairs ( paths ) do
		if id == goal then
			break
		end
		
		if not cachedPaths [ id ] then
			cachedPaths [ id ] = {}
		end
		if not cachedPaths [ id ] [ goal ] then
			local n = i + 1
			cachedPaths [ id ] [ goal ] = paths [ n ] -- Cache only next node
			cachedNum = cachedNum + 1
		end
	end]]--

	if returnsize <= 0 then
		--Plugin_Printf("path return 5\n")
		return resPath[ 2 ].id
	end

	--Plugin_Printf("path return 6\n")
	return resPath
end

function astar.getNearestWp ( origin, playarea )

	local nearestWp = -1
	local nearestDist = 99999999999
	local dist = nil
	
	if playarea == nil then
		searchIn = nodes
	else
		searchIn = playarea_nodes[playarea]
	end

	for _, node in ipairs ( searchIn ) do
		dist =  Vec3DistanceSq ( origin, node.origin )
		
		if dist < nearestDist then
			nearestDist = dist
			nearestWp = node.id
		end
	end
	
	return nearestWp
end

function astar.loadWaypoints ( filename )

	clearAll ()
	
	nodes = {}
	cachedPaths = {}

	playarea_nodes = {}
	for i=1, 100, 1 do -- 100 playareas should enough xD
		playarea_nodes[i] = {}
	end
	
	playarea_nodes[999] = {} -- and define one far from others to be used for wasteland waypoints
	
	handle, err = io.open ( filename )
	
	if err then
		print("could not load "..filename.."\n")
		return nil
	end

	while true do
		local line = handle:read ()
		if not line then
			break
		end
		
		--print(line.."\n")

		local tokens = {}
		tokens.fisttok = strtok ( line, "," )
		tokens.finaltok = {}
		
		for _, tok in ipairs ( tokens.fisttok ) do
			local ftok = strtok ( tok, "%s" )
			table.insert ( tokens.finaltok, ftok )
		end
		
		buildNodes ( tokens.finaltok )
	end
	
	buildPlayareaNodes()
	
	return nodes
end	

return astar
