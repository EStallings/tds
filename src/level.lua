function SetupLevel(world)
	local level = {}
	level.data = generatePass1(0, 0, 15, 15, 0)
	level.updated = true
	BuildLevelPhysics(level, world)
	
	return level
end

function setLevelPxSize(level, width, height)
	levelPxWidth = width
	levelPxHeight = height
	xOffset = levelPxWidth
	yOffset = levelPxHeight
end

function BuildLevelPhysics(level, world)
	local grid = level.data.grid
	local nodes = level.data.nodes
	local nodesByID = level.data.nodesByID
	local x0 = level.data.x0
	local y0 = level.data.y0
	local w = level.data.width
	local h = level.data.height
	local doorMap = level.data.doorMap
	local doorMap2 = {}
	local wallShapeV = love.physics.newRectangleShape(wallthickness, cellsize)
	local wallShapeH = love.physics.newRectangleShape(cellsize, wallthickness)

	level.walls = {}
	level.walls.body = love.physics.newBody(world, 0, 0, "static")
	level.walls.fixtures = {}
	level.walls.shapes = {}
	level.doors = {}
	level.doorStop = {}
	level.doorStop.body = love.physics.newBody(world, 0, 0, "static")
	level.doorStop.fixtures = {}
	level.doorStop.shapes = {}

	local scale = (cellsize-hcs)*2
	local offsetX = 6*hcs --no idea why.
	local offsetY = hcs

	function doorMapContains(x0, y0, x1, y1)
		if not doorMap[x0] then return false end
		if not doorMap[x0][y0] then return false end
		if not doorMap[x0][y0][x1] then return false end
		if not doorMap[x0][y0][x1][y1] then return false end
		return true
	end

	function canMakeDoor(x0, y0, x1, y1)
		if not doorMap[x0][y0][x1][y1][1] then return false end
		if not doorMap[x1][y1][x0][y0][1] then return false end
		doorMap[x0][y0][x1][y1][1] = false
		doorMap[x1][y1][x0][y0][1] = false
		return true
	end

	function makeWall(x0, y0, x1, y1)
		local shape = love.physics.newEdgeShape(x0*scale+offsetX, y0*scale+offsetY, x1*scale+offsetX, y1*scale+offsetY)
		local fixture = love.physics.newFixture( level.walls.body, shape )

		local doorStopShape = love.physics.newRectangleShape(((x0+x1)/2)*scale+offsetX+wallthickness/2, ((y0+y1)/2)*scale+offsetY+wallthickness/2, wallthickness, wallthickness)
		local doorStopFixture = love.physics.newFixture( level.doorStop.body, doorStopShape)
		fixture:setUserData("Wall")
		doorStopFixture:setUserData("Doorstop")
		
		table.insert(level.walls.shapes, shape)
		table.insert(level.walls.fixtures, fixture)
		table.insert(level.doorStop.shapes, doorStopShape)
		table.insert(level.doorStop.fixtures, doorStopFixture)
	end

	function makeDoor(x, y, w, h, xo, yo, xgo, ygo)
		local doorContainer = {}
		local doorAnchor = {}
		local doorObject = {}

		doorObject.body = love.physics.newBody(world, x*scale+offsetX+xo+xgo, y*scale+offsetY+yo+ygo, "dynamic")
		doorObject.shape = love.physics.newRectangleShape(0, 0, w, h)
		doorObject.fixture = love.physics.newFixture(doorObject.body, doorObject.shape, 5)
		doorObject.fixture:setUserData("Door")
		doorContainer.doorObject = doorObject
		local joint = love.physics.newRevoluteJoint( level.walls.body, doorObject.body, x*scale+offsetX+xgo, y*scale+offsetY+ygo, false)
		joint:setLimits(-math.pi*(7/8), math.pi*(7/8))
		-- joint:setLimitsEnabled(true)
		doorContainer.joint = joint
		table.insert(level.doors, doorContainer)
	end

	for i = x0, x0+w do
		for j = y0, y0+h do
			if(grid[i] and  grid[i][j]) then

				if (not grid[i-1] or grid[i-1][j] ~= grid[i][j]) then
					if not doorMapContains(i, j, i-1, j) then
						makeWall(i, j, i, j+1)
					elseif canMakeDoor(i, j, i-1, j) then
						makeDoor(i, j, wallthickness, cellsize-10, 0, hcs-5, wallthickness*(3/4), 16)
					end
				end
				
				if (not grid[i+1] or grid[i+1][j] ~= grid[i][j]) then 
					if not doorMapContains(i, j, i+1, j) then
						makeWall(i+1, j, i+1, j+1)
					elseif canMakeDoor(i, j, i+1, j) then
						makeDoor(i+1, j, wallthickness, cellsize-10, 0, hcs-5, wallthickness*(3/4), 16)
					end
				end
				
				if (not grid[i][j-1] or grid[i][j-1] ~= grid[i][j]) then 
					if not doorMapContains(i, j, i, j-1) then
						makeWall(i, j, i+1, j)
					elseif canMakeDoor(i, j, i, j-1) then
						makeDoor(i, j, cellsize-10, wallthickness, hcs-5, 0, 16, wallthickness*(3/4))
					end
				end
				
				if (not grid[i][j+1] or grid[i][j+1] ~= grid[i][j]) then 
					if not doorMapContains(i, j, i, j+1) then
						makeWall(i, j+1, i+1, j+1)
					elseif canMakeDoor(i, j, i, j+1) then
						makeDoor(i, j+1, cellsize-10, wallthickness, hcs-5, 0, 16, wallthickness*(3/4))
					end
				end
			end
		end
	end

