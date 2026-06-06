-- window_manager.lua
-- WindowManager.lua
-- A scene/screen manager for LÖVR

-- window_manager.lua
local M = {
  scenes = {},
  current = nil,
  previous = nil,
  transition = nil,
  default_transition = 'fade',
  transition_duration = 0.5,
  debug = false
}

M.Transitions = {
  NONE = 'none',
  FADE = 'fade',
  SLIDE_LEFT = 'slide_left',
  SLIDE_RIGHT = 'slide_right',
  SLIDE_UP = 'slide_up',
  SLIDE_DOWN = 'slide_down'
}

local transitionFunctions = {
  fade = function(progress, direction)
    local alpha = direction == 'in' and progress or (1 - progress)
    return {alpha = alpha}
  end,
  slide_left = function(progress, direction)
    local offset = direction == 'in' and (1 - progress) * 2 or progress * -2
    return {x = offset}
  end,
  slide_right = function(progress, direction)
    local offset = direction == 'in' and (progress - 1) * 2 or progress * 2
    return {x = offset}
  end,
  slide_up = function(progress, direction)
    local offset = direction == 'in' and (1 - progress) * 2 or progress * -2
    return {y = offset}
  end,
  slide_down = function(progress, direction)
    local offset = direction == 'in' and (progress - 1) * 2 or progress * 2
    return {y = offset}
  end
}

-- Register a scene (just stores the scene module)
function M.register(name, scene)
  M.scenes[name] = scene
end

-- Switch to a scene (replaces current)
function M.switch(name, transition, duration, data)
  local scene = M.scenes[name]
  if not scene then
    error('Scene "' .. name .. '" not registered')
  end

  local previous = M.current
  local transitionType = transition or M.default_transition
  local transDuration = duration or M.transition_duration

  -- Exit previous scene if it exists
  if previous and previous.exit then
    previous.exit()
  end

  -- Set up transition
  if transitionType ~= M.Transitions.NONE then
    M.transition = {
      type = transitionType,
      duration = transDuration,
      elapsed = 0,
      direction = 'in',
      from = previous,
      to = scene
    }
  end

  M.previous = previous
  M.current = scene

  -- Load new scene if it has load function
  if scene.load then
    scene.load(data)
  end
end

-- Update current scene
function M.update(dt)
  -- Update transition
  if M.transition then
    M.transition.elapsed = M.transition.elapsed + dt
    if M.transition.elapsed >= M.transition.duration then
      M.transition = nil
    end
  end

  -- Update current scene
  if M.current and M.current.update then
    M.current.update(dt)
  end
end

-- Draw with transitions
function M.draw(pass)
  if not M.current then return end

  if M.transition then
    local t = M.transition
    local progress = math.min(t.elapsed / t.duration, 1.0)
    local transFunc = transitionFunctions[t.type]

    if transFunc then
      local params = transFunc(progress, t.direction)

      pass:push()
      if params.x then pass:translate(params.x, 0, 0) end
      if params.y then pass:translate(0, params.y, 0) end
      if params.alpha then pass:setColor(1, 1, 1, params.alpha) end

      if M.current.draw then
        M.current.draw(pass)
      end

      pass:pop()
    end
  else
    if M.current.draw then
      M.current.draw(pass)
    end
  end

  -- Debug info
  if M.debug and M.current then
    pass:text('Scene: ' .. (M.current.name or 'unnamed'), 0, 1.5, -3, 0.1)
  end
end

-- Forward input events
function M.keypressed(key, scancode, isRepeat)
  if M.current and M.current.keypressed then
    M.current.keypressed(key, scancode, isRepeat)
  end
end

function M.keyreleased(key, scancode)
  if M.current and M.current.keyreleased then
    M.current.keyreleased(key, scancode)
  end
end

function M.setDebug(enabled)
  M.debug = enabled
end

return M
