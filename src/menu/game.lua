modeGame = {}

function modeGame.load(args)
	love.physics.setMeter(pixelsPerMeter)
	world  =  love.physics.newWorld()
	world:setCallbacks(beginContact, endContact, preSolve, postSolve)
	camera =  Camera(0, 0)
	player =  SetupPlayer(500,400)
	image = love.graphics.newImage('assets/stars.jpg')
	level = SetupLevel(world)
	love.mouse.setVisible(false)
	love.mouse.setGrabbed(true)
	love.window.setMode(1920,1080,{borderless=true})
	levelCanvas = love.graphics.newCanvas(levelPxWidth, levelPxHeight)

	block1 = {}
	block1.body = love.physics.newBody(world, 200, 550, "static")
	block1.shape = love.physics.newRectangleShape(0, 0, 50, 50)
	block1.fixture = love.physics.newFixture(block1.body, block1.shape, 5)
	block1.fixture:setUserData("Block1")

	block2 = {}
	block2.body = love.physics.newBody(world, 200, 650, "dynamic")
	block2.shape = love.physics.newRectangleShape(0, 0, 50, 200)
	block2.fixture = love.physics.newFixture(block2.body, block2.shape, 5)
	block2.fixture:setUserData("Block2")

	joint = love.physics.newRevoluteJoint(block1.body, block2.body, 200, 550)


	  effect = love.graphics.newShader [[
        extern number time;
        vec4 effect(vec4 color, Image texture, vec2 texture_coords, vec2 pixel_coords)
        {
            vec4 texcolor = Texel(texture, texture_coords);
            return texcolor*color*vec4(cos(time), sin(time*0.5), acos(time), 1.0);
            //return vec4((1.0+sin(time))/2.0, abs(cos(time)), abs(sin(time)), 1.0);
        }
    ]]
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
	-- love.graphics.draw(image)

	DrawLevel(level, levelCanvas)
	love.graphics.polygon("fill", block1.body:getWorldPoints(block1.shape:getPoints()))
	love.graphics.polygon("fill", block2.body:getWorldPoints(block2.shape:getPoints()))
	love.graphics.setShader()
	love.graphics.setColor(120,120,120)
	love.graphics.circle('fill', player.body:getX(), player.body:getY(), 32)
	
	player:draw()

end

function drawHud()
	-- love.graphics.setColor(220, 30, 30, 255)
	love.graphics.print("Current FPS: "..tostring(love.timer.getFPS( )), 10, 10)
	local vx, vy = player.body:getLinearVelocity()
	love.graphics.print("Speed: "..tostring(math.sqrt(vx*vx+vy*vy)), 10, 40)
	love.graphics.print("Rotation: "..tostring(player.body:getAngularVelocity()), 10, 60)
end

function beginContact(a, b, coll)
    -- print(a:getUserData().." colliding with "..b:getUserData())
end

function endContact(a, b, coll)
    
end

function preSolve(a, b, coll)
    
end

function postSolve(a, b, coll, normalimpulse1, tangentimpulse1, normalimpulse2, tangentimpulse2)
    
end