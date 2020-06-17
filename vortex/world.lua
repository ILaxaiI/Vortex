local spatialHash = {}
spatialHash.__index = spatialHash
spatialHash.__tostring = function() return "Instance of Vortex World" end

function spatialHash:new(cellSize)
  local s = setmetatable({},spatialHash)
  s.cellSize = cellSize or 100
  s.grid = {}
  return s
end
local floor,min,max = math.floor,math.min,math.max

function spatialHash:toHCoords(x,y)
  return floor(x/self.cellSize),floor(y/self.cellSize)
end


function spatialHash:insert(e,next)
  local cx,cy = self:toHCoords(e:getPosition())
  self.grid[cx] = self.grid[cx] or {}
  self.grid[cx][cy] = self.grid[cx][cy] or {}

  --self.minx = min(cx,self.minx)
  --self.maxx = max(cx,self.maxx)
  --self.miny = min(cy,self.miny)
  --self.maxy = max(cy,self.maxy)
  local cell = self.grid[cx][cy]
  local cid = #cell+1
  cell[cid] = e
  e.hashCoordinates = {x = cx,y = cy,id = cid}
end

function spatialHash:moved(e)
  local precx,precy,cid = e.hashCoordinates.x,e.hashCoordinates.y,e.hashCoordinates.id
  local cx,cy = self:toHCoords(e:getPosition())
  if cx ~= precx or cy ~= precy then
    local cell = self.grid[precx][precy]
    local len = #cell
    cell[cid] = cell[len]
    cell[cid].hashCoordinates.id = cid
    cell[len] = nil
    
    self.grid[cx] = self.grid[cx] or {}
    self.grid[cx][cy] = self.grid[cx][cy] or {}
    
    --self.minx = min(cx,self.minx)
    --self.maxx = max(cx,self.maxx)
    --self.miny = min(cy,self.miny)
    --self.maxy = max(cy,self.maxy)

    local nid = #self.grid[cx][cy]+1
  
    self.grid[cx][cy][nid] = e
    e.hashCoordinates.x,e.hashCoordinates.y,e.hashCoordinates.id = cx,cy,nid
  end
end
  

function spatialHash:remove(e)
  local precx,precy,cid = e.hashCoordinates.x,e.hashCoordinates.y,e.hashCoordinates.id
  local cell = self.grid[precx][precy]
  local len = #cell
  cell[cid] = cell[len]
  cell[cid].hashCoordinates.id = cid
  cell[len] = nil
end




function spatialHash:getEntities(ox,oy,radius,type)
  radius = radius or 1
  local x,y = ox-radius,oy-radius
  local n = 0
  
  local maxn = self.grid[x] and self.grid[x][y] and #self.grid[x][y] or 0
  return function()
    repeat
    n = n + 1
      if n > maxn then
        y = y + 1
        if y > radius+oy then 
          x = x+1 
          y = oy-1
            if x > radius+ox then return nil end
        end
        maxn = self.grid[x] and self.grid[x][y] and #self.grid[x][y] or 0
        n = 1
      end
      
    until self.grid[x] and self.grid[x][y] and self.grid[x][y][n] and (not type or self.grid[x][y][n].type == type)
    
    return self.grid[x][y][n],x,y,n
  end 
end

function spatialHash:applyFunction(x1,y1,x2,y2,funct,...)
  local grid = self.grid
  for x = x1,x2 do
    local gx = grid[x]
    if gx then
      for y = y1,y2 do
        local gxy = gx[y]
        if gxy then
          for en =#gxy,1,-1 do
            funct(gxy[en],...)
          end
        end
      end
    end
  end
end

function spatialHash:drawDebugg()
  for x,v in pairs(self.grid) do
    for y,v2 in pairs(v) do
      love.graphics.rectangle("line",x*self.cellSize,y*self.cellSize,self.cellSize,self.cellSize)
    end
  end
end
function spatialHash:cleanup()
    local grid = self.grid
    for x,v in pairs(grid) do
      if not next(v) then 
        grid[x] = nil
      else
        for y,v2 in pairs(v) do
          if #v2 == 0 then
          v[y] = nil
        end
      end
    end
  end
end



return setmetatable(spatialHash,{__call = spatialHash.new})
