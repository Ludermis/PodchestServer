extends "res://Scripts/Base/Impact.gd"

var ownerScript
var timeRemaining
var impactName = "RootImpact"
var animStart
var animEnd
var endAnimStartTime = 0.1
var disableSkills = false

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
	if disableSkills:
		ownerScript.canUseSkills = false

func update(delta):
	ownerScript.canMove = false
	if disableSkills:
		ownerScript.canUseSkills = false
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
	if disableSkills:
		ownerScript.canUseSkills = true
