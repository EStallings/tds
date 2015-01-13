--[[
	SPRITE
	Animated graphic objects. Sprites can be dynamically animated and efficently so; it is possible to re-use quads throughout different animations.

	Textures must be formatted as a grid of fixed dimensions, gridX and gridY.

	Animation cells are 3-dimensional tables. The first table, 'cells' is  a container. The container stores string indexed tables for each animation derived from the sprite sheet. Animation tables should be appropriately named as they are the names you will use to reference animations in your code. Each animation table contains a number of animation cells, indexed numerically. Each cell should contain two numberical properties and an optional extra property of varying type:

		quad - numerical reference to the quad on the spritesheet (e.g. on a 3x3 grid of quads, the bottom right tile would have a reference of 9)
		time - time the this frame should be displayed for. This allows for dynamic animtions.
		next - the next frame or animation to use. This property is optional. A nil next value creates a looping animation.

	The next element may be nil, a number, or a string. As mentioned above nil will cause the animation to loop. A number will direct the next frame to the given frame inside the current animation (this can be used for dynamic looping). A string reference implements a command.

	Currently there are two commands: "stop" causes the animation to remain on the current frame, and "loop" has the same effect as a nil value. Any other string will be interpreted as an animation change command. The sprite's animation will be set to the animation matching the string given and will start at the first frame of the new animation.

	Sprites always default to the "idle" animation unless a default is specified. As such it is advisable that any cell tables contain at least an "idle" animation.
]]

Sprite = function(spriteName, delay)
	local sprite = {}
	local img = cache.image("assets/sprites/" .. spriteName .. ".png")
	sprite.atlas = {image = img, width = img:getWidth(), height = img:getHeight()}

	sprite.meta = cache.sprite("assets/sprites/" .. spriteName .. ".spr") --metadata (animations, grid sizes...)

	local gridX = sprite.meta.gridX
	local gridY = sprite.meta.gridY
	local offsetX = sprite.meta.offsetX
	local offsetY = sprite.meta.offsetY
	sprite.meta.width = gridX - 1
	sprite.meta.height = gridY - 1

	--setup Quads
	sprite.quad = {}
	for y = 0, (sprite.atlas.height / gridY) - 1 do
		for x = 0, (sprite.atlas.width / gridX) - 1 do
			table.insert(sprite.quad, love.graphics.newQuad(x * gridX, y * gridY, gridX - 1, gridY - 1, sprite.atlas.width, sprite.atlas.height))
		end
	end

	--some handy vars
	sprite.cells = sprite.meta.cells or {idle = {{quad = 1, time = 1, next = 0}}}
	sprite.animation = sprite.meta.defaultAnimation or "idle"

	--essential vars
	sprite.delay = delay
	sprite.frameNum = 1
	sprite.frame = sprite.cells[sprite.animation][1]
	sprite.time = love.timer.getTime()
	sprite.offsetX = offsetX or 0
	sprite.offsetY = offsetY or 0
	sprite.color = sprite.meta.color or color.white
	sprite.scaleX = 1
	sprite.scaleY = 1
	sprite.originX = 0
	sprite.originY = 0
	sprite.frameTime = sprite.meta.frameTime or 0.25
	function sprite:update(self, dt, t)
		if not self.delay or t - self.time >= self.delay then
			self.delay = nil
			if t - self.time > (self.frame.time or self.frameTime) * (self.animationSpeed or 1) then
				if type(self.frame.next) == "string" and self.frame.next ~= "stop" then
					--text-based instructions
					if self.frame.next == "loop" then
						--loop current animation
						self.frameNum = self.frameNum + 1 <= # self.cells[self.animation] and self.frameNum + 1 or 1
						self.frame = self.cells[self.animation][self.frameNum]
					elseif self.frame.next == "bounce" then
						self.nextCell = (not self.nextCell or self.nextCell == -1) and 1 or -1
						self.frameNum = self.frameNum + self.nextCell <= # self.cells[self.animation] and self.frameNum + self.nextCell or 1
						self.frame = self.cells[self.animation][self.frameNum]
					elseif self.frame.next == "kill" then
						self.kill = true
					else
						--change animation
						self.animation = self.frame.next
						self.frame = self.cells[self.animation][1]
						self.frameNum = 1
						self.nextCell = nil
					end
				elseif type(self.frame.next) == "number" and self.frame.next ~= 0 then
					--skip to referenced frame
					self.frame = self.cells[self.animation][self.frame.next]
					self.frameNum = self.frame.next
				elseif not self.frame.next then
					--loop/bounce is arg is blank
					self.frameNum = self.frameNum + (self.nextCell or 1) <= # self.cells[self.animation] and self.frameNum + (self.nextCell or 1) or 1
					self.frame = self.cells[self.animation][self.frameNum]
				end
				self.time = t --update last frame change time
			end
		end
	end

	function sprite:draw(drawX, drawY, rotation)
		if not self.delay then
			if self.meta.mode then
				love.graphics.setBlendMode(self.meta.mode)
			end
			love.graphics.setColor(self.frame.color or self.color)
			rotation = rotation + math.pi/2	
			local ox, oy = getOffsetVector(rotation)
			local dx = drawX + self.offsetX * ox
			local dy = drawY - self.offsetY * oy
			
			love.graphics.draw(self.atlas.image, self.quad[self.frame.quad], dx, dy, rotation, self.scaleX, self.scaleY, self.originX, self.originY)
			love.graphics.setBlendMode("alpha")
		end
	end

	function sprite:setAnimation(self, animation, frame, t)
		frame = (frame and frame <= # self.cells[animation]) and frame or 1
		self.animation = animation
		self.frame = self.cells[self.animation][frame]
		self.frameNum = frame
		self.time = t or love.timer.getTime()
		self.nextCell = nil
	end
	return sprite
end