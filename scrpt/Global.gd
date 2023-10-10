extends Node
enum GameState {
	DEFAULT,
	SELECTED,
	ACTION_MENU,
	PROFILE,
	ATTACK_TARGETING,
	COMBAT_FORECAST,
	SKILL_TARGETING,
	SKILL_MENU,
	ROUND_END,
	WARP
}


var profileMenu = false
var actionMenu = false
var combatForecast = false
var focusUnit: Unit
var activeUnit: Unit
var day: bool = true
var gameTime
var timeFactor = 1
var trueTimeFactor = 1
var rotationFactor = 15
var rng
var state: int = 0
var slamage = 5
#combat variables
var attacker = {
	"NAME" : "Null", "ACC": 0, "DMG": 0, "AVOID": 0, "DEF": 0,
	"CRIT": 0, "CAVD": 0, "LIFE": 0, "CLIFE": 0, "RLIFE":0}
var defender = {
	"NAME" : "Null", "ACC": 0, "DMG": 0, "AVOID": 0, "DEF": 0,
	"CRIT": 0, "CAVD": 0, "LIFE": 0, "CLIFE": 0, "RLIFE":0}
func _init():
	rng = RandomNumberGenerator.new()
	randomize()

