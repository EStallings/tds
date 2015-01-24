require 'require'

local MODE = modeGame
local SUSPEND = nil
function modeChange(nmode, args)
	if MODE.exit then MODE.exit() end
	MODE = nmode
	if MODE.load then MODE.load(args) end
end

function suspend(suspend)
	SUSPEND = suspend
end

function endSuspend()
	SUSPEND = nil
end

function love.load()
	loadAssets()
	initControls()
	if MODE.load then MODE.load() end
end

function love.update(dt)
	updateControls()

	if SUSPEND then
		SUSPEND.update()
		return
	end
	if MODE.update then MODE.update(dt) end
end

function love.draw()
	if MODE.draw then MODE.draw() end

	if SUSPEND then
		SUSPEND.draw()
	end
	-- love.graphics.setColor(240, 10, 10, 255)
	-- love.graphics.setNewFont(RussianFont, 32)
	--debug drawing
end