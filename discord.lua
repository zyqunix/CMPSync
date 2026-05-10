--dependencies

local headers = {
  ["content-type"] = "application/json",
  ["user-agent"] = "mybot (https://www.example.com, 1.0)"
}
local internet = require("internet")
local component = require("component")
local term = require("term")
local filesystem = require("filesystem")
local event = require("event")

local args = {...}
local cmdargs = {
  user = nil,
  password = nil,
  server = nil,
  message = nil
}

local i = 1
while i <= #args do
  if args[i] == "-u" or args[i] == "--user" then
    cmdargs.user = args[i + 1]
    i = i + 2
  elseif args[i] == "-p" or args[i] == "--password" then
    cmdargs.password = args[i + 1]
    i = i + 2
  elseif args[i] == "-server" or args[i] == "-s" then
    cmdargs.server = tonumber(args[i + 1])
    i = i + 2
  elseif args[i] == "-m" or args[i] == "--message" then
    cmdargs.message = args[i + 1]
    i = i + 2
  else
    i = i + 1
  end
end

local noninteractive = cmdargs.user and cmdargs.password and cmdargs.server and cmdargs.message

local serversfile = ("/home/servers.lua")
if not filesystem.exists(serversfile) then
  local serversfile = io.open(serversfile, "w")
  serversfile:write(string.format("return {\n}"))
  serversfile:close()
end

local shortcutsfile = ("/home/shortcuts.lua")
if not filesystem.exists(shortcutsfile) then
  local shortcutsfile = io.open(shortcutsfile, "w")
  shortcutsfile:write(string.format("return {\n}"))
  shortcutsfile:close()
end

--dependencies

--main code

local json = { _version = "0.1.2" }
local encode
local escape_char_map = {
  [ "\\" ] = "\\",
  [ "\"" ] = "\"",
  [ "\b" ] = "b",
  [ "\f" ] = "f",
  [ "\n" ] = "n",
  [ "\r" ] = "r",
  [ "\t" ] = "t",
}
local escape_char_map_inv = { [ "/" ] = "/" }
for k, v in pairs(escape_char_map) do
  escape_char_map_inv[v] = k
end
local function escape_char(c)
  return "\\" .. (escape_char_map[c] or string.format("u%04x", c:byte()))
end
local function encode_nil(val)
  return "null"
end
local function encode_table(val, stack)
  local res = {}
  stack = stack or {}
  if stack[val] then error("circular reference") end
  stack[val] = true
  if rawget(val, 1) ~= nil or next(val) == nil then
    local n = 0
    for k in pairs(val) do
      if type(k) ~= "number" then
        error("invalid table: mixed or invalid key types")
      end
      n = n + 1
    end
    if n ~= #val then
      error("invalid table: sparse array")
    end
    for i, v in ipairs(val) do
      table.insert(res, encode(v, stack))
    end
    stack[val] = nil
    return "[" .. table.concat(res, ",") .. "]"
  else
    for k, v in pairs(val) do
      if type(k) ~= "string" then
        error("invalid table: mixed or invalid key types")
      end
      table.insert(res, encode(k, stack) .. ":" .. encode(v, stack))
    end
    stack[val] = nil
    return "{" .. table.concat(res, ",") .. "}"
  end
end
local function encode_string(val)
  return '"' .. val:gsub('[%z\1-\31\\"]', escape_char) .. '"'
end
local function encode_number(val)
  if val ~= val or (val <= -math.huge) or (val >= math.huge) then
    error("unexpected number value '" .. tostring(val) .. "'")
  end
  return string.format("%.14g", val)
end
local type_func_map = {
  [ "nil"     ] = encode_nil,
  [ "table"   ] = encode_table,
  [ "string"  ] = encode_string,
  [ "number"  ] = encode_number,
  [ "boolean" ] = tostring,
}
encode = function(val, stack)
  local t = type(val)
  local f = type_func_map[t]
  if f then
    return f(val, stack)
  end
  error("unexpected type '" .. t .. "'")
end
function json.encode(val)
  return ( encode(val) )
end

local gpu = component.gpu

