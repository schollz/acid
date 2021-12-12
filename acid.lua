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

local CHORDS={"I","ii","iii","IV","V","vi","vii","i"}

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

  song={root=36,scale="Major",notes={},chord_progression=s{"I","I","I","I"},measure_length=64,chord_current=""}
  song.measure_note=song.measure_length

  sequencer=lattice:new{
    ppqn=96
  }
  local step_global=0
  local last_step={}
  local current_notes={}
  sequencer:new_pattern({
    action=function(t)
      -- do chord changes
      song.measure_note=song.measure_note+1
      if song.measure_note>song.measure_length then
        song.measure_note=1
        song.chord_current=song.chord_progression()
        song.notes=MusicUtil.generate_chord_roman(song.root,song.scale,song.chord_current)
        print("current chord: "..song.chord_current)
      end

      -- TODO: add chord to pulses
      -- for _,ins in ipairs({"chord","bass","lead","kick","snare","clap","hat","reverb"}) do
      for _,ins in ipairs({"chord","bass","kick","reverb"}) do
        i_[ins]:pulse(song.notes)
      end
    end,
    swing=60,
    division=1/16
  })

  -- setup engine defaults
  engine.acid_delay(clock.get_beat_sec()/8,2,0.015)

  -- <debug>
  params:set("clock_tempo",130)
  params_randomize_all()
  -- </debug>

  sequencer:hard_restart()
end

function params_randomize_all()
  for _,ins in ipairs({"kick","snare","hat","clap"}) do
    params:set("acid_"..ins.."_reverb",5)
  end
  for _,ins in ipairs({"kick","snare","hat","clap","reverb"}) do
    params:set("acid_"..ins.."_n",math.random(6,8))
    params:set("acid_"..ins.."_k",math.random(15,40))
  end
  for _,ins in ipairs({"bass","lead"}) do
    i_[ins].seed=math.random(1,100)
    params:set("acid_"..ins.."_n",math.random(1,8))
    params:set("acid_"..ins.."_k",math.random(50,100))
    params:set("acid_"..ins.."_amp_1",12)
    params:set("acid_"..ins.."_amp_2",12)
    params:set("acid_"..ins.."_amp_3",4)
    for _,thing in ipairs({"note","duration"}) do
      params:set("acid_"..ins.."_"..thing,8)
      for i=1,8 do
        local k="acid_"..ins.."_"..thing.."_"..i
        params:set(k,math.random(1,15))
      end
    end
    i_[ins]:randomize_all()
  end
  params:set("acid_bass_n",8)
  params:set("acid_bass_k",100)
  params:set("acid_bass_reverb",5)
  params:set("acid_chord_reverb",5)

  params:set("acid_reverb_n",8)
  params:set("acid_reverb_k",25)
  params:set("acid_reverb_attack",0.1)
  params:set("acid_reverb_decay",0.5)

  params:set("acid_chord_n",8)
  params:set("acid_chord_k",100/16/4)
  params:set("acid_chord_attack",clock.get_beat_sec()*4)
  params:set("acid_chord_decay",0.1)

  params:set("acid_kick_n",8)
  params:set("acid_kick_k",0)
  params:set("acid_kick_reverb",0)
end

function params_randomize()
  for _,ins in ipairs({"bass","lead"}) do
    i_[ins].seed=math.floor(os.clock()*1000)
    i_[ins]:randomize_all()
  end
end

