
--lib
Camera = require 'lib/hump.camera'
cache  = require 'lib/cache'
         require 'lib/color'



--source
require 'src/util'
require 'src/globals'
require 'src/assetLoader'
require 'src/generation/levelGen'
require 'src/level'
require 'src/sprite'
require 'src/controls'

--menus
require 'src/menu/game'
require 'src/menu/menu'

--entities
require 'src/entities/player'
require 'src/entities/enemy'

--misc
require 'src/misc/weapons'


--assets
RussianFont = 'assets/MCTIME.TTF'