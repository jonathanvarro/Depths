#!/usr/bin/env bash
# Runs every check and the three opening play-throughs with no window, so
# nothing pops up or takes focus (owner, 2026-10-27). Prints one line per
# check and a summary.
#
#   tools/run_checks.sh                 # headless, no screenshots
#   tools/run_checks.sh --shots DIR     # in an off-screen window, saving screenshots to DIR
#
# GODOT can point at another Godot 4.7 binary.

GODOT="${GODOT:-/e/Red Noon/game/.tools/godot/Godot_v4.7.2-stable_win64_console.exe}"
cd "$(dirname "$0")/.."
MODE=(--headless)
SHOTS=""
if [ "$1" = "--shots" ]; then
	SHOTS="$2"
	MODE=(--position -10000,-10000)  # a real window, kept off-screen
fi

failed=0
run() {
	local name="$1"; shift
	local out
	out=$(timeout 300 "$GODOT" "${MODE[@]}" --path . --resolution 1280x720 "$@" 2>&1 | grep -E "^FAIL|fails=|SCRIPT ERROR|Parse Error" | head -4 | tr '\n' ' ')
	echo "$name: $out"
	if ! echo "$out" | grep -q "fails=0" || echo "$out" | grep -q "ERROR"; then
		failed=$((failed + 1))
	fi
}

for f in tools/*_check.gd; do
	run "$(basename "$f" .gd)" --script "$f" -- desk "$SHOTS"
done
for hero in mara corin alwen; do
	run "opening $hero" --script tools/opening_playthrough.gd -- desk "$SHOTS" 7 "" "$hero"
done
echo "failed: $failed"
[ "$failed" -eq 0 ]
