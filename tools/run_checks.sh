#!/usr/bin/env bash
# Runs every check and the three opening play-throughs with no window, so
# nothing pops up or takes focus (owner, 2026-10-27). Prints one line per
# check and a summary.
#
#   tools/run_checks.sh                 # headless, no screenshots
#   tools/run_checks.sh --shots DIR     # real renderer on a hidden desktop, saving screenshots to DIR
#
# GODOT can point at another Godot 4.7 binary; PYTHON at a Python 3.
# --shots runs each check through tools/testing/background_godot.py, on a
# private Windows desktop that is never shown, so no window can take focus
# (#253). It never falls back to the visible desktop.

GODOT="${GODOT:-/e/Red Noon/game/.tools/godot/Godot_v4.7.2-stable_win64_console.exe}"
cd "$(dirname "$0")/.."
MODE=(--headless)
SHOTS=""
if [ "$1" = "--shots" ]; then
	SHOTS="$2"
	MODE=()
fi
PYTHON="${PYTHON:-python}"
LOGS="${TMPDIR:-${TEMP:-/tmp}}/depths-checks"

failed=0
run() {
	local name="$1"; shift
	local out
	if [ -n "$SHOTS" ]; then
		rm -rf "$LOGS"; mkdir -p "$LOGS"
		"$PYTHON" tools/testing/background_godot.py --godot "$(cygpath -w "$GODOT")" --project "$(cygpath -w "$PWD")" \
				--output "$(cygpath -w "$LOGS")" --timeout 300 -- --resolution 1280x720 "$@" > /dev/null 2>&1
		out=$(cat "$LOGS/stdout.log" "$LOGS/stderr.log" 2>/dev/null | grep -E "^FAIL|fails=|SCRIPT ERROR|Parse Error" | head -4 | tr '\n' ' ')
	else
		out=$(timeout 300 "$GODOT" "${MODE[@]}" --path . --resolution 1280x720 "$@" 2>&1 | grep -E "^FAIL|fails=|SCRIPT ERROR|Parse Error" | head -4 | tr '\n' ' ')
	fi
	echo "$name: $out"
	if ! echo "$out" | grep -q "fails=0" || echo "$out" | grep -q "ERROR"; then
		failed=$((failed + 1))
	fi
}

# Each check starts from the default settings: a check that changes one
# (and stops before putting it back) mustn't change the next (2026-11-11).
TEST_SETTINGS="${APPDATA:-$HOME/.local/share}/Godot/app_userdata/Depths/test_settings.cfg"
for f in tools/*_check.gd; do
	# Only the suite's own checks (they print "fails="); native capture
	# fixtures with their own report format run separately (#253).
	grep -q 'fails=' "$f" || continue
	rm -f "$TEST_SETTINGS"
	run "$(basename "$f" .gd)" --script "$f" -- desk "$SHOTS"
done
rm -f "$TEST_SETTINGS"
for hero in mara corin alwen; do
	rm -f "$TEST_SETTINGS"
	run "opening $hero" --script tools/opening_playthrough.gd -- desk "$SHOTS" 7 "" "$hero"
done
echo "failed: $failed"
[ "$failed" -eq 0 ]
