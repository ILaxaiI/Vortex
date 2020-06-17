# Vortex
A simple Bullet-hell Library for Löve

It uses Instance Drawing to basically remove the overhead of using love.graphics.draw for every individual bullet.
One could easely modify it to be used for other things instead.

# How to use:

```lua
--require the folder, the init.lua does the rest
local vortex = require("Vortex")
local world = vortex.world(<number> cellSize) --/:new(), creates a spatial Hash

local BulletType = vortex.bulletType(<vortex World> world,<number> radius,<LoveArrayTexture> tex,<number> animationSpeed)  -- /:create()
```
This will create 2 meshes internally, one rectangle mesh with the size of radius to draw your texture to, one instance mesh to manage position of draws. Offscreen bullets are not culled, simply because doing so was slower than just drawing them anyways.

The bulletdraw shader is used to pick array texture layers and thus animate bullets without much overhead.

```lua
 local bullet = BulletType(<number> x,y,vx,vy) --/:insert()
```
this will create a bullet at the given coordinates, note that x and y are only stored in a love byteData object and can only be accesed via 'getPossition'. this is because building a mesh from bytedata is (probably) faster, and definetly saves memory.


```lua
local player = vortex.entity(<vortex World> world,<number> x,y,radisu) --/:new()
```
this creates an entity for the bullets to collide with.
note that entitys do store their possition in x,y but changing those directly will mess up their world possition
use ':moveTo' or change their velocities, or call :moved after changing x,y

```lua
function love.update(dt)
  BulletType:update(dt) -- simply mooves all the bullets.
  player:update(dt) -- moves the player and does collision calculations
  BulletType:applyChanges() --!!! this will update the instance mesh and is required to actually make anything moove
end

function love.draw()
  BulletType:draw()
  player:draw()
end
