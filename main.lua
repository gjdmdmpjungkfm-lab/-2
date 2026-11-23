-- IRON FRONTIER - LÖVE 2D mobile factory defense prototype
local TILE, COLS, ROWS = 48, 22, 14
local map, buildings, enemies, particles = {}, {}, {}, {}
local cameraX, cameraY = 0, 0
local iron, copper, wave, waveTimer = 80, 25, 0, 12
local selected, gameOver = "miner", false
local uiH, topH = 82, 54
local ore = {}
local buttons = {
  {id="miner", label="MINER", cost=25},
  {id="belt", label="BELT", cost=2},
  {id="turret", label="TURRET", cost=45},
  {id="wall", label="WALL", cost=8},
}
local core = {x=11,y=7,hp=100,maxHp=100}
local font, small
local function key(x,y) return x..":"..y end
local function inside(x,y) return x>=1 and y>=1 and x<=COLS and y<=ROWS end
local function occupied(x,y)
  for _,b in ipairs(buildings) do if b.x==x and b.y==y then return true end end
  return core.x==x and core.y==y
end
local function addText(t,x,y,f) love.graphics.setFont(f or font); love.graphics.print(t,x,y) end
function love.load()
  love.window.setTitle("IRON FRONTIER")
  love.graphics.setBackgroundColor(.055,.07,.075)
  font=love.graphics.newFont(14); small=love.graphics.newFont(10)
  for y=1,ROWS do map[y]={}; for x=1,COLS do map[y][x]="ground" end end
  math.randomseed(os.time())
  for i=1,36 do
    local x,y=math.random(2,COLS-1),math.random(2,ROWS-1)
    if math.abs(x-core.x)+math.abs(y-core.y)>3 then
      map[y][x]=(i%3==0) and "copper" or "iron"
      ore[key(x,y)]=true
    end
  end
  table.insert(buildings,{x=core.x-1,y=core.y,type="belt",dir=1})
  table.insert(buildings,{x=core.x-2,y=core.y,type="belt",dir=1})
end
local function cost(id)
  if id=="miner" then return 25 elseif id=="belt" then return 2 elseif id=="turret" then return 45 else return 8 end
end
local function place(x,y)
  if not inside(x,y) or occupied(x,y) then return end
  if selected=="miner" and not ore[key(x,y)] then return end
  local c=cost(selected)
  if iron<c then return end
  iron=iron-c
  table.insert(buildings,{x=x,y=y,type=selected,progress=0,dir=1})
end
local function spawnWave()
  wave=wave+1
  local count=3+wave*2
  for i=1,count do
    local side=math.random(1,4); local x,y
    if side==1 then x,y=1,math.random(1,ROWS)
    elseif side==2 then x,y=COLS,math.random(1,ROWS)
    elseif side==3 then x,y=math.random(1,COLS),1
    else x,y=math.random(1,COLS),ROWS end
    table.insert(enemies,{x=(x-.5)*TILE,y=(y-.5)*TILE,hp=20+wave*3,speed=18+wave*1.5})
  end
  waveTimer=25
end
local function worldToTile(x,y) return math.floor(x/TILE)+1,math.floor(y/TILE)+1 end
local function screenToWorld(x,y) return x+cameraX,y+cameraY end
local function drawTile(x,y,t)
  local sx,sy=(x-1)*TILE-cameraX,(y-1)*TILE-cameraY
  if t=="ground" then love.graphics.setColor(.12,.15,.15)
  elseif t=="iron" then love.graphics.setColor(.35,.38,.38)
  else love.graphics.setColor(.25,.42,.43) end
  love.graphics.rectangle("fill",sx,sy,TILE-1,TILE-1)
  if t=="iron" or t=="copper" then
    love.graphics.setColor(t=="iron" and .68 or .9,t=="iron" and .72 or .48,t=="iron" and .72 or .22)
    love.graphics.circle("fill",sx+24,sy+24,8)
    love.graphics.circle("fill",sx+15,sy+15,3)
  end
end
local function drawBuilding(b)
  local x,y=(b.x-1)*TILE-cameraX,(b.y-1)*TILE-cameraY
  if b.type=="miner" then
    love.graphics.setColor(.85,.55,.18); love.graphics.rectangle("fill",x+6,y+6,36,36,5)
    love.graphics.setColor(.15,.17,.17); love.graphics.circle("fill",x+24,y+24,10)
    love.graphics.setColor(1,.8,.35); love.graphics.circle("line",x+24,y+24,14)
  elseif b.type=="belt" then
    love.graphics.setColor(.28,.34,.35); love.graphics.rectangle("fill",x+3,y+8,42,32,4)
    love.graphics.setColor(.85,.72,.35)
    for i=0,2 do love.graphics.polygon("fill",x+10+i*12,y+17,x+18+i*12,y+24,x+10+i*12,y+31) end
  elseif b.type=="turret" then
    love.graphics.setColor(.25,.52,.48); love.graphics.circle("fill",x+24,y+24,19)
    love.graphics.setColor(.12,.17,.17); love.graphics.rectangle("fill",x+20,y+5,8,25,3)
    love.graphics.setColor(.75,.9,.78); love.graphics.circle("line",x+24,y+24,19)
  else
    love.graphics.setColor(.38,.42,.43); love.graphics.rectangle("fill",x+4,y+4,40,40,3)
    love.graphics.setColor(.58,.63,.62); love.graphics.rectangle("line",x+4,y+4,40,40,3)
  end
