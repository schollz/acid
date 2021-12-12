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
      self:param_set_from_binary(name,b)
    end
  end
end

function Grid_:param_to_binary(name,bits)
  local t={}
  for i=1,bits do
    table.insert(t,1)
  end
  local val_max=binary.decode(t)
  local num_binary=util.linlin(self.params[name].min,self.params[name].max,0,val_max,params:get(name))
  local b=binary.encode(num_binary)
  while #b<bits do
    table.insert(b,0)
  end
  return b
end

function Grid_:param_set_from_binary(name,t)
  local tmax={}
  for i,_ in ipairs(t) do
    table.insert(tmax,1)
  end
  local val_max=binary.decde(tmax)
  local num_binary=binary.decode(t)
  local val=util.linlin(0,tmax,self.params[name].min,self.params[name].max,num_binary)
  params:set(name,val)
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
      local b=self:param_to_binary(name,7)
      for i,v in ipairs(b) do
        if v>0 then
          local row=8-i
          self.visual[row][col]=15
        end
      end
    end
  elseif self.page==PAGE_BASS then

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
