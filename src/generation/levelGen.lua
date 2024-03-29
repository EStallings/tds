--[[
	Responsible for generating rooms in a variety of patterns, and linking them
	with doors in such a way that every room is accessible
]]--

MAX_TILE = 16
WALL_TYPE_WALL   = 0
WALL_TYPE_THIN   = 1
WALL_TYPE_WINDOW = 2

function generatePass1(initx, inity, globalWidth, globalHeight, gindex)
	local grid = {};
	local head = nil;
	local randomSeed = love.math.random(2000) 
	-- local randomSeed = 176 
	love.math.setRandomSeed(randomSeed)
	print("Seed: "..randomSeed)
	--helps provide more tuned random behavior for how many attempts to make each time a room is subdivided
	local rand_cornersToPick = {[0]=2,3,3,4,4,4,5,5,5,5,6,6,6,6,6,7,7,7,7,8,8,8,9,9,10,10}
	local rand_roomDeltas = {[0]=0.999}
	local from = {};
	local nodes = {};
	local nodesByID = {};
	local tiles = {};
	local startgindex = gindex;
	local doorMap = {}

	--SECTION
	--These variables MIGHT be better to pass in, but currently I'm doing it randomly.
	local roomSizeDelta = rand_roomDeltas[rint(table.getn(rand_roomDeltas))]
	local tileset = table.randFrom(assets.tilesets)

	--END SECTION
	function setup()
		grid = {};
		for i = initx, initx+globalWidth do
			grid[i] = {};
			for j = inity, inity+globalHeight do
				grid[i][j] = gindex;
			end
		end
		
		head = makeNode(gindex, nil, initx, inity, globalWidth, globalHeight, true);
		generate(head);
		floodfilltest();
		nodes = getEndNodes(false);
		nodesByID = getEndNodesByID(nodes);
		constructGraph();
		buildDoors();
		buildWalls();
		buildFloors();
		local endNodes = getEndNodes(true);
		local endNodesByID = getEndNodesByID(endNodes);
		return {['gindex'] = gindex, ['nodes'] = endNodes, ['doorMap'] = doorMap, ['nodesByID'] = endNodesByID, ['grid'] = grid, ['tiles'] = tiles, ['x0'] = initx, ['y0'] = inity, ['width'] = globalWidth, ['height'] = globalHeight};
	end

	--gets only the nodes with actual active cells on the grid
	--useful for getting rid of the nodes that got entirely covered during construction
	function getEndNodes()
		local activeids = {};
		local activenodes = {};
		for i = initx, initx+globalWidth do
			for j = inity, inity+globalHeight do
				activeids[grid[i][j]] = true;
			end
		end

		for _, node in ipairs(nodes) do
			if (activeids[node.id]) then
				table.insert(activenodes,node);
			end
		end

		return activenodes;
	end

	--Same as above, but returns the nodesbyid
	function getEndNodesByID(currentNodes)
		local ret = {};
		for _, node in ipairs(currentNodes) do
			ret[node.id] = node;
		end
		return ret;
	end


	--An abstract representation of a room
	function makeNode(id, parent, x, y, _width, _height, check)
		if (x < initx or y < inity or _width <= 0 or _height <= 0) then
			print("Number out of [range!!] =  " + x + " , " + y + ", " + _width + ", " + _height);
		end

		local NODE = {}

		NODE.children = {};
		NODE.neighbors = {}; --for second pass to build into a graph. should contain booleans
		NODE.neighborwalls = {};
		NODE.wallTypes = {};
		NODE.parent = parent;
		NODE.x = x;
		NODE.y = y;
		NODE.width = _width;
		NODE.height = _height;
		NODE.id = id;
		NODE.success = true;
		NODE.explored = false;
		NODE.floor = nil;
		NODE.doors = {};
		NODE.doorsto = {};
		NODE.area = _width*_height;
		NODE.roomset = table.randFrom(tileset); --TODO this might not be best truly random!
		NODE.defaultWall = NODE.roomset.walls['wall1.png']
		NODE.corners = {
			[0]={['x'] = x,        ['y'] = y,           ['ix'] = 1,  ['iy'] = 1,  ['lw'] = _width, ['lh'] = _height},
			{['x'] = x,        ['y'] = y+_height,   ['ix'] = 1,  ['iy'] = -1, ['lw'] = _width, ['lh'] = _height},
			{['x'] = x+_width, ['y'] = y,           ['ix'] = -1, ['iy'] = 1,  ['lw'] = _width, ['lh'] = _height},
			{['x'] = x+_width, ['y'] = y+_height,   ['ix'] = -1, ['iy'] = -1, ['lw'] = _width, ['lh'] = _height}
		}

		if (rint(10)>8) then
			local midcornx = x+rint(_width-3)+1 ;
			local midcorny = y+rint(_height-3)+1;
			table.insert(NODE.corners,{['x'] = midcornx, ['y'] = midcorny,    ['ix'] = 1 , ['iy'] = 1,  ['lw'] = _width-midcornx, ['lh'] = _height-midcorny }); --'5th corner' for center room creation
		end

		if (check) then
			--check for valid placement
			for i = x, _width do
				for j = y, _height do
					if (grid[i][j] ~= startgindex and grid[i][j] ~= parent.id) then
						NODE.success = false
						-- print("[Rejected!] =  " )
						return
					end
				end
			end
			--fill in grid at x, y coordinates
			if (NODE.success) then
				for i = x, x+_width do
					for j = y, y+_height do
						grid[i][j] = id;
					end
				end
			end
		end

		tiles[id] = rint(MAX_TILE);
		--TODO: select tileset for the node
		table.insert(nodes,NODE);
		nodesByID[id] = NODE;
		return NODE;
	end

	function buildFloors()
		for i, node in pairs(nodes) do
			node.floor = table.randFrom(node.roomset.floors)
		end
	end

	--Sets wall types; this can be used to make windows or thin walls that can be shot through
	function buildWalls()
		for i, node in pairs(nodes) do
			for neighborID, _ in pairs(node.neighbors) do
				-- TODO... This might be more in-depth than initially thought

				--[[
					Walls need to not only have different types, but different patterns.
					Currently, I can only think of three types of walls: Wall, Window, and Thin Wall. It might be desirable to
					have more types to allow for different bullet penetration/visibility/light effects, so this should be kept
					generalized.

					Patterns are also a concern. My current inclination is to pick a "WALL TYPE" - Wall, Thin Wall, etc and then
					select a random pattern to use, like:

					Wall-Wall-Window-Wall-Wall-Window-Wall-Wall

					that will repeat itself. This way even spacing of windows or other "special wall types" can be repeated. Also,
					it should sometimes (with some configurable probability) pick no pattern at all for window placement.

					Also, Walls and Windows need textures. My current thought is that the heirarchy will look something like this:

					Tileset -- this is the top-level aesthetic. There might be a 80s tileset, a grunge tileset, whatever. This is the style of the LEVEL
						Roomset -- this is the set chosen for the room being decorated, chosen at random. Each roomset contains its own art, and each
									roomset can draw from the "All" roomset in the tileset
							Walls
								Wall_1 { type=wall/thinwall/thickwall/etc/etc }
								...
							Windows
								Window_1 { type=window/etc/etc }
								...
							Floors
								Floor_1
								...
							Decor
							...
				]]--

				--TODO FOR NOW I am just setting all walls to wall1
				for _, neighborWall in pairs(node.neighborwalls[neighborID]) do
					neighborWall.type = "wall1.png"
					neighborWall.image = node.roomset.walls[neighborWall.type]
				end
			end
		end



	end

	function addToDoorMap(x0, y0, x1, y1)
		if not doorMap[x0]         then doorMap[x0] = {} end
		if not doorMap[x0][y0]     then doorMap[x0][y0] = {} end
		if not doorMap[x0][y0][x1] then doorMap[x0][y0][x1] = {} end
		                                doorMap[x0][y0][x1][y1] = {true}
	end

	function buildDoors()
		from[grid[initx][inity]] = nil;
		-- local s_n = nil
		-- while s_n == nil do
		-- 	s_n = nodes[rint(table.getn(nodes))]
		-- end
		-- local stack = {s_n.id}                                --Random room
		
		local stack = {grid[initx][inity]}                                      --Static start position
		--local stack = [grid[rint(globalWidth)+initx][rint(globalHeight)+inity]] --Bias towards large rooms
		local explored = {grid[initx][inity]} --ids
		while table.getn(stack) > 0 do
			local nodeID = table.remove(stack)
			local node = nodesByID[nodeID]
			
			--Determine which neighbors to attempt to explore
			local choices = {};
			for n, _ in pairs(node.neighbors) do
				if (not explored[n]) then
					table.insert(choices,n);
				end
			end
			if table.getn(choices) > 0 then
				node.explored = true;
				choices = shuffle(choices);
				--Randomly explore choices
				for c, _ in pairs(choices) do
					local neighborID = choices[c];
					local neighbor   = nodesByID[neighborID];
					if (not node.doorsto[neighborID]) then
						local doorIndex = rint(table.getn(node.neighborwalls[neighborID])-1)+1
						-- print("Door options: "..table.getn(node.neighborwalls[neighborID]) .. ", door index: "..doorIndex .. ", result: ")
						table.insert(node.doors, node.neighborwalls[neighborID][doorIndex])
						node.doorsto[neighborID] = true
						neighbor.doorsto[nodeID] = true
						local door = node.neighborwalls[neighborID][doorIndex]
						addToDoorMap(door.x, door.y, door.dx, door.dy)
						addToDoorMap(door.dx, door.dy, door.x, door.y)
						-- print("Door from " .. nodeID .. " to " .. neighborID);
					end
					--Add all neighbors to stack in random order
					table.insert(stack, neighborID);
					--stack.splice(rint(stack.length), 0, neighborID);
					explored[neighborID] = true;
					from[neighborID] = nodeID;
				end

				--Do some extra doors
				local numExtra = rint(20)-7;
				if not (numExtra <= 0) then
					local choices = {};
					for n, _ in pairs(node.neighbors) do
						table.insert(choices, n);
					end
					choices = shuffle(choices);
					local limit = choices.length;
					local i = 0;
					while i < numExtra and i < table.getn(choices) do
						i = i+1;
						local neighborID = table.remove(choices);
						if (not node.doorsto[neighborID]) then
							local doorIndex = rint(table.getn(node.neighborwalls[neighborID])-1)+1
							table.insert(node.doors, node.neighborwalls[neighborID][doorIndex]);
							local door = node.neighborwalls[neighborID][doorIndex]
							addToDoorMap(door.x, door.y, door.dx, door.dy)
							addToDoorMap(door.dx, door.dy, door.x, door.y)
							-- print("Random Door!")
						end
					end
				end
			end

		end
		-- print(explored);
	end

	function constructGraph()
		--do scan in 2x2 chunks
		local check = {}
		for i = initx, initx+globalWidth do
			for j = inity, inity+globalHeight do

				local ul = grid[i  ][j  ];
				local ll = grid[i  ][j+1];
				
				if grid[i+1] ~= nil then
					local ur = grid[i+1][j  ];
					local lr = grid[i+1][j+1];
					if (ul ~= ur) then
						nodesByID[ul].neighbors[ur] = true;
						if (not nodesByID[ul].neighborwalls[ur]) then
							nodesByID[ul].neighborwalls[ur] = {};
						end
						table.insert(nodesByID[ul].neighborwalls[ur], {['x'] = i  , ['y'] = j  , ['dx'] = i+1, ['dy'] = j  , ['drawX'] = (i+1)*cellsize-wallthickness, ['drawY'] = j*cellsize, ['rot'] = 0, ['type'] = nil})

						nodesByID[ur].neighbors[ul] = true;
						if (not nodesByID[ur].neighborwalls[ul]) then
							nodesByID[ur].neighborwalls[ul] = {};
						end
						table.insert(nodesByID[ur].neighborwalls[ul], {['x'] = i+1, ['y'] = j  , ['dx'] = i  , ['dy'] = j  , ['drawX'] = (i+1)*cellsize, ['drawY'] = j*cellsize, ['rot'] = 0, ['type'] = nil});

					end
				end
				if ll ~= nil then
					
					if (ul ~= ll) then
						nodesByID[ul].neighbors[ll] = true;
						if (not nodesByID[ul].neighborwalls[ll]) then
							nodesByID[ul].neighborwalls[ll] = {};
						end
						table.insert(nodesByID[ul].neighborwalls[ll], {['x'] = i  , ['y'] = j  , ['dx'] = i  , ['dy'] = j+1, ['drawX'] = i*cellsize, ['drawY'] = (j+1)*cellsize, ['rot'] = -d90, ['type'] = nil});

						nodesByID[ll].neighbors[ul] = true;
						if (not nodesByID[ll].neighborwalls[ul]) then
							nodesByID[ll].neighborwalls[ul] = {};
						end
						table.insert(nodesByID[ll].neighborwalls[ul], {['x'] = i  , ['y'] = j+1, ['dx'] = i  , ['dy'] = j  , ['drawX'] = i*cellsize, ['drawY'] = (j+1)*cellsize+wallthickness, ['rot'] = -d90, ['type'] = nil});

					end
					if (ul ~= lr)then end
					if (ur ~= ll)then end
					-- if (ur ~= lr) then
					-- 	nodesByID[ur].neighbors[lr] = true;
					-- 	if (not nodesByID[ur].neighborwalls[lr]) then
					-- 		nodesByID[ur].neighborwalls[lr] = {};
					-- 	end
					-- 	table.insert(nodesByID[ur].neighborwalls[lr], {['x'] = i+1, ['y'] = j  , ['dx'] = i+1, ['dy'] = j+1, ['drawX'] = (i+1)*cellsize, ['drawY'] = (j+1)*cellsize-wallthickness, ['rot'] = -d90, ['type'] = nil});

					-- 	nodesByID[lr].neighbors[ur] = true;
					-- 	if (not nodesByID[lr].neighborwalls[ur]) then
					-- 		nodesByID[lr].neighborwalls[ur] = {};
					-- 	end
					-- 	table.insert(nodesByID[lr].neighborwalls[ur], {['x'] = i+1, ['y'] = j+1, ['dx'] = i+1, ['dy'] = j  , ['drawX'] = (i+1)*cellsize, ['drawY'] = (j+1)*cellsize, ['rot'] = -d90, ['type'] = nil});

					-- end

				end
				-- if (lr ~= ll) then
				-- 	nodesByID[lr].neighbors[ll] = true;
				-- 	if (not nodesByID[lr].neighborwalls[ll]) then
				-- 		nodesByID[lr].neighborwalls[ll] = {};
				-- 	end
				-- 	table.insert(nodesByID[lr].neighborwalls[ll], {['x'] = i+1, ['y'] = j+1, ['dx'] = i  , ['dy'] = j+1, ['drawX'] = (i+1)*cellsize-wallthickness, ['drawY'] = (j+1)*cellsize, ['rot'] = 0, ['type'] = nil});

				-- 	nodesByID[ll].neighbors[lr] = true;
				-- 	if (not nodesByID[ll].neighborwalls[lr]) then
				-- 		nodesByID[ll].neighborwalls[lr] = {};
				-- 	end
				-- 	table.insert(nodesByID[ll].neighborwalls[lr], {['x'] = i  , ['y'] = j+1, ['dx'] = i+1, ['dy'] = j+1, ['drawX'] = (i+1)*cellsize, ['drawY'] = (j+1)*cellsize, ['rot'] = 0, ['type'] = nil});

				-- end
			end
		end
	end

	function floodfilltest()
		nodes = {};
		nodesByID = {};

		local visitedCells = {};
		for i = initx, initx+globalWidth do
			visitedCells[i] = {};
			for j = inity, inity+globalHeight do
				visitedCells[i][j] = false;
			end
		end

		for i = initx, initx+globalWidth do
			for j = inity, inity+globalHeight do
				if (not visitedCells[i][j]) then
					local tovisit = {{['x'] = i, ['y'] = j}};
					local newid = gindex + 1;
					gindex = gindex + 1;
					local id = grid[i][j];
					local node = makeNode(newid, nil, i, j, 1, 1, false); --width and height irrelevant now
					while(table.getn(tovisit) > 0) do
						local point = table.remove(tovisit);
						local x = point.x;
						local y = point.y;
						if not (x < initx or y < inity or x > initx+globalWidth or y > inity+globalHeight) then
				 			if not (grid[x] == undefined or grid[x][y] ~= id) then
				 			-- print(x + ", " + y);
					 			if (not visitedCells[x][y]) then
						 			visitedCells[x][y] = true;
						 			grid[x][y] = newid;
						 			node.area = node.area + 1;
						 			table.insert(tovisit, {['x'] = x+1, ['y'] = y  });
									table.insert(tovisit, {['x'] = x-1, ['y'] = y  });
									table.insert(tovisit, {['x'] = x  , ['y'] = y+1});
									table.insert(tovisit, {['x'] = x  , ['y'] = y-1});
								end
							end
						end
					end
				end
			end
		end
	end

	function generate(node)
		local x = node.x;
		local y = node.y;
		local width = node.width;
		local height = node.height;

		--Base case
		if width == 1 and height == 1 then
			return;
		end

		--Randomly return based on size
		local area = width*height
		local ratio = (math.sqrt(area)/(math.sqrt(globalWidth*globalHeight)*roomSizeDelta))
		if (love.math.random() > ratio) then
			-- print("Returning randomly! p="..(ratio))
			return;
		end

		-- print("new parent node!")
		--Determine how many corners to do
		local numTries = rand_cornersToPick[rint(table.getn(rand_cornersToPick))];
		-- print("Numtries = "..numTries)
		for n = 0, numTries do

			--Determine a corner to start
			if not (table.getn(node.corners) == 0) then
				local cornerIndex = rint(table.getn(node.corners))
				local corner = node.corners[cornerIndex];
				local sx = corner.x;
				local sy = corner.y;
				local ix = corner.ix; --Index amount/direction
				local iy = corner.iy;
				local lw = corner.lw; --limits
				local lh = corner.lh;

				--Start with a 1x1
				local nx = sx;
				local ny = sy;
				local nw = 0;
				local nh = 0;

				--Walk a random amount on X and Y
				local dx = rintnormal(0.1, 1, lw)+1;
				local dy = rintnormal(0.1, 1, lh)+1;

				if (dx > lw-1) then
					dx = lw-1;
				end
				if (dy > lh-1) then
					dy = lh-1;
				end
				if (dx <= 0) then
					dx = 1;
				end
				if (dy <= 0) then
					dy = 1;
				end

				local nw = dx;
				local nh = dy;
				if (ix < 0) then
					nx = nx-dx 
				end
				if (iy < 0) then
					ny = ny-dy
				end

				--Create a new node with the new width and height
				local newNode = makeNode(gindex+1, node, nx, ny, nw, nh, true);

				--Check if node was successfully created
				if (newNode and newNode.success) then
				
					--Basic book keeping
					gindex = gindex + 1;
					table.insert(node.children, newNode);
					table.remove(node.corners, cornerIndex);
				end
			end
		end
		for _, c in ipairs(node.children) do
			generate(c);
		end
	end
	return setup();
end
