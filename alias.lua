-- create a `pm` alias that delegates to `/vx/pm/init.lua` when available
if fs.exists("/vx/pm/init.lua") then
  pcall(function() shell.setAlias("pm", "/vx/pm/init.lua") end)
else
  print("No pm script found at /vx/pm/init.lua")
end