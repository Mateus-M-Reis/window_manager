-- init.lua
-- A scene/screen manager for LÖVR

---@class Scene
---@field name? string The optional name of the scene used for debugging.
---@field load? fun(data: any) Called when the scene is switched to. Receives custom data.
---@field update? fun(dt: number) Called every frame to update scene logic.
---@field draw? fun(pass: lovr.Pass) Called every frame to render the scene.
---@field exit? fun() Called right before leaving the scene.
---@field keypressed? fun(key: string, scancode: number, isRepeat: boolean) Forwarded keypress event.
---@field keyreleased? fun(key: string, scancode: number) Forwarded keyrelease event.

---@class TransitionState
---@field type string The type of transition (e.g., 'fade', 'slide_left').
---@field duration number Total duration of the transition in seconds.
---@field elapsed number Time elapsed since the transition started.
---@field direction 'in'|'out' The direction of the transition animation.
---@field from? Scene The scene being transitioned away from.
---@field to Scene The scene being transitioned into.

---@class WindowManager
---@field scenes table<string, Scene> Registered scenes dictionary.
---@field current? Scene The currently active scene.
---@field previous? Scene The previously active scene.
---@field transition? TransitionState The active transition configuration, if any.
---@field default_transition string Fallback transition type.
---@field transition_duration number Fallback transition duration.
---@field debug boolean Toggle for displaying on-screen debug info.
local M = {
  scenes = {},
  current = nil,
  previous = nil,
  transition = nil,
  default_transition = 'fade',
  transition_duration = 0.5,
  debug = false
}

---@enum TransitionType
M.Transitions = {
  NONE = 'none',
  FADE = 'fade',
  SLIDE_LEFT = 'slide_left',
  SLIDE_RIGHT = 'slide_right',
  SLIDE_UP = 'slide_up',
  SLIDE_DOWN = 'slide_down'
}

---@type table<string, fun(progress: number, direction: 'in'|'out'): table<string, number>>
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

---Registers a scene module with a unique lookup name.
---@param name string The unique identifier for this scene.
---@param scene Scene The scene module table containing lifecycle hooks.
function M.register(name, scene)
  M.scenes[name] = scene
end

---Switches active scenes and triggers an optional transition animation.
---@param name string The name of the registered target scene.
---@param transition? TransitionType The transition style to use. Defaults to `M.default_transition`.
---@param duration? number The transition duration in seconds. Defaults to `M.transition_duration`.
---@param data? any Arbitrary data package passed down directly to the target scene's `load` hook.
function M.switch(name, transition, duration, data)
  local scene = M.scenes[name]
  if not scene then
    error('Scene "' .. name .. '" not registered')
  end

  local previous = M.current
  local transitionType = transition or M.default_transition
  local transDuration = duration or M.transition_duration

  if previous and previous.exit then
    previous.exit()
  end

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

  if scene.load then
    scene.load(data)
  end
end

---Updates timers for transitions and ticks the active scene logic.
---@param dt number Delta time in seconds since the last frame.
function M.update(dt)
  if M.transition then
    M.transition.elapsed = M.transition.elapsed + dt
    if M.transition.elapsed >= M.transition.duration then
      M.transition = nil
    end
  end

  if M.current and M.current.update then
    M.current.update(dt)
  end
end

---Renders the current scene, wrapping it in transition transforms if active.
---@param pass lovr.Pass The LÖVR render pass object.
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

  if M.debug and M.current then
    pass:text('Scene: ' .. (M.current.name or 'unnamed'), 0, 1.5, -3, 0.1)
  end
end

---Forwards engine keypress callbacks to the active scene.
---@param key string The name of the key pressed.
---@param scancode number The platform-independent scancode.
---@param isRepeat boolean True if the key press is a repeat event.
function M.keypressed(key, scancode, isRepeat)
  if M.current and M.current.keypressed then
    M.current.keypressed(key, scancode, isRepeat)
  end
end

---Forwards engine keyrelease callbacks to the active scene.
---@param key string The name of the key released.
---@param scancode number The platform-independent scancode.
function M.keyreleased(key)
  if M.current and M.current.keyreleased then
    M.current.keyreleased(key)
  end
end

---Toggles HUD text tracking the active scene module name.
---@param enabled boolean
function M.setDebug(enabled)
  M.debug = enabled
end

return M
