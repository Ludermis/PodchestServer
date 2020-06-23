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
var gameStartedTime : float
var gameLength : float
var type = "none"
var winner
var uniqueObjectID = 0
var objects = {}
var roomMaster = -1
var playersFocused = {}

func ready():
	Vars.roomUniqueID += 1
	teams[1] = {"color": Color.from_hsv(randf(),1.0,1.0), "playerCount": 0, "score": 0}
	teams[2] = {"color": teams[1]["color"].inverted(), "playerCount": 0, "score": 0}
	Vars.logInfo("Room " + str(id) + " created.")

func findNewRoomMaster ():
	for i in playerIDS:
		if playersFocused[i]:
			return i
	return -1

func update():
	if started == true && ended == false && (started && Vars.time - gameStartedTime >= gameLength):
		endGame()

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
	Vars.players[who] = {"room": id, "position": Vector2.ZERO, "color" : teams[playerTeam]["color"], "team": playerTeam, "inGame": false}
	if started:
		main.rpc_id(who,"gameStarted")
		for i in playerIDS:
			if Vars.players[i]["inGame"]:
				main.rpc_id(i,"playerJoined",who,Vars.players[who])
	else:
		for i in playerIDS:
				main.rpc_id(i,"playerCountUpdated",playerCount,minPlayers)
	Vars.logInfo(str("User ", who," joined room ", id, " || ", playerCount, " / ", minPlayers))
	if playerCount == minPlayers && started == false:
		startGame()

func startGame ():
	started = true
	gameStartedTime = Vars.time
	Vars.logInfo("Game started on room " + str(id) + " with " + str(playerCount) + " players.")
	for i in playerIDS:
		main.rpc_id(i,"gameStarted")

func dirtCreated (who, pos, team):
	if dirts.has(pos):
		Vars.logError("Room " + str(id) + " had a dirtCreated, but a dirt already exist there.")
		return
	dirtCount += 1
	dirts[pos] = {"position": pos, "color": teams[team]["color"], "team": team}
	teams[dirts[pos]["team"]]["score"] += 1
	for i in playerIDS:
		if Vars.players[i]["inGame"]:
			main.rpc_id(i,"dirtCreated",dirts[pos])

func dirtChanged (who, pos, team):
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

func updateAnimation (who, anim):
	for i in playerIDS:
		if Vars.players[i]["inGame"] && i != who:
			main.rpc_id(i,"animationUpdated",who,anim)

func updatePosition (who, newPosition):
	Vars.players[who]["position"] = newPosition
	for i in playerIDS:
		if Vars.players[i]["inGame"] && i != who:
			main.rpc_id(i,"positionUpdated",who,newPosition)

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
		main.rpc_id(who,"playerJoined",i,Vars.players[i])
	for i in dirts:
		main.rpc_id(who,"dirtCreated",dirts[i])
	for i in objects:
		main.rpc_id(who,"objectCreated",who,objects[i]["object"],objects[i]["data"])

func demandGameTime(who):
	main.rpc_id(who,"gotGameTime",gameLength - (Vars.time - gameStartedTime))

func playerDisconnected (who):
	leaveRoom(who)

func leaveRoom (who):
	playerCount -= 1
	playerIDS.erase(who)
	playersFocused.erase(who)
	if roomMaster == who:
		roomMaster = findNewRoomMaster()
		broadcastRoomMaster()
	teams[Vars.players[who]["team"]]["playerCount"] -= 1
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
	Vars.logInfo(str("User ", who," left room ", id, " || ", playerCount, " / ", minPlayers))
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
