extends Node

var id = 0
var dirts = {}
var dirtCount = 0
var teams = {}
var playerIDS = []
var playerCount = 0
var main
var minPlayers = 2
var maxPlayers = 2
var started = false
var ended = false
var selectionStarted = false
var gameStartedTime : float
var gameLength : float
var selectionStartedTime : float
var selectionLength : float = 8
var type = "none"
var winner
var uniqueObjectID = 0
var objects = {}
var mapSizeX = 50
var mapSizeY = 50
var gridSize = 64
var space : RID
var roomBorders

func ready():
	Vars.roomUniqueID += 1
	space = Physics2DServer.space_create()
	Physics2DServer.space_set_active(space,true)
	roomBorders = preload("res://Scripts/Misc/RoomBorders.gd").new()
	roomBorders.position = Vector2(0,0)
	roomBorders.room = id
	roomBorders.main = main
	roomBorders.init()
	teams[1] = {"color": Color.from_hsv(randf(),1.0,1.0), "playerCount": 0, "score": 0, "playerInfo": {}}
	teams[2] = {"color": teams[1]["color"].inverted(), "playerCount": 0, "score": 0, "playerInfo": {}}
	Vars.logInfo("Room " + str(id) + " created.")

func selectCharacter (who, which, characterName, skin):
	objects[who]["object"] = which
	objects[who]["instance"] = load("res://Scripts/Characters/" + characterName + ".gd").new()
	objects[who]["instance"]["characterName"] = characterName
	objects[who]["instance"]["skin"] = skin
	objects[who]["instance"]["main"] = main
	objects[who]["instance"]["room"] = id
	objects[who]["instance"]["id"] = who
	objects[who]["instance"]["team"] = objects[who]["team"]
	objects[who]["instance"]["playerName"] = Vars.getNameByID(who)
	objects[who]["instance"]["position"] = Vector2(gridSize * mapSizeX / 2, -gridSize * mapSizeY / 2)

func update(delta):
	if started == true && ended == false && Vars.time - gameStartedTime >= gameLength:
		endGame()
	if selectionStarted == true && started == false && Vars.time - selectionStartedTime >= selectionLength:
		startGame()
	if started && !ended:
		for i in objects:
			objects[i]["instance"].update(delta)

func newUniqueObjectID():
	uniqueObjectID += 1
	while playerIDS.has(uniqueObjectID):
		uniqueObjectID += 1

func objectUpdated (who, obj, data):
	if !objects.has(obj):
		if Vars.debugTextLevel >= 1:
			Vars.logError("Room " + str(id) + " had a objectUpdated, but that object doesn't exist anymore.")
		return
	for i in data:
		objects[obj]["instance"][i] = data[i]

func objectCalled (who, obj, funcName, data):
	if !objects.has(obj):
		if Vars.debugTextLevel >= 1:
			Vars.logError("Room " + str(id) + " had a objectCalled, but that object doesn't exist anymore.")
		return

func playerJoined (who):
	if playerIDS.has(who):
		if Vars.debugTextLevel >= 1:
			Vars.logError("Room " + str(id) + " had a playerJoined, but that player joined already.")
		return
	if started || selectionStarted:
		if Vars.debugTextLevel >= 1:
			Vars.logError("Room " + str(id) + " had a playerJoined, but either game or selection started.")
		return
	playerCount += 1
	playerIDS.append(who)
	var playerTeam = 1
	if teams[2]["playerCount"] < teams[1]["playerCount"]:
		playerTeam = 2
	teams[playerTeam]["playerCount"] += 1
	teams[playerTeam]["playerInfo"][who] = {"name": Vars.getNameByID(who), "dirtCreatedScore": 0, "dirtChangedScore": 0}
	Vars.players[who]["room"] = id
	objects[who] = {"team": playerTeam}
	selectCharacter(who,"res://Prefabs/Characters/Villager.tscn","Villager","")
	for i in playerIDS:
		main.rpc_id(i,"playerCountUpdated",playerCount,minPlayers)
	if started:
		main.rpc_id(who,"gameStarted")
	Vars.logInfo(str("User ", who, " (", Vars.getNameByID(who), ") joined room ", id, " [", playerCount, " / ", minPlayers, "]"))
	if playerCount == minPlayers && selectionStarted == false:
		selectionStarted = true
		selectionStartedTime = Vars.time
		for i in playerIDS:
			main.rpc_id(i,"selectionStarted")

