-- Regression tests for the window manager.
-- Run from the repository root with: luajit tests/run.lua
-- or: lua5.4 tests/run.lua

local root = (arg and arg[0] and arg[0]:match('^(.*)[/\\]tests[/\\]run%.lua$')) or '.'
if root == '' then root = '.' end
package.path = root .. '/?.lua;' .. root .. '/?/init.lua;' .. package.path

local tests = {}

local function test(name, fn)
  tests[#tests + 1] = {name = name, fn = fn}
end

local function eq(actual, expected, message)
  if actual ~= expected then
    error(('%s: expected %s, got %s'):format(
      message or 'assertion failed',
      tostring(expected),
      tostring(actual)
    ), 2)
  end
end

local function fresh()
  package.loaded['init'] = nil
  return require('init')
end

local Pass = {}
Pass.__index = Pass

function Pass.new()
  return setmetatable({
    pushes = 0,
    pops = 0,
    alphas = {},
    translations = {},
    texts = {}
  }, Pass)
end

function Pass:push() self.pushes = self.pushes + 1 end
function Pass:pop() self.pops = self.pops + 1 end
function Pass:translate(x, y, z) self.translations[#self.translations + 1] = {x, y, z} end
function Pass:setColor(_, _, _, alpha) self.alphas[#self.alphas + 1] = alpha end
function Pass:text(text) self.texts[#self.texts + 1] = text end
function Pass:balanced() return self.pushes == self.pops end

local function newScene(name)
  local scene = {name = name, log = {}}
  function scene.load(data) scene.log.load = {data} end
  function scene.update(dt) scene.log.updates = (scene.log.updates or 0) + 1; scene.log.dt = dt end
  function scene.draw() scene.log.draws = (scene.log.draws or 0) + 1 end
  function scene.exit() scene.log.exits = (scene.log.exits or 0) + 1 end
  return scene
end

test('register and switch call lifecycle hooks', function()
  local wm = fresh()
  local a, b = newScene('a'), newScene('b')
  wm.register('a', a)
  wm.register('b', b)

  wm.switch('a', {data = 'first'})
  eq(wm.current, a, 'current scene')
  eq(a.log.load[1], 'first', 'load data')
  eq(wm.transition.type, wm.default_transition, 'default transition')
  eq(wm.transition.duration, wm.transition_duration, 'default duration')

  wm.switch('b', 'fade', 0.25, {level = 1})
  eq(wm.current, b, 'current scene after switch')
  eq(wm.previous, a, 'previous scene')
  eq(a.log.exits, 1, 'old scene exit')
  eq(b.log.load[1].level, 1, 'new scene data')
  eq(wm.transition.type, 'fade', 'transition type')
  eq(wm.transition.duration, 0.25, 'transition duration')
end)

test('positional switch arguments remain supported', function()
  local wm = fresh()
  local a, b = newScene('a'), newScene('b')
  wm.register('a', a)
  wm.register('b', b)

  wm.switch('a')
  wm.switch('b', nil, nil, 'payload')
  eq(b.log.load[1], 'payload', 'data passed positionally')
  eq(wm.transition.type, wm.default_transition, 'default transition')
end)

test('switch options table sets transition, duration, and data', function()
  local wm = fresh()
  local scene = newScene('a')
  wm.register('a', scene)

  wm.switch('a', {
    transition = wm.Transitions.SLIDE_UP,
    duration = 0.1,
    data = {score = 10}
  })
  eq(wm.transition.type, 'slide_up', 'options transition')
  eq(wm.transition.duration, 0.1, 'options duration')
  eq(scene.log.load[1].score, 10, 'options data')
end)

test('unknown transitions fall back and still render', function()
  local wm = fresh()
  local a, b = newScene('a'), newScene('b')
  wm.register('a', a)
  wm.register('b', b)

  wm.switch('a')
  wm.switch('b', 'not_a_transition', 0.5)
  eq(wm.transition, nil, 'invalid transition is cleared')

  local pass = Pass.new()
  wm.draw(pass)
  eq(b.log.draws, 1, 'scene is drawn without a transition')
  eq(pass:balanced(), true, 'pass state is balanced')
end)

test('switching with NONE cancels an in-flight transition', function()
  local wm = fresh()
  local a, b = newScene('a'), newScene('b')
  wm.register('a', a)
  wm.register('b', b)

  wm.switch('a', 'fade', 1.0)
  wm.update(0.25)
  eq(wm.transition.type, 'fade', 'transition is active')

  wm.switch('b', wm.Transitions.NONE)
  eq(wm.transition, nil, 'transition is cancelled')

  local pass = Pass.new()
  wm.draw(pass)
  eq(pass:balanced(), true, 'pass state is balanced')
end)

test('draw applies and restores transition transforms', function()
  local wm = fresh()
  local scene = newScene('a')
  wm.register('a', scene)

  wm.switch('a', 'slide_left', 1.0)
  wm.update(0.25)
  local pass = Pass.new()
  wm.draw(pass)

  eq(#pass.translations, 1, 'one translation applied')
  eq(pass:balanced(), true, 'pass state is balanced')
  eq(scene.log.draws, 1, 'scene draw called once')
end)

test('zero duration does not break rendering', function()
  local wm = fresh()
  local scene = newScene('a')
  wm.register('a', scene)

  wm.switch('a', 'fade', 0)
  local pass = Pass.new()
  wm.draw(pass)
  eq(pass:balanced(), true, 'pass state is balanced')
  eq(scene.log.draws, 1, 'scene still draws')
end)

test('draw before a scene is safe', function()
  local wm = fresh()
  local pass = Pass.new()
  wm.draw(pass)
  eq(pass.pushes, 0, 'no pass push without a scene')
end)

test('keyboard wrappers forward all arguments', function()
  local wm = fresh()
  local pressed, released = {}, {}
  wm.register('keys', {
    keypressed = function(key, scancode, isRepeat) pressed = {key, scancode, isRepeat} end,
    keyreleased = function(key, scancode) released = {key, scancode} end
  })
  wm.switch('keys')

  wm.keypressed('space', 44, true)
  wm.keyreleased('space', 44)
  eq(pressed[1], 'space', 'key')
  eq(pressed[2], 44, 'scancode')
  eq(pressed[3], true, 'isRepeat')
  eq(released[1], 'space', 'released key')
  eq(released[2], 44, 'released scancode')
end)

test('mouse, text, focus, visibility, and resize wrappers forward', function()
  local wm = fresh()
  local events = {}
  wm.register('events', {
    mousepressed = function(...) events.mousepressed = {...} end,
    mousereleased = function(...) events.mousereleased = {...} end,
    mousemoved = function(...) events.mousemoved = {...} end,
    wheelmoved = function(...) events.wheelmoved = {...} end,
    textinput = function(...) events.textinput = {...} end,
    focus = function(...) events.focus = {...} end,
    visible = function(...) events.visible = {...} end,
    resize = function(...) events.resize = {...} end
  })
  wm.switch('events')

  wm.mousepressed(1, 2, 3, true, 2)
  wm.mousereleased(4, 5, 6, false, 1)
  wm.mousemoved(7, 8, 9, 10, true)
  wm.wheelmoved(1, -1)
  wm.textinput('a', 97)
  wm.focus(true, 'desktop')
  wm.visible(false, 'desktop')
  wm.resize(800, 600)

  eq(events.mousepressed[1], 1, 'mousepressed x')
  eq(events.mousepressed[3], 3, 'mousepressed button')
  eq(events.mousepressed[4], true, 'mousepressed istouch')
  eq(events.mousereleased[2], 5, 'mousereleased y')
  eq(events.mousemoved[3], 9, 'mousemoved dx')
  eq(events.mousemoved[4], 10, 'mousemoved dy')
  eq(events.wheelmoved[2], -1, 'wheelmoved dy')
  eq(events.textinput[1], 'a', 'textinput text')
  eq(events.textinput[2], 97, 'textinput code')
  eq(events.focus[1], true, 'focus state')
  eq(events.focus[2], 'desktop', 'focus display')
  eq(events.visible[1], false, 'visible state')
  eq(events.resize[1], 800, 'resize width')
  eq(events.resize[2], 600, 'resize height')
end)

test('dispatch calls custom hooks and returns their values', function()
  local wm = fresh()
  local scene = {
    custom = function(a, b) return a + b, a * b end
  }
  wm.register('custom', scene)
  wm.switch('custom')

  local sum, product = wm.dispatch('custom', 3, 4)
  eq(sum, 7, 'first return value')
  eq(product, 12, 'second return value')
  eq(wm.dispatch('missing'), nil, 'missing hook returns nil')

  scene.custom = 42
  eq(wm.dispatch('custom'), nil, 'non-function hook is ignored')
end)

test('register rejects invalid scene values', function()
  local wm = fresh()
  local ok, err = pcall(function() wm.register('bad', 42) end)
  eq(ok, false, 'invalid scene errors')
  eq(type(err) == 'string' and err:match('must be a table or a function') ~= nil, true, 'error message')
end)

test('scene factories produce a fresh scene per switch', function()
  local wm = fresh()
  local built = 0
  local loaded = {}

  wm.register('factory', function()
    built = built + 1
    local id = built
    local scene = {name = 'factory' .. id}
    function scene.load() loaded[#loaded + 1] = id end
    return scene
  end)

  wm.switch('factory')
  local first = wm.current
  eq(built, 1, 'factory called once')
  eq(loaded[1], 1, 'first instance loaded')

  wm.switch('factory')
  eq(built, 2, 'factory called again')
  eq(loaded[2], 2, 'second instance loaded')
  eq(wm.current == first, false, 'a new table is used')
end)

test('scene factories must return a table', function()
  local wm = fresh()
  wm.register('bad_factory', function() return nil end)
  local ok = pcall(function() wm.switch('bad_factory') end)
  eq(ok, false, 'invalid factory return errors')
end)

test('switching to an unregistered scene errors', function()
  local wm = fresh()
  local ok, err = pcall(function() wm.switch('missing') end)
  eq(ok, false, 'unregistered scene errors')
  eq(type(err) == 'string' and err:match('not registered') ~= nil, true, 'error message')
end)

test('update advances transitions and scene logic', function()
  local wm = fresh()
  local scene = newScene('a')
  wm.register('a', scene)

  wm.switch('a', 'fade', 0.5)
  wm.update(0.25)
  eq(wm.transition.elapsed, 0.25, 'transition elapsed')
  eq(scene.log.updates, 1, 'scene updated')
  eq(scene.log.dt, 0.25, 'delta time forwarded')

  wm.update(0.3)
  eq(wm.transition, nil, 'transition finished')
end)

test('debug overlay uses the current scene name', function()
  local wm = fresh()
  local scene = newScene('debug_scene')
  wm.register('debug', scene)
  wm.switch('debug')
  wm.setDebug(true)

  local pass = Pass.new()
  wm.draw(pass)
  eq(pass.texts[1], 'Scene: debug_scene', 'debug text')
end)

test('main.lua wires engine events to the active scene', function()
  fresh()
  local events = {}
  local function record(name)
    return function(...) events[name] = {...} end
  end

  package.loaded['src.intro'] = {
    load = function(data) events.load = data end,
    keypressed = record('keypressed'),
    keyreleased = record('keyreleased'),
    mousepressed = record('mousepressed'),
    mousereleased = record('mousereleased'),
    mousemoved = record('mousemoved'),
    wheelmoved = record('wheelmoved'),
    textinput = record('textinput'),
    focus = record('focus'),
    visible = record('visible'),
    resize = record('resize')
  }
  package.loaded['src.menu'] = {}
  package.loaded['src.level'] = {}

  _G.lovr = {}
  dofile(root .. '/main.lua')
  lovr.load()

  eq(events.load, 'pt-br', 'entry point data reaches the first scene')
  eq(type(lovr.keypressed), 'function', 'keypressed callback')
  eq(type(lovr.mousemoved), 'function', 'mousemoved callback')

  lovr.keypressed('space', 44, false)
  lovr.keyreleased('space', 44)
  lovr.mousepressed(1, 2, 3)
  lovr.mousereleased(1, 2, 3)
  lovr.mousemoved(1, 2, 3, 4)
  lovr.wheelmoved(1, -1)
  lovr.textinput('a', 97)
  lovr.focus(true, 'desktop')
  lovr.visible(false, 'desktop')
  lovr.resize(800, 600)

  eq(events.keypressed[2], 44, 'keypressed forwarded')
  eq(events.keyreleased[2], 44, 'keyreleased forwarded')
  eq(events.mousepressed[3], 3, 'mousepressed forwarded')
  eq(events.mousemoved[4], 4, 'mousemoved forwarded')
  eq(events.wheelmoved[2], -1, 'wheelmoved forwarded')
  eq(events.textinput[1], 'a', 'textinput forwarded')
  eq(events.focus[1], true, 'focus forwarded')
  eq(events.visible[1], false, 'visible forwarded')
  eq(events.resize[2], 600, 'resize forwarded')

  _G.lovr = nil
end)

local failures = 0
for i, case in ipairs(tests) do
  local ok, err = pcall(case.fn)
  if ok then
    print(('ok %d - %s'):format(i, case.name))
  else
    failures = failures + 1
    print(('not ok %d - %s'):format(i, case.name))
    print('  ' .. tostring(err):gsub('\n', '\n  '))
  end
end

print(('%d tests, %d failed'):format(#tests, failures))
if failures > 0 then
  os.exit(1)
end
