local internet = require("internet")
local fs = require("filesystem")
local shell = require("shell")

local files = {
  "discord.lua",
  "fission_reactor.lua",
  "fusion_reactor.lua",
  "monitor.lua",
  "servers.lua"
}

local base_url = "https://raw.githubusercontent.com/zyqunix/CMPSync/refs/heads/master/"

for _, file in ipairs(files) do
  print("downloading " .. file)
  local response = internet.request(base_url .. file)
  local content = ""
  for chunk in response do
    content = content .. chunk
  end
  local handle = io.open(file, "w")
  handle:write(content)
  handle:close()
  print("downloaded " .. file)
end

print("all downloads successful")