end

function DrawLevel(level, canvas)
	if not level.updated then
		love.graphics.draw(canvas)
	else
		local grid = level.data.grid
		local nodes = level.data.nodes
		local nodesByID = level.data.nodesByID
		local x0 = level.data.x0
		local y0 = level.data.y0
		local w = level.data.width
		local h = level.data.height
		local gfx = canvas
		love.graphics.setCanvas(gfx)

			gfx:clear()
			-- love.graphics.translate(-gfx:getWidth()/2, -gfx:getHeight()/2)
			love.graphics.setColor(255,255,255)
			love.graphics.rectangle('line', -gfx:getWidth()/2,-gfx:getWidth()/2,gfx:getWidth(), gfx:getHeight())
			love.graphics.rectangle('fill',0,0,10,10)
			for i = x0, x0+w do
				for j = y0, y0+h do
					love.graphics.draw(nodesByID[grid[i][j]].floor, i*cellsize-hcs, j*cellsize-hcs)
					love.graphics.print( grid[i][j], i*cellsize-hcs, j*cellsize-hcs)
				end
			end
			love.graphics.setColor(255,255,255)
			for _,node in pairs(nodes) do
				-- print(node.id)
				for neighborID, _ in pairs(node.neighbors) do
					for _, neighborWall in pairs(node.neighborwalls[neighborID]) do
						love.graphics.draw(neighborWall.image, neighborWall.drawX-hcs, neighborWall.drawY-hcs, neighborWall.rot)
					end
				end
			end
			for _,node in pairs(nodes) do
				for _,door in pairs(node.doors) do
					if door then
						love.graphics.rectangle('fill',(door.x-(door.x-door.dx)/2)*cellsize-doorsize/2, (door.y-(door.y-door.dy)/2)*cellsize-doorsize/2, doorsize, doorsize)
					end
				end
			end
			for i = x0, x0+w do
				for j = y0, y0+h do
					if(grid[i] and  grid[i][j]) then
						local n0 = nodesByID[grid[i][j]]
						local defaultWall = n0.defaultWall

						if (not grid[i-1]) then
							love.graphics.draw(defaultWall, i*cellsize-hcs, j*cellsize-hcs)
							love.graphics.line(i*cellsize-hcs, j*cellsize-hcs, i*cellsize-hcs, (j+1)*cellsize-hcs)
						elseif (grid[i-1][j] ~= grid[i][j]) then
							love.graphics.line(i*cellsize-hcs, j*cellsize-hcs, i*cellsize-hcs, (j+1)*cellsize-hcs)
						end
						
						if (not grid[i+1]) then
							love.graphics.draw(defaultWall, (i+1)*cellsize-hcs-wallthickness, j*cellsize-hcs)
							love.graphics.line((i+1)*cellsize-hcs, j*cellsize-hcs, (i+1)*cellsize-hcs, (j+1)*cellsize-hcs)
						elseif (grid[i+1][j] ~= grid[i][j]) then
							love.graphics.line((i+1)*cellsize-hcs, j*cellsize-hcs, (i+1)*cellsize-hcs, (j+1)*cellsize-hcs)
						end
						
						if (not grid[i][j-1]) then
							love.graphics.draw(defaultWall, i*cellsize-hcs, j*cellsize-hcs+wallthickness, -d90)
							love.graphics.line(i*cellsize-hcs, j*cellsize-hcs, (i+1)*cellsize-hcs, j*cellsize-hcs)
						elseif (grid[i][j-1] ~= grid[i][j]) then
							love.graphics.line(i*cellsize-hcs, j*cellsize-hcs, (i+1)*cellsize-hcs, j*cellsize-hcs)
						end
						
						if (not grid[i][j+1]) then
							love.graphics.draw(defaultWall, i*cellsize-hcs, (j+1)*cellsize-hcs, -d90)
							love.graphics.line(i*cellsize-hcs, (j+1)*cellsize-hcs, (i+1)*cellsize-hcs, (j+1)*cellsize-hcs)
						elseif (grid[i][j+1] ~= grid[i][j]) then
							love.graphics.line(i*cellsize-hcs, (j+1)*cellsize-hcs, (i+1)*cellsize-hcs, (j+1)*cellsize-hcs)
						end

					end
				end
			end
			love.graphics.setColor(0,0,255)
			love.graphics.translate(-7*hcs, -cellsize)
			for _, shape in pairs(level.walls.shapes) do
				love.graphics.line(level.walls.body:getWorldPoints(shape:getPoints()))
			end
			love.graphics.origin()
		love.graphics.setCanvas()
		level.updated = false
	end
	love.graphics.setColor(0, 255, 0)
	for _, doorC in pairs(level.doors) do
		-- love.graphics.line(doorC.doorObject.body:getWorldPoints(doorC.doorObject.shape:getPoints()))
		love.graphics.polygon("fill", doorC.doorObject.body:getWorldPoints(doorC.doorObject.shape:getPoints()))
	end
	love.graphics.setColor(255, 255, 0)
	for _, doors in pairs(level.doorStop.shapes) do
		-- love.graphics.line(doorC.doorObject.body:getWorldPoints(doorC.doorObject.shape:getPoints()))
		love.graphics.polygon("fill", level.doorStop.body:getWorldPoints(doors:getPoints()))
	end
end
