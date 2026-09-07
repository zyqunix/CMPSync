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

r = component.nc_fission_reactor

local x = r.getLengthX()
local y = r.getLengthY()
local z = r.getLengthZ()
local energy_stored = r.getEnergyStored()
local max_energy = r.getMaxEnergyStored()
local energy_change = r.getEnergyChange()

local process_time = r.getCurrentProcessTime()
local fuel_process_time = r.getFissionFuelTime()
local fuel_name = r.getFissionFuelName()

local cells = r.getNumberOfCells()

local heat_level = r.getHeatLevel()
local max_heat = r.getMaxHeatLevel()
local efficiency = r.getEfficiency()
local heat_mult = r.getHeatMultiplier()

local processing
if r.isProcessing() then
    processing = "REACTOR ACTIVE"
    local message = string.format(
    [[
    # %dx%dx%d FISSION REACTOR (%d Cells)
    ## %s
    %d RF/t || %d RF / %d RF || Running at %d 
    Processing %s - %.2f Finished - %d s Left
    %d\% H / %d H
    ]], x, y, z, cells, 
    processing,
    energy_change, energy_stored, max_energy, efficiency,
    fuel_name, (process_time * 100) / fuel_process_time, process_time / 20,
    heat_level, max_heat
    )
else
    processing = "REACTOR INACTIVE"
    local message = string.format(
    [[
    # %dx%dx%d FISSION REACTOR (%d Cells)
    ## %s
    ]], x, y, z, cells, processing)
end


term.clear()
print(message)

sendToDiscord(1, message)
