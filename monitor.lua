local shell = require("shell")
local c = require("component")

local has_fission = false
local has_fusion = false

for address, component_type in c.list() do
  if component_type == "nc_fission_reactor" then
    has_fission = true
  elseif component_type == "nc_fusion_reactor" then
    has_fusion = true
  end
end

while true do
  if has_fission then shell.execute("./fission_reactor.lua") end
  if has_fusion then shell.execute("./fusion_reactor.lua") end
  if fusion or fission then shell.execute("./discord.lua") end
  os.sleep(300)
end
