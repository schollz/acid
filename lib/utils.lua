function table.shuffle(tbl)
  for i=#tbl,2,-1 do
    local j=math.random(i)
    tbl[i],tbl[j]=tbl[j],tbl[i]
  end
end

function table.reverse(tbl)
  for i=1,math.floor(#tbl/2) do
    local tmp=tbl[i]
    tbl[i]=tbl[#tbl-i+1]
    tbl[#tbl-i+1]=tmp
  end
end

function table.print(tbl)
  for i,v in ipairs(tbl) do
    print(i,v)
  end
end

binary={}

-- binary.encode encodes with smallest number first
function binary.encode(num)
  local r={}
  while num>1 do
    table.insert(r,num%2)
    num=math.floor(num/2)
  end
  table.insert(r,1)
  -- table.reverse(r)
  -- for i,v in ipairs(r) do
  --   print(i,v)
  -- end
  return r
end

function binary.decode(t)
  local num=0

  for i,v in ipairs(t) do
    if v>0 then
      num=num+2^(i-1)
    end
  end
  return math.floor(num)
end

for _,v in ipairs({12,99,1,32,127}) do
  print(v)
  local t=binary.encode(v)
  table.print(t)
  print("num=",binary.decode(t))
end
