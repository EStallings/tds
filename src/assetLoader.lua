--Responsible for loading all of the sound and texture files used by the game 

--love.graphics.newImage()

assets = {}

function loadAssets()


	function loadTilesets()
		assets.tilesets = {}
		local dir = "assets/tilesets"


		local f1 = love.filesystem.getDirectoryItems(dir) --Top level directory
		for _, tileset in ipairs(f1) do
			assets.tilesets[tileset] = {}
			local f2 = love.filesystem.getDirectoryItems(dir.."/"..tileset) --Inside tilesets
			for __, roomset in ipairs(f2) do
				assets.tilesets[tileset][roomset] = {}
				local f3 = love.filesystem.getDirectoryItems(dir.."/"..tileset.."/"..roomset) --Inside roomsets
				for ___, subdir in ipairs(f3) do
					assets.tilesets[tileset][roomset][subdir] = {}
					local f4 = love.filesystem.getDirectoryItems(dir.."/"..tileset.."/"..roomset.."/"..subdir)
					for ____, name in ipairs(f4) do
						assets.tilesets[tileset][roomset][subdir][name] = love.graphics.newImage(dir .. "/" .. tileset .. "/" .. roomset .. "/" .. subdir .. "/" .. name)
		    			-- print(tileset .. "/" .. roomset .. "/" .. subdir .. "/" .. name) --outputs something like "1. main.lua"
		    		end
		    	end
		    end
		end
	end

	loadTilesets()
	print(table.tostring(assets))
end