-- local pattern_time = require("pattern")
local Grid_={}

local PAGE_MIXER=1
local PAGE_BASS=2
local INSTRUMENTS={
  "chord",
  "lead",
  "bass",
  "kick",
  "snare",
  "clap",
  "hat",
  "reverb",
}

function Grid_:new(args)
  local m=setmetatable({},{__index=Grid_})
  local args=args==nil and {} or args

  -- initiate the grid
  m.g=grid.connect()
  m.g.key=function(x,y,z)
    if m.grid_on then
      m:grid_key(x,y,z)
    end
  end
  print("grid columns: "..m.g.cols)

  -- setup visual
  m.visual={}
  m.grid_width=16
  for i=1,8 do
    m.visual[i]={}
    for j=1,m.grid_width do
      m.visual[i][j]=0
    end
  end
  m.page=PAGE_MIXER

  -- keep track of pressed buttons
  m.pressed_buttons={}

  -- grid refreshing
  m.grid_refresh=metro.init()
  m.grid_refresh.time=0.03
  m.grid_refresh.event=function()
    if m.grid_on then
      m:grid_redraw()
    end
  end
  m.grid_refresh:start()

  -- calculate parameter ranges
  m.params={}
  for _,p in ipairs(params.params) do
    if p.controlspec~=nil then
      m.params[p.id]={min=p.controlspec.minval,max=p.controlspec.maxval}
    end
  end

  return m
end

function Grid_:grid_key(x,y,z)
  self:key_press(y,x,z==1)
  self:grid_redraw()
end

function Grid_:key_press(row,col,on)
  if on then
    table.insert(self.pressed_buttons,{row=row,col=col,time=clock.get_beats()*clock.get_beat_sec()})
  else
    local did_remove=false
    for i,v in ipairs(self.pressed_buttons) do
      if did_remove==false and v.row==row and v.col==col then
        table.remove(self.pressed_buttons,i)
        did_remove=true
      end
    end
  end

  -- navigation on every page
  if row==8 then
    if on then
      self.page=col
    end
    do return end
  end

  -- define functions for pressing keys
  local press={}
  press[PAGE_MIXER]=self:key_press_mixer
  press[PAGE_BASS]=self:key_press_bass
  if on then
    press[self.page](row,col)
  end
end

function Grid_:key_press_mixer(row,col)
  for i,ins in ipairs(INSTRUMENTS) do
    if row==i then
      local name="acid_"..ins.."_amp_scale"
      local b=param_to_binary(name,7)
      local index=8-row -- 1-7
      b[index]=1-b[index]
      param_set_from_binary(name,b)
    end
  end
end

function Grid_:key_press_bass(row,col)
  -- 1. n
  -- 2. k {0,12.5,25,33.3,50,66.6,75,100}
  -- 3. mod1
  -- 4. mod2
  -- 5. note {-12,-7,-5,0,5,7,14,17}
  -- 6. duration {0.05,0.1,0.25,0.5,1,2,4,8}
  -- 7. amp seqeunce
  local ins="bass"
  if row<=4 then
    local names={"n","k","mod1","mod2"}
    local name="acid_"..ins.."_"..names[row]
    local b=param_to_binary(name,8)
    b[col]=1-b[col]
    param_set_from_binary(name,b)
  else
    local names={"note","duration","amp"}
    local name="acid_"..ins.."_"..names[row].."_"..col
    params:delta(name,1)
  end
end

function Grid_:get_visual()
  -- clear visual
  for row=1,8 do
    for col=1,self.grid_width do
      self.visual[row][col]=self.visual[row][col]-1
      if self.visual[row][col]<0 then
        self.visual[row][col]=0
      end
    end
  end

  -- illuminate the page
  if self.page==PAGE_MIXER then
    for col,ins in ipairs(INSTRUMENTS) do
      local name="acid_"..ins.."_amp_scale"
      local b=param_to_binary(name,7)
      for i,v in ipairs(b) do
        if v>0 then
          local row=8-i
          self.visual[row][col]=15
        end
      end
    end
  elseif self.page==PAGE_BASS then
    local ins="bass"
    local names={"n","k","mod1","mod2","note","duration","amp"}
    for i,name in ipairs(names) do
      name="acid_"..ins.."_"..name
      if i<=4 then
        local b=param_to_binary(name,8)
        for col,v in ipairs(b) do
          self.visual[row][col]=v*15
        end
      else
        for col=1,8 do
          self.visual[row][col]=params:get(name.."_"..col)
        end
      end
    end
  end
  self.visual[8][self.page]=15

  -- illuminate currently pressed button
  for _,v in ipairs(self.pressed_buttons) do
    self.visual[v.row][v.col]=15
  end

  return self.visual
end

function Grid_:grid_redraw()
  self.g:all(0)
  local gd=self:get_visual()
  local s=1
  local e=self.grid_width
  local adj=0
  for row=1,8 do
    for col=s,e do
      if gd[row][col]~=0 then
        self.g:led(col+adj,row,gd[row][col])
      end
    end
  end
  self.g:refresh()
end

return Grid_
