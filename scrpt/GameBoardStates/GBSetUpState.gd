extends GenericState
class_name GBSetUpState
var slave

func setup(newSlaves):
	super.setup(newSlaves)
	slave = slaves[0]

func _handle_bind(bind):
	
	match bind:
		"invalid": return
		"ui_accept": pass
		"ui_info": slave._on_gameboard_toggle_prof()
		"ui_return": slave.regress_menu()
		"ui_scroll_left": pass
		"ui_scroll_right": pass
		"ui_right": pass
		"ui_up": pass
		"ui_left": pass
		"ui_down": pass
