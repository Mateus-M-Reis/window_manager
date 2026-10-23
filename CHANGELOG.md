# Changelog

All notable changes to this project are documented in this file. The project
does not use tagged releases yet, so entries are grouped by change set.

## [Unreleased]

Changes since `bbbc7ae` (`add lsp annotations`).

### Added

- **Options-table `switch()`.** The preferred form is now
  `window_manager.switch('level', { transition = 'fade', duration = 0.4, data = ... })`.
  The existing positional signature remains supported.
- **Generic event forwarding.** `window_manager.dispatch(event, ...)` calls an
  optional hook on the active scene. Dedicated wrappers are available for
  keyboard, mouse, wheel, text, focus, visibility, and resize events.
- **Scene factories.** `register()` now accepts a function returning a scene
  table. The factory is invoked on every switch, so each visit starts with
  fresh state.
- **Regression tests and CI.** `tests/run.lua` runs with LuaJIT, Lua 5.1, and
  Lua 5.4; `.github/workflows/ci.yml` runs the suite on pushes and pull
  requests.
- **MIT license.**

### Fixed

- **Keyboard events now reach scenes.** `main.lua` forwards
  `lovr.keypressed` and `lovr.keyreleased` to the manager, and
  `keyreleased` forwards the `scancode` argument. Scenes that implement
  these hooks previously never received them in the bundled example.
- **Switching with `window_manager.Transitions.NONE` now cancels an
  in-flight transition.** Previously the old fade/slide kept running and was
  applied to the new scene.
- **Unknown transition names no longer blank the screen.** An unrecognized
  name is reported to the console and falls back to `none`; the current
  scene is always drawn. Previously the scene was skipped for the whole
  transition duration.
- **Demo scenes reset their timers in `load()`**, so revisiting a scene does
  not immediately trigger its scripted `switch()`.

### Migration notes

No public function was removed or renamed, and existing calls to `register`,
`switch`, `update`, `draw`, and `setDebug` keep working. Projects upgrading
from `bbbc7ae` should check the following:

1. **Add keyboard forwarding if you use scene keyboard hooks.** The manager
   never registered LÖVR callbacks by itself, so this was already required;
   it is now shown in the bundled example and README. Add the following to
   your entry point (unless you already forward these events yourself):

   ```lua
   function lovr.keypressed(key, scancode, isrepeat)
     window_manager.keypressed(key, scancode, isrepeat)
   end

   function lovr.keyreleased(key, scancode)
     window_manager.keyreleased(key, scancode)
   end
   ```

   Projects that do not use keyboard hooks do not need this.

2. **Check the console for `unknown transition` warnings.** A typo now
   means "no transition" instead of "render nothing while the transition
   runs". Correct the transition name if the warning appears.

3. **Remove any workaround that cleared the transition manually.** If you
   set `window_manager.transition = nil` before switching with `none` to
   avoid the stale-fade bug, `switch()` now handles that for you.

4. **`keyreleased` handlers may keep their old signature.** Scenes declaring
   `keyreleased(key)` continue to work; the new `scancode` argument is
   appended, so one-argument handlers are unaffected.

5. **The new APIs are optional.** Keep using positional `switch()` calls and
   table scenes if that fits your project. To receive mouse, text, focus,
   visibility, or resize events, forward them from your entry point or call
   `dispatch()` directly (see the README).

6. **Invalid registrations now fail earlier.** `register()` accepts only a
   table or a function; passing another value raises an error at
   registration time instead of on the first switch. Valid registrations are
   unaffected.

### Compatibility

- `register`, `switch`, `update`, `draw`, and `setDebug` keep their existing
  signatures.
- `switch()` still accepts `nil` for the transition and duration.
- `window_manager.Transitions` values and built-in transition names are
  unchanged.
- Existing scene tables work exactly as before; factories are opt-in.
