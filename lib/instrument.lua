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
  self.n=self.n or 16
  self.k=self.k or 1
  self.w=self.w or 0
  self.reverb_send=0
  self.delay_send=0
  self.note_num=1
  self.note_def=self.note_def or {0-24,5-24,7-24,14-24,17-24,29-24,29-24,31-24,0,5,7,14,17,29,29,31}
  -- TODO: different note_def for lead
  self.note_freq={0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0} -- each can be 0-15, each index corresponds to note_def index
  self.duration_num=1
  self.duration_def={0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15} -- each is defined 0-15
  self.duration_freq={0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0} -- each is defined 0-15
  self.amp=1
  self.amp_def={0.005,0.01,0.02,0.04,0.06,0.08,0.1,0.2,0.3,0.4,0.5,0.6,0.7,0.8,0.9,1.0} -- each is defined 1-16
  self.amp_seq={0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0} -- each is defined 1-16
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

function Instrument:pulse()
  self.seq_gate0=self.seq_gate()
  if not self.seq_gate0 then 
    do return end 
  end
  self.seq_duration0=self.seq_duration()
  self.seq_note0=self.seq_note()
  self.seq_amp0=self.seq_amp()
  if self.id=="bass" or self.id=="lead" then
    local note=self.seq_note0+song.root
    if self.id=="lead" then 
      note = note + 12 
    end
    --print(self.id,self.seq_gate0,self.seq_amp0,note,self.seq_duration0)
    engine["acid_"..self.id](self.seq_amp0,note,self.delay_send,self.reverb_send)
    engine["acid_"..self.id.."_gate"](1)
    clock.run(function()
      clock.sleep(clock.get_beat_sec()/16*self.seq_duration0)
      engine["acid_"..self.id.."_gate"](0)
    end)
  elseif self.id=="kick" or self.id=="snare" or self.id=="hat" or self.id=="clap" then
    --print(self.id,self.seq_gate0,self.seq_amp0,note,self.seq_duration0)
    engine.acid_drum(self.id,self.seq_amp0,self.delay_send,self.reverb_send)
  end
end

--
-- fx
--
function Instrument:set_fx(fx_name,v)
  print(fx_name,v)
  --self[fx_name.."_send"]=v
end

--
-- amp
--
function Instrument:set_amp(i,v)
  self.amp_seq[i]=v

  -- update the amp sequence
  local j=1
  for i=16,1,-1 do 
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
function Instrument:set_num(k,v)
  k=k.."_num"
  self[k]=v
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

function Instrument:er_update()
  self.seq_gate:settable(er.gen(self.k,self.n,self.w))
end

return Instrument
