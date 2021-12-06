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
--grid__=include("acid/lib/grid_")
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

  song={root=36,scale="Major"}

  sequencer=lattice:new{
    ppqn=96
  }
  local step_global=0
  local last_step={}
  local current_notes={}
  sequencer:new_pattern({
    action=function(t)
      for _,ins in ipairs({"bass","lead","kick"}) do
        i_[ins]:pulse()
      end
    end,
    division=1/16
  })

  -- <debug>
  params_randomize_all()
  -- </debug>

  sequencer:hard_restart()
end

function params_randomize_all()
  for _,ins in ipairs({"bass","lead"}) do
    i_[ins].seed=math.random(1,100)
    params:set("acid_"..ins.."_n",math.random(4,16))
    params:set("acid_"..ins.."_k",math.random(50,100))
    if ins=="lead" then
      params:set("acid_"..ins.."_w",math.random(0,3)*2+1)
    else
      params:set("acid_"..ins.."_w",math.random(0,3)*2)
    end
    params:set("acid_"..ins.."_amp_1",12)
    params:set("acid_"..ins.."_amp_2",12)
    params:set("acid_"..ins.."_amp_3",4)
    params:set("acid_"..ins.."_amp_4",12)
    params:set("acid_"..ins.."_amp_5",12)
    params:set("acid_"..ins.."_amp_6",4)
    params:set("acid_"..ins.."_amp_7",12)
    params:set("acid_"..ins.."_amp_8",12)
    for _,thing in ipairs({"note","duration"}) do
      params:set("acid_"..ins.."_"..thing,math.random(1,15))
      for i=1,16 do
        local k="acid_"..ins.."_"..thing.."_"..i
        params:set(k,math.random(0,15))
      end
    end
    i_[ins]:randomize_all()
  end
end

function params_randomize()
  for _,ins in ipairs({"bass","lead"}) do
    i_[ins].seed=math.floor(os.clock()*1000)
    i_[ins]:randomize_all()
  end
end

function params_init()
  i_={}
  local control1_16=controlspec.new(1,16,'lin',1,1,'',1/16,true)
  local control1_15=controlspec.new(1,15,'lin',1,1,'',1/15,true)
  local control0_15=controlspec.new(0,15,'lin',1,0,'',1/16,true)
  local control0_100p=controlspec.new(0,100,'lin',1,50,'%',1/100,true)
  local percussion={"kick","snare","clap","hat"}
  local percussion_defaults={
    kick={n=16,k=4/16*100,w=0},
    snare={n=16,k=2/16*100,w=4},
    clap={n=16,k=4/16*100,w=2},
    hat={n=16,k=5/16*100,w=4},
  }
  for _, ins in ipairs(percussion) do
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
    params:set_action("acid_"..ins.."_w",function(w)
      print(ins.." w",w)
      i_[ins]:set_w(w)
    end)
    for _, erthing in ipairs({"n","k","w"}) do 
      params:set("acid_"..ins.."_"..erthing,percussion_defaults[ins][erthing])
    end

    -- delay/reverb send
    for _, fxname in ipairs({"delay","reverb"}) do 
      local k="acid_"..ins.."_"..fxname
      print(k)
      params:add_control(k,fxname.." send",control0_100p)
      params:set_action(k,fxname.." send",function(v)
        i_[ins]:set_fx(fxname,v/100)
      end)  

      print("here comes an error!")
      --params:set(k,1)
      print("won't get here cause error")
    end
    -- amp
    params:add_group("amps",16)
    for i=1,16 do 
      local k="acid_"..ins.."_amp_"..i 
      params:add_control(k,i,control0_15)
      params:set_action(k,function(v)
        i_[ins]:set_amp(i,v)
      end)
      if i==1 then
        params:set(k,8)
      end
    end
  end
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
    params:set_action("acid_"..ins.."_w",function(w)
      --print(ins.." w",w)
      i_[ins]:set_w(w)
    end)
    -- -- delay/reverb send
    -- for _, fx in ipairs({"delay","reverb"}) do 
    --   params:add_control("acid_"..ins.."_"..fx,fx.." send",control0_100p)
    --   params:set_action("acid_"..ins.."_"..fx,fx.." send",function(v)
    --     --i_[ins]:set_fx(fx,v/100)
    --   end)  
    --   params:set("acid_"..ins.."_"..fx,0)
    -- end
    -- amp
    params:add_group("amps",16)
    for i=1,16 do 
      local k="acid_"..ins.."_amp_"..i 
      params:add_control(k,i,control0_15)
      params:set_action(k,function(v)
        i_[ins]:set_amp(i,v)
      end)
    end
    -- notes/durations
    for _,thing in ipairs({"note","duration"}) do
      params:add_group(thing.."s",17)
      params:add_control("acid_"..ins.."_"..thing,"# "..thing.."s",control0_15)
      params:set_action("acid_"..ins.."_"..thing,function(v)
        i_[ins]:set_num(thing,v)
      end)
      for i=1,16 do
        local k="acid_"..ins.."_"..thing.."_"..i
        params:add_control(k,i,control0_15)
        params:set_action(k,function(v)
          --print("setting "..ins.." i to "..v)
          i_[ins]:set_freq(thing,i,v)
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
