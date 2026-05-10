local shell = require("shell")

while true do
  shell.execute("/home/nc.lua")
  shell.execute("/home/discord.lua")
  
  os.sleep(300)
end