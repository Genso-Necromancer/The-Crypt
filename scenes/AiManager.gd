extends Node
var gameBoard : GameBoard
var player := []
var enemy := []
var terrainData
var unitData = UnitData.unitData
var aHex : AHexGrid2D
var threatArray = []
var BoardState
var lvCap = 20
var terrainMax = 2
var terrainMin = 0
var newRange = (1-0)
var tWeight = 1
var uWeight = 0.25
var ulWeight = 0.25
var dmgWeight = 0.25
var accWeight = 0.25
var grWeight = 1.2

var survWeight = 1.1
var waitWeight = 0.12
var survThresh = 0.5
var accScale = 2.2
var safeBonus: float = 1.4
var playerValues = {}
var enemyValues = {}
var terrainValues = {}
@export var maxDepth = 3

func init_ai():
	#link up dependancies
	gameBoard = get_parent()
	aHex = gameBoard.hexStar


func get_move(state: BoardState):

	playerValues.clear()
	enemyValues.clear()
	terrainValues.clear()
	#assigns weighted value for the AI to compare
	playerValues = assign_unit_value(state.player)
	enemyValues = assign_unit_value(state.enemy)
	terrainValues = assign_terrain_value(state.terrainData)
	
	var moves = find_moves(state)
	return moves

func find_moves(state: BoardState):
	var validMoves = []
	
	for unit in state.enemy:
		var unitCell = unit.cell
		
		var moves = get_valid_moves(unit, unit.cell, unit.unitData.Stats.Move, state)
		if moves == null or moves.size() == 0:
			continue
		else:
			validMoves.append({"Unit": unit, "Best Move": moves})
	var bestAction = find_best_action(validMoves)
#	print(validMoves)
#	print("Best?? ", validMoves)
#	print("We made it: ", bestAction)
	return bestAction
	
func find_best_action(moves):
	var bestValue: float = -INF
	var bestMove = null
	for move in moves:
#		print(move)
		if move["Best Move"]["value"] > bestValue:
			bestValue = move["Best Move"]["value"]
			bestMove = move
	return bestMove
	
func get_valid_moves(unit, cell, move, state):
	#This just runs the functions which actually compares all the possible moves before sending it up the pipeline
	var path = aHex.find_all_paths(cell, move, unit.moveType, true)
	var threat
	var bestAttack = null
	var bestMove = null
	var waitValue = null
	var validMoves = path.duplicate()
	var validAttacks = find_valid_attacks(unit, path, state)
#	print(validAttacks)
	if validAttacks != null:
		bestAttack = find_best_attack(validAttacks)
	if validMoves != null:
		bestMove = find_best_move(validMoves, unit, state, bestAttack)
	waitValue = find_wait_value(unit, bestAttack, bestMove)
#	print(unit, "'s ","Best Attack: ", bestAttack)
#	print(unit, "'s ","Best Move: ", bestMove)
#	print(unit, "'s ","Wait Value: ", waitValue)
	var bestAction = find_best_of_set(bestAttack, bestMove, waitValue)
#	print(unit, "'s ","Best Action: ", bestAction)
	return bestAction
	#HERE You gathered each attackable unit and the spaces you can attack them from.
	#Each target and it's spaces need VALUES to be processed
			
func find_best_of_set(attack, move, wait):
	var bestMove = null
	if attack != null and attack["value"] >= move["value"]:
		if attack["value"] >= wait["value"]:
			bestMove = attack
	elif move!= null and move["value"] > wait["value"]:
		bestMove = move
	else:
		bestMove = wait
	return bestMove
			
func find_wait_value(unit, bestAttack, bestMove):
	var value: float = 0
	var dmgTaken = 0
	var dmgDealt = 0
	var bestTerrain = terrainValues[Vector2i(unit.cell)]
	var tradeUp = false
	if bestAttack == null and bestMove == null:
		value = 1
	for terrain in terrainValues:
		if terrainValues[terrain] > terrainValues[Vector2i(unit.cell)]:
			tradeUp = true
	if !tradeUp:
		value += waitWeight
	var waitAction = {"Action": "Wait", "value": value}
	return waitAction

func find_best_move(validMoves, unit, state, bestAttack):
	var movePairs = []
	var curLife = unit.unitData.CurLife
	var maxLife = unit.unitData.Stats.Life
	var lifePrc:float = (maxLife - ((maxLife-curLife) / maxLife)) / 10
#	var value:float = 0
	for cell in validMoves:
		if !state.occupied.has(cell):
			movePairs.append({"Action": "Move","tile":Vector2i(cell), "value": terrainValues[Vector2i(cell)]})
	var bestValue:float = -INF
	var bestMove
#	var dmgTaken = 0
#	var dmgDealt = 0
#	var survRatio = 0
	for pair in movePairs:
#		print(pair)
		if pair["value"] > terrainValues[Vector2i(unit.cell)]:
			if lifePrc < survThresh:
				pair["value"] = pair["value"] * ((((maxLife-curLife) / maxLife) + 1) * survWeight)
		if pair["value"] > bestValue:
			bestValue = pair["value"]
			bestMove = pair.duplicate()
#	print("best: ", bestMove)
	return bestMove

func find_best_attack(attacks):
	var bestValue:float = -INF
	var bestAttack = null
	for attack in attacks:
		if attack["value"] > bestValue:
			bestValue = attack["value"]
			bestAttack = attack.duplicate()
	return bestAttack
	
func find_valid_attacks(aiUnit, path, state):
	#Needs updating for unique weapon ID
	var validAttacks = []
#	threat = aHex.find_threat(path, ranges)
	var aiInv = aiUnit.unitData.Inv
	var wepData = UnitData.itemData
	var targetDef
	for wep in aiInv:
		var wepID = wep["ID"]
		var ranges = [wepData[wepID].MinRange, wepData[wepID].MaxRange]
		var threat = aHex.find_threat(path, ranges, aiUnit.moveType)
		for unit in state.player:
			match wepData[wepID].Type:
				"Physical":
					targetDef = "Bar"
					if (aiUnit.combatData.Dmg - unit.unitData.Stats.Bar <= 0):
						continue
				"Magic":
					targetDef = "RES"
					if (aiUnit.combatData.Dmg - unit.unitData.Stats.Mag <= 0):
						continue
			
			if threat.has(unit.cell):
	#			var radius = aHex.find_all_paths(unit.cell, ranges[1], true)
				var reach = aHex.find_threat([unit.cell], ranges)
	#			print(reach)
				
				for cell in reach:
					var attack = {}
					if path.has(cell) and cell != unit.cell and !state.occupied.has(cell):
						var safe = check_safe(aiUnit, unit, cell)
						attack = {"Action": "Attack", "target" : unit, "launch" : Vector2i(cell), "safe": safe, "weapon": wep}
						var value = get_attack_value(aiUnit, attack, targetDef)
#						print(attack, " ", value)
						validAttacks.append({"Action": "Attack", "weapon": wep, "target" : unit, "launch" : Vector2i(cell), "value": value})
	return validAttacks
	
func get_attack_value(aiUnit, attack, targetDef):
	var value: float = 0
#	print("StarT: ", value, " + ", playerValues[attack.target])
	value += playerValues[attack.target]
#	print(value)
#	print(" + ", terrainValues[attack.launch])
	value += (terrainValues[attack.launch])
	value -= (aHex.compute_cost(aiUnit.cell, attack.launch, aiUnit.moveType) / 100) 
#	print(value)
#	print(" + ", enemyValues[aiUnit])
#	value += enemyValues[aiUnit]
#	print(value)
#	print(" + ", combat_values(aiUnit, attack, targetDef))
	value += combat_values(aiUnit, attack, targetDef)
#	print(value)
	if attack.safe:
		value = value * safeBonus
	return value
	
