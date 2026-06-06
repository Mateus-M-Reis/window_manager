# LÖVR Window Manager

A lightweight, efficient scene/screen manager for **LÖVR**, designed for seamless navigation between menus, levels, and transitions.

## 🚀 Features

* **Scene Transitions**: Smooth visual transitions between scenes (Fade, Slide, etc.).
* **Data Passing**: Easily pass data objects between scenes via the `load()` lifecycle method.
* **Lightweight**: Minimalist design with no dependencies.
* **Encapsulated**: Designed to be modular and easy to integrate into any LÖVR project.

## 🛠️ Installation

Simply copy the `init.lua` (or `window_manager.lua`) file into your project folder. We recommend using it as a module:

```lua
local wm = require 'window_manager.init'

```

## 🎮 Usage

### 1. Registering Scenes

Each scene is a Lua module with optional lifecycle functions (`load`, `update`, `draw`, `exit`).

```lua
local menu = {
  name = 'menu',
  load = function() print("Menu loaded!") end,
  draw = function(pass) -- Draw your scene here end
}

wm.register('menu', menu)

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

