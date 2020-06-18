extends Node

var id = 0
var dirts = {}
var dirtCount = 0
var teams = {}
var playerIDS = []
var playerCount = 0
var main

func ready():
	Vars.roomUniqueID += 1
	randomize()
	var firstH = randf()
	var secondH = randf()
	while abs(firstH - secondH) < 0.4:
		secondH = randf()
	teams[1] = {"color": Color.from_hsv(firstH, 1.0, 1.0, 1.0)}
	teams[2] = {"color": Color.from_hsv(secondH, 1.0, 1.0, 1.0)}
	print("Room " + str(id) + " started.")

func playerJoined (who):
	randomize()
	playerCount += 1
	playerIDS.append(who)
	Vars.players[who] = {"room": id, "position": Vector2.ZERO, "color" : teams[((playerCount + 1) % 2) + 1]["color"], "team": ((playerCount + 1) % 2) + 1}
	main.rpc_id(who,"updateTeams",teams)
	for i in playerIDS:
		main.rpc_id(who,"playerJoined",i,Vars.players[i])
	for i in playerIDS:
		if i != who:
			main.rpc_id(i,"playerJoined",who,Vars.players[who])
	for i in dirts:
		main.rpc_id(who,"dirtCreated",dirts[i])
	print(str("user ", who," joined room ", id))

func dirtCreated (who, pos, color):
	dirtCount += 1
	dirts[pos] = {"position": pos, "color": color}
	for i in playerIDS:
		main.rpc_id(i,"dirtCreated",dirts[pos])

func dirtChanged (who, pos, color):
	dirts[pos]["color"] = color
	for i in playerIDS:
		main.rpc_id(i,"dirtChanged",dirts[pos])

func updatePosition (who, newPosition):
	Vars.players[who]["position"] = newPosition
	for i in playerIDS:
		if i != who:
			main.rpc_unreliable_id(i,"positionUpdated",who,newPosition)

func playerDisconnected (who):
	playerCount -= 1
	playerIDS.erase(who)
	for i in playerIDS:
		main.rpc_id(i,"playerDisconnected",who)

func removeRoom ():
	for i in playerIDS:
		Vars.players[i]["room"] = -1
	Vars.rooms.erase(id)
