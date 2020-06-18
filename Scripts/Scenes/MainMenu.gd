extends Node2D


func _ready():
	Server.startServer()

remote func playerJoined (who, msg):
	if msg == "quickgame":
		if Vars.rooms.size() == 0:
			var room = preload("res://Scripts/Network/Room.gd").new()
			room.main = get_tree().root.get_node("Main")
			room.id = Vars.roomUniqueID
			room.ready()
			Vars.rooms[room.id] = room
			Vars.players[who]["room"] = room.id
			Vars.rooms[Vars.players[who]["room"]].playerJoined(who)
		else:
			Vars.players[who]["room"] = Vars.rooms.keys()[0]
			Vars.rooms[Vars.players[who]["room"]].playerJoined(who)

remote func dirtCreated (who, pos, color):
	Vars.rooms[Vars.players[who]["room"]].dirtCreated(who,pos,color)

remote func dirtChanged (who, pos, color):
	Vars.rooms[Vars.players[who]["room"]].dirtChanged(who,pos,color)

remote func updatePosition (who, newPosition):
	Vars.rooms[Vars.players[who]["room"]].updatePosition(who,newPosition)
