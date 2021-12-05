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

include("acid/lib/utils")
s=require("sequins")
er=require("er")
grid__=include("acid/lib/grid_")
MusicUtil=require "musicutil"
lattice=require("lattice")
instrument_=include("acid/lib/instrument")
engine.name="Acid"
local shift=false

function init()
  -- grid_=grid__:new({})
  -- initialize metro for updating screen
  timer=metro.init()
  timer.time=1/15
  timer.count=-1
  timer.event=update_screen
  timer:start()
end

function params_init()
  i_={}
  local control1_16=controlspec.new(1,16,'lin',1,16,'',1/16)
  local control0_15=controlspec.new(0,15,'lin',1,15,'',1/16)
  local control0_100p=controlspec.new(0,100,'lin',1,50,'%',1/100)
  local instruments={"bass","lead"}
  for _,ins in ipairs(instruments) do
    i_[ins]=instrument_:new()
    params:add_separator(ins)
    -- note number
    params:add_control("acid_"..ins.."_notes","notes",control1_16)
    params:set_action("acid_"..ins.."_notes",function(v)
      i_[ins]:set_note_num(v)
    end)
    -- er "n"
    params:add_control("acid_"..ins.."_n","n",control1_16)
    params:set_action("acid_"..ins.."_n",function(n)
      i_[ins]:set_n(n)
    end)
    -- er "k"
    params:add_control("acid_"..ins.."_k","k",control0_100p)
    params:set_action("acid_"..ins.."_k",function(kp)
      i_[ins]:set_kp(kp)
    end)
    -- accents
    params:add_group("accent",16)
    for i=1,16 do
      local k="acid_"..ins.."_accent_"..i
      params:add_control(k,i,control0_15)
      params:set_action(k,function(v)
        i_[ins]:set_accent(i,v)
      end)
    end
    -- note probabilities
    params:add_group("note probability",16)
    for i=1,16 do
      local k="acid_"..ins.."_note_"..i
      params:add_control(k,i,control0_15)
      params:set_action(k,function(v)
        i_[ins]:set_note_freq(i,v)
      end)
    end
  end
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

function lmap(s,lo,hi,fn)
  if fn==nil then
    fn=util.linln
  end
  return fn(0,15,lo,hi,s)
end
