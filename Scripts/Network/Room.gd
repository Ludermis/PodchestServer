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

func ready():
	Vars.roomUniqueID += 1
	teams[1] = {"color": Color.from_hsv(randf(),1.0,1.0), "playerCount": 0, "score": 0}
	teams[2] = {"color": teams[1]["color"].inverted(), "playerCount": 0, "score": 0}
	print("Room " + str(id) + " created.")

func update():
	if started == true && ended == false && (started && Vars.time - gameStartedTime >= gameLength):
		endGame()

func playerJoined (who):
	playerCount += 1
	playerIDS.append(who)
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
	print(str("user ", who," joined room ", id, " || ", playerCount, " / ", minPlayers))
	if playerCount == minPlayers && started == false:
		startGame()

func startGame ():
	started = true
	gameStartedTime = Vars.time
	print("Game started on room " + str(id) + " with " + str(playerCount) + " players.")
	for i in playerIDS:
		main.rpc_id(i,"gameStarted")

func dirtCreated (who, pos, color):
	dirtCount += 1
	dirts[pos] = {"position": pos, "color": color, "team": Vars.players[who]["team"]}
	teams[dirts[pos]["team"]]["score"] += 1
	for i in playerIDS:
		if Vars.players[i]["inGame"]:
			main.rpc_id(i,"dirtCreated",dirts[pos])

func dirtChanged (who, pos, color):
	teams[dirts[pos]["team"]]["score"] -= 1
	dirts[pos]["color"] = color
	dirts[pos]["team"] = Vars.players[who]["team"]
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
			main.rpc_unreliable_id(i,"positionUpdated",who,newPosition)

func readyToGetObjects (who):
	Vars.players[who]["inGame"] = true
	for i in playerIDS:
		main.rpc_id(i,"updateTeams",teams)
	for i in playerIDS:
		main.rpc_id(who,"playerJoined",i,Vars.players[i])
	for i in dirts:
		main.rpc_id(who,"dirtCreated",dirts[i])

func demandGameTime(who):
	main.rpc_id(who,"gotGameTime",gameLength - (Vars.time - gameStartedTime))

func playerDisconnected (who):
	leaveRoom(who)

func leaveRoom (who):
	playerCount -= 1
	playerIDS.erase(who)
	teams[Vars.players[who]["team"]]["playerCount"] -= 1
	if started && ended == false:
		for i in playerIDS:
			if Vars.players[i]["inGame"]:
				main.rpc_id(i,"updateTeams",teams)
		for i in playerIDS:
			if Vars.players[i]["inGame"]:
				main.rpc_id(i,"playerDisconnected",who)
	print(str("user ", who," left room ", id, " || ", playerCount, " / ", minPlayers))
	if playerCount == 0:
		if ended == false:
			removeRoom(str("room ", id," is removed because no players left."))
		else:
			removeRoom(str("room ", id," is removed because game is over."))

func endGame():
	ended = true
	var winner = -1
	if teams[1]["score"] > teams[2]["score"]:
		winner = 1
	if teams[2]["score"] > teams[1]["score"]:
		winner = 2
	for i in playerIDS:
		main.rpc_id(i,"gameEnded",{"winner": winner, "scores": [0,teams[1]["score"],teams[2]["score"]]})
	print("Game ended on room " + str(id))

func removeRoom (msg):
	Vars.rooms.erase(id)
	print(msg)
