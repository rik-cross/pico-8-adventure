pico-8 cartridge // http://www.pico-8.com
version 18
__lua__

debug = false


function newapple(x,y)
 return newentity({
     -- create a position component
     position = newposition(x,y,4,5),
     -- sprite
     sprite = newsprite({ idle = { images = {{0,16}}, flip = false } }),
     -- item
     item = 'apple'
   })
end

database = {}
database.apple = {
 maxstack = 3,
 position = {w=4, h=5},
 sprite = { idle = { images = {{0,16}}, flip = false } },
 newfunction = newapple
}

cutscene = {}
cutscene.scene = {}
cutscene.step = 1
cutscene.timer = 0
cutscene.wait = function(t)
  cutscene.timer += 1
  if cutscene.timer > t then
    cutscene.advance()
  end
end
cutscene.advance = function()
  if #cutscene.scene > 0 then
    cutscene.step += 1
    cutscene.timer = 0
  end
end
cutscene.update = function()
  if #cutscene.scene > 0 then
    if cutscene.step > #cutscene.scene then
      -- reset
      cutscene.scene = {}
      cutscene.step = 1
      cutscene.timer = 0
    else
      -- run the next part of the scene
      local f = cutscene.scene[cutscene.step][1]
      local p1 = cutscene.scene[cutscene.step][2]
      local p2 = cutscene.scene[cutscene.step][3]
      local p3 = cutscene.scene[cutscene.step][4]
      f(p1,p2,p3)
    end
  end
end

curtain = {}
curtain.state = 'up'
curtain.height = 0
curtain.speed = 4
curtain.set = function(s)
 curtain.state = s
 cutscene.advance()
end
curtain.draw = function()
  -- top
  rectfill(0,-1,128,curtain.height-1,0)
  --bottom
  rectfill(0,129,128,129-curtain.height,0)
end
curtain.update = function()
 if curtain.state == 'up' then
   if curtain.height > 0 then
     curtain.height -= curtain.speed
   end
 end
 if curtain.state == 'down' then
   if curtain.height <= 64 then
     curtain.height += curtain.speed
   end
 end
end

outside = {}
outside.x = 0
outside.y = 0
outside.w = 22
outside.h = 11
outside.bg = 3

shop = {}
shop.x = 22
shop.y = 0
shop.w = 12
shop.h = 8
shop.bg = 2

currentroom = outside
function setcurrentroom(room)
 currentroom = room
 cutscene.advance()
end
function moveroom(room,entity,x,y)
 cutscene.scene = {
   {curtain.set,'down'},
   {cutscene.wait,20},
   {setcurrentroom,room},
   {entity.position.setposition,x,y},
   {curtain.set,'up'},
   {cutscene.wait,20}
 }
end

-- a table comtaining all game entities
entities = {}

function printoutline(t,x,y,c)
  -- draw the outline
  for xoff=-1,1 do
    for yoff=-1,1 do
      print(t,x+xoff,y+yoff,0)
    end
  end
  --draw the text
  print(t,x,y,c)
end

