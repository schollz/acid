-- local pattern_time = require("pattern")
local Grid_={}

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
  m.page=0

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

  m:init()

  return m
end

function Grid_:init()
  -- define functions for pressing keys
  self.press_fn={}
  self.press_fn[PAGE_MIXER]=function(row,col)
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
  self.press_fn[1]=function(row,col)
    local ins=INSTRUMENTS[self.page]
    if row<=2 then
      local names={"mod1","mod2"}
      local name="acid_"..ins.."_"..names[row]
      local b=param_to_binary(name,8)
      b[col]=1-b[col]
      param_set_from_binary(name,b)
    elseif row>=4 then
      local name="acid_chord_"..(row-3)
      params:set(name,col)
    end
  end
  for i=2,3 do
    self.press_fn[i]=function(row,col)
      local ins=INSTRUMENTS[self.page]
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
  end
  for i=4,8 do
    self.press_fn[i]=function(row,col)
      local ins=INSTRUMENTS[self.page]
      if row<=5 then
        local names={"n","k","w","mod1","mod2"}
        local name="acid_"..ins.."_"..names[row]
        local b=param_to_binary(name,8)
        b[col]=1-b[col]
        param_set_from_binary(name,b)
      elseif row<=6 then
        local names={"amp"}
        local name="acid_"..ins.."_"..names[row].."_"..col
        params:delta(name,1)
      end
    end
  end
end

function Grid_:grid_key(x,y,z)
  self:key_press(y,x,z==1)
  self:grid_redraw()
end

function Grid_:key_press(row,col,on)
  if on then
    table.insert(self.pressed_buttons,{row=row,col=col,time=clock.get_beats()*clock.get_beat_sec(),filled=false})
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
      if col==self.page then
        self.page=0
      else
        self.page=col
      end
    end
    do return end
  end

  if on then
    self.press_fn[self.page](row,col)
  end
end

function Grid_:get_visual()
  local ct=clock.get_beats()*clock.get_beat_sec()

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
  local ins=INSTRUMENTS[self.page]
  if self.page==0 then
    -- MIXER
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
  elseif self.page==1 then
    -- CHORDS
    local names={"mod1","mod2","","1","2","3","4"}
    for row,name in ipairs(names) do
      name="acid_"..ins.."_"..name
      if row<=2 then
        local b=param_to_binary(name,8)
        for col,v in ipairs(b) do
          self.visual[row][col]=v*15
        end
      elseif row>=4 then
        -- highlight each row
        if song.chord_progression.ix==row-3 then
          for col=1,8 do
            self.visual[row][col]=7
          end
        end
        local col=params:get(name)
        self.visual[row][col]=15
      end
    end
  elseif self.page<=3 then
    local names={"n","k","mod1","mod2","note","duration","amp"}
    for row,name in ipairs(names) do
      name="acid_"..ins.."_"..name
      if row<=4 then
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
  elseif self.page>=4 then
    local names={"n","k","w","mod1","mod2","amp"}
    for row,name in ipairs(names) do
      name="acid_"..ins.."_"..name
      if row<=4 then
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
  if self.page>0 then
    self.visual[8][self.page]=15
  end

  -- illuminate currently pressed button
  for i,v in ipairs(self.pressed_buttons) do
    if not v.filled and v.row<8 then
      -- illuminate the halo
      local dt=v.time-ct
      local spread=2*dt
      local row_min=util.clamp(util.round(v.row-spread),1,8)
      local row_max=util.clamp(util.round(v.row+spread),1,8)
      local col_min=util.clamp(util.round(v.col-spread),1,8)
      local col_max=util.clamp(util.round(v.col+spread),1,8)
      for row=row_min,row_max do
        for col=col_min,col_max do
          local dist=math.sqrt((row-v.row)^2+(col-v.col)^2)
          self.visual[row][col]=math.floor(15-dist)
        end
      end
      self.pressed_buttons[i].filled=(row_min==1 and col_min==1 and row_max==8 and col_max==8)
      if self.pressed_buttons[i].filled then
        -- TODO: run function to clear current button
        print("DO SOMETHING")
      end
    end
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
