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
local inited=false

function init()
  params_init()

  -- initialize grid
  -- grid_=grid__:new({})

  -- constant timer
  timer=metro.init()
  timer.time=1/15
  timer.count=-1
  timer.event=updater
  timer:start()
end

-- asynchronous init
function init2()
  inited=true

  sequencer=lattice:new{
    ppqn=96
  }
  local step_global=0
  local last_step={}
  local current_notes={}
  sequencer:new_pattern({
    action=function(t)
      for _,ins in ipairs({"bass"}) do
        i_[ins]:pulse()
      end
    end,
    division=1/4
  })

  -- <debug>
  params_randomize()
  -- </debug>

  sequencer:hard_restart()
end

function params_randomize()
  params:set("acid_"..ins.."_n",16)
  params:set("acid_"..ins.."_k",15)
  params:set("acid_"..ins.."_w",math.random(0,3)*2+1)
  for _,ins in ipairs({"bass","lead"}) do
    for _,thing in ipairs({"note","accent"}) do
      params:set("acid_"..ins.."_"..thing,math.random(1,15))
      for i=1,16 do
        local k="acid_"..ins.."_"..thing.."_"..i
        params:set(k,i,math.random(0,15))
      end
    end
  end
end

function params_init()
  i_={}
  local control1_16=controlspec.new(1,16,'lin',1,16,'',1/16,true)
  local control1_15=controlspec.new(1,15,'lin',1,15,'',1/15,true)
  local control0_15=controlspec.new(0,15,'lin',1,15,'',1/16,true)
  local control0_100p=controlspec.new(0,100,'lin',1,50,'%',1/100,true)
  local instruments={"bass","lead"}
  for _,ins in ipairs(instruments) do
    i_[ins]=instrument_:new({id=ins})
    params:add_separator(ins)
    -- er "n"
    params:add_control("acid_"..ins.."_n","n",control1_16)
    params:set_action("acid_"..ins.."_n",function(n)
      i_[ins]:set_n(n)
    end)
    -- er "k"
    params:add_control("acid_"..ins.."_k","k",control0_100p)
    params:set_action("acid_"..ins.."_k",function(kp)
      i_[ins]:set_kp(kp/100)
    end)
    -- er "w"
    params:add_control("acid_"..ins.."_w","w",control0_15)
    params:set_action("acid_"..ins.."_w",function(n)
      i_[ins]:set_w(w)
    end)
    -- notes/accents
    for _,thing in ipairs({"note","accent"}) do
      params:add_group(thing.."s",17)
      params:add_control("acid_"..ins.."_"..thing,"# "..thing.."s",control0_15)
      params:set_action("acid_"..ins.."_"..thing,function(v)
        i_[ins]:set_num(thing,v)
      end)
      for i=1,16 do
        local k="acid_"..ins.."_"..thing.."_"..i
        params:add_control(k,i,control0_15)
        params:set_action(k,function(v)
          i_[ins]:seq_freq(thing,i,v)
        end)
      end
    end
  end
end

function updater()
  if not inited then
    init2()
  end
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
