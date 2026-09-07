local component = require("component")
local filesystem = require("filesystem")
local term = require("term")

function sendToDiscord(serverIndex, message)
  local pipeFile = "/tmp/discord_pipe"
  local file = io.open(pipeFile, "w")
  if file then
    file:write(serverIndex .. "\n" .. message)
    file:flush()
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
local cooling_Rate = r.getReactorCoolingRate()

local processing
if r.isProcessing() then
    processing = "REACTOR ACTIVE"
else
    processing = "REACTOR INACTIVE"
end

local message = string.format(
[[
\*\* SIZE %.0f FUSION REACTOR \*\*
**%s**
-> %s-%s
-> %.2f RF/%.2f RF || %.2f RF/t
-> %.2f%% Efficiency at %.2f Megakelvin (%.2f Cooling Rate)
]], toroid_size, processing, first_fuel, second_fuel, energy_stored, max_energy, energy_gen, efficiency, temperature / 1000000, cooling_Rate)

term.clear()
print(message)

sendToDiscord(1, message)
