local shell = require("shell")
local c = require("component")

local fission = c.nc_fission_reactor
local fusion = c.nc_fusion_reactor

while true do
  if fission then shell.execute("./fission_reactor.lua") end
  if fusion then shell.execute("./fusion_reactor.lua") end
  if fusion or fission then shell.execute("./discord.lua") end
  
  os.sleep(300)
end
