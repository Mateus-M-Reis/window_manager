local window_manager = require'init'

local lang = "pt-br"

local intro = {}

local timer = 0

function intro.load(lang)
  print("\nLOADING INTRO")
  print("lang:", lang)
end

function intro.update(dt)
  timer = timer + dt

  if timer > 2 then
    window_manager.switch('menu', nil, nil, { something = "something" })
  end
end

function intro.draw(pass)
  pass:setColor(1, 1, 1, 1)
  pass:text("This is the INTRO scene", 0, 0, -10)
  pass:text("lang is " .. lang, 0, -1, -10)
end

return intro
