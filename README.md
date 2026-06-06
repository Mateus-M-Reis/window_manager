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
wm.switch('game', 'fade', 0.5, { difficulty = 'hard', level = 1 })

-- Inside game.lua
function game.load(data)
  if data then
    print("Starting level: " .. data.level)
  end
end
```

## 🔄 Transitions

The manager includes built-in transitions:

* `wm.Transitions.NONE`
* `wm.Transitions.FADE`
* `wm.Transitions.SLIDE_LEFT`
* `wm.Transitions.SLIDE_RIGHT`
* `wm.Transitions.SLIDE_UP`
* `wm.Transitions.SLIDE_DOWN`

## 📖 API Reference

| Function | Description |
| --- | --- |
| `wm.register(name, scene)` | Registers a scene module. |
| `wm.switch(name, trans, dur, data)` | Switches to a new scene, with optional transition and data. |
| `wm.update(dt)` | Updates the active scene and handles transitions. |
| `wm.draw(pass)` | Renders the active scene and any active transition. |

