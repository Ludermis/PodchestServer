extends Node2D


func _ready():
	randomize()
	var firstH = randf()
	var secondH = randf()
	while abs(firstH - secondH) < 0.4:
		secondH = randf()
	Vars.teams[1] = {"color": Color.from_hsv(firstH, 1.0, 1.0, 1.0)}
	Vars.teams[2] = {"color": Color.from_hsv(secondH, 1.0, 1.0, 1.0)}
	Server.startServer()

remote func playerJoined (who):
	randomize()
	Vars.playerCount += 1
	Vars.playerIDS.append(who)
	Vars.players[who] = {"position": Vector2.ZERO, "color" : Vars.teams[((Vars.playerCount + 1) % 2) + 1]["color"], "team": ((Vars.playerCount + 1) % 2) + 1}
	print(str("user ", who," defined."))
	rpc_id(who,"updateTeams",Vars.teams)
	for i in Vars.playerIDS:
		rpc_id(who,"playerJoined",i,Vars.players[i])
	for i in Vars.playerIDS:
		if i != who:
			rpc_id(i,"playerJoined",who,Vars.players[who])
	for i in range(1,Vars.dirtCount + 1):
		rpc_id(who,"dirtCreated",Vars.dirts[i])

remote func dirtCreated (pos, color):
	Vars.dirtCount += 1
	Vars.dirts[Vars.dirtCount] = {"id": Vars.dirtCount, "position": pos, "color": color}
	rpc("dirtCreated",Vars.dirts[Vars.dirtCount])

remote func dirtChanged (id, color):
	Vars.dirts[id]["color"] = color
	rpc("dirtChanged",Vars.dirts[id])

remote func updatePosition (who, newPosition):
	Vars.players[who]["position"] = newPosition
	for i in Vars.playerIDS:
		if i != who:
			rpc_unreliable_id(i,"positionUpdated",who,newPosition)
