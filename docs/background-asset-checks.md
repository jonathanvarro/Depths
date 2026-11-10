# Unobtrusive automated asset checks (#253)

Owner preference, 2026-11-09: test windows must not minimize or interrupt the
apps they are actively using. This is also recorded in AGENTS.md for Claude
and Codex. Interactive previews may be opened on request.

## Default workflow

Use Godot `--headless` for imports, parse checks and logic checks. Browser
gallery checks use headless Chromium. Blender exporters run `--background`.
Keep helper consoles hidden. Do not launch fullscreen or always-on-top tests,
activate existing windows, send desktop keyboard input or restore focus after
the fact: restoring focus would still interrupt what the owner was doing.

Native screenshot checks need the real renderer. A hidden PowerShell launcher
does not prevent Godot from activating its own game window. On Windows, use
`tools/testing/background_godot.py` for these checks. It creates a temporary
Windows desktop, launches Godot there and never switches the visible desktop.
Godot can still render and save images while its windows stay off the owner's
interactive desktop, including when a harness resizes its window.

The helper uses Python's standard library and Windows desktop/process APIs.
It forces a windowed startup, hides the helper console, captures stdout/stderr,
waits with a timeout and closes its process/desktop handles. On an error or
timeout it terminates only the test process it launched. It never changes
other windows or falls back to a foreground run. A restricted execution sandbox
may deny desktop creation; normal approved Windows desktop access is needed.

## Run a native check

Example from `E:/GitHub/Depths`, with the prepared rat review:

```powershell
$env:APPDATA='E:/GitHub/Depths/build/descent-check-user'
& 'C:/Users/jonat/.cache/codex-runtimes/codex-primary-runtime/dependencies/python/python.exe' `
  tools/testing/background_godot.py `
  --godot E:/GitHub/Depths/build/research-godot-4.7.2/Godot_v4.7.2-stable_win64_console.exe `
  --project E:/GitHub/Depths/build/local-rat-landmarks-v1 `
  --output E:/GitHub/Depths/build/local-background-check-v1/rat-review `
  --timeout 60 -- --script res://check.gd --quit-after 18000
```

Import the project headlessly first if needed. Native fixtures and imports
should still run sequentially. The output folder receives stdout.log,
stderr.log and launch.json. The harness saves its images/report to its normal
locations. Check both the launch result and the harness's validation report;
a zero Godot exit code alone does not prove the script passed.

`test_was_foreground` must be false. `foreground_unchanged` compares the
foreground handle before/after as an additional observation, not a requirement
that the owner keep the same app selected during a longer run. The launcher
does not capture window titles or the owner's screen.

The harness must use isolated test saves/settings, keep fullscreen disabled
and avoid native prompts, live input automation and explicit foreground calls.
An unattended hidden prompt could stall until the timeout. Tests requiring
physical mouse/keyboard interaction should be reserved for an owner-requested
visible preview. This helper does not modify project.godot or the game's normal
window behaviour. No global Windows focus settings are changed.

## Verified on this PC

Godot 4.7.2 Mobile / D3D12, AMD Radeon RX 9070 XT:

- A disposable 320×180 cube scene resized to 480×270 and saved a valid,
  nonblank GPU image on the private desktop. Its image/colour assertions
  passed; the test never became the active desktop's foreground window and
  the foreground handle was unchanged.
- The existing rat/landmark native review passed all 951 checks and produced
  its 150 captures through the same launcher, without taking foreground focus.
- A deliberately stalled headless fixture timed out with exit 124 and cleaned
  up its process/desktop, without taking foreground focus.

The minimal probe is `tools/testing/background_probe.gd`; copy it as probe.gd
into an ignored disposable project under build/ with the Mobile renderer,
then run `--script res://probe.gd --quit-after 120` through the helper. Actual
local probe results are in `build/local-background-check-v1`.

Engine references: [headless command-line option](https://docs.godotengine.org/en/stable/tutorials/editor/command_line_tutorial.html)
and [Godot 4.7.2 Windows window activation implementation](https://github.com/godotengine/godot/blob/4.7.2-stable/platform/windows/display_server_windows.cpp).
