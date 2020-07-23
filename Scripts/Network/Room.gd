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
	teams[1] = {"color": Color.from_hsv(randf(),1.0,1.0), "playerCount": 0, "score": 0, "playerInfo": {}}
	teams[2] = {"color": teams[1]["color"].inverted(), "playerCount": 0, "score": 0, "playerInfo": {}}
	Vars.logInfo("Room " + str(id) + " created.")

func findNewRoomMaster ():
	var rtn = -1
	var curTime = OS.get_ticks_msec()
	for i in playerIDS:
		if rtn == -1:
			rtn = i
		else:
			if !Vars.players[i].has("lastSeen") || !Vars.players[rtn].has("lastSeen"):
				Vars.logError("Room " + str(id) + " had a findNewRoomMaster, but a player doesn't have lastSeen yet.")
				continue
			if (curTime - Vars.players[i]["lastSeen"]) + 7 < (curTime - Vars.players[rtn]["lastSeen"]):
				rtn = i
	return rtn

func selectCharacter (who, which, characterName, skin):
	objects[who]["object"] = which
	objects[who]["characterName"] = characterName
	objects[who]["data"]["skin"] = skin

func update():
	if roomMaster != -1:
		if Vars.players[roomMaster].has("lastSeen"):
			if OS.get_ticks_msec() - Vars.players[roomMaster]["lastSeen"] > 45:
				roomMaster = findNewRoomMaster()
				broadcastRoomMaster()
		else:
			Vars.logError("Room " + str(id) + " had a update, but room master doesn't have lastSeen.")
	if started == true && ended == false && Vars.time - gameStartedTime >= gameLength:
		endGame()
	if selectionStarted == true && started == false && Vars.time - selectionStartedTime >= selectionLength:
		startGame()

func newUniqueObjectID():
	uniqueObjectID += 1
	while playerIDS.has(uniqueObjectID):
		uniqueObjectID += 1

func objectCreated (who, obj, data):
	Vars.players[who]["lastSeen"] = OS.get_ticks_msec()
	newUniqueObjectID()
	data["id"] = uniqueObjectID
	if objects.has(data["id"]):
		Vars.logError("Room " + str(id) + " had a objectCreated, but that id is not unique.")
	objects[uniqueObjectID] = {"object": obj, "data": data}
	for i in playerIDS:
		if Vars.players[i]["inGame"]:
			main.rpc_id(i,"objectCreated",who, obj, data)

func objectUpdated (who, obj, data):
	Vars.players[who]["lastSeen"] = OS.get_ticks_msec()
	if !objects.has(obj):
		Vars.logError("Room " + str(id) + " had a objectUpdated, but that object doesn't exist anymore.")
		return
	for i in data.keys():
		objects[obj]["data"][i] = data[i]
	for i in playerIDS:
		if Vars.players[i]["inGame"] && i != who:
			main.rpc_id(i,"objectUpdated",who, obj, data)

func objectRemoved (who, obj):
	Vars.players[who]["lastSeen"] = OS.get_ticks_msec()
	if !objects.has(obj):
		Vars.logError("Room " + str(id) + " had a objectRemoved, but that object doesn't exist anymore.")
		return
	objects.erase(obj)
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
	Vars.players[who]["lastSeen"] = OS.get_ticks_msec()
	playersFocused[who] = true
	if roomMaster == -1:
		roomMaster = who
		broadcastRoomMaster()

func playerJoined (who):
	if playerIDS.has(who):
		Vars.logError("Room " + str(id) + " had a playerJoined, but that player joined already.")
		return
	if started || selectionStarted:
		Vars.logError("Room " + str(id) + " had a playerJoined, but either game or selection started.")
		return
	Vars.players[who]["lastSeen"] = OS.get_ticks_msec()
	playerCount += 1
	playerIDS.append(who)
	playersFocused[who] = false
	var playerTeam = 1
	if teams[2]["playerCount"] < teams[1]["playerCount"]:
		playerTeam = 2
	teams[playerTeam]["playerCount"] += 1
	teams[playerTeam]["playerInfo"][who] = {"name": Vars.getNameByID(who), "dirtCreatedScore": 0, "dirtChangedScore": 0}
	Vars.players[who]["room"] = id
	objects[who] = {"object": "res://Prefabs/Characters/Villager.tscn", "characterName": "Villager", "data": {"id": who, "skin": "", "position": Vector2(64 * mapSizeX / 2, -64 * mapSizeY / 2), "modulate": teams[playerTeam]["color"].blend(Color(1,1,1,0.5)), "team": playerTeam, "playerName": Vars.getNameByID(who)}}
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

