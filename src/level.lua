function SetupLevel(world)
	local level = {}
	level.data = generatePass1(0, 0, 20, 20, 0)
	level.updated = true
	level.canvas = love.graphics.newCanvas(levelPxWidth, levelPxHeight)
	
	return level
end

cellsize = 20;
hcs = cellsize/2;
doorsize = 20
levelPxWidth  = 2048
levelPxHeight = 2048
xOffset = levelPxWidth/2
yOffset = levelPxHeight/2

function setLevelPxSize(level, width, height)
	levelPxWidth = width
	levelPxHeight = height
	xOffset = levelPxWidth
	yOffset = levelPxHeight
	level.canvas = love.graphics.newCanvas(levelPxWidth, levelPxHeight)
end

function DrawLevel(level)
	if not level.updated then
		love.graphics.draw(level.canvas)
	else

		local grid = level.data.grid
		local nodes = level.data.nodes
		local x0 = level.data.x0
		local y0 = level.data.y0
		local w = level.data.width
		local h = level.data.height
		local gfx = level.canvas
		love.graphics.setCanvas(gfx)

			gfx:clear()
			-- love.graphics.translate(-gfx:getWidth()/2, -gfx:getHeight()/2)
			love.graphics.setColor(255,255,255)
			love.graphics.rectangle('line', -gfx:getWidth()/2,-gfx:getWidth()/2,gfx:getWidth(), gfx:getHeight())
			love.graphics.rectangle('fill',0,0,10,10)
			for i = x0, x0+w do
				for j = y0, y0+h do
					if(grid[i] and  grid[i][j]) then
						if(not grid[i-1] or grid[i-1][j] ~= grid[i][j]) then
							love.graphics.line(i*cellsize-hcs, j*cellsize-hcs, i*cellsize-hcs, (j+1)*cellsize-hcs)
						end
						if(not grid[i+1] or grid[i+1][j] ~= grid[i][j]) then
							love.graphics.line((i+1)*cellsize-hcs, j*cellsize-hcs, (i+1)*cellsize-hcs, (j+1)*cellsize-hcs)
						end
						if(grid[i][j-1] ~= grid[i][j]) then
							love.graphics.line(i*cellsize-hcs, j*cellsize-hcs, (i+1)*cellsize-hcs, j*cellsize-hcs)
						end
						if(grid[i][j+1] ~= grid[i][j]) then
							love.graphics.line(i*cellsize-hcs, (j+1)*cellsize-hcs, (i+1)*cellsize-hcs, (j+1)*cellsize-hcs)
						end
					end
					love.graphics.print( grid[i][j], i*cellsize-hcs, j*cellsize-hcs)
				end
			end
			love.graphics.setColor(255,255,255)
			for _,node in pairs(nodes) do
				for _,door in pairs(node.doors) do
					if door then
						love.graphics.rectangle('fill',(door.x-(door.x-door.dx)/2)*cellsize-doorsize/2, (door.y-(door.y-door.dy)/2)*cellsize-doorsize/2, doorsize, doorsize)
					end
				end
			end
			love.graphics.origin()
		love.graphics.setCanvas()
		level.updated = false
	end
end
