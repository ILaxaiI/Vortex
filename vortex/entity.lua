local entity = {}
entity.__index = entity


function entity:new(world,x,y,r,vx,vy)
  local e = setmetatable({hits = 0,world = world,x = x,y = y,r = r,vx = vx or 0,vy = vy or 0,type = 1},entity)
  world:insert(e)
  return e
end

function entity:setVelocity(vx,vy)
  self.vx = vx
  self.vy = vy
end

function entity:getPosition()
  return self.x,self.y
end


function entity:moveTo(x,y)
  self.x = x
  self.y = y
  self.world:moved(self)
end

function entity:move(dt)
  self.x = self.x + self.vx *dt
  self.y = self.y + self.vy *dt
  self.world:moved(self)

end
local lgc = love.graphics.circle

function entity:draw()
  lgc("line",self.x,self.y,self.r)
end
local function hit(entity)
  entity.hits = entity.hits+1
end



local abs = math.abs
local function sing(n)
  return n/abs(n)
end

local function collide(bullet,self,dt)
  if bullet.type == 2 then
  local bx,by = bullet:getPosition()
  
  --test if the radius of the bullet are Overlapping
  local sx,sy = self.x,self.y
  local dx,dy = bx - sx,by - sy
  local r = (bullet.r+self.r)*(bullet.r+self.r)
  if dx*dx + dy*dy <= r then
    hit(self)
    bullet:remove()
    return
  end
  
  --tunnel prevention maths
  local bdx,bdy = (bullet.vx-self.vx)*dt,(bullet.vy-self.vy)*dt
  local bprex,bprey = bx-bdx,by-bdy
  
  if bdx ~= 0 or bdy ~= 0 then
    local dx2,dy2 = bprex-sx, bprey-sy  
     if sing(dx*bdx+dy*bdy) ~= sing(dx2*bdx+dy2*bdy) then
        local n = (dx*bdy-bdx*dy)
        local l = n*n/(bdx*bdx+bdy*bdy) 
        if l < r then
          hit(self)
          bullet:remove() 
          return
        end
      end
    end
  end
end
local sq2 = math.sqrt(2)
function entity:update(dt)
  self:move(dt)
  local cx,cy = self.world:toHCoords(self.x-self.r,self.y-self.r)
  local dx,dy = self.world:toHCoords(self.vx*dt-self.r,self.vy*dt-self.r)
  
  self.world:applyFunction(cx-1 - (dx > 0 and dx or 0),cy-1 - (dy > 0 and dy or 0),cx+1-(dx < 0 and dx or 0),cy+1-(dy < 0 and dy or 0),collide,self,dt)
end


return setmetatable(entity,{__call = entity.new})