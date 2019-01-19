pico-8 cartridge // http://www.pico-8.com
version 16
__lua__

debug = true

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

-- a table comtaining all game entities
entities = {}

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

function newdialogue()
  local d = {}
  d.text = nil
  d.timed = false
  d.timeremaining = 0
  d.cursor = 0
  d.set = function(text,timed)
    d.text = text
    d.timed = timed
    d.cursor = 0
    if timed then d.timeremaining = 100 end
  end
  return d
end

function newbounds(xoff,yoff,w,h)
  local b = {}
  b.xoff = xoff
  b.yoff = yoff
  b.w = w
  b.h = h
  return b
end

function newtrigger(xoff,yoff,w,h,f)
  local t = {}
  t.xoff = xoff
  t.yoff = yoff
  t.w = w
  t.h = h
  t.f = f
  return t
end

-- creates and returns a new control component
function newcontrol(left,right,up,down,input)
  local c = {}
  c.left = left
  c.right = right
  c.up = up
  c.down = down
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
  return i
end

-- creates and returns a new position
function newposition(x,y,w,h)
  local p = {}
  p.x = x
  p.y = y
  p.w = w
  p.h = h
  return p
end

-- creates and returns a new sprite
function newsprite(sl,i)
  local s = {}
  s.spritelist = sl
  s.index = i
  s.flip = false
  return s
end

function newanimation(d,t)
  local a = {}
  a.timer = 0
  a.delay = d
  a.type = t
  return a
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
  return e
end

function playerinput(ent)
  ent.intention.left = btn(ent.control.left)
  ent.intention.right = btn(ent.control.right)
  ent.intention.up = btn(ent.control.up)
  ent.intention.down = btn(ent.control.down)
  ent.intention.moving = ent.intention.left or ent.intention.right or
                         ent.intention.up or ent.intention.down
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

animationsystem = {}
animationsystem.update = function()
  for ent in all(entities) do
    if ent.sprite and ent.animation then
      if ent.animation.type == 'always' or (ent.intention and ent.animation.type == 'walk' and ent.intention.moving) then
        -- increment the animation timer
        ent.animation.timer += 1
        -- if the timer is higher than the delay
        if ent.animation.timer > ent.animation.delay then
          -- increment then index ans reset the timer
          ent.sprite.index += 1
          if ent.sprite.index > #ent.sprite.spritelist then
            ent.sprite.index = 1
          end
          ent.animation.timer = 0
        end
      else
        ent.sprite.index = 1
      end
    end
  end
end

triggersystem = {}
triggersystem.update = function()
  for ent in all(entities) do
    if ent.trigger and ent.position then
      for o in all(entities) do
        if o.bounds and o.position then
          if touching(ent.position.x+ent.trigger.xoff,ent.position.y+ent.trigger.yoff,ent.trigger.w,ent.trigger.h,
                      o.position.x+o.bounds.xoff,o.position.y+o.bounds.yoff,o.bounds.w,o.bounds.h) then
            ent.trigger.f(ent,o)
          end
        end
      end
    end
  end
end

dialoguesystem = {}
dialoguesystem.update = function()
  for ent in all(entities) do
    if ent.dialogue then
      if ent.dialogue.text then
        if ent.dialogue.cursor < #ent.dialogue.text then
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

gs = {}
gs.update = function()
  cls()
  sort(entities, ycomparison)

  local camerax = -64+player.position.x+(player.position.w/2)
  local cameray = -64+player.position.y+(player.position.h/2)

  --centre camera on player
  camera(camerax,cameray)
  map()

  -- draw all entities with sprites and positions
  for ent in all(entities) do

    -- flip sprites?
    if ent.sprite and ent.intention then
      if ent.sprite.flip == false and ent.intention.left then ent.sprite.flip = true end
      if ent.sprite.flip and ent.intention.right then ent.sprite.flip = false end
    end

    -- draw entity
    if ent.sprite ~= nil and ent.position ~= nil then
      sspr(ent.sprite.spritelist[ent.sprite.index][1],
           ent.sprite.spritelist[ent.sprite.index][2],
           ent.position.w, ent.position.h,
           ent.position.x, ent.position.y,
           ent.position.w, ent.position.h,
           ent.sprite.flip,false)
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
        rect(ent.position.x+ent.trigger.xoff,
             ent.position.y+ent.trigger.yoff,
             ent.position.x+ent.trigger.xoff+ent.trigger.w-1,
             ent.position.y+ent.trigger.yoff+ent.trigger.h-1,10)
      end
    end
  end

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

  -- draw dialogue boxes
  for ent in all(entities) do
    if ent.dialogue and ent.position then
      if ent.dialogue.text ~= nil then
        if (ent.dialogue.timed == false) or
           (ent.dialogue.timed and ent.dialogue.timeremaining > 0) then
          local texttodraw = sub(ent.dialogue.text,0,ent.dialogue.cursor)
          -- draw the outline
          for x=-1,1 do
            for y=-1,1 do
              print(texttodraw,ent.position.x-10+x,ent.position.y-10+y,0)
            end
          end
          --draw the text
          print(texttodraw,ent.position.x-10,ent.position.y-10,7)
        end
      end
    end
  end