func startGame ():
	started = true
	gameStartedTime = Vars.time
	Vars.logInfo("Game started on room " + str(id) + " with " + str(playerCount) + " players.")
	for i in objects:
		objects[i]["instance"].init()
	for i in playerIDS:
		main.rpc_id(i,"gameStarted")

func readyToGetObjects (who):
	if ended:
		main.rpc_id(who,"updateTeams",teams)
		main.rpc_id(who,"gameEnded",{"winner": winner, "scores": [0,teams[1]["score"],teams[2]["score"]], "playerNames": {1: teams[1]["playerNames"], 2: teams[2]["playerNames"]}, "yourCharacter": objects[who]["instance"]["characterName"], "goldEarned": -1})
		return
	Vars.players[who]["inGame"] = true
	for i in playerIDS:
		main.rpc_id(i,"updateTeams",teams)
	for i in playerIDS:
		if Vars.players[i]["inGame"] && i != who:
			main.rpc_id(i,"playerJoined",who,objects[who]["object"],objects[who]["instance"].getSharedData())
	for i in dirts:
		main.rpc_id(who,"dirtCreated",dirts[i])
	for i in playerIDS:
		main.rpc_id(who,"playerJoined",i,objects[i]["object"],objects[i]["instance"].getSharedData())
	for i in objects:
		if !("Characters" in objects[i]["object"]):
			main.rpc_id(who,"objectCreated",who,objects[i]["object"],objects[who]["instance"].getSharedData())

func demandGameTime(who, unixTime):
	if started:
		main.rpc_id(who,"gotGameTime",gameLength - (Vars.time - gameStartedTime), unixTime)
	elif selectionStarted:
		main.rpc_id(who,"gotGameTime",selectionLength - (Vars.time - selectionStartedTime), unixTime)

func playerDisconnected (who):
	leaveRoom(who)

func leaveRoom (who):
	if !playerIDS.has(who):
		if Vars.debugTextLevel >= 1:
			Vars.logError("Room " + str(id) + " had a leaveRoom, but that player doesn't exist in room.")
		return
	Vars.players[who]["room"] = -1
	Vars.players[who]["inGame"] = false
	playerCount -= 1
	playerIDS.erase(who)
	if !started:
		teams[objects[who]["instance"]["team"]]["playerCount"] -= 1
		teams[objects[who]["instance"]["team"]]["playerInfo"].erase(who)
	objects.erase(who)
	
	if started && ended == false:
		for i in playerIDS:
			if Vars.players[i]["inGame"]:
				main.rpc_id(i,"updateTeams",teams)
		for i in playerIDS:
			if Vars.players[i]["inGame"]:
				main.rpc_id(i,"playerDisconnected",who)
	if !started:
		for i in playerIDS:
			main.rpc_id(i,"playerCountUpdated",playerCount,minPlayers)
	Vars.logInfo(str("User ", who, " (", Vars.getNameByID(who), ") left room ", id, " [", playerCount, " / ", minPlayers, "]"))
	if playerCount == 0:
		if ended == false:
			removeRoom(str("Room ", id," is removed because no players left."))
		else:
			removeRoom(str("Room ", id," is removed because game is over."))

func endGame():
	ended = true
	winner = -1
	if teams[1]["score"] > teams[2]["score"]:
		winner = 1
	if teams[2]["score"] > teams[1]["score"]:
		winner = 2
	
	for t in range(1,2 + 1):
		for i in teams[t]["playerInfo"]:
			var pName = teams[t]["playerInfo"][i]["name"]
			if pName == "Guest":
				continue
			if winner == -1:
				Vars.accounts[pName]["draws"] += 1
			elif winner == t:
				Vars.accounts[pName]["wins"] += 1
			else:
				Vars.accounts[pName]["loses"] += 1
	
	for i in playerIDS:
		var goldEarned = 0
		if Vars.getNameByID(i) != "Guest":
			var multiplier = 1
			if objects[i]["instance"]["team"] == winner:
				multiplier = 2
			goldEarned = (20 + int(randf() * 20)) * multiplier
			Vars.accounts[Vars.accountsByIDs[i]]["gold"] += goldEarned
		main.rpc_id(i,"gameEnded",{"winner": winner, "scores": [0,teams[1]["score"],teams[2]["score"]], "playerInfos": {1: teams[1]["playerInfo"], 2: teams[2]["playerInfo"]}, "yourCharacter": objects[i]["instance"]["characterName"], "goldEarned": int(goldEarned)})
	Vars.saveAccounts()
	Vars.logInfo("Game ended on room " + str(id))

func removeRoom (msg):
	Vars.rooms.erase(id)
	Vars.logInfo(msg)
