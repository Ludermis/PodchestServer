extends Node2D


func _ready():
	Server.startServer()

remote func playerJoined (who):
	randomize()
	Vars.playerIDS.append(who)
	Vars.players[who] = {"position": Vector2.ZERO, "color" : Color.from_hsv(randf(), 1.0, 1.0, 1.0)}
	print(str("user ", who," defined."))
	for i in Vars.playerIDS:
		rpc_id(who,"playerJoined",i,Vars.players[i])
	for i in Vars.playerIDS:
		if i != who:
			rpc_id(i,"playerJoined",who,Vars.players[who])

remote func updatePosition (who, newPosition):
	Vars.players[who]["position"] = newPosition
	for i in Vars.playerIDS:
		if i != who:
			rpc_unreliable_id(i,"positionUpdated",who,newPosition)
