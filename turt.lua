arg = {...}
Version = 1.121
AutoUpdate = true
if #arg == 0 then
  print("Usage:") 
  print("turt <filename>")
  print("turt update")
  return exit
end
local function gitUpdate(ProgramName, Filename, ProgramVersion)
  if http then
    local getGit = http.get("https://raw.github.com/darkrising/darkprograms/darkprograms/programVersions")
    local getGit = getGit.readAll()
    NVersion = textutils.unserialize(getGit)
    if NVersion[ProgramName].Version > ProgramVersion then
      getGit = http.get(NVersion[ProgramName].GitURL)
      getGit = getGit.readAll()
      local file = fs.open(Filename, "w")
      file.write(getGit)
      file.close()
      return true
    end
  else
    return false
  end
end
local function split(str, pattern) -- Splits string by pattern, returns table
  local t = { }
  local fpat = "(.-)" .. pattern
  local last_end = 1
  local s, e, cap = str:find(fpat, 1)
  while s do
    if s ~= 1 or cap ~= "" then
      table.insert(t,cap)
    end
    last_end = e+1
    s, e, cap = str:find(fpat, last_end)
  end
  if last_end <= #str then
    cap = str:sub(last_end)
    table.insert(t, cap)
  end
  return t
end
local function stealthUpdate()
  if AutoUpdate == true then 
    if gitUpdate("turt", shell.getRunningProgram(), Version) == true then
      return true
    end
  end
  return false
end
regComs = {
  MF = turtle.forward,
  MB = turtle.back,
  MU = turtle.up,
  MD = turtle.down,
  
  TL = turtle.turnLeft,
  TR = turtle.turnRight,
  
  AF = turtle.attack,
  AU = turtle.attackUp,
  AD = turtle.attackDown,
  
  DF = turtle.dig,
  DU = turtle.digUp,
  DD = turtle.digDown,
  
  PF = turtle.place,
  PU = turtle.placeUp,
  PD = turtle.placeDown,
  
  SF = turtle.suck,
  SU = turtle.suckUp,
  SD = turtle.suckDown,
  
  FF = turtle.drop,
  FU = turtle.dropUp,
  FD = turtle.dropDown,
} 
speComs = {
  SL = {
    arg = 1,
    run = function()
      turtle.select(co[cou].args[1])
    end,
  },
  LOOP = {
    arg = 1,
    indent = "in",
    run = function()
      --print("Loop created: ".. co[cou].pos .. " L:".. co[cou].args[1] .. " R:".. cou)
      runBack[co[cou].pos] = {}
      runBack[co[cou].pos].returnTo = cou 
      runBack[co[cou].pos].loopsLeft = co[cou].args[1]
    end,
  },
  END = {
    indent = "out",
    run = function()
      if runBack[co[cou].pos].loopsLeft == "INF" then
        cou = runBack[co[cou].pos].returnTo
      elseif runBack[co[cou].pos].loopsLeft > 1 then
        runBack[co[cou].pos].loopsLeft = runBack[co[cou].pos].loopsLeft - 1
        cou = runBack[co[cou].pos].returnTo
      else
        runBack[co[cou].pos] = nil
      end
    end,
  },
}
runBack = {}
local function inTur(cString)
  cString = cString:gsub("%s+", " ") --remove all extra space
  cString = string.upper(cString) --convert all string to uppercase
  ex = split(cString, " ") --split string into the seperate commands
  co = {}
  pos = 0
  i = 1
  ri = 1
  repeat --Add commands and arguments to the command stack
    co[ri] = {}
    co[ri].name = ex[i]
    if speComs[ex[i]] and speComs[ex[i]].indent then -- Work out indents for functions that require them
      if speComs[ex[i]].indent == "in" then
        pos = pos + 1
        co[ri].pos = pos
      elseif speComs[ex[i]].indent == "out" then
        co[ri].pos = pos
        pos = pos - 1
      end
    end
    if speComs[ex[i]] and speComs[ex[i]].arg then
      co[ri].args = {}
      for j = 1, speComs[ex[i]].arg do
        if tonumber(ex[i + j]) then
          table.insert(co[ri].args, tonumber(ex[i + j]))
        else
          table.insert(co[ri].args, ex[i + j])
        end
      end
      i = i + speComs[ex[i]].arg
    end
    i = i + 1
    ri = ri + 1
  until i > #ex
  
  lFile = fs.open("log.txt", "w")
  for name, data in pairs(co) do
    add = ""
    if data.pos then add = add.."P:".. data.pos .. " " end
    if data.args then 
      add = add.."A"
      for j = 1, #data.args do
        add = add.."("..j.."):".. data.args[1] .." " 
      end
    end
    lFile.writeLine(data.name .." " .. add)
  end
  lFile.close()
  
  cou = 1
  repeat
    if co[cou] and regComs[co[cou].name] then
      regComs[co[cou].name]()
    elseif co[cou] and speComs[co[cou].name] then
      if speComs[co[cou].name].run then
        speComs[co[cou].name].run()
      end
    end
    cou = cou + 1
  until cou >= #ex
end
if arg[1] == "update" then
  print("Checking for updates...")
  if stealthUpdate() == true then
    print("Program updated.")
    return exit
  elseif stealthUpdate() == false then
    print("Program up-to-date.")
    return exit
  end
end
file = fs.open(arg[1], "r")
wFile = file.readAll()
file.close()
inTur(wFile)