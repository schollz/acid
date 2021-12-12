local Instrument={}

function Instrument:new(o)
  o=o or {}
  setmetatable(o,self)
  self.__index=self
  o:init()
  return o
end

function Instrument:init()
  self.id=self.id or "unknown"
  self.mod1=0.5
  self.mod2=0.5
  self.amp_scale_def={0,0.5,0.75,1,1.25,1.5,2}
  self.amp_scale=1
  self.n_def={9,10,11,12,13,14,15,16}
  self.n=self.n or 16
  self.k=self.k or 1
  self.w=self.w or 0
  self.num_def={1,2,3,4,6,10,12,16}
  self.note_num=1
  self.note_def=self.note_def or {-12,-7,-5,0,5,7,14,17}
  -- TODO: different note_def for lead
  self.note_freq={0,0,0,0,0,0,0,0} -- each can be 0-15, each index corresponds to note_def index
  self.duration_num=1
  self.duration_def={0.05,0.1,0.25,0.5,1,2,4,8} -- each is defined 0-15
  self.duration_freq={0,0,0,0,0,0,0,0} -- each is defined 0-15
  self.amp=1
  self.amp_def={}
  for i=1,16 do
    self.amp_def[i]=(i-1)/15
  end
  self.amp_seq={0,0,0,0,0,0,0,0} -- each is defined 1-16
  self.seq_duration=s{0}
  self.seq_note=s{0}
  self.seq_gate=s{0}
  self.seq_amp=s{0}
  self.seed=1
end

function Instrument:randomize_all()
  self:randomize_k("note")
  self:randomize_k("duration")
end

function Instrument:pulse(notes)
  -- TODO: use "notes" information to inform which note is played
  self.seq_gate0=self.seq_gate()
  if not self.seq_gate0 then
    do return end
  end
  local ins=self.id
  local mod1=0.5
  local mod2=0.5
  if ins~="reverb" then
    mod1=params:get("acid_"..ins.."_mod1")/100
    mod2=params:get("acid_"..ins.."_mod2")/100
  end

  self.seq_duration0=self.seq_duration()
  self.seq_note0=self.seq_note()
  self.seq_amp0=self.seq_amp()*self.amp_scale
  if self.id=="bass" or self.id=="lead" then
    table.sort(notes)
    -- local note=self.seq_note0+song.root -- +notes[1]
    local note=self.seq_note0+notes[1]
    if self.id=="lead" then
      note=note+12
    end
    --print(self.id,self.seq_gate0,self.seq_amp0,note,self.seq_duration0)
    -- print(ins,self.seq_amp0,
    --   note,
    --   mod1,
    --   mod2,
    --   params:get("acid_"..ins.."_delay"),
    -- params:get("acid_"..ins.."_reverb"))
    engine["acid_"..self.id](
      self.seq_amp0,
      note,
      mod1,
      mod2,
      params:get("acid_"..ins.."_delay"),
    params:get("acid_"..ins.."_reverb"))
    engine["acid_"..self.id.."_gate"](1)
    clock.run(function()
      clock.sleep(clock.get_beat_sec()/16*self.seq_duration0)
      engine["acid_"..self.id.."_gate"](0)
    end)
  elseif self.id=="chord" then
    -- play chords with the pad
    for i,note in ipairs(notes) do
      note=note+12
      if math.random()<0.2 then
        note=note-12
      end
      if math.random()<0.2 then
        note=note+12
      end
      -- if i>0 then
      --   print(self.id,self.seq_amp0,
      --     note,
      --     mod1,
      --     mod2,
      --     params:get("acid_chord_attack"),
      --     params:get("acid_chord_decay"),
      --     params:get("acid_"..ins.."_delay"),
      --   params:get("acid_"..ins.."_reverb"))
      -- end
      engine.acid_chord(self.seq_amp0,
        note,
        mod1,
        mod2,
        params:get("acid_chord_attack"),
        params:get("acid_chord_decay"),
        params:get("acid_"..ins.."_delay"),
      params:get("acid_"..ins.."_reverb"))
    end
  elseif self.id=="reverb" then
    -- print(self.id,1,params:get("acid_reverb_attack"),params:get("acid_reverb_decay"))
    engine.acid_reverb(1,params:get("acid_reverb_attack"),params:get("acid_reverb_decay"))
  elseif self.id=="kick" or self.id=="snare" or self.id=="hat" or self.id=="clap" then
    engine.acid_drum(self.id,
      self.seq_amp0,
      mod1,
      mod2,
      params:get("acid_"..ins.."_delay"),
    params:get("acid_"..ins.."_reverb"))
  end
end

--
-- amp
--

function Instrument:set_amp_scale(v)
  self.amp_scale=v
end

function Instrument:set_amp(i,v)
  self.amp_seq[i]=v

  -- update the amp sequence
  local j=1
  for i=8,1,-1 do
    if self.amp_seq[i]>0 and j==1 then
      j=i
    end
  end
  local amp_seq={}
  for i=1,j do
    local v=0
    if self.amp_seq[i]>0 then
      v=self.amp_def[self.amp_seq[i]]
    end
    table.insert(amp_seq,v)
  end

  self.seq_amp:settable(amp_seq)
end

--
-- notes/durations
--
function Instrument:set_num_i(k,i)
  k=k.."_num"
  self[k]=self.num_def[i]
end

function Instrument:set_freq(k,i,v)
  k=k.."_freq"
  self[k][i]=v
end

function Instrument:randomize_k(k)
  k_freq=k.."_freq"
  k_num=k.."_num"
  k_def=k.."_def"
  k_seq="seq_"..k
  local pool={}
  for i,v in ipairs(self[k_freq]) do
    if v>0 then
      for k=1,v do
        table.insert(pool,self[k_def][i])
      end
    end
  end
  if #pool==0 then
    --print("randomize_k ",k,"empty")
    self[k_seq]=s{0}
    do return end
  end

  math.randomseed(self.seed)
  local selected={}
  for i=1,self[k_num] do
    table.insert(selected,pool[math.random(#pool)])
  end
  self[k_seq]:settable(selected)
end

--
-- patterns
--

function Instrument:set_kp(kp)
  self.k=util.round(self.n*kp)
  self:er_update()
end

function Instrument:set_n_index(i)
  self.n=self.n_def[i]
  self:er_update()
end

function Instrument:set_n(n)
  self.n=n
  self:er_update()
end

function Instrument:set_k(k)
  self.k=k
  self:er_update()
end

function Instrument:set_w(w)
  self.w=w
  self:er_update()
end

function Instrument:set_wp(wp)
  self.w=util.round(self.n*wp)
  self:er_update()
end

function Instrument:er_update()
  self.seq_gate:settable(er.gen(self.k,self.n,self.w))
end

return Instrument
