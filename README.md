# LÖVR Window Manager

A lightweight, efficient scene/screen manager for **LÖVR**, designed for seamless navigation between menus, levels, and transitions.

## 🚀 Features

* **Scene Transitions**: Smooth visual transitions between scenes (Fade, Slide, etc.).
* **Data Passing**: Easily pass data objects between scenes via the `load()` lifecycle method.
* **Event Forwarding**: Keyboard, mouse, text, focus, visibility, and resize events can be routed to the active scene.
* **Scene Factories**: Register a factory to get a fresh scene table on every visit.
* **Lightweight**: Minimalist design with no dependencies.
* **Encapsulated**: Designed to be modular and easy to integrate into any LÖVR project.

## 🛠️ Installation

Simply drop the module into your `lib/` folder or whatever directory you prefer.

```lua
local window_manager = require 'lib.window_manager'
```

In this repository the module lives at the project root, so the demo's
`main.lua` uses `require 'init'` instead. When vendoring the module, use the
path you chose consistently in your entry point and in any scene that calls
the manager.

## 🎮 Usage

### 1. Registering Scenes

Register scenes with `window_manager.register('scene_name', require 'path.to.scene')`

```lua
-- main.lua
local window_manager = require 'lib.window_manager'

function lovr.load()
  window_manager.register('intro', require 'src.intro')
  window_manager.register('menu', require 'src.menu')
  window_manager.register('level', require 'src.level')
  window_manager.switch('intro')
end

function lovr.update(dt)
  window_manager.update(dt)
end

function lovr.draw(pass)
  window_manager.draw(pass)
end
```

Each scene is a Lua module with optional lifecycle functions (`load`, `update`, `draw`, `exit`).

```lua
-- src/intro.lua
local window_manager = require 'lib.window_manager'

local intro = {}

function intro.load(lang)
  print("\nLOADING INTRO")
end

function intro.update(dt)
  -- update your scene here
end

function intro.draw(pass)
  pass:text("This is the INTRO scene", 0, 0, -10)
end

function intro.exit()
  -- executed when you switch to another scene
end
```

### 2. Switching Scenes (with Data)

You can pass any Lua object (tables, strings, numbers) as a parameter when
switching scenes. The data is received in the `load()` function of the target
scene.

```lua
-- Switch to 'game' with an explicit transition and custom configuration
window_manager.switch('game', {
  transition = window_manager.Transitions.FADE,
  duration = 0.5,
  data = { difficulty = 'hard', level = 1 },
})

-- Inside game.lua
function game.load(data)
  if data then
    print("Starting level: " .. data.level)
  end
end
```

The older positional form remains supported:
`window_manager.switch('game', 'fade', 0.5, { difficulty = 'hard' })`.
Omitting the options uses `default_transition` and `transition_duration`.

### 3. Scene Factories

A registered table is a singleton, so module-level state persists between
visits. Register a function instead to create a fresh scene on every switch:

```lua
local function new_level()
  local level = {timer = 0}

  function level.load(data)
    level.timer = 0
  end

  function level.update(dt)
    level.timer = level.timer + dt
  end

  return level
end

window_manager.register('level', new_level)
```

The factory is called every time the scene is switched to. Use a plain table
when shared state is intentional.

### 4. Engine Events

The manager does not register LÖVR callbacks by itself. Forward the events you
want scenes to receive from your entry point. Keyboard events have dedicated
wrappers:

```lua
function lovr.keypressed(key, scancode, isrepeat)
  window_manager.keypressed(key, scancode, isrepeat)
end

function lovr.keyreleased(key, scancode)
  window_manager.keyreleased(key, scancode)
end
```

The same pattern applies to the other engine events:

```lua
function lovr.mousepressed(...) window_manager.mousepressed(...) end
function lovr.mousereleased(...) window_manager.mousereleased(...) end
function lovr.mousemoved(...) window_manager.mousemoved(...) end
function lovr.wheelmoved(...) window_manager.wheelmoved(...) end
function lovr.textinput(...) window_manager.textinput(...) end
function lovr.focus(...) window_manager.focus(...) end
function lovr.visible(...) window_manager.visible(...) end
function lovr.resize(...) window_manager.resize(...) end
```

Scenes can then implement the optional matching hooks:

```lua
function level.keypressed(key, scancode, isRepeat) end
function level.mousemoved(x, y, dx, dy, istouch) end
function level.focus(focused, display) end
```

For a custom event, call `dispatch` directly:

```lua
function lovr.filechanged(...)
  window_manager.dispatch('filechanged', ...)
end
```

Scenes that only declare `keyreleased(key)` continue to work.

## 🔄 Transitions

The manager includes built-in transitions:

* `window_manager.Transitions.NONE`
* `window_manager.Transitions.FADE`
* `window_manager.Transitions.SLIDE_LEFT`
* `window_manager.Transitions.SLIDE_RIGHT`
* `window_manager.Transitions.SLIDE_UP`
* `window_manager.Transitions.SLIDE_DOWN`

Only the incoming scene is animated: the outgoing scene's `exit()` hook runs
as soon as the switch begins and it is no longer drawn. Starting a new switch
cancels any transition that is still in flight. An unknown transition name is
reported to the console and falls back to `NONE` instead of leaving the screen
blank.

## 📖 API Reference

| Function | Description |
| --- | --- |
| `window_manager.register(name, scene_or_factory)` | Registers a scene table or a factory function. |
| `window_manager.switch(name, options_or_transition, duration, data)` | Switches to a new scene using an options table or positional arguments. |
| `window_manager.update(dt)` | Updates the active scene and handles transitions. |
| `window_manager.draw(pass)` | Renders the active scene and any active transition. |
| `window_manager.dispatch(event, ...)` | Calls an optional hook on the active scene. |
| `window_manager.keypressed(key, scancode, isRepeat)` | Forwards a key press to the active scene. |
| `window_manager.keyreleased(key, scancode)` | Forwards a key release to the active scene. |
| `window_manager.setDebug(enabled)` | Toggles the on-screen scene name overlay. |

Additional event wrappers: `mousepressed`, `mousereleased`, `mousemoved`,
`wheelmoved`, `textinput`, `focus`, `visible`, and `resize`.

See [CHANGELOG.md](CHANGELOG.md) for behavior changes and migration notes.

## 🧪 Development

The test suite has no external dependencies:

```sh
luajit tests/run.lua
lua5.4 tests/run.lua
```

CI runs the same suite on LuaJIT, Lua 5.1, and Lua 5.4.

## 📄 License

MIT — see [LICENSE](LICENSE).

