local shell = require("shell")

while true do
  shell.execute("./nc.lua")
  shell.execute("./discord.lua")
  
  os.sleep(300)
end
