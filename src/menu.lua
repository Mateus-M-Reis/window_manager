local window_manager = require'init'

local M = {}

local timer = 0

local something

function M.load(data)
  print("\nLOADING MENU")
  print("something:\t", data.something)
  something = data.something
end

function M.update(dt)
  timer = timer + dt

  if timer > 2 then
    window_manager.switch('level', nil, nil, { option = { option_1 = "option_1" } })
  end
end

function M.draw(pass)
  pass:setColor(1, 1, 1, 1)
  pass:text("Now you are in the MENU", 0, 2, -10)
  pass:text("something is " .. something, 0, 1, -10)
end

return M