end

function _init()

  -- create a player entity
  player = newentity({
    -- create a position component
    position = newposition(10,10,4,8),
    -- create a sprite component
    sprite = newsprite({{8,0},{12,0},{16,0},{20,0}},1),
    -- create a control component
    control = newcontrol(0,1,2,3,playerinput),
    -- create an intention component
    intention = newintention(),
    -- create a new bounding box
    bounds = newbounds(0,6,4,2),
    -- create a new animation component
    animation = newanimation(3,'walk'),
    -- dialogue component
    dialogue = newdialogue()
  })
  add(entities,player)

  -- create a tree entity
  add(entities,
    newentity({
      -- create a position component
      position = newposition(30,30,16,16),
      -- create a sprite component
      sprite = newsprite({{8,8}},1),
      -- create a new bounding box
      bounds = newbounds(6,12,4,4),
      -- trigger component
      trigger = newtrigger(4,10,8,8,
        function(self,other)
          if other == player then
            other.dialogue.set('oh look, a tree!',true)
          end
        end)
    })
  )

  -- create a shop entity
  add(entities,
    newentity({
      -- create a position component
      position = newposition(60,40,16,16),
      -- create a sprite component
      sprite = newsprite({{40,0}},1),
      -- create a new bounding box
      bounds = newbounds(0,8,16,8),
      -- create a new trigger component
      trigger = newtrigger(10,16,5,3,
        function(self,other)
          if other == player then
            currentroom = shop
            other.position.x = 240
            other.position.y = 40
          end
        end)
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
            currentroom = outside
            other.position.x = 70
            other.position.y = 55
          end
        end)
    })
  )

end

function _update()
  --check player input
  controlsystem.update()
  -- move entities
  physicssystem.update()
  -- animate entities
  animationsystem.update()
  -- check triggers
  triggersystem.update()
  -- update dialogue
  dialoguesystem.update()
end

function _draw()
  gs.update()
end


__gfx__
0000000088888888888888880000000000000000000000555500000033333333cccccccccccc33333333cccc3333cccccccc3333333333333333333333333333
000000008fff8fff8fff8fff0000000000000000000005555550000033333333cccccccccc333333333333cc33cccccccccccc33333443333334433333344333
007007008fff8fff8fff8fff0000000000000000000055555555000033333333ccccccccc33333333333333c3cccccccccccccc3334554333345543333455433
0007700081118111811181110000000000000000000555555555500033333333ccccccccc33333333333333c3cccccccccccccc3345445444454454344544544
0007700011111111111111110000000000000000005555555555550033333333cccccccc3333333333333333cccccccccccccccc345445444454454344544544
0070070011f1111f11f11f110000000000000000055555555555555033333333cccccccc3333333333333333cccccccccccccccc334554333345543333455433
0000000011111111111111110000000000000000555555555555555533333333cccccccc3333333333333333cccccccccccccccc333443333334433333344333
0000000002202020020000020000000000000000444444444444444433333333cccccccc3333333333333333cccccccccccccccc333443333334433333333333
000880000000000bb00000000000000000000000444444444444444433333333cccccccc3333333333333333cccccccccccccccc333443333334433333344333
0008800000000bbbbbbb00000000000000000000446666666455555433733333cccccccc3333333333333333cccccccccccccccc333443333334433333344333
0000000000000bbbbbbb00000000000000000000446676666456665437773333cc7ccccc3333333333333333cccccccccccccccc334554333345543333455433
88000088000bbbbbbbbbbb000000000000000000446766666456665433733333c7c7cccc3333333333333333cccccccccccccccc345445444454454334544543
88000088000bbbbbbbbbbbb00000000000000000446666666455555433333333ccccccccc33333333333333c3cccccccccccccc3345445444454454334544543
0000000000bbbbbbbbbbbbb000000000000000004466666664555654333333a3cccccc7cc33333333333333c3cccccccccccccc3334554333345543333455433
0008800000bbbbbbbbbbbbb0000000000000000044444444445555543333a333ccccc7c7cc333333333333cc33cccccccccccc33333443333334433333344333
00088000000bbbbbbbbbb0000000000000000000444444444455555433333333cccccccccccc33333333cccc3333cccccccc3333333333333333333333344333
0000000000000bb40bb4000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000056555555
00000000000000040040000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000056555555
00000000000000044400000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000004444444456555555
00000000000000044000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000004444444466666666
00000000000000444000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000004444444455555655
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
__gff__
0000000080800000800000808080808000000000000000008000008080808080000000000000000000000000000000800000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
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