func dirtCreated (who, painter, pos, team):
	if ended:
		return
	Vars.players[who]["lastSeen"] = OS.get_ticks_msec()
	if !objects.has(painter):
		#Vars.logError("Room " + str(id) + " had a dirtCreated, but painter doesn't exist.")
		return
	if dirts.has(pos):
		#Vars.logError("Room " + str(id) + " had a dirtCreated, but a dirt already exist there.")
		return
	dirtCount += 1
	dirts[pos] = {"position": pos, "color": teams[team]["color"], "team": team}
	teams[dirts[pos]["team"]]["score"] += 1
	if team == objects[painter]["data"]["team"]:
		teams[objects[painter]["data"]["team"]]["playerInfo"][painter]["dirtCreatedScore"] += 1
	else:
		teams[objects[painter]["data"]["team"]]["playerInfo"][painter]["dirtCreatedScore"] -= 1
	for i in playerIDS:
		if Vars.players[i]["inGame"]:
			main.rpc_id(i,"dirtCreated",dirts[pos])

func dirtChanged (who, painter, pos, team):
	if ended:
		return
	Vars.players[who]["lastSeen"] = OS.get_ticks_msec()
	if !objects.has(painter):
		#Vars.logError("Room " + str(id) + " had a dirtChanged, but painter doesn't exist.")
		return
	if !dirts.has(pos):
		Vars.logError("Room " + str(id) + " had a dirtChanged, but there is no dirt there.")
		return
	if dirts[pos]["team"] == team:
		#Vars.logError("Room " + str(id) + " had a dirtChanged, but the dirt is already that color.")
		return
	teams[dirts[pos]["team"]]["score"] -= 1
	dirts[pos]["color"] = teams[team]["color"]
	dirts[pos]["team"] = team
	teams[dirts[pos]["team"]]["score"] += 1
	if team == objects[painter]["data"]["team"]:
		teams[objects[painter]["data"]["team"]]["playerInfo"][painter]["dirtChangedScore"] += 1
	else:
		teams[objects[painter]["data"]["team"]]["playerInfo"][painter]["dirtChangedScore"] -= 1
	for i in playerIDS:
		if Vars.players[i]["inGame"]:
			main.rpc_id(i,"dirtChanged",dirts[pos])

func readyToGetObjects (who):
	Vars.players[who]["lastSeen"] = OS.get_ticks_msec()
	if ended:
		main.rpc_id(who,"updateTeams",teams)
		main.rpc_id(who,"gameEnded",{"winner": winner, "scores": [0,teams[1]["score"],teams[2]["score"]], "playerNames": {1: teams[1]["playerNames"], 2: teams[2]["playerNames"]}, "yourCharacter": objects[who]["characterName"], "goldEarned": -1})
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

func demandGameTime(who, unixTime):
	Vars.players[who]["lastSeen"] = OS.get_ticks_msec()
	if started:
		main.rpc_id(who,"gotGameTime",gameLength - (Vars.time - gameStartedTime), unixTime)
	elif selectionStarted:
		main.rpc_id(who,"gotGameTime",selectionLength - (Vars.time - selectionStartedTime), unixTime)

func playerDisconnected (who):
	leaveRoom(who)

func leaveRoom (who):
	if !playerIDS.has(who):
		Vars.logError("Room " + str(id) + " had a leaveRoom, but that player doesn't exist in room.")
		return
	Vars.players[who]["room"] = -1
	Vars.players[who]["inGame"] = false
	playerCount -= 1
	playerIDS.erase(who)
	playersFocused.erase(who)
	if !started:
		teams[objects[who]["data"]["team"]]["playerCount"] -= 1
		teams[objects[who]["data"]["team"]]["playerInfo"].erase(who)
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
			if objects[i]["data"]["team"] == winner:
				multiplier = 2
			goldEarned = (20 + int(randf() * 20)) * multiplier
			Vars.accounts[Vars.accountsByIDs[i]]["gold"] += goldEarned
		main.rpc_id(i,"gameEnded",{"winner": winner, "scores": [0,teams[1]["score"],teams[2]["score"]], "playerInfos": {1: teams[1]["playerInfo"], 2: teams[2]["playerInfo"]}, "yourCharacter": objects[i]["characterName"], "goldEarned": int(goldEarned)})
	Vars.saveAccounts()
	Vars.logInfo("Game ended on room " + str(id))

func removeRoom (msg):
	Vars.rooms.erase(id)
	Vars.logInfo(msg)