func combat_values(aiUnit, attack, targetDef):
	var aiInv = aiUnit.unitData.Inv
	

	
	var value: float
	var target = attack.target
	var dmgDealt = aiUnit.combatData.Dmg - target.unitData.Stats[targetDef]
	var remHP = attack.target.unitData.CurLife - dmgDealt
	remHP = clampf(remHP, 0, 1000)
	var dmgTaken = 0
	if remHP == 0:
		value += 1
	else:
#		print(value)
		value += ((target.unitData.Stats.Life - remHP) / target.unitData.Stats.Life)
#		print(target.unitData.Stats.Life)
#		print(value)
		value = value * dmgWeight
	var accScore = aiUnit.combatData.Hit - target.combatData.Avoid
	accScore = clampf(accScore, 0, 1000)
	if accScore != 0:
		var accValue = accScore/100
		accValue = accValue - 0.5
		accValue = accValue * accScale
		var grazeProc:float  = target.combatData.GrzPrc
		var grazeScore: float = (grazeProc / 100)
		if grazeScore < 1:
#			print("grz: ", grazeScore)
#			print("b4: ",accValue)
			accValue -= grazeScore * grWeight
#			print("aft: ",accValue)
		else:
			accValue = -10
		value += accValue * accWeight
	else:
		value -= 10
	
			
	match target.combatData.Type:
		"Physical":
			dmgTaken = target.combatData.Dmg - aiUnit.unitData.Stats.Bar
		"Magic":
			dmgTaken = target.combatData.Dmg - aiUnit.unitData.Stats.Mag
			
	if aiUnit.unitData.CurLife - dmgTaken <= 0 and target.unitData.CurLife - dmgDealt > 0:
		value = value * survWeight
	return value
	
func check_safe(aiUnit, target, launch):
	var wepData = UnitData.itemData
	var distance = aHex.compute_cost(launch, target.cell, false, aiUnit.moveType,)
	var equip = target.get_equipped_weapon()
	var wepID = equip["ID"]
	var targetReach
	var safe = false
	var wep = wepData[wepID]
	if target.is_in_group("Player"):
		targetReach = wep.MaxRange
	elif target.is_in_group("Enemy"):
		targetReach = wep.MaxRange
#	if distance == 3:
#		print(launch, target.cell)
	if distance > targetReach:
		safe = true
		return safe
	else:
		return safe
	
func assign_terrain_value(map):
	var oldValue: float = 0
	var value: float = 0
	var oldRange: float = (terrainMax - terrainMin)
	var valuedTiles = {}
	for tile in map:
		oldValue = tile[2] / 10
		value = ((oldValue-(terrainMin))*newRange/oldRange) + 0

		value = value * tWeight

		valuedTiles[tile[0]] = value
	return valuedTiles
	
func assign_unit_value(team):
	var teamValues = {}
	var i = 0
	var avgLv = 0
	while i < 2:
		if i == 0:
			var total = 0
			for unit in team:
				total += unit.unitData.Profile.Level
			if team.size() != 0:
				avgLv = total / team.size()
		if i == 1:
			var oldRange: float = ((avgLv - 1) - (avgLv - 20))
			
			for unit in team:
				var oldValue: float = 0
				var value: float = 0

				oldValue += floorf(avgLv - unit.unitData.Profile.Level)
#				
				match unit.unitData.Profile.Class:
					"Lady": oldValue += 10000
				value = ((oldValue-(avgLv - 20))*newRange/oldRange) + 0
				value = value * uWeight
				if unit.is_in_group("Player"):
					var lifeValue: float = ((unit.activeStats.Life - unit.unitData.CurLife) / unit.unitData.Stats.Life)
					lifeValue = lifeValue * ulWeight
					value += lifeValue
				if unit.is_in_group("Enemy"):
					value = 1 - value
				teamValues[unit] = value
#				print(unit, " ", value)
		i += 1
	return teamValues
	
func compile_action(bestAction):
	
	var actor
	for key in bestAction:
		actor = key
	var action = bestAction[actor][0][0]
	var target = bestAction[actor][0][1]
#	var actorPath = threatArray[0][2]
	var compiledAction = [action, actor, target]
#	print(compiledAction)
	return compiledAction
	
