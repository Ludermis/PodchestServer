extends Node

var id
var position
var room
var realColor
var whoSummoned

func getSharedData ():
	var data = {}
	data["id"] = id
	data["realColor"] = realColor
	data["position"] = position
	return data

func init ():
	return self

func update (delta):
	pass

func destroy ():
	#whoSummoned.fakeDirts.erase(position)
	Vars.rooms[room].removeObject(id)
