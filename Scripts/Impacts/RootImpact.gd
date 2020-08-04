extends "res://Scripts/Base/Impact.gd"

var ownerScript
var timeRemaining
var impactName = "RootImpact"
var animStart
var animEnd
var endAnimStartTime = 0.1

func _init():
	type = "constant"

func getSharedData ():
	var data = {}
	data["timeRemaining"] = timeRemaining
	data["animStart"] = animStart
	data["animEnd"] = animEnd
	data["endAnimStartTime"] = endAnimStartTime
	data["ownerNode"] = ownerScript.id
	return data

func begin():
	ownerScript.canMove = false
	if animStart != null:
		ownerScript.animation = animStart

func update(delta):
	ownerScript.canMove = false
	timeRemaining -= delta
	if timeRemaining <= endAnimStartTime:
		if animEnd != null:
			ownerScript.animation = animEnd
	if timeRemaining <= 0:
		end()
		return

func end():
	if animEnd != null:
		ownerScript.animation = animEnd
	ownerScript.canMove = true
	ownerScript.impacts.erase(id)