if not noninteractive then
  local bootscreen = {
  "   _____   __  __   _____  ",
  "  / ____| |  \\/  | |  __ \\ ",
  " | |      | \\  / | | |__) |",
  " | |      | |\\/| | |  ___/ ",
  " | |____  | |  | | | |     ",
  "  \\_____| |_|  |_| |_|     "
  }

  local screenwidth, screenheight = gpu.getResolution()
  local centerx = math.floor(screenwidth / 2)
  local centery = math.floor(screenheight / 2)

  term.clear()

  for i, line in ipairs(bootscreen) do
    local linex = centerx - math.floor(#line / 2)
    gpu.set(linex, centery - math.ceil(#bootscreen / 2) + i - 1, line)
  end

  local slidedelay = 1
  local slidedistance = #bootscreen + 1
  os.sleep(slidedelay)
  for i = 0, slidedistance do
    gpu.copy(1, i + 1, screenwidth, screenheight - i, 0, -i)
    os.sleep(0.05)
  end

  term.clear()
end

local loginusr = cmdargs.user
local loginpwd = cmdargs.password

if not loginusr then
  io.write("username:\n")
  loginusr = io.read()
end

local function checkpassword(attempt)
  if component.isAvailable("data") then
    local file = io.open("/home/password.lua", "r")
    if not file then return false end
    for line in file:lines() do
      local salted,salt = line:match("^([^;]+);(.+)$")
      if salted and salt then
        salted = component.data.decode64(salted)
        salt = component.data.decode64(salt)
        if(salted == component.data.sha256(attempt..salt)) then
          file:close()
          return true
        end
      end
    end
    file:close()
    return false
  else
    local file = io.open("/home/password.lua", "r")
    if not file then return false end
    local password = file:read("*a")
    file:close()
    return attempt == password
  end
end

if filesystem.exists("/home/password.lua") then
  if not loginpwd then
    io.write("password:\n")
    loginpwd = io.read()
  end
else
  if component.isAvailable("data") then
    if not loginpwd then
      io.write("enter the password you want to be set:\n")
      loginpwd = io.read()
    end
    local file = io.open("/home/password.lua","w")
    local salt = component.data.random(16)
    local hashed = component.data.encode64(component.data.sha256(loginpwd..salt))
    file:write(string.format("%s;%s\n",hashed,component.data.encode64(salt)))
    file:close()
    if not cmdargs.password then
      term.clear()
      io.write("password:\n")
      loginpwd = io.read()
    end
  else
    if not loginpwd then
      io.write("enter the password you want to be set:\n")
      loginpwd = io.read()
    end
    local file = io.open("/home/password.lua","w")
    file:write(loginpwd)
    file:close()
    if not cmdargs.password then
      term.clear()
      io.write("password:\n")
      loginpwd = io.read()
    end
  end
end

if checkpassword(loginpwd) == true then
  if not noninteractive then
    term.clear()
  end

  -- main code

  local options = dofile("/home/servers.lua")

  if next(options) == nil then
    local function saveoptions()
      local file = io.open("/home/servers.lua", "w")
      file:write("return {\n")
      for i, option in ipairs(options) do
        file:write(string.format("  {name = %q, value = %q},\n", option.name, option.value))
      end
      file:write("}\n")
      file:close()
    end

    local function addoption()
      print("enter a name for the new server:")
      io.write()
      local name = io.read()
      print("enter a webhook link for the new server:")
      io.write()
      local value = io.read()
      table.insert(options, {name = name, value = value})
      saveoptions()
      print("option added.")
    end

    local function removeoption()
      print("enter the number of the server you want to remove:")
      for i, option in ipairs(options) do
        print(i .. ". " .. option.name)
      end
      io.write()
      local choice = tonumber(io.read())
      if choice and options[choice] then
        table.remove(options, choice)
        saveoptions()
        print("server removed.")
      else
        print("invalid choice.")
      end
    end

    local function listoptions()
      print("existing options:")
      for i, option in ipairs(options) do
        print(i .. ". " .. option.name)
      end
    end

    while true do
      print("\n")
      print("the server list is empty, add a new server")
      print("1. add a server")
      print("2. remove a server")
      print("3. list existing servers")
      print("4. exit")
      io.write()
      local choice = tonumber(io.read())
      if choice == 1 then
        term.clear()
        addoption()
      elseif choice == 2 then
        term.clear()
        removeoption()
      elseif choice == 3 then
        term.clear()
        listoptions()
      elseif choice == 4 then
        term.clear()
        break
      else
        print("invalid choice.")
      end
    end
  end

  local options = dofile("/home/servers.lua")

  local choice = cmdargs.server

  if not choice then
    for i, option in ipairs(options) do
      print(i .. ". " .. option.name)
    end
    io.write()
    choice = tonumber(io.read())
  end

  local url = options[choice].value

  if not noninteractive then
    term.clear()
  end

  if cmdargs.message then
    local shortcuts = dofile("/home/shortcuts.lua")
    local dissected = {}

    for segment in cmdargs.message:gmatch("%S+") do
      table.insert(dissected, segment)
    end

    for i, segment in ipairs(dissected) do
      for j, shortcut in ipairs(shortcuts) do
        if segment == shortcut.name then
          dissected[i] = shortcut.value
          break
        end
      end
    end
    local message = table.concat(dissected, " ")

    local contents = {
      content = message,
      username = "cmp" .. " - " .. loginusr,
      avatar_url = "https://cdn.discordapp.com/attachments/1082257996429668395/1082722647030378607/image.png?size=4096"
    }

    local request = internet.request(url, json.encode(contents), headers, "post")
    local response = ""
    for chunk in request do
      response = response .. chunk
    end

    os.sleep(1)

    term.clear()
    print("message sent. exiting.")
    os.sleep(1)
    term.clear()
    return
  end

  local contents = {
  embeds = {
    {
      title = "login",
      description = loginusr .. " just logged in!",
      color = 5763719
    }
  },
  username = "cmp",
  avatar_url = "https://cdn.discordapp.com/attachments/1082257996429668395/1082722647030378607/image.png?size=4096"
  }

  internet.request(url, json.encode(contents), headers, "post")

  while true do

    local message = io.read()

      if message == "/logout" then
        break

      elseif message == "/settings" then
        print("select a setting to modify")
        print("1. servers")
        print("2. shortcuts")
        local setting_choice = io.read()

        if setting_choice == "1" then
          local options = dofile("/home/servers.lua")

          local function saveoptions()
            local file = io.open("/home/servers.lua", "w")
            file:write("return {\n")
            for i, option in ipairs(options) do
              file:write(string.format("  {name = %q, value = %q},\n", option.name, option.value))
            end
            file:write("}\n")
            file:close()
          end

          local function addoption()
            print("enter a name for the new server:")
            io.write()
            local name = io.read()
            print("enter a webhook link for the new server:")
            io.write()
            local value = io.read()
            table.insert(options, {name = name, value = value})
            saveoptions()
            print("option added.")
          end

          local function removeoption()
            print("enter the number of the server you want to remove:")
            for i, option in ipairs(options) do
              print(i .. ". " .. option.name)
            end
            io.write()
            local choice = tonumber(io.read())
            if choice and options[choice] then
              table.remove(options, choice)
              saveoptions()
              print("server removed.")
            else
              print("invalid choice.")
            end
          end

          local function listoptions()
            print("existing options:")
            for i, option in ipairs(options) do
              print(i .. ". " .. option.name)
            end
          end

          while true do
            print("\n")
            print("select a subcommand:")
            print("1. add a server")
            print("2. remove a server")
            print("3. list existing servers")
            print("4. exit")
            io.write()
            local choice = tonumber(io.read())
            if choice == 1 then
              term.clear()
              addoption()
            elseif choice == 2 then
              term.clear()
              removeoption()
            elseif choice == 3 then
              term.clear()
              listoptions()
            elseif choice == 4 then
              term.clear()
              break
            else
              print("invalid choice.")
            end
          end

        elseif setting_choice == "2" then
          local options = dofile("/home/shortcuts.lua")

          local function saveoptions()
            local file = io.open("/home/shortcuts.lua", "w")
            file:write("return {\n")
            for i, option in ipairs(options) do
              file:write(string.format("  {name = %q, value = %q},\n", option.name, option.value))
            end
            file:write("}\n")
            file:close()
          end

          local function addoption()
            print("enter the name of the shortcut:")
            io.write()
            local name = io.read()
            print("enter what you want it to be replaced with:")
            io.write()
            local value = io.read()
            table.insert(options, {name = name, value = value})
            saveoptions()
            print("shortcut added.")
          end

          local function removeoption()
            print("enter the number of the shortcut you want to remove:")
            for i, option in ipairs(options) do
              print(i .. ". " .. option.name .. " => " .. option.value)
            end
            io.write()
            local choice = tonumber(io.read())
            if choice and options[choice] then
              table.remove(options, choice)
              saveoptions()
              print("shortcut removed.")
            else
              print("invalid choice.")
            end
          end

          local function listoptions()
            print("existing shortcuts:")
            for i, option in ipairs(options) do
              print(i .. ". " .. option.name)
            end
          end

          while true do
            print("\n")
            print("select a subcommand:")
            print("1. add a shortcut")
            print("2. remove a shortcut")
            print("3. list existing shortcuts")
            print("4. exit")
            io.write()
            local choice = tonumber(io.read())
            if choice == 1 then
              term.clear()
              addoption()
            elseif choice == 2 then
              term.clear()
              removeoption()
            elseif choice == 3 then
              term.clear()
              listoptions()
            elseif choice == 4 then
              term.clear()
              break
            else
              print("invalid choice.")
            end
          end
        end
        io.write()
      end

    local shortcuts = dofile("/home/shortcuts.lua")
    local dissected = {}

    for segment in message:gmatch("%S+") do
      table.insert(dissected, segment)
    end

    for i, segment in ipairs(dissected) do
      for j, shortcut in ipairs(shortcuts) do
        if segment == shortcut.name then
          dissected[i] = shortcut.value
          break
        end
      end
    end
    local message = table.concat(dissected, " ")

    local contents = {

      content = message,
      username = "cmp" .. " - " .. loginusr,
      avatar_url = "https://cdn.discordapp.com/attachments/1082257996429668395/1082722647030378607/image.png?size=4096"
  }

    internet.request(url, json.encode(contents), headers, "post")

  end

  local contents = {
  embeds = {
    {
      title = "logout",
      description = loginusr .. " logged out.",
      color = 15548997
    }
  },
  username = "cmp",
  avatar_url = "https://cdn.discordapp.com/attachments/1082257996429668395/1082722647030378607/image.png?size=4096"
  }

  internet.request(url, json.encode(contents), headers, "post")

  if not noninteractive then
    term.clear()
    print("logging out")
    os.sleep(1)
    term.clear()
  end
else
  if not noninteractive then
    term.clear()
    print("exiting")
    os.sleep(1)
    term.clear()
  end
end

--main code