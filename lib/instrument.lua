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
  self.note_num=1
  self.note_def=self.note_def or {0-36,5-36,7-36,14-36,17-36,29-36,29-36,31-36,0,5,7,14,17,29,29,31}
  self.note_freq={0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0} -- each can be 0-15, each index corresponds to note_def index
  self.accent_num=1
  self.accent_def={0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15} -- each is defined 0-15
  self.accent_freq={0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0} -- each is defined 0-15
  self.seq_accent=s{0}
  self.seq_note=s{0}
  self.seq_gate=s{0}
  self.seed=1
end

function Instrument:randomize_all()
  self:randomize_k("note")
  self:randomize_k("accent")
end

function Instrument:pulse()
  self.seq_gate0=self.seq_gate()
  self.seq_accent0=self.seq_accent()
  self.seq_note0=self.seq_note()
  print(self.id,self.seq_gate0,self.seq_note0,self.seq_accent0)
end

--
-- notes/accents
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
  self.seq_gate=self.seq_gate:settable(er.gen(self.k,self.n,self.w))
end

return Instrument
