extends Node

var room
var endPosition
var whoSummoned
var speed = 512
var planted = false
var area
var id
var materialScale = 1.0
var timeToExplode = 5
var position

func getSharedData ():
	var data = {}
	data["id"] = id
	data["materialScale"] = materialScale
	data["whoSummoned"] = whoSummoned.id
	data["position"] = position
	return data

func init ():
	pass

func update (delta):
	if timeToExplode < 0:
		for x in range(1,area / 2 + 2):
			for y in range (-area / 2 + (x - 1),area / 2 + 1 - (x - 1)):
				dirtToPos(Vars.optimizeVector(position + Vector2(32,32),64) + Vector2(y * 64, (x - 1) * 64))
		for x in range(1,area / 2 + 1):
			for y in range (-area / 2 + x,area / 2 + 1 - x):
				dirtToPos(Vars.optimizeVector(position + Vector2(32,32),64) + Vector2(y * 64, -x * 64))
		destroy()
		return
	if planted:
		timeToExplode -= delta
	else:
		position = position.move_toward(endPosition,delta * speed)
	materialScale += delta
	if planted == false && position.distance_to(endPosition) < 0.1:
		position = endPosition
		planted = true
	Vars.rooms[room].updateObject(id,getSharedData())

func dirtToPos (pos):
	if !Vars.rooms[room].dirts.has(pos):
		Vars.tryPlaceDirt(room,whoSummoned.id,pos,whoSummoned.team)
	elif Vars.rooms[room].dirts[pos].team != whoSummoned.team:
		Vars.tryChangeDirt(room,whoSummoned.id,pos,whoSummoned.team)

func destroy ():
	Vars.rooms[room].removeObject(id)