function cprint(t,y,c)
 local x = (128 - (#t * 4) - 1) / 2
 print(t,x,y,c)
end

function ycomparison(a,b)
  if a.position == nil or b.position == nil then return false end
  return a.position.y + a.position.h >
         b.position.y + b.position.h
end

function sort(list, comparison)
  for i = 2,#list do
    local j = i
    while j > 1 and comparison(list[j-1], list[j]) do
      list[j],list[j-1] = list[j-1],list[j]
      j -= 1
    end
  end
end

function canwalk(x,y)
  return not fget(mget(x/8,y/8),7)
end

function touching(x1,y1,w1,h1,x2,y2,w2,h2)
  return x1+w1 > x2 and
  x1 < x2+w2 and
  y1+h1 > y2 and
  y1 < y2+h2
end

function newinventory(s,v,x,y,items)
 local i = {}
 i.size = s
 i.visible = v
 i.x = x
 i.y = y
 i.items = items
 -- fill up inventory space
 for x=i.size-#i.items,i.size do
  add(i.items,nil)
 end
 i.selected = 1
 return i
end

function newdialogue()
  local d = {}
  d.text = {nil,nil}
  d.timed = false
  d.timeremaining = 0
  d.cursor = 0
  d.set = function(text,timed)
    -- split text into 2 lines
    if #text > 15 then

      local splitpos = 15
      local spacefound = false

      while splitpos < #text and spacefound == false do
        if sub(text,splitpos,splitpos) == ' ' then
          spacefound = true
        end
        splitpos += 1
      end
      d.text[0] = sub(text,0,splitpos-1)
      d.text[1] = sub(text,splitpos,#text)
    else
      d.text[0] = text
      d.text[1] = nil
    end
    d.timed = timed
    d.cursor = 0
    if timed then d.timeremaining = 100 end
    cutscene.advance()
  end
  return d
end

function newstate(initialstate,r)
  local s = {}
  s.current = initialstate
  s.previous = initialstate
  s.rules = r
  return s
end

function newbounds(xoff,yoff,w,h)
  local b = {}
  b.xoff = xoff
  b.yoff = yoff
  b.w = w
  b.h = h
  return b
end

function newtrigger(xoff,yoff,w,h,f,type)
  local t = {}
  t.xoff = xoff
  t.yoff = yoff
  t.w = w
  t.h = h
  t.f = f
  -- type = 'once', 'always' and 'wait'
  t.type = type
  t.active = false
  return t
end

-- creates and returns a new control component
function newcontrol(left,right,up,down,o,x,input)
  local c = {}
  c.left = left
  c.right = right
  c.up = up
  c.down = down
  c.o = o
  c.x = x
  c.input = input
  return c
end

-- creates and returns a new intention component
function newintention()
  local i = {}
  i.left = false
  i.right = false
  i.up = false
  i.down = false
  i.moving = false
  i.o = false
  i.x = false
  return i
end

-- creates and returns a new position
function newposition(x,y,w,h)
  local p = {}
  p.x = x
  p.y = y
  p.w = w
  p.h = h
  p.setposition = function(x,y)
    p.x = x
    p.y = y
    cutscene.advance()
  end
  return p
end

-- creates and returns a new sprite
function newsprite(sl)
  local s = {}
  s.spritelist = sl
  s.index = 1
  --s.flip = false
  return s
end

function newanimation(l)
  local a = {}
  a.timer = 0
  a.delay = 3
  a.list = l
  return a
end

function newbattle(hitboxes,hurtboxes,damage)
 local b = {}
 b.hitboxes = hitboxes
 b.hurtboxes = hurtboxes
 b.health = 100
 b.damage = damage
 return b
end

-- creates and returns a new entity
function newentity(componenttable)
  local e = {}
  e.position = componenttable.position or nil
  e.sprite = componenttable.sprite or nil
  e.control = componenttable.control or nil
  e.intention = componenttable.intention or nil
  e.bounds = componenttable.bounds or nil
  e.animation = componenttable.animation or nil
  e.trigger = componenttable.trigger or nil
  e.dialogue = componenttable.dialogue or nil
  e.state = componenttable.state or {current='idle'}
  e.inventory = componenttable.inventory or nil
  e.item = componenttable.item or false
  e.battle = componenttable.battle or nil
  e.gamestate = 'playing'
  return e
end

function playerinput(ent)

  if #cutscene.scene > 0 then
    ent.intention.left = false
    ent.intention.right = false
    ent.intention.up = false
    ent.intention.down = false
    ent.intention.o = false
    ent.intention.x = false
  else
    if ent.gamestate then
     if ent.gamestate == 'playing' then
      ent.intention.left = btn(ent.control.left)
      ent.intention.right = btn(ent.control.right)
      ent.intention.up = btn(ent.control.up)
      ent.intention.down = btn(ent.control.down)
      ent.intention.o = btnp(ent.control.o)
      ent.intention.x = btnp(ent.control.x)
     elseif ent.gamestate == 'inventory' then
      ent.intention.left = btnp(ent.control.left)
      ent.intention.right = btnp(ent.control.right)
      ent.intention.up = btnp(ent.control.up)
      ent.intention.down = btnp(ent.control.down)
      ent.intention.o = btnp(ent.control.o)
      ent.intention.x = btnp(ent.control.x)
     end
    end
  end
end

function npcinput(ent)
  ent.intention.left = true
end

controlsystem = {}
controlsystem.update = function()
  for ent in all(entities) do
    if ent.control ~= nil and ent.intention ~= nil then
      ent.control.input(ent)
    end
  end
end

physicssystem = {}
physicssystem.update = function()
  for ent in all(entities) do
   if ent.gamestate and ent.gamestate == 'playing' then
    if ent.position and ent.bounds then

      local newx = ent.position.x
      local newy = ent.position.y

      if ent.intention then
        if ent.intention.left then newx -= 1 end
        if ent.intention.right then newx += 1 end
        if ent.intention.up then newy -= 1 end
        if ent.intention.down then newy += 1 end
      end

      local canmovex = true
      local canmovey = true

      --
      -- map collision
      --

      -- update x position if allowed to move
      if not canwalk(newx+ent.bounds.xoff,ent.position.y+ent.bounds.yoff) or
         not canwalk(newx+ent.bounds.xoff+ent.bounds.w-1,ent.position.y+ent.bounds.yoff+ent.bounds.h-1) or
         not canwalk(newx+ent.bounds.xoff,ent.position.y+ent.bounds.yoff) or
         not canwalk(newx+ent.bounds.xoff+ent.bounds.w-1,ent.position.y+ent.bounds.yoff+ent.bounds.h-1) then
        canmovex = false
      end

      -- update y position if allowed to move
      if not canwalk(ent.position.x+ent.bounds.xoff,newy+ent.bounds.yoff) or
         not canwalk(ent.position.x+ent.bounds.xoff+ent.bounds.w-1,newy+ent.bounds.yoff) or
         not canwalk(ent.position.x+ent.bounds.xoff+ent.bounds.w-1,newy+ent.bounds.yoff+ent.bounds.h-1) or
         not canwalk(ent.position.x+ent.bounds.xoff+ent.bounds.w-1,newy+ent.bounds.yoff+ent.bounds.h-1) then
        canmovey = false
      end

      --
      -- entity collision
      --

      -- check x
      for o in all(entities) do
        if o.position and o.bounds then
          if o ~= ent and
             touching(newx+ent.bounds.xoff,ent.position.y+ent.bounds.yoff,ent.bounds.w,ent.bounds.h,
                      o.position.x+o.bounds.xoff,o.position.y+o.bounds.yoff,o.bounds.w,o.bounds.h) then
            canmovex = false
          end
        end
      end

      -- check y
      for o in all(entities) do
        if o.position and o.bounds then
          if o ~= ent and
             touching(ent.position.x+ent.bounds.xoff,newy+ent.bounds.yoff,ent.bounds.w,ent.bounds.h,
                      o.position.x+o.bounds.xoff,o.position.y+o.bounds.yoff,o.bounds.w,o.bounds.h) then
            canmovey = false
          end
        end
      end

      if canmovex then ent.position.x = newx end
      if canmovey then ent.position.y = newy end
    end
   end
  end
end

animationsystem = {}
animationsystem.update = function()
  for ent in all(entities) do
   if ent.gamestate and ent.gamestate == 'playing' then
    if ent.sprite and ent.animation and ent.state then

      if ent.animation.list[ent.state.current] then
       -- increment timer
       ent.animation.timer += 1
       -- if timer is higher than the delay
       if ent.animation.timer > ent.animation.delay then
        -- increment the index and reset the timer
        ent.sprite.index += 1
        if ent.sprite.index > #ent.sprite.spritelist[ent.state.current]['images'] then
         ent.sprite.index = 1
        end
        ent.animation.timer = 0
       end
      end

    end
  end
 end
end

triggersystem = {}
triggersystem.update = function()
  for ent in all(entities) do
    if ent.trigger and ent.position then
      local triggered = false
      for o in all(entities) do
        if ent ~= o and o.bounds and o.position then
          if touching(ent.position.x+ent.trigger.xoff,ent.position.y+ent.trigger.yoff,ent.trigger.w,ent.trigger.h,
                      o.position.x+o.bounds.xoff,o.position.y+o.bounds.yoff,o.bounds.w,o.bounds.h) then
            -- trigger is activated
            triggered = true
            if ent.trigger.type == 'once' then
              ent.trigger.f(ent,o)
              ent.trigger = nil
              break
            end
            if ent.trigger.type == 'always' then
              ent.trigger.f(ent,o)
              ent.trigger.active = true
            end
            if ent.trigger.type == 'wait' then
              if ent.trigger.active == false then
                ent.trigger.f(ent,o)
                ent.trigger.active = true
              end
            end
          end
        end
      end

      if triggered == false then
        ent.trigger.active = false
      end

    end
  end
end

dialoguesystem = {}
dialoguesystem.update = function()
  for ent in all(entities) do
    if ent.dialogue then
      if ent.dialogue.text[0] then

        -- calculate length of text
        local len = #ent.dialogue.text[0]
        if ent.dialogue.text[1] and #ent.dialogue.text[1] > 0 then
          len += #ent.dialogue.text[1]
        end

        if ent.dialogue.cursor < len then
          ent.dialogue.cursor += 1
        end
        if ent.dialogue.timed and
           ent.dialogue.timeremaining > 0 then
          ent.dialogue.timeremaining -= 1
        end
      end
    end
  end
end

statesystem = {}
statesystem.update = function()
 for ent in all(entities) do
  if ent.gamestate and ent.gamestate == 'playing' then
  if ent.state and ent.state.rules then

   ent.state.previous = ent.state.current

   for s,r in pairs(ent.state.rules) do
    if r() then ent.state.current = s end
   end

  end
  end
 end
end

itemsystem = {}
itemsystem.update = function()
 for ent in all(entities) do
  if ent.item then

   for o in all(entities) do
    if o ~= ent and o.position and o.bounds and ent.position then

     if touching(ent.position.x,ent.position.y,ent.position.w,ent.position.h,
                 o.position.x+o.bounds.xoff,o.position.y+o.bounds.yoff,o.bounds.w,o.bounds.h) then
      if o.inventory then
       if o.intention and o.intention.x then

        local found = false
        -- is there an existing place to stack the item?
        for p=1,o.inventory.size do
         if o.inventory.items[p] ~= nil then
          if o.inventory.items[p]['id'] == ent.item then
           if o.inventory.items[p]['num'] < database[ent.item]['maxstack'] then
            o.inventory.items[p]['num'] += 1
            del(entities,ent)
            found = true
            break
           end
          end
         end
        end

        -- is there a spare inventory slot?
        if found == false then
         for p=1,o.inventory.size do
          if o.inventory.items[p] == nil then
           o.inventory.items[p] = { id=ent.item, num=1 }
           del(entities,ent)
           break
          end
         end
        end

       end
      end
     end

    end
   end

  end
 end
end

gamestatesystem = {}
gamestatesystem.update = function()
 for ent in all(entities) do
  if ent.gamestate and ent.intention then
   if ent.intention.o and ent.intention.x then
    if ent.gamestate == 'playing' then
     ent.gamestate = 'inventory'
    else
     if ent.gamestate == 'inventory' then
      ent.gamestate = 'playing'
     end
    end
   end
  end
 end
end

inventorysystem = {}
inventorysystem.update = function()
 for ent in all(entities) do
  if ent.inventory and ent.inventory.visible then
   if ent.gamestate and ent.gamestate == 'inventory' then
    if ent.intention.left then
     ent.inventory.selected = max(1,ent.inventory.selected-1)
    elseif ent.intention.right then
     ent.inventory.selected = min(ent.inventory.selected+1,ent.inventory.size)
    elseif ent.intention.down then
     -- drop item
     -- if item exists at selected position
     if ent.inventory.items[ent.inventory.selected] then
      --local i = ent.inventory.items[ent.inventory.selected]
      --if i.position then
       -- update position
       --i.position.x = ent.position.x
       --i.position.y = ent.position.y
       --add(entities,i)
       --del(ent.inventory.items,i)
       --ent.inventory.items[ent.inventory.selected] = nil
      --end

      local id = ent.inventory.items[ent.inventory.selected]['id']
      local num = ent.inventory.items[ent.inventory.selected]['num']
      local f = database[id]['newfunction']

      add(entities,f(ent.position.x,ent.position.y))
      ent.inventory.items[ent.inventory.selected]['num'] -= 1
      if ent.inventory.items[ent.inventory.selected]['num'] < 1 then
       ent.inventory.items[ent.inventory.selected] = nil
      end

     end
    end
   end
  end
 end
end

battlesystem = {}
battlesystem.update = function()
 for ent in all(entities) do
  if ent.battle and ent.state and ent.position then
   -- if entity has hitbox for the current state
   if ent.battle.hitboxes[ent.state.current] and ent.state.current ~= ent.state.previous then

    -- other entities to hit
    for o in all(entities) do
     if o ~= ent and o.battle and o.state and o.position then
      -- if entity has a hurtbox
      if o.battle.hurtboxes[o.state.current] then

       local hitbox = ent.battle.hitboxes[ent.state.current]
       local hurtbox = o.battle.hurtboxes[o.state.current]
       if touching( ent.position.x+hitbox.xoff, ent.position.y+hitbox.yoff, hitbox.w, hitbox.h,
                    o.position.x+hurtbox.xoff, o.position.y+hurtbox.yoff, hurtbox.w, hurtbox.h) then
        -- deal damage
        o.battle.health -= ent.battle.damage
        if o.battle.health < 1 then
         -- drop inventory items
         if o.inventory and #o.inventory.items > 0 then
          for p=1,#o.inventory.items do
           for n=1,o.inventory.items[p]['num'] do
            local id = o.inventory.items[p]['id']
            local f = database[id]['newfunction']
            add(entities,f(o.position.x, o.position.y))
           end
          end
         end
         del(entities,o)
        end
       end

      end
     end
    end

   end
  end
 end
end

gs = {}
gs.update = function()
  sort(entities, ycomparison)

  local camerax = -64+player.position.x+(player.position.w/2)
  local cameray = -64+player.position.y+(player.position.h/2)

  --centre camera on player
  camera(camerax,cameray)
  map()

  camera()
  --crosshair sprite
  --spr(16,64-4,64-4)

  -- draw room border
  -- top border
  rectfill(-1,-1,128,(currentroom.y*8)-cameray-1,currentroom.bg)
  -- left border
  rectfill(-1,-1,(currentroom.x*8)-camerax-1,128,currentroom.bg)
  -- right border
  rectfill((currentroom.x+currentroom.w)*8-camerax,-1,128,128,currentroom.bg)
  -- bottom border
  rectfill(-1,(currentroom.y+currentroom.h)*8-cameray,128,128,currentroom.bg)

  camera(camerax,cameray)

  -- draw all entities with sprites and positions
  for ent in all(entities) do

    -- draw entity
    if ent.sprite and ent.position and ent.state then

     -- reset sprite index if state has changed
     if ent.state.current != ent.state.previous then
      ent.sprite.index = 1
     end

      sspr(ent.sprite.spritelist[ent.state.current]['images'][ent.sprite.index][1],
           ent.sprite.spritelist[ent.state.current]['images'][ent.sprite.index][2],
           ent.position.w, ent.position.h,
           ent.position.x, ent.position.y,
           ent.position.w, ent.position.h,
           ent.sprite.spritelist[ent.state.current]['flip'],false)

      -- highlight items
      if ent.item then
        -- top-left
        sspr(8,0,2,2,ent.position.x-2,ent.position.y-2)
        -- top-right
        sspr(14,0,2,2,ent.position.x+ent.position.w,ent.position.y-2)
        -- bottom-left
        sspr(8,6,2,2,ent.position.x-2,ent.position.y+ent.position.h)
        -- bottom-right
        sspr(14,6,2,2,ent.position.x+ent.position.w,ent.position.y+ent.position.h)
     end

     -- display health bar
     if ent.battle then
      --print(ent.battle.health,ent.position.x-2,ent.position.y-2,7)
      rect(ent.position.x+(ent.position.w/2)-4,ent.position.y-2,ent.position.x+(ent.position.w/2)+4,ent.position.y-2,8)
      rect(ent.position.x+(ent.position.w/2)-4,ent.position.y-2,ent.position.x+(ent.position.w/2)-4+ceil(8/100*ent.battle.health),ent.position.y-2,12)
     end

    end

    -- draw bounding boxes
    if debug then
      -- bounding boxes
      if ent.position and ent.bounds then
        rect(ent.position.x+ent.bounds.xoff,
             ent.position.y+ent.bounds.yoff,
             ent.position.x+ent.bounds.xoff+ent.bounds.w-1,
             ent.position.y+ent.bounds.yoff+ent.bounds.h-1,9)
      end
      -- trigger boxes
      if ent.position and ent.trigger then
        local colour
        if ent.trigger.active then colour = 11 else colour = 10 end
        rect(ent.position.x+ent.trigger.xoff,
             ent.position.y+ent.trigger.yoff,
             ent.position.x+ent.trigger.xoff+ent.trigger.w-1,
             ent.position.y+ent.trigger.yoff+ent.trigger.h-1,colour)
      end
      -- hitboxes
      if ent.battle and ent.position and ent.state then
       local s = ent.state.current
       local hb = ent.battle.hitboxes[s]
       if hb then
        rect(ent.position.x+hb.xoff,
             ent.position.y+hb.yoff,
             ent.position.x+hb.xoff+hb.w-1,
             ent.position.y+hb.yoff+hb.h-1,12)
       end
      end
      -- hurtboxes
      if ent.battle and ent.position and ent.state then
       local s = ent.state.current
       local hb = ent.battle.hurtboxes[s]
       if hb then
        rect(ent.position.x+hb.xoff,
             ent.position.y+hb.yoff,
             ent.position.x+hb.xoff+hb.w-1,
             ent.position.y+hb.yoff+hb.h-1,7)
       end
      end
    end
  end

  -- draw dialogue boxes
  for ent in all(entities) do
    if ent.dialogue and ent.position then
      if ent.dialogue.text[0] then
        if (ent.dialogue.timed == false) or
           (ent.dialogue.timed and ent.dialogue.timeremaining > 0) then

          -- move text up if there are 2 lines
          local offset = 0
          if ent.dialogue.text[1] then
            if #ent.dialogue.text[1] > 0 then
              offset -= 8
            end
          end

          -- draw line 1
          local texttodraw = sub(ent.dialogue.text[0],0,ent.dialogue.cursor)
          printoutline(texttodraw,ent.position.x-10,ent.position.y+offset-8,7)

          -- draw line 2
          if ent.dialogue.text[1] then
            texttodraw = sub(ent.dialogue.text[1],0,max(0,ent.dialogue.cursor - #ent.dialogue.text[0]))
            printoutline(texttodraw,ent.position.x-10,ent.position.y+offset,7)
          end

        end
      end
    end
  end

  camera()

  -- draw inventories
  for ent in all(entities) do
   if ent.inventory and ent.inventory.visible then
    rectfill(ent.inventory.x,ent.inventory.y,ent.inventory.x+(ent.inventory.size*9),ent.inventory.y+9,0)
    for i=1,ent.inventory.size do
     -- draw inventory slot
     rectfill(ent.inventory.x+1+(i-1)*9,ent.inventory.y+1,ent.inventory.x+1+(i-1)*9+7,ent.inventory.y+8,6)
     -- draw item if one exists
     if ent.inventory.items[i] then
      --local e = ent.inventory.items[i]
      --sspr(e.sprite.spritelist[e.state.current]['images'][e.sprite.index][1],
      --     e.sprite.spritelist[e.state.current]['images'][e.sprite.index][2],
      --     e.position.w, e.position.h,
      --     ent.inventory.x + 1 + (i-1)*9 + ((8-e.position.w) / 2), ent.inventory.y + 1 + ((8-e.position.h) / 2),
      --     e.position.w, e.position.h,
      --     e.sprite.spritelist[e.state.current]['flip'],false)

      local id = ent.inventory.items[i]['id']
      local num = ent.inventory.items[i]['num']

      sspr(database[id]['sprite']['idle']['images'][1][1],
           database[id]['sprite']['idle']['images'][1][2],
           database[id]['position'].w, database[id]['position'].h,
           ent.inventory.x + 1 + (i-1)*9 + ((8-database[id]['position'].w) / 2), ent.inventory.y + 1 + ((8-database[id]['position'].h) / 2),
           database[id]['position'].w, database[id]['position'].h,
           database[id]['sprite']['idle']['flip'],false)

      -- number of stacked items
      if num > 1 then
       print(num,ent.inventory.x + 1 + (i-1)*9 , ent.inventory.y + 1,7)
      end

     end
    end
    if ent.gamestate and ent.gamestate == 'inventory' then
     rect(ent.inventory.x+((ent.inventory.selected-1)*9),ent.inventory.y,ent.inventory.x+((ent.inventory.selected-1)*9)+9,ent.inventory.y+9,10)
     if ent.inventory.items[ent.inventory.selected] then
      printoutline(ent.inventory.items[ent.inventory.selected]['id'],ent.inventory.x+1,ent.inventory.y-8,7)
     end
    end
   end
  end

  curtain.draw()

end

playstate = {}
playstate.update = function()
 --check player input
 controlsystem.update()
 -- move entities
 physicssystem.update()
 -- animate entities
 animationsystem.update()
 -- check triggers
 triggersystem.update()
 -- item system
 itemsystem.update()
 -- state system
 statesystem.update()
 -- update dialogue
 dialoguesystem.update()
 -- update battle system
 battlesystem.update()
 -- update cutscene
 cutscene.update()
 -- update game state
 gamestatesystem.update()
 -- update inventories
 inventorysystem.update()
 -- update curtain
 curtain.update()
end
playstate.draw = function()
 cls()
 gs.update()
end
titlestate = {}
titlestate.draw = function()
 cls()
 cprint('adventure game',30,12)
 sspr(0,32,10,14,60,70)
 -- 100
 cprint('press x to start', max(100,150 - statemanager.frame) ,12)
end
gameoverstate = {}
gameoverstate.draw = function()
 rectfill(0,54,128,70,5)
 cprint('game over',60,12)
end

titlestate.rules = { {rule = function() return btn(5,0) end, newstate = playstate} }
playstate.rules = { {rule = function() return player.battle.health < 1 end, newstate = gameoverstate} }
gameoverstate.rules = { {rule = function() return statemanager.frame > 200 end, newstate = titlestate} }

statemanager = {}
statemanager.frame = 0
statemanager.current = nil
statemanager.update = function()
 if statemanager.current and statemanager.current.update then
  statemanager.current.update()
 end
 if statemanager.frame < 3000 then
  statemanager.frame += 1
 end
 if statemanager.current and statemanager.current.rules then
  for r in all(statemanager.current.rules) do
   if r.rule() then
    statemanager.current = r.newstate
    statemanager.frame = 0
   end
  end
 end
end
statemanager.draw = function()
 if statemanager.current and statemanager.current.draw then
  statemanager.current.draw()
 end
end

function _init()

  -- create a player entity
  player = newentity({
    -- create a position component
    position = newposition(10,10,10,14),
    -- create a sprite component
    --sprite = newsprite({{8,0},{12,0},{16,0},{20,0}},1),
    sprite = newsprite({
                         standleft  = { images = {{0,32}}, flip = true },
                         moveleft   = { images = {{0,32},{10,32},{20,32},{30,32}}, flip = true },
                         standright = { images = {{0,32}}, flip = false },
                         moveright  = { images = {{0,32},{10,32},{20,32},{30,32}}, flip = false },
                         standup    = { images = {{40,32}}, flip = false },
                         moveup     = { images = {{40,32},{50,32},{60,32},{70,32}}, flip = false },
                         standdown  = { images = {{80,32}}, flip = false },
                         movedown   = { images = {{80,32},{90,32},{100,32},{110,32}}, flip = false },
                         hitleft    = { images = {{0,46},{10,46},{20,46},{30,46}}, flip = true },
                         hitright   = { images = {{0,46},{10,46},{20,46},{30,46}}, flip = false },
                         hitdown    = { images = {{80,46},{90,46},{100,46},{110,46}}, flip = false },
                         hitup      = { images = {{40,46},{50,46},{60,46},{70,46}}, flip = false }
                      }),
    -- create a control component
    control = newcontrol(0,1,2,3,4,5,playerinput),
    -- create an intention component
    intention = newintention(),
    -- create a new bounding box
    bounds = newbounds(3,9,4,3),
    -- create a new animation component
    animation = newanimation({moveleft=true,moveright=true,moveup=true,movedown=true,hitleft=true,hitright=true,hitdown=true,hitup=true}),
    -- dialogue component
    dialogue = newdialogue(),
    -- state component
    state = newstate('standright',{ moveup = function() return player.intention.up end,
                                    movedown = function() return player.intention.down end,
                                    moveleft = function() return player.intention.left end,
                                    moveright = function() return player.intention.right end,
                                    standup = function() return (not player.intention.up and player.state.current == 'moveup') or (player.state.current == 'hitup' and player.sprite.index > 3) end,
                                    standdown = function() return (not player.intention.down and player.state.current == 'movedown') or (player.state.current == 'hitdown' and player.sprite.index > 3) end,
                                    standleft = function() return (not player.intention.left and player.state.current == 'moveleft') or (player.state.current == 'hitleft' and player.sprite.index > 3) end,
                                    standright = function() return (not player.intention.right and player.state.current == 'moveright') or (player.state.current == 'hitright' and player.sprite.index > 3) end,
                                    hitright = function() return (player.state.current == 'standright' or player.state.current == 'moveright') and (player.intention.o and not player.intention.x) and (not player.intention.right) end,
                                    hitleft = function() return (player.state.current == 'standleft' or player.state.current == 'moveleft') and (player.intention.o and not player.intention.x) and (not player.intention.left) end,
                                    hitup = function() return (player.state.current == 'standup' or player.state.current == 'moveup') and (player.intention.o and not player.intention.x) and (not player.intention.up) end,
                                    hitdown = function() return (player.state.current == 'standdown' or player.state.current == 'movedown') and (player.intention.o and not player.intention.x) and (not player.intention.down) end,
                                  }),
    -- inventory component
    inventory = newinventory(3,true,(128 - (3*9+1)) / 2,115,{}),
    -- battle component
    battle = newbattle({ hitleft = {xoff=0,yoff=3,w=3,h=9},
                         hitright = {xoff=7,yoff=3,w=3,h=9},
                         hitdown = {xoff=3,yoff=12,w=4,h=3},
                         hitup = {xoff=3,yoff=0,w=4,h=3}},
                        {
                         standright = {xoff=3,yoff=3,w=4,h=9},
                         standleft = {xoff=3,yoff=3,w=4,h=9},
                         standup = {xoff=3,yoff=3,w=4,h=9},
                         standdown = {xoff=3,yoff=3,w=4,h=9},
                         moveright = {xoff=3,yoff=3,w=4,h=9},
                         moveleft = {xoff=3,yoff=3,w=4,h=9},
                         moveup = {xoff=3,yoff=3,w=4,h=9},
                         movedown = {xoff=3,yoff=3,w=4,h=9},
                         hitright = {xoff=3,yoff=3,w=4,h=9},
                         hitleft = {xoff=3,yoff=3,w=4,h=9},
                         hitup = {xoff=3,yoff=3,w=4,h=9},
                         hitdown = {xoff=3,yoff=3,w=4,h=9},
                        },25)
  })
  add(entities,player)

  -- create a ghost
  add(entities,
    newentity({
      -- create a position component
      position = newposition(30,60,8,7),
      -- create a sprite component
      sprite = newsprite({ idle = { images = {{16,0}}, flip = false } }),
      -- battle component
      battle = newbattle({idle={xoff=0,yoff=0,w=8,h=7}},{idle={xoff=0,yoff=0,w=8,h=7}},0.5),

      trigger = newtrigger(-20,-20,48,47,function(self,other)
       if other == player then
        local xdiff = self.position.x - player.position.x
        local ydiff = self.position.y - player.position.y
        self.position.x -= xdiff / 25
        self.position.y -= ydiff / 25
       end
       end, 'always')

    })
  )

  -- create a tree entity
  add(entities,
    newentity({
      -- create a position component
      position = newposition(30,30,16,16),
      -- create a sprite component
      sprite = newsprite({ idle = { images = {{8,8}}, flip = false } }),
      -- create a new bounding box
      bounds = newbounds(6,12,4,4),
      -- battle component
      battle = newbattle({},{idle={xoff=0,yoff=0,w=16,h=16}},0),
      -- inventory component
      inventory = newinventory(1,false,0,0,{{id='apple',num=2}}),
      -- trigger component
      trigger = newtrigger(4,10,8,8,
        function(self,other)
          if other == player then
            -- cutscene
            cutscene.scene = {
              {other.dialogue.set,'oh look, a tree. how beautiful!',true},
              {cutscene.wait,100},
              {other.dialogue.set,'some more text!',true},
              {cutscene.wait,100}
            }

          end
        end,'wait')
    })
  )

  -- create a shop entity
  add(entities,
    newentity({
      -- create a position component
      position = newposition(60,40,16,16),
      -- create a sprite component
      sprite = newsprite({ idle = { images = {{40,0}}, flip = false } }),
      -- create a new bounding box
      bounds = newbounds(0,8,16,8),
      -- create a new trigger component
      trigger = newtrigger(10,16,5,3,
        function(self,other)
          if other == player then
            moveroom(shop,other,242,44)
          end
        end,'wait')
    })
  )

  -- create a shop door exit trigger
  add(entities,
    newentity({
      -- create a position component
      position = newposition(240,55,16,3),
      -- create a new trigger component
      trigger = newtrigger(0,0,8,3,
        function(self,other)
          if other == player then
            moveroom(outside,other,70,55)
          end
        end,'wait')
    })
  )

  -- create an apple
  add(entities,newapple(20,20))
  add(entities,newapple(40,20))
  add(entities,newapple(60,20))
  add(entities,newapple(80,20))

  statemanager.current = titlestate

end

function _update()
  statemanager.update()
end

function _draw()
 statemanager.draw()
end


__gfx__
0000000066000066007777000000000000000000000000555500000033333333cccccccccccc33333333cccc3333cccccccc3333333333333333333333333333
0000000060000006077777700000000000000000000005555550000033333333cccccccccc333333333333cc33cccccccccccc33333443333334433333344333
0070070000000000777777770000000000000000000055555555000033333333ccccccccc33333333333333c3cccccccccccccc3334554333345543333455433
0007700000000000775775770000000000000000000555555555500033333333ccccccccc33333333333333c3cccccccccccccc3345445444454454344544544
0007700000000000777777770000000000000000005555555555550033333333cccccccc3333333333333333cccccccccccccccc345445444454454344544544
0070070000000000777777770000000000000000055555555555555033333333cccccccc3333333333333333cccccccccccccccc334554333345543333455433
0000000060000006707070700000000000000000555555555555555533333333cccccccc3333333333333333cccccccccccccccc333443333334433333344333
0000000066000066000000000000000000000000444444444444444433333333cccccccc3333333333333333cccccccccccccccc333443333334433333333333
000880000000000bb00000000000000000000000444444444444444433333333cccccccc3333333333333333cccccccccccccccc333443333334433333344333
0008800000000bbbbbbb00000000000000000000446666666455555433733333cccccccc3333333333333333cccccccccccccccc333443333334433333344333
0000000000000bbbbbbb00000000000000000000446676666456665437773333cc7ccccc3333333333333333cccccccccccccccc334554333345543333455433
88000088000bbbbbbbbbbb000000000000000000446766666456665433733333c7c7cccc3333333333333333cccccccccccccccc345445444454454334544543
88000088000bbbbbbbbbbbb00000000000000000446666666455555433333333ccccccccc33333333333333c3cccccccccccccc3345445444454454334544543
0000000000bbbbbbbbbbbbb000000000000000004466666664555654333333a3cccccc7cc33333333333333c3cccccccccccccc3334554333345543333455433
0008800000bbbbbbbbbbbbb0000000000000000044444444445555543333a333ccccc7c7cc333333333333cc33cccccccccccc33333443333334433333344333
00088000000bbbbbbbbbb0000000000000000000444444444455555433333333cccccccccccc33333333cccc3333cccccccc3333333333333333333333344333
0004000000000bb40bb4000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000056555555
08400000000000040040000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000056555555
88880000000000044400000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000004444444456555555
88880000000000044000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000004444444466666666
08800000000000444000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000004444444455555655
00000000000000044000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000004444444455555655
00000000000000044000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000055555655
00000000000000044000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000066666666
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000066776677
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000066776677
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000077667766
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000077667766
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000066776677
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000066776677
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000077667766
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000077667766
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00088880000008888000000000000000000000000008888000000888800000000000000000000000000888800000088880000000000000000000000000000000
0008fff0000008fff0000008888000000888800000088880000008888000000888800000088880000008ff80000008ff80000008888000000888800000000000
0008fff0000008fff0000008fff0000008fff00000088880000008888000000888800000088880000008ff80000008ff80000008ff80000008ff800000000000
000811100000081110000008fff0000008fff0000001811000000181100000088880000008888000000811800000081180000008ff80000008ff800000000000
00011110000001111000000811100000081110000001181000000118100000011810000001181000000111100000011110000008118000000811800000000000
00011f1000000111f00000011110000001f11000000f11f000000111f000000f81f000000f811000000f11f0000001f1f0000001111000000f1f100000000000
00011110000001111000000111100000011110000001111000000121100000011110000001111000000111100000011110000001111000000111100000000000
00002200000002020000000020000000000020000000220000000002000000011110000001121000000111100000011110000001111000000111100000000000
00000000000000000000000000000000000000000000000000000000000000002200000000200000000022000000002000000000220000000002000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000004000000004000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000004000000004000000004000000004000000000000000000000000000000000000000000000000000000
00088880040008888000000888800000088880000008888000000888800000088880000008888000000888800000088880000008888000000888800000000000
0008fff0400008fff0000008fff0000008fff00000088880000008888000000888800000088880000008ff80000008ff80000008ff80000008ff800000000000
0008fff4000008fff0000008fff0000008fff00000088880000008888000000888800000088880000008ff80000008ff80000008ff80000008ff800000000000
00081140000008111044000811100000081110000001811000000181100000018110000001811000000811800000081180000008118000000811800000000000
00011f100000011f4400000111100000011110000001181000000118100000011810000001181000000111100000011110000001111000000111100000000000
0001111000000111100000011f440000011f1000000f11f000000f111000000f111000000f111000000f11f000000f11f0000001f1f0000001f1f00000000000
00011110000001111000000111104400011140000001111000000111100000011110000001111000000411100000041110000001411000000141100000000000
00002200000000220000000022000000002204000000220000000022000000002200000000220000000411100000041110000001411000000114100000000000
00000000000000000000000000000000000000400000000000000000000000000000000000000000000422000000004200000000240000000022400000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000400000000004000000000040000000000400000000000
__gff__
0000000000800000800000808080808000000000000000008000008080808080000000000000000000000000000000800000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__map__
0d0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0e2f2f2f2f2f2f2f2f2f2f2f2f00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1f07070707070707070707070707070707070707071f2f3f3f3f3f3f3f3f3f3f3f2f00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1f070707070707070707070b080c070707070717071f2f3f3f3f3f3f3f3f3f3f3f2f00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1f07070707070707070707080808070707070707071f2f3f3f3f3f3f3f3f3f3f3f2f00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1f07071707070707070707081808190707070707071f2f3f3f3f3f3f3f3f3f3f3f2f00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1f07070707070707070707081808080c07070707071f2f3f3f3f3f3f3f3f3f3f3f2f00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1f070707070707070707071b0808081c17070707071f2f3f3f3f3f3f3f3f3f3f3f2f00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1f07070707070707070707070707070707070707071f2f2f2f2f2f2f2f2f2e2f2f2f00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1f07070707070707071707070707070707070707071f00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1f07070707070707070707070707070707070707071f00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1d0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f0f1e00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
