assert(love.graphics.getSupported().glsl3,"Glsl3 required!")
local bulletType = {}
bulletType.__index = bulletType
local spatialHash
    
bulletType.bufferHandle = {1,5000}
local ffi = require("ffi")

local function getPositionStuff(bufferSize,data)
  local p1
  if not data then
    data = love.data.newByteData(ffi.sizeof("float[3]")*bufferSize)
    p1 = ffi.cast("float*",data:getFFIPointer())
  else 
    local oldData = data
    data = love.data.newByteData(ffi.sizeof("float[3]")*bufferSize)
    p1 = ffi.cast("float*",data:getFFIPointer())
    local p2 = ffi.cast("float*",oldData:getFFIPointer())
    ffi.copy(p1,p2,oldData:getSize())
    oldData:release()
  end
  local mesh = love.graphics.newMesh({{"InstancePosition", "float", 3}}, bufferSize, nil, "dynamic")
  mesh:setVertices(data)
  return data,p1,mesh
end

ffi.cdef("typedef struct {int id,type; float vx,vy; struct {float x,y; int id;} hashCoordinates;} bullet;")
local t = ffi.typeof("bullet")

function bulletType:create(world,meshSize,ArrayTexture,bufferSize,timePerFrame)
  
  local btype = setmetatable({
    instanceCount = 0,
    world = world,
    time = love.timer.getTime(),
    
    texLayerCount = ArrayTexture:getLayerCount(),
    frameTime = timePerFrame,
    bulletList = {},
    bufferSize = bufferSize,
    bulletMesh = love.graphics.newMesh({{-meshSize,-meshSize,0,0},{meshSize,-meshSize,1,0},{-meshSize,meshSize,0,1},{meshSize,meshSize,1,1}},"strip","static"),
    r = meshSize
  },bulletType)
  btype.parent = btype
  btype.ffiData,btype.ffiPtr,btype.instanceMesh = getPositionStuff(bufferSize)
  
  btype.bulletMesh:setTexture(ArrayTexture)
  btype.bulletMesh:attachAttribute("InstancePosition",btype.instanceMesh,"perinstance")
  btype.__index = btype
  ffi.metatype(t,btype)
  return btype
end
 
 
bulletType.shader = love.graphics.newShader("vortex/bulletdraw.glsl")
 

function bulletType:getPosition()
  local ptr = (self.id-1)*3
  return self.ffiPtr[ptr],self.ffiPtr[ptr+1]
end



function bulletType:move(dt)
  local ptr = (self.id-1)*3
  local x,y = self.ffiPtr[ptr] + self.vx*dt,self.ffiPtr[ptr+1] + self.vy*dt
  self.ffiPtr[ptr] = x
  self.ffiPtr[ptr+1] = y 
  self.world:moved(self)
  return x,y
end




function bulletType:setPosition(x,y)
  local ptr = (self.id-1)*3
  self.prex = x
  self.prey = y
  self.ffiPtr[ptr] = x
  self.ffiPtr[ptr+1] = y
  self.world:moved(self)
end

function bulletType:setRemovalCondition(fnkt)
  self.remCon = fnkt
end

bulletType.queue = {[0] = 0}

function bulletType:insert(x,y,vx,vy)
  self.instanceCount = self.instanceCount + 1
  if self.instanceCount > self.bufferSize then
    self:bufferTooSmall()
  end
  
  local t 
  if self.queue[0] > 1 then
    t = self.queue[self.queue[0]]
    self.queue[self.queue[0]] = nil
    self.queue[0] = self.queue[0] - 1
    t.id = self.instanceCount
    t.vx = vx or 0
    t.vy = vy or 0
  else
    t = {id = self.instanceCount,vx = vx or 0,vy = vy or 0,type = 2}
  end
  
  local b = setmetatable(t,self)
  self.bulletList[b.id] = b
  local ptr = (b.id-1)*3
  self.ffiPtr[ptr] = x
  self.ffiPtr[ptr+1] = y
  self.ffiPtr[ptr+2] = love.timer.getTime() - self.time 
  self.world:insert(b)
  return b
end

bulletType.__call = bulletType.insert

function bulletType:remove()
  local parent = self.parent
  local ptr = (self.id-1)*3
  self.ffiPtr[ptr] = self.ffiPtr[(parent.instanceCount-1)*3]
  self.ffiPtr[ptr+1] = self.ffiPtr[(parent.instanceCount-1)*3+1]
  self.ffiPtr[ptr+2] = self.ffiPtr[(parent.instanceCount-1)*3+2]

  self.bulletList[self.id] = self.bulletList[parent.instanceCount]
  if parent.instanceCount > 0  then
    self.bulletList[self.id].id = self.id
    self.bulletList[parent.instanceCount] = nil
    parent.instanceCount = parent.instanceCount - 1 
  end
  self.world:remove(self)
  self.queue[0] = self.queue[0] + 1
  self.queue[self.queue[0]] = self
end


local handles = {}
  --increase Buffer Size, requires creation of a new mesh, so this might be slow
  handles[1] = function(self)
    self.bufferSize = self.bufferSize + self.bufferHandle[2]
    self.instanceMesh:release()
    self.ffiData,self.ffiPtr,self.instanceMesh = getPositionStuff(self.bufferSize,self.ffiData)
    self.bulletMesh:attachAttribute("InstancePosition",self.instanceMesh,"perinstance")
  end
  
function bulletType:bufferTooSmall()
  handles[self.bufferHandle[1]](self)
end
function bulletType:drawDebugg()
  for i = 1,self.instanceCount do
  local x,y =   self.bulletList[i]:getPosition()
  love.graphics.circle("line",x,y,self.r)
end
end

function bulletType:setBufferOOBHandle(handle,arg)
  self.bufferHandle = {handle,arg}
end

function bulletType:applyChanges()
  self.instanceMesh:setVertices(self.ffiData)
end

function bulletType:update(dt)
 
  for i = self.instanceCount,1,-1 do
  local x,y = self.bulletList[i]:move(dt)
  if self.remCon and self.remCon(self.bulletList[i],x,y) then
    self.bulletList[i]:remove()
  end
  end
end


function bulletType:draw()
  self.shader:send("time",love.timer.getTime()-self.time)
  self.shader:send("timePerLayer",self.frameTime)
  self.shader:send("layerCount",self.texLayerCount)
  love.graphics.setShader(self.shader)
  love.graphics.drawInstanced(self.bulletMesh,self.instanceCount)
  love.graphics.setShader()
end



return setmetatable(bulletType,{__call = bulletType.create})