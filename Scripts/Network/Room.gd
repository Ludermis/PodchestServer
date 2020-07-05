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
var roomMaster = -1
var playersFocused = {}
var mapSizeX = 50
var mapSizeY = 50

func ready():
	Vars.roomUniqueID += 1
	teams[1] = {"color": Color.from_hsv(randf(),1.0,1.0), "playerCount": 0, "score": 0}
	teams[2] = {"color": teams[1]["color"].inverted(), "playerCount": 0, "score": 0}
	Vars.logInfo("Room " + str(id) + " created.")

func findNewRoomMaster ():
	var rtn = -1
	for i in playerIDS:
		if playersFocused[i]:
			if rtn == -1:
				rtn = i
			elif Vars.players[i]["ping"] < Vars.players[rtn]["ping"]:
				rtn = i
	return rtn

func selectCharacter (who, which, skin):
	objects[who]["object"] = which
	objects[who]["data"]["skin"] = skin

func update():
	if started == true && ended == false && Vars.time - gameStartedTime >= gameLength:
		endGame()
	if selectionStarted == true && started == false && Vars.time - selectionStartedTime >= selectionLength:
		startGame()

func newUniqueObjectID():
	uniqueObjectID += 1
	while playerIDS.has(uniqueObjectID):
		uniqueObjectID += 1

func objectCreated (who, obj, data):
	newUniqueObjectID()
	data["id"] = uniqueObjectID
	objects[uniqueObjectID] = {"object": obj, "data": data}
	for i in playerIDS:
		if Vars.players[i]["inGame"]:
			main.rpc_id(i,"objectCreated",who, obj, data)

func objectUpdated (who, obj, data):
	for i in data.keys():
		objects[obj]["data"][i] = data[i]
	for i in playerIDS:
		if Vars.players[i]["inGame"] && i != who:
			main.rpc_id(i,"objectUpdated",who, obj, objects[obj]["data"])

func objectRemoved (who, obj):
	for i in playerIDS:
		if Vars.players[i]["inGame"] && i != who:
			main.rpc_id(i,"objectRemoved",who, obj)

func broadcastRoomMaster ():
	for i in playerIDS:
		main.rpc_id(i,"roomMasterChanged",roomMaster)

func playerUnfocused (who):
	playersFocused[who] = false
	if who == roomMaster:
		roomMaster = findNewRoomMaster()
		broadcastRoomMaster()

func playerFocused (who):
	playersFocused[who] = true
	if roomMaster == -1:
		roomMaster = who
		broadcastRoomMaster()

func playerJoined (who):
	playerCount += 1
	playerIDS.append(who)
	playersFocused[who] = false
	var playerTeam = 1
	if teams[2]["playerCount"] < teams[1]["playerCount"]:
		playerTeam = 2
	teams[playerTeam]["playerCount"] += 1
	Vars.players[who] = {"room": id, "ping": 0, "inGame": false}
	objects[who] = {"object": "res://Prefabs/Characters/Villager.tscn", "data": {"id": who, "skin": "", "position": Vector2(64 * mapSizeX / 2, -64 * mapSizeY / 2), "modulate": teams[playerTeam]["color"].blend(Color(1,1,1,0.5)), "team": playerTeam, "playerName": Vars.getNameByID(who)}}
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
	for i in playerIDS:
		main.rpc_id(i,"gameStarted")

func dirtCreated (who, pos, team):
	if team <= 0:
		Vars.logError("Room " + str(id) + " had a dirtCreated, but that team doesn't exist.")
		return
	if dirts.has(pos):
		#Vars.logError("Room " + str(id) + " had a dirtCreated, but a dirt already exist there.")
		return
	dirtCount += 1
	dirts[pos] = {"position": pos, "color": teams[team]["color"], "team": team}
	teams[dirts[pos]["team"]]["score"] += 1
	for i in playerIDS:
		if Vars.players[i]["inGame"]:
			main.rpc_id(i,"dirtCreated",dirts[pos])

func dirtChanged (who, pos, team):
	if team <= 0:
		Vars.logError("Room " + str(id) + " had a dirtCreated, but that team doesn't exist.")
		return
	if !dirts.has(pos):
		Vars.logError("Room " + str(id) + " had a dirtChanged, but there is no dirt there.")
		return
	teams[dirts[pos]["team"]]["score"] -= 1
	dirts[pos]["color"] = teams[team]["color"]
	dirts[pos]["team"] = team
	teams[dirts[pos]["team"]]["score"] += 1
	for i in playerIDS:
		if Vars.players[i]["inGame"]:
			main.rpc_id(i,"dirtChanged",dirts[pos])

func readyToGetObjects (who):
	if ended:
		main.rpc_id(who,"updateTeams",teams)
		main.rpc_id(who,"gameEnded",{"winner": winner, "scores": [0,teams[1]["score"],teams[2]["score"]]})
		return
	Vars.players[who]["inGame"] = true
	playerFocused(who)
	for i in playerIDS:
		main.rpc_id(i,"updateTeams",teams)
	for i in playerIDS:
		if Vars.players[i]["inGame"] && i != who:
			main.rpc_id(i,"playerJoined",who,objects[who]["object"],objects[who]["data"])
	for i in dirts:
		main.rpc_id(who,"dirtCreated",dirts[i])
	for i in playerIDS:
		if Vars.players[i]["inGame"]:
			main.rpc_id(who,"playerJoined",i,objects[i]["object"],objects[i]["data"])
	for i in objects:
		if !("Characters" in objects[i]["object"]):
			main.rpc_id(who,"objectCreated",who,objects[i]["object"],objects[i]["data"])

func demandGameTime(who, unixTime, ping):
	if started:
		Vars.players[who]["ping"] = ping
		if roomMaster != -1 && Vars.players[roomMaster]["ping"] > Vars.players[who]["ping"] + 20:
			roomMaster = who
			broadcastRoomMaster()
		main.rpc_id(who,"gotGameTime",gameLength - (Vars.time - gameStartedTime), unixTime)
	elif selectionStarted:
		main.rpc_id(who,"gotGameTime",selectionLength - (Vars.time - selectionStartedTime), unixTime)

func playerDisconnected (who):
	leaveRoom(who)

func leaveRoom (who):
	playerCount -= 1
	playerIDS.erase(who)
	playersFocused.erase(who)
	teams[objects[who]["data"]["team"]]["playerCount"] -= 1
	objects.erase(who)
	if roomMaster == who:
		roomMaster = findNewRoomMaster()
		broadcastRoomMaster()
	
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
	for i in playerIDS:
		main.rpc_id(i,"gameEnded",{"winner": winner, "scores": [0,teams[1]["score"],teams[2]["score"]]})
	Vars.logInfo("Game ended on room " + str(id))

func removeRoom (msg):
	Vars.rooms.erase(id)
	Vars.logInfo(msg)
