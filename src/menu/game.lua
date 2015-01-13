modeGame = {}

function modeGame.load(args)
	love.physics.setMeter(64)
	world  =  love.physics.newWorld()
	camera =  Camera(0, 0)
	player   =  SetupPlayer(0, 0)
	image = love.graphics.newImage('assets/stars.jpg')
	love.mouse.setVisible(false)
	love.mouse.setGrabbed(true)
end

function modeGame.update(dt)
	world:update(dt)
	player:update(dt)
	camera:lookAt(player.body:getX(), player.body:getY())
	camera:rotateTo(-player.body:getAngle())
end


function modeGame.draw()
	camera:draw(drawWorld)
	drawHud()
end

function drawWorld()
	love.graphics.draw(image)
	love.graphics.setColor(120,120,120)
	love.graphics.circle('fill', player.body:getX(), player.body:getY(), 32)
	player:draw()
end

function drawHud()
	love.graphics.setColor(220, 30, 30, 255)
	love.graphics.print("Current FPS: "..tostring(love.timer.getFPS( )), 10, 10)
	local vx, vy = player.body:getLinearVelocity()
	love.graphics.print("Speed: "..tostring(math.sqrt(vx*vx+vy*vy)), 10, 40)
	love.graphics.print("Rotation: "..tostring(player.body:getAngularVelocity()), 10, 60)
end
