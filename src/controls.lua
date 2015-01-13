local mouseX = 0
local mouseY = 0

local function keyboard(key)
	return function()
		return love.keyboard.isDown(key) and 1 or 0
	end
end

local function mouseButton(button)
	return function()
		return love.mouse.isDown(button)
	end
end

local function getMouseX()
	return mouseX
end

local function getMouseY()
	return mouseY
end

function initControls()
	joysticks = love.joystick.getJoysticks()
end

function getControlStatus(binding)
	local ret = false
	for i, j in pairs (bindings[binding]) do
		ret = ret or j()
	end
	return ret
end

function updateControls()
	mouseX, mouseY = camera:worldCoords(love.mouse.getPosition())
end

function love.joystickremoved(joystick)
	initControls()
end

function love.joystickadded(joystick)
	initControls()
end

bindings = {
	move_up = {keyboard('w')},
	move_down = {keyboard('s')},
	move_left = {keyboard('a')},
	move_right = {keyboard('d')},
	look_x = {getMouseX},
	look_y = {getMouseY},
	shoot = {keyboard('l')},
	use = {keyboard('e')},
}

function love.keyreleased(key, unicode) if key == 'escape' then love.event.push('quit') end end
