-- acid v0.0.1
-- ?
--
-- llllllll.co/t/?
--
--
--
--    ▼ instructions below ▼
--
-- ?

grid__=include("acid/lib/grid_")
MusicUtil=require "musicutil"
lattice=require("lattice")
engine.name="Acid"
local shift=false

function init()
  grid_=grid__:new({})
  -- initialize metro for updating screen
  timer=metro.init()
  timer.time=1/15
  timer.count=-1
  timer.event=update_screen
  timer:start()
end

function update_screen()
  redraw()
end

function key(k,z)
  if k==1 then
    shift=z==1
  end
  if shift then
    if k==1 then
    elseif k==2 then
    elseif k==3 then 
    end
  else
    if k==1 then
    elseif k==2 then
    elseif k==3 then 
    end
  end
end

function enc(k,d)
  if shift then
    if k==1 then
    elseif k==2 then
    elseif k==3 then 
    end
  else
    if k==1 then
    elseif k==2 then
    elseif k==3 then 
    end
  end
end

function redraw()
  screen.clear()
  screen.move(10,10)
  screen.text("acid")
  screen.update()
end

function rerun()
  norns.script.load(norns.state.script)
end
