-- local pattern_time = require("pattern")
local Grid_={}


function Grid_:new(args)
  local m=setmetatable({},{__index=Grid_})
  local args=args==nil and {} or args

  -- callback for visualization
  m.visual_fn=args.visual_fn

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
  m.playing={}
  m.grid_width=16
  for i=1,8 do
    m.visual[i]={}
    for j=1,m.grid_width do
      m.visual[i][j]=0
    end
  end


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

  return m
end

function Grid_:grid_key(x,y,z)
  self:key_press(y,x,z==1)
  self:grid_redraw()
end

function Grid_:key_press(row,col,on)
  if on then
    table.insert(self.pressed_buttons,{row=row,col=col,time=clock.get_beats()*clock.get_beat_sec()}
  else
    local did_remove=false
    for i,v in ipairs(self.pressed_buttons) do
        if did_remove==false and v.row==row and v.col==col then 
            table.remove(self.pressed_buttons,i)
            did_remove=true
        end
    end
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

  if self.visual_fn~=nil then 
    self.visual_fn(self.visual)
  end

  -- illuminate currently pressed button
  for _, v in ipairs(self.pressed_buttons) do
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
