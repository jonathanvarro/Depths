extends RefCounted
## Stable names for status art and the current CombatState.Intent order.
const STATUS := {
	"bleeding":preload("res://art/ui/backlog96-v1/status/bleeding.png"),
	"wounded":preload("res://art/ui/backlog96-v1/status/wounded.png"),
	"healing":preload("res://art/ui/backlog96-v1/status/healing.png"),
	"down":preload("res://art/ui/backlog96-v1/status/down.png"),
	"unconscious":preload("res://art/ui/backlog96-v1/status/unconscious.png"),
	"deep-wound":preload("res://art/ui/backlog96-v1/status/deep-wound.png"),
	"limp":preload("res://art/ui/backlog96-v1/status/limp.png"),
	"dressed-overlay":preload("res://art/ui/backlog96-v1/status/dressed-overlay.png")
}
const INTENT := [
	preload("res://art/ui/backlog96-v1/intent/attack.png"),
	preload("res://art/ui/backlog96-v1/intent/lunge.png"),
	preload("res://art/ui/backlog96-v1/intent/dart.png"),
	preload("res://art/ui/backlog96-v1/intent/web.png"),
	preload("res://art/ui/backlog96-v1/intent/bite.png"),
	preload("res://art/ui/backlog96-v1/intent/swing.png"),
	preload("res://art/ui/backlog96-v1/intent/heavy.png"),
	preload("res://art/ui/backlog96-v1/intent/shield.png"),
	preload("res://art/ui/backlog96-v1/intent/killing-blow.png"),
	preload("res://art/ui/backlog96-v1/intent/shoot.png"),
	preload("res://art/ui/backlog96-v1/intent/bash.png"),
	preload("res://art/ui/backlog96-v1/intent/brace.png"),
	preload("res://art/ui/backlog96-v1/intent/call.png"),
	preload("res://art/ui/backlog96-v1/intent/screech.png"),
	preload("res://art/ui/backlog96-v1/intent/cleaver.png")
]
static func intention(value: int) -> Texture2D:
	return INTENT[value] if value>=0 and value<INTENT.size() else null
