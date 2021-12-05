local Instrument={}

function Instrument:new(o)
  o=o or {}
  setmetatable(o,self)
  self.__index=self
  o:init()
  return o
end

function Instrument:pulse()
  local gate=self.seq_gate()
end

function Instrument:init()
  self.n=self.n or 16
  self.k=self.k or 1
  self.w=self.w or 0
  self.seq_gate=s{0}
  self.note_num=1
  self.note_def=self.note_def or {0-36,5-36,7-36,14-36,17-36,29-36,29-36,31-36,0,5,7,14,17,29,29,31}
  self.note_freq={0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0} -- each can be 0-15, each index corresponds to note_def index
  self.accent_val={0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0} -- each is defined 0-15
  self.seq_accent=s{0}
  self.seq_note=s{0}
  self.seed=os.time()
end

function Instrument:randomize()
  self:accent_randomize()
  self:notes_randomize()
end

--
-- notes
--
function set_note_num(v)
  self.note_num=v
end

function set_note_freq(i,v)
  -- sets note i to be randomized at frequency v
  self.note_freq[i]=v
end

function notes_randomize()
  -- regenerate note pool
  -- find last non-zero element, that will be last
  local note_pool={}
  for i,v in ipairs(self.note_freq) do
    if v>0 then
      for k=1,v do
        table.insert(note_pool,self.note_def[i])
      end
    end
  end

  -- TODO: use seed here
  local notes={}
  for i=1,self.note_num do
    table.insert(notes,note_pool[math.random(#note_pool)])
  end
  self.seq_note:settable(notes)
end

--
-- accents
--

function Instrument:set_accent(i,v)
  -- sets note i to be randomized at frequency v
  self.accent_freq[i]=v
end

function Instrument:accent_randomize()
  -- find last non-zero element, that will be last
  local j=1
  for i=16,1,-1 do
    if self.accent_val[i]>0 and j==1 then
      j=i
    end
  end

  local accents={}
  for i=1,j do
    table.insert(accents,self.accent_val[i])
  end
  -- TODO: use seed here
  table.shuffle(accents)

  self.seq_accent:settable(accents)
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