function params_init()
  i_={}
  local control1_8=controlspec.new(1,8,'lin',1,1,'',1/8,true)
  local control1_7=controlspec.new(1,7,'lin',1,1,'',1/7,true)
  local control0_7=controlspec.new(0,7,'lin',1,0,'',1/8,true)
  local control0_15=controlspec.new(0,15,'lin',1,0,'',1/16,true)
  local control0_100p=controlspec.new(0,100,'lin',1,50,'%',1/101,true)
  local control0_255=controlspec.new(0,255,'lin',1,32,'',1/256,true)
  local controlmeasure=controlspec.new(0.01,4,'lin',0.01,0.5,'measure',0.01/4)
  local control_small_time=controlspec.new(0,1,'lin',0.01,0.1,'s',0.01/1)
  local percussion={"kick","snare","clap","hat"}
  local percussion_defaults={
    kick={n=16,k=4/16*100,w=0},
    snare={n=16,k=2/16*100,w=4},
    clap={n=16,k=4/16*100,w=2},
    hat={n=16,k=5/16*100,w=4},
  }
  local knw=function(ins)
    -- er "n"
    params:add_control("acid_"..ins.."_n","n",control0_255)
    params:set_action("acid_"..ins.."_n",function(n)
      i_[ins]:set_n(n)
    end)
    -- er "k"
    params:add_control("acid_"..ins.."_k","k",control0_100p)
    params:set_action("acid_"..ins.."_k",function(kp)
      i_[ins]:set_kp(kp/100)
    end)
    -- er "w"
    params:add_control("acid_"..ins.."_w","w",control0_100p)
    params:set_action("acid_"..ins.."_w",function(wp)
      i_[ins]:set_wp(wp/100)
    end)
  end
  local shared_parms=function(ins)
    params:add_separator(ins)
    -- mixer volume
    params:add_control("acid_"..ins.."_amp_scale","amp scale",control0_100p)
    params:set_action("acid_"..ins.."_amp_scale",function(n)
      i_[ins]:set_amp(n/100)
    end)

    knw(ins)
    -- amp sequence
    params:add_group("amps",8)
    for i=1,8 do
      local k="acid_"..ins.."_amp_"..i
      params:add_control(k,i,control0_15)
      params:set_action(k,function(v)
        i_[ins]:set_amp(i,v)
      end)
      if i==1 then
        params:set(k,8)
      end
    end
    -- mods 1 and 2
    for i=1,2 do
      local k="acid_"..ins.."_mod"..i
      params:add_control(k,"mod "..i,control0_100p)
      params:set(k,50)
    end

    -- add attack/decay parameters for chords
    if ins=="chord" then
      params:add_control("acid_chord_attack","attack",controlmeasure)
      params:add_control("acid_chord_decay","decay",controlmeasure)
      for i=1,4 do
        params:add_option("acid_chord_"..i,"chord "..i,CHORDS)
        params:set_action("acid_chord_"..i,function(v)
          song.chord_progression[i]=CHORDS[v]
        end)
      end
    end

    if ins=="lead" or ins=="bass" then
      -- notes/durations
      for _,thing in ipairs({"note","duration"}) do
        params:add_group(thing.."s",9)
        params:add_control("acid_"..ins.."_"..thing,"# "..thing.."s",control1_8)
        params:set_action("acid_"..ins.."_"..thing,function(v)
          i_[ins]:set_num_i(thing,v)
        end)
        for i=1,8 do
          local k="acid_"..ins.."_"..thing.."_"..i
          params:add_control(k,i,control0_15)
          params:set_action(k,function(v)
            --print("setting "..ins.." i to "..v)
            i_[ins]:set_freq(thing,i,v)
          end)
        end
      end
    end

    -- delay/reverb send
    for _,fxname in ipairs({"delay","reverb"}) do
      local k="acid_"..ins.."_"..fxname
      params:add_control(k,fxname.." send",control0_100p)
      params:set(k,0)
    end

  end

  -- insert the parameters
  local instruments={"chord","bass","lead"}
  for _,ins in ipairs(instruments) do
    i_[ins]=instrument_:new({id=ins})
    shared_parms(ins)
  end
  for _,ins in ipairs(percussion) do
    i_[ins]=instrument_:new({id=ins})
    shared_parms(ins)
    for _,erthing in ipairs({"n","k","w"}) do
      params:set("acid_"..ins.."_"..erthing,percussion_defaults[ins][erthing])
    end
  end

  -- effects
  i_["reverb"]=instrument_:new({id="reverb"})
  knw("reverb")
  params:add_control("acid_reverb_attack","reverb attack",control_small_time)
  params:add_control("acid_reverb_decay","reverb decay",control_small_time)
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
