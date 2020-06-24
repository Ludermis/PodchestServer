extends Node

var playerCount = 0
var players = {}
var rooms = {}
var roomUniqueID = 1
var time : float = 0 setget ,getTime
var accounts = {}
var accountsByIDs = {}
var IDsByAccounts = {}

func _ready():
	pass

func _process(delta):
	pass


func getNameByID (who):
	if !accountsByIDs.has(who):
		return "Guest"
	return accountsByIDs[who]

func currentTimeToString ():
	var timeDict = OS.get_time();
	var hS = str(timeDict.hour)
	var mS = str(timeDict.minute)
	var sS = str(timeDict.second)
	if timeDict.hour < 10:
		hS = "0" + hS
	if timeDict.minute < 10:
		mS = "0" + mS
	if timeDict.second < 10:
		sS = "0" + sS
	return str("[",hS,":",mS,":",sS,"]")

func logInfo (msg):
	print ("[INFO] " + currentTimeToString() + " " + msg)

func logError (msg):
	print ("[ERROR] " + currentTimeToString() + " " + msg)

func getTime() -> float:
	return OS.get_ticks_msec() / 1000.0

func saveAccounts ():
	var save = File.new()
	save.open("user://accounts.txt",File.WRITE)
	save.store_string(JSON.print(accounts, " "))

func optimizeVector(pos, opt):
	var newv = Vector2.ZERO;
	var nx = fmod(pos.x,opt);
	var ny = fmod(pos.y,opt);
	if (nx < 0):
		nx += opt;
	if (ny < 0):
		ny += opt;
	newv.x = pos.x - nx
	newv.y = pos.y - ny;
	return newv;

func loadAccounts():
	var save = File.new()
	if not save.file_exists("user://accounts.txt"):
		return
	save.open("user://accounts.txt", File.READ)
	var data = JSON.parse(save.get_as_text()).result
	save.close()
	accounts = data
