# Changelog

All notable changes to this project are documented in this file. The project
does not use tagged releases yet, so entries are grouped by change set.

## [Unreleased]

Changes since `bbbc7ae` (`add lsp annotations`).

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

No public function was removed or renamed, and existing calls to
`register`, `switch`, `update`, `draw`, and `setDebug` keep working. Projects
upgrading from `bbbc7ae` should check the following:

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

### Compatibility

- `register`, `switch`, `update`, `draw`, and `setDebug` keep their existing
  signatures.
- `switch()` still accepts `nil` for the transition and duration.
- `window_manager.Transitions` values and built-in transition names are
  unchanged.