end
local function hitButton(x,y)
  local w=love.graphics.getWidth()/#buttons
  if y<love.graphics.getHeight()-uiH then return false end
  local i=math.floor(x/w)+1
  if buttons[i] then selected=buttons[i].id; return true end
  return false
end
local function tap(x,y)
  if hitButton(x,y) then return end
  if y<topH then return end
  local wx,wy=screenToWorld(x,y-topH)
  local tx,ty=worldToTile(wx,wy)
  place(tx,ty)
end
function love.mousepressed(x,y,button) if button==1 then tap(x,y) end end
function love.touchpressed(id,x,y) tap(x*love.graphics.getWidth(),y*love.graphics.getHeight()) end
function love.keypressed(k)
  if k=="1" then selected="miner" elseif k=="2" then selected="belt"
  elseif k=="3" then selected="turret" elseif k=="4" then selected="wall"
  elseif k=="escape" then love.event.quit() end
end
function love.update(dt)
  if gameOver then return end
  waveTimer=waveTimer-dt
  if waveTimer<=0 then spawnWave() end
  for _,b in ipairs(buildings) do
    if b.type=="miner" then
      b.progress=b.progress+dt
      if b.progress>=2.5 then b.progress=0; iron=iron+3 end
    elseif b.type=="turret" then
      b.cool=(b.cool or 0)-dt
      if b.cool<=0 then
        for i,e in ipairs(enemies) do
          local bx,by=(b.x-.5)*TILE,(b.y-.5)*TILE
          if (e.x-bx)^2+(e.y-by)^2<190^2 then
            e.hp=e.hp-18; b.cool=.7
            if e.hp<=0 then table.remove(enemies,i); iron=iron+2 end
            break
          end
        end
      end
    end
  end
  for i=#enemies,1,-1 do
    local e=enemies[i]
    local tx,ty=(core.x-.5)*TILE,(core.y-.5)*TILE
    local dx,dy=tx-e.x,ty-e.y; local d=math.sqrt(dx*dx+dy*dy)
    if d<22 then core.hp=core.hp-8*dt
    else e.x=e.x+dx/d*e.speed*dt; e.y=e.y+dy/d*e.speed*dt end
  end
  if core.hp<=0 then core.hp=0; gameOver=true end
end
function love.draw()
  local sw,sh=love.graphics.getWidth(),love.graphics.getHeight()
  love.graphics.push()
  love.graphics.translate(0,topH)
  for y=1,ROWS do for x=1,COLS do drawTile(x,y,map[y][x]) end end
  for _,b in ipairs(buildings) do drawBuilding(b) end
  local cx,cy=(core.x-1)*TILE-cameraX,(core.y-1)*TILE-cameraY
  love.graphics.setColor(.25,.72,.72); love.graphics.rectangle("fill",cx+3,cy+3,42,42,6)
  love.graphics.setColor(.85,1,1); love.graphics.rectangle("line",cx+3,cy+3,42,42,6)
  love.graphics.setColor(.1,.2,.2); love.graphics.circle("fill",cx+24,cy+24,10)
  for _,e in ipairs(enemies) do
    love.graphics.setColor(.78,.22,.16); love.graphics.circle("fill",e.x-cameraX,e.y-cameraY,10)
    love.graphics.setColor(1,.55,.4); love.graphics.circle("line",e.x-cameraX,e.y-cameraY,10)
  end
  love.graphics.pop()
  love.graphics.setColor(.045,.065,.07); love.graphics.rectangle("fill",0,0,sw,topH)
  love.graphics.setColor(.55,.9,.83); addText("IRON FRONTIER",12,8)
  love.graphics.setColor(1,1,1); addText("IRON "..iron.."   COPPER "..copper.."   WAVE "..wave,12,29,small)
  love.graphics.setColor(.2,.22,.22); love.graphics.rectangle("fill",sw-124,13,110,12,3)
  love.graphics.setColor(.25,.85,.55); love.graphics.rectangle("fill",sw-124,13,110*core.hp/core.maxHp,12,3)
  love.graphics.setColor(1,1,1); addText("CORE "..math.floor(core.hp).."%",sw-124,29,small)
  love.graphics.setColor(.04,.055,.06); love.graphics.rectangle("fill",0,sh-uiH,sw,uiH)
  local bw=sw/#buttons
  for i,b in ipairs(buttons) do
    local x=(i-1)*bw
    love.graphics.setColor(selected==b.id and .22 or .12,selected==b.id and .38 or .16,selected==b.id and .35 or .17)
    love.graphics.rectangle("fill",x+4,sh-uiH+7,bw-8,uiH-14,7)
    love.graphics.setColor(.85,.92,.88); addText(b.label,x+10,sh-uiH+17,small)
    addText(tostring(b.cost).." IRON",x+10,sh-uiH+38,small)
  end
  if gameOver then
    love.graphics.setColor(0,0,0,.78); love.graphics.rectangle("fill",0,0,sw,sh)
    love.graphics.setColor(1,.35,.25); addText("BASE DESTROYED",sw/2-65,sh/2-10)
    love.graphics.setColor(1,1,1); addText("Restart the app to try again",sw/2-82,sh/2+15,small)
  end
end
