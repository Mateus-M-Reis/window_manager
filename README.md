# LÖVR Window Manager

A lightweight, efficient scene/screen manager for **LÖVR**, designed for seamless navigation between menus, levels, and transitions.

## 🚀 Features

* **Scene Transitions**: Smooth visual transitions between scenes (Fade, Slide, etc.).
* **Data Passing**: Easily pass data objects between scenes via the `load()` lifecycle method.
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
local window_manager = require'lib.window_manager'

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
local window_manager = require'lib.window_manager'

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

You can pass any Lua object (tables, strings, numbers) as a parameter when switching scenes. The data is received in the `load()` function of the target scene.

```lua
-- Switch to 'game' scene passing custom configuration
window_manager.switch('game', 'fade', 0.5, { difficulty = 'hard', level = 1 })

-- Inside game.lua
function game.load(data)
  if data then
    print("Starting level: " .. data.level)
  end
end
```

### 3. Keyboard Input

The manager does not register LÖVR callbacks by itself. Forward the events
you want scenes to receive from your entry point:

```lua
function lovr.keypressed(key, scancode, isrepeat)
  window_manager.keypressed(key, scancode, isrepeat)
end

function lovr.keyreleased(key, scancode)
  window_manager.keyreleased(key, scancode)
end
```

Scenes can then implement the optional `keypressed(key, scancode, isRepeat)`
and `keyreleased(key, scancode)` hooks. Scenes that only declare
`keyreleased(key)` continue to work.

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
| `window_manager.register(name, scene)` | Registers a scene module. |
| `window_manager.switch(name, trans, dur, data)` | Switches to a new scene, with optional transition and data. |
| `window_manager.update(dt)` | Updates the active scene and handles transitions. |
| `window_manager.draw(pass)` | Renders the active scene and any active transition. |
| `window_manager.keypressed(key, scancode, isRepeat)` | Forwards a key press to the active scene. |
| `window_manager.keyreleased(key, scancode)` | Forwards a key release to the active scene. |
| `window_manager.setDebug(enabled)` | Toggles the on-screen scene name overlay. |

See [CHANGELOG.md](CHANGELOG.md) for behavior changes and migration notes.

