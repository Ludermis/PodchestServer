extends Node

var playerCount = 0
var players = {}
var rooms = {}
var roomUniqueID = 1
var time : float = 0 setget ,getTime
var accounts = {}
var accountsByIDs = {}
var IDsByAccounts = {}
var build = "40"
var accountsFileLocation = "user://accounts.txt"
var logsFolder = "user://logs/"
var debugTextLevel = 1
var friction = 0.2

var store = {
	"characters": {
			"Xedarin": {"gold": 450, "AP": 260}
			#"Mold": {"gold": 1350, "AP": 450}
		},
	"skins": {
			"Villager": {"Villagernaut": {"AP": 1350}}
		}
}

func _ready():
	var dir = Directory.new()
	if !dir.dir_exists(logsFolder):
		dir.open("user://")
		dir.make_dir("logs")

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

func currentDateToString ():
	var dateDict = OS.get_datetime();
	var mS = str(dateDict.day)
	var sS = str(dateDict.month)
	if dateDict.day < 10:
		mS = "0" + mS
	if dateDict.month < 10:
		sS = "0" + sS
	return str("[",mS,".",sS,".",dateDict.year,"]")

func currentDateToStringMinimal ():
	var dateDict = OS.get_datetime();
	var mS = str(dateDict.day)
	var sS = str(dateDict.month)
	if dateDict.day < 10:
		mS = "0" + mS
	if dateDict.month < 10:
		sS = "0" + sS
	return str(mS,"-",sS,"-",dateDict.year)

func listFiles(path):
	var files = []
	var dir = Directory.new()
	dir.open(path)
	dir.list_dir_begin()
	while true:
		var file = dir.get_next()
		if file == "":
			break
		elif not file.begins_with("."):
			files.append(file)
	dir.list_dir_end()
	return files

func logInfo (msg):
	var txt = "[INFO] " + currentDateToString() + " " + currentTimeToString() + " " + msg
	print (txt)
	
	var logName = currentDateToStringMinimal() + ".txt"
	
	var save = File.new()
	
	if !save.file_exists(logsFolder + logName):
		save.open(logsFolder + logName,File.WRITE)
		save.close()
	
	save.open(logsFolder + logName,File.READ_WRITE)
	save.seek_end()
	save.store_line(txt)
	save.close()

func logError (msg):
	var txt = "[ERROR] " + currentDateToString() + " " + currentTimeToString() + " " + msg
	print (txt)
	
	var logName = currentDateToStringMinimal() + ".txt"
	
	var save = File.new()
	
	if !save.file_exists(logsFolder + logName):
		save.open(logsFolder + logName,File.WRITE)
		save.close()
	
	save.open(logsFolder + logName,File.READ_WRITE)
	save.seek_end()
	save.store_line(txt)
	save.close()

func getTime() -> float:
	return OS.get_ticks_msec() / 1000.0

func saveAccounts ():
	var save = File.new()
	save.open(accountsFileLocation,File.WRITE)
	save.store_string(JSON.print(accounts, " "))
	save.close()

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

func tryPlaceDirt (room, painter, pos, team):
	if pos.x < 0 || pos.y < -(rooms[room].mapSizeY - 1) * 64 || pos.x > (rooms[room].mapSizeX - 1) * 64 || pos.y > 0:
		return
	rooms[room].dirtCreated(painter,pos,team)

func tryChangeDirt (room, painter, pos, team):
	if pos.x < 0 || pos.y < -(rooms[room].mapSizeY - 1) * 64 || pos.x > (rooms[room].mapSizeX - 1) * 64 || pos.y > 0:
		return
	rooms[room].dirtChanged(painter,pos,team)

func accountInfoCompleter(acc):
	var needSave = false
	if !accounts[acc].has("ownedCharacters"):
		accounts[acc]["ownedCharacters"] = ["Villager"]
		needSave = true
	if !accounts[acc].has("gold"):
		accounts[acc]["gold"] = 100
		needSave = true
	if !accounts[acc].has("AP"):
		accounts[acc]["AP"] = 50
		needSave = true
	if !accounts[acc].has("ownedSkins"):
		accounts[acc]["ownedSkins"] = {}
		needSave = true
	if !accounts[acc].has("auth"):
		accounts[acc]["auth"] = 1
		needSave = true
	if !accounts[acc].has("wins"):
		accounts[acc]["wins"] = 0
		needSave = true
	if !accounts[acc].has("loses"):
		accounts[acc]["loses"] = 0
		needSave = true
	if !accounts[acc].has("draws"):
		accounts[acc]["draws"] = 0
		needSave = true
	if needSave:
		Vars.saveAccounts()

func loadAccounts():
	var save = File.new()
	if not save.file_exists(accountsFileLocation):
		return
	save.open(accountsFileLocation, File.READ)
	var data = JSON.parse(save.get_as_text()).result
	save.close()
	accounts = data
