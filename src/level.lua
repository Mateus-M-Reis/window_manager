local window_manager = require'init'

local M = {}

local timer = 0

local option

function M.load(data)
  print("\nLOADING LEVEL")
  print("options:\t")
  for k, v in pairs(data.option) do
    print(k, v)
  end

  option = data.option
end

function M.update(dt)
  timer = timer + dt

  if timer > 3 then lovr.event.quit() end
end

function M.draw(pass)
  pass:setColor(1, 1, 1, 1)
  pass:text("Now you are in the LEVEL", 0, 3, -10)
  pass:text("option_1 is " .. option.option_1, 0, 2, -10)
  pass:text("This is it. Hope you can make good use of this.", 0, -5, -15)
end

return M
