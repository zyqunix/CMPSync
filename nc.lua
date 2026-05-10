local filesystem = require("filesystem")

function sendToDiscord(serverIndex, message)
  local pipeFile = "/tmp/discord_pipe"
  local file = io.open(pipeFile, "w")
  if file then
    file:write(serverIndex .. "\n" .. message)
    file:close()
  end
end

r = component.nc_fusion_reactor

local toroid_size = r.getToroidSize()
local first_fuel = string.upper(r.getFirstFusionFuel():match("{%s*([^,]+)"))
local second_fuel = string.upper(r.getSecondFusionFuel():match("{%s*([^,]+)"))
local energy_stored = r.getEnergyStored()
local max_energy = r.getMaxEnergyStored()
local energy_gen = r.getReactorProcessPower()
local efficiency = r.getEfficiency()
local temperature = r.getTemperature()
local cooling_Rate = r.getCoolingRate()

local processing
if r.isProcessing() do
    processing = "REACTOR ACTIVE"
else:
    processing = "REACTOR INACTIVE"
end

local message = string.format(
[[
\*\* SIZE %f FUSION REACTOR \*\*
**%s**
-> %s-%s
-> %d RF/%d RF || %d RF/t
-> %.2f%% Efficiency at %.2f Kelvin (%.2f Cooling Rate)
]],
toroid_size,
processing,
first_fuel, second_fuel,
energy_stored, max_energy, energy_gen,
efficiency, temperature, cooling_Rate)

sendToDiscord(1, message)