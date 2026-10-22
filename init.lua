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
---@field mousepressed? fun(x: number, y: number, button: number) Forwarded mouse press event.
---@field mousereleased? fun(x: number, y: number, button: number) Forwarded mouse release event.
---@field mousemoved? fun(x: number, y: number, dx: number, dy: number) Forwarded mouse movement event.
---@field wheelmoved? fun(dx: number, dy: number) Forwarded mouse wheel event.
---@field textinput? fun(text: string, code: number) Forwarded text input event.
---@field focus? fun(focused: boolean, display: string) Forwarded focus event.
---@field visible? fun(visible: boolean, display: string) Forwarded visibility event.
---@field resize? fun(width: number, height: number) Forwarded window resize event.

---@alias SceneFactory fun(): Scene

---@class SwitchOptions
---@field transition? TransitionType The transition style to use.
---@field duration? number The transition duration in seconds.
---@field data? any Arbitrary data passed to the target scene's `load` hook.

---@class TransitionState
---@field type TransitionType The type of transition (e.g., 'fade', 'slide_left').
---@field duration number Total duration of the transition in seconds.
---@field elapsed number Time elapsed since the transition started.
---@field direction 'in'|'out' The direction of the transition animation.
---@field from? Scene The scene being transitioned away from.
---@field to Scene The scene being transitioned into.

---@class WindowManager
---@field scenes table<string, Scene|SceneFactory> Registered scenes or factories.
---@field current? Scene The currently active scene.
---@field previous? Scene The previously active scene.
---@field transition? TransitionState The active transition configuration, if any.
---@field default_transition TransitionType Fallback transition type.
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

---Registers a scene or a factory that creates one.
---Factories are called on every switch, so each visit gets a fresh scene table.
---@param name string The unique identifier for this scene.
---@param scene Scene|SceneFactory A scene table or a function returning one.
function M.register(name, scene)
  local sceneType = type(scene)
  if sceneType ~= 'table' and sceneType ~= 'function' then
    error(('Scene "%s" must be a table or a function returning a table'):format(name))
  end
  M.scenes[name] = scene
end

---Switches active scenes and triggers an optional transition animation.
---Accepts positional arguments or a single options table as the second argument.
---Unknown transition names are reported and fall back to `M.Transitions.NONE`.
---@param name string The name of the registered target scene.
---@param transition? TransitionType|SwitchOptions The transition style, or an options table.
---@param duration? number The transition duration in seconds. Defaults to `M.transition_duration`.
---@param data? any Arbitrary data package passed directly to the target scene's `load` hook.
function M.switch(name, transition, duration, data)
  if type(transition) == 'table' then
    local options = transition
    transition = options.transition
    duration = options.duration
    data = options.data
  end

  local registered = M.scenes[name]
  if not registered then
    error('Scene "' .. name .. '" not registered')
  end

  local scene = registered
  if type(registered) == 'function' then
    scene = registered()
    if type(scene) ~= 'table' then
      error(('Scene factory "%s" must return a table'):format(name))
    end
  end

  local previous = M.current
  local transitionType = transition or M.default_transition
  local transDuration = duration or M.transition_duration

  if transitionType ~= M.Transitions.NONE and not transitionFunctions[transitionType] then
    print(('window_manager: unknown transition "%s", falling back to "none"'):format(tostring(transitionType)))
    transitionType = M.Transitions.NONE
  end

  if previous and previous.exit then
    previous.exit()
  end

  -- Cancel any transition that was still running, even when the new switch
  -- uses no transition at all.
  M.transition = nil

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

  local transition = M.transition
  local params
  if transition then
    local progress = transition.duration > 0 and math.min(transition.elapsed / transition.duration, 1.0) or 1.0
    local transFunc = transitionFunctions[transition.type]
    params = transFunc and transFunc(progress, transition.direction) or {}
  end

  if params then
    pass:push()
    if params.x then pass:translate(params.x, 0, 0) end
    if params.y then pass:translate(0, params.y, 0) end
    if params.alpha then pass:setColor(1, 1, 1, params.alpha) end
  end

  if M.current.draw then
    M.current.draw(pass)
  end

  if params then
    pass:pop()
  end

  if M.debug and M.current then
    pass:text('Scene: ' .. (M.current.name or 'unnamed'), 0, 1.5, -3, 0.1)
  end
end

---Calls an optional hook on the active scene.
---Use this for engine events that do not have a dedicated wrapper.
---@param event string The scene hook name (for example, 'mousemoved').
---@vararg any Arguments forwarded to the hook.
---@return any result The hook's return value, if any.
function M.dispatch(event, ...)
  local scene = M.current
  local handler = scene and scene[event]
  if type(handler) == 'function' then
    return handler(...)
  end
end

---Forwards engine keypress callbacks to the active scene.
---@param key string The name of the key pressed.
---@param scancode number The platform-independent scancode.
---@param isRepeat boolean True if the key press is a repeat event.
function M.keypressed(key, scancode, isRepeat)
  return M.dispatch('keypressed', key, scancode, isRepeat)
end

---Forwards engine keyrelease callbacks to the active scene.
---@param key string The name of the key released.
---@param scancode? number The platform-independent scancode.
function M.keyreleased(key, scancode)
  return M.dispatch('keyreleased', key, scancode)
end

---Forwards engine mouse press callbacks to the active scene.
---@param x number The x position of the mouse.
---@param y number The y position of the mouse.
---@param button number The mouse button that was pressed.
---@vararg any Additional LÖVR arguments (for example, `istouch` and `presses`).
function M.mousepressed(x, y, button, ...)
  return M.dispatch('mousepressed', x, y, button, ...)
end

---Forwards engine mouse release callbacks to the active scene.
---@param x number The x position of the mouse.
---@param y number The y position of the mouse.
---@param button number The mouse button that was released.
---@vararg any Additional LÖVR arguments (for example, `istouch` and `presses`).
function M.mousereleased(x, y, button, ...)
  return M.dispatch('mousereleased', x, y, button, ...)
end

---Forwards engine mouse movement callbacks to the active scene.
---@param x number The new x position of the mouse.
---@param y number The new y position of the mouse.
---@param dx number The x movement since the last event.
---@param dy number The y movement since the last event.
---@vararg any Additional LÖVR arguments (for example, `istouch`).
function M.mousemoved(x, y, dx, dy, ...)
  return M.dispatch('mousemoved', x, y, dx, dy, ...)
end

---Forwards engine mouse wheel callbacks to the active scene.
---@param dx number The relative horizontal wheel motion.
---@param dy number The relative vertical wheel motion.
function M.wheelmoved(dx, dy)
  return M.dispatch('wheelmoved', dx, dy)
end

---Forwards engine text input callbacks to the active scene.
---@param text string The UTF-8 encoded text.
---@param code number The unicode codepoint of the character.
function M.textinput(text, code)
  return M.dispatch('textinput', text, code)
end

---Forwards engine focus callbacks to the active scene.
---@param focused boolean Whether the application is focused.
---@param display string The display that changed focus.
function M.focus(focused, display)
  return M.dispatch('focus', focused, display)
end

---Forwards engine visibility callbacks to the active scene.
---@param visible boolean Whether the application is visible.
---@param display string The display that changed visibility.
function M.visible(visible, display)
  return M.dispatch('visible', visible, display)
end

---Forwards engine window resize callbacks to the active scene.
---@param width number The new window width.
---@param height number The new window height.
function M.resize(width, height)
  return M.dispatch('resize', width, height)
end

---Toggles HUD text tracking the active scene module name.
---@param enabled boolean
function M.setDebug(enabled)
  M.debug = enabled
end

return M
