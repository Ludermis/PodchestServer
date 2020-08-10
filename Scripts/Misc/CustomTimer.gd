extends Node
class_name CustomTimer

var time = 0 setget setTime
var timeLeft = 0
var working = false
var id
signal timeout

func setTime (t):
	if time == t:
		return
	time = t
	timeLeft = time

func start ():
	timeLeft = time
	working = true

func stop ():
	working = false

func update (delta):
	if !working:
		return
	timeLeft -= delta
	if timeLeft <= 0:
		emit_signal('timeout')
		timeLeft = time
