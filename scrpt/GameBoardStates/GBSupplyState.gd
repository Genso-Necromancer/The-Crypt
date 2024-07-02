extends GenericState
class_name GBSupplyState
var slave

func setup(newSlaves):
	super.setup(newSlaves)
	slave = slaves[0]

func _handle_bind(bind):
	match bind:
		"invalid": return
		"ui_accept": pass
		"ui_info": pass
		"ui_return": pass
		"ui_scroll_left": pass
		"ui_scroll_right": pass
		"ui_right": pass
		"ui_up": pass
		"ui_left": pass
		"ui_down": pass
