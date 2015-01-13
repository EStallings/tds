function SetupPlayer(x, y)
	local player = {}
	player.body = love.physics.newBody(world, x, y, 'dynamic')
	player.body:setAngularDamping(0)
	player.body:setFixedRotation(true)
	player.shape = love.physics.newCircleShape(32)
	player.fixture = love.physics.newFixture(player.body, player.shape)
	player.sprite = Sprite("player")
	player.rotation = 0

	function player:update(dt)
		local speed = 400
		local vx, vy = 0, 0
		vy = vy - getControlStatus('move_up')
		vy = vy + getControlStatus('move_down')
		vx = vx - getControlStatus('move_left')
		vx = vx + getControlStatus('move_right')
		vx = vx * speed
		vy = vy * speed
		vx, vy = capVector(vx, vy, speed)
		player.body:setLinearVelocity(vx, vy)

		local mx, my = getControlStatus('look_x'), getControlStatus('look_y')
		local px, py = player.body:getPosition()
		player.rotation = math.atan2(my - py, mx - px)		
	end

	function player:draw()
		self.sprite:draw(player.body:getX(), player.body:getY(), player.rotation)
		love.graphics.circle('fill', getControlStatus('look_x'), getControlStatus('look_y'), 5)
	end
	
	return player
end

