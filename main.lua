local window_manager = require'init'

local lang = "pt-br"

function lovr.load()
  window_manager.register('intro', require 'src.intro')
  window_manager.register('menu', require 'src.menu')
  window_manager.register('level', require 'src.level')
  window_manager.switch('intro', { data = lang })
end

function lovr.update(dt)
  window_manager.update(dt)
end

function lovr.draw(pass)
  window_manager.draw(pass)
end

function lovr.keypressed(key, scancode, isrepeat)
  window_manager.keypressed(key, scancode, isrepeat)
end

function lovr.keyreleased(key, scancode)
  window_manager.keyreleased(key, scancode)
end

function lovr.mousepressed(...)
  window_manager.mousepressed(...)
end

function lovr.mousereleased(...)
  window_manager.mousereleased(...)
end

function lovr.mousemoved(...)
  window_manager.mousemoved(...)
end

function lovr.wheelmoved(...)
  window_manager.wheelmoved(...)
end

function lovr.textinput(...)
  window_manager.textinput(...)
end

function lovr.focus(...)
  window_manager.focus(...)
end

function lovr.visible(...)
  window_manager.visible(...)
end

function lovr.resize(...)
  window_manager.resize(...)
end
