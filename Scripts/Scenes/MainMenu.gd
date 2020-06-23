extends Node2D


func _ready():
	randomize()
	Vars.loadAccounts()
	Server.startServer()

func _process(delta):
	for i in Vars.rooms:
		Vars.rooms[i].update()

remote func playerJoined (who, msg):
	if msg == "quick1v1":
		var foundRoom = -1
		for i in Vars.rooms:
			if Vars.rooms[i].ended == false && Vars.rooms[i].type == msg && Vars.rooms[i].playerCount < Vars.rooms[i].maxPlayers:
				foundRoom = Vars.rooms[i].id
		if foundRoom == -1:
			var room = preload("res://Scripts/Network/Room.gd").new()
			room.main = get_tree().root.get_node("Main")
			room.id = Vars.roomUniqueID
			room.type = "quick1v1"
			room.gameLength = 90
			room.ready()
			Vars.rooms[room.id] = room
			Vars.players[who]["room"] = room.id
			Vars.rooms[Vars.players[who]["room"]].playerJoined(who)
		else:
			Vars.players[who]["room"] = foundRoom
			Vars.rooms[Vars.players[who]["room"]].playerJoined(who)
	if msg == "quick2v2":
		var foundRoom = -1
		for i in Vars.rooms:
			if Vars.rooms[i].ended == false && Vars.rooms[i].type == msg && Vars.rooms[i].playerCount < Vars.rooms[i].maxPlayers:
				foundRoom = Vars.rooms[i].id
		if foundRoom == -1:
			var room = preload("res://Scripts/Network/Room.gd").new()
			room.main = get_tree().root.get_node("Main")
			room.id = Vars.roomUniqueID
			room.type = "quick2v2"
			room.gameLength = 90
			room.minPlayers = 4
			room.maxPlayers = 4
			room.ready()
			Vars.rooms[room.id] = room
			Vars.players[who]["room"] = room.id
			Vars.rooms[Vars.players[who]["room"]].playerJoined(who)
		else:
			Vars.players[who]["room"] = foundRoom
			Vars.rooms[Vars.players[who]["room"]].playerJoined(who)

remote func demandOnline(who):
	rpc_id(who,"updateStats",{"rooms": Vars.rooms.size(), "playerCount": Vars.playerCount})

remote func playerFocused (who):
	if Vars.rooms.has(Vars.players[who]["room"]):
		Vars.rooms[Vars.players[who]["room"]].playerFocused(who)
	else:
		Vars.logError("User" + str(who) + " tried to playerFocused but that room doesn't exists.")

remote func playerUnfocused (who):
	if Vars.rooms.has(Vars.players[who]["room"]):
		Vars.rooms[Vars.players[who]["room"]].playerUnfocused(who)
	else:
		Vars.logError("User" + str(who) + " tried to playerUnfocused but that room doesn't exists.")

remote func leaveRoom (who):
	if Vars.rooms.has(Vars.players[who]["room"]):
		Vars.rooms[Vars.players[who]["room"]].leaveRoom(who)
	else:
		Vars.logError("User" + str(who) + " tried to leaveRoom but that room doesn't exists.")

remote func demandGameTime (who, unixTime, ping):
	if Vars.rooms.has(Vars.players[who]["room"]):
		Vars.rooms[Vars.players[who]["room"]].demandGameTime(who, unixTime, ping)
	else:
		Vars.logError("User" + str(who) + " tried to demandGameTime but that room doesn't exists.")

remote func readyToGetObjects(who):
	if Vars.rooms.has(Vars.players[who]["room"]):
		Vars.rooms[Vars.players[who]["room"]].readyToGetObjects(who)
	else:
		Vars.logError("User" + str(who) + " tried to readyToGetObjects but that room doesn't exists.")

remote func dirtCreated (who, pos, team):
	if Vars.rooms.has(Vars.players[who]["room"]):
		Vars.rooms[Vars.players[who]["room"]].dirtCreated(who,pos,team)
	else:
		Vars.logError("User" + str(who) + " tried to dirtCreated but that room doesn't exists.")

remote func dirtChanged (who, pos, team):
	if Vars.rooms.has(Vars.players[who]["room"]):
		Vars.rooms[Vars.players[who]["room"]].dirtChanged(who,pos,team)
	else:
		Vars.logError("User" + str(who) + " tried to dirtChanged but that room doesn't exists.")

remote func objectCreated (who, obj, data):
	if Vars.rooms.has(Vars.players[who]["room"]):
		Vars.rooms[Vars.players[who]["room"]].objectCreated(who, obj, data)
	else:
		Vars.logError("User" + str(who) + " tried to objectCreated but that room doesn't exists.")

remote func objectUpdated (who, obj, data):
	if Vars.rooms.has(Vars.players[who]["room"]):
		Vars.rooms[Vars.players[who]["room"]].objectUpdated(who, obj, data)
	else:
		Vars.logError("User" + str(who) + " tried to objectUpdated but that room doesn't exists.")

remote func objectRemoved (who, obj):
	if Vars.rooms.has(Vars.players[who]["room"]):
		Vars.rooms[Vars.players[who]["room"]].objectRemoved(who, obj)
	else:
		Vars.logError("User" + str(who) + " tried to objectRemoved but that room doesn't exists.")

remote func registerAccount (who, username, password):
	Vars.logInfo("User " + str(who) + " tried to register a account with " + username + ":" + password)
	if Vars.accounts.has(username):
		rpc_id(who,"registerFailed","That username already exists.")
		Vars.logInfo("User " + str(who) + " couldn't register the account because username " + username + " already exists.")
	else:
		Vars.accounts[username] = {"password": password}
		Vars.saveAccounts()
		rpc_id(who,"registerCompleted")
		Vars.logInfo("User " + str(who) + " registered account " + username)

remote func logoutAccount (who):
	if !Vars.accountsByIDs.has(who):
		Vars.logError("User " + str(who) + " tried to logout, but is not logged in. WTF ?")
	else:
		Vars.logInfo("User " + str(who) + " logged out from " + Vars.accountsByIDs[who] + " via manual logout")
		Vars.accountsByIDs.erase(who)

remote func loginAccount (who, username, password):
	Vars.logInfo("User " + str(who) + " tried to login a account with " + username + ":" + password)
	if !Vars.accounts.has(username):
		rpc_id(who,"loginFailed")
		Vars.logInfo("User " + str(who) + " couldn't login to account " + username + " because it doesn't exist.")
	elif Vars.accounts[username]["password"] != password:
		rpc_id(who,"loginFailed")
		Vars.logInfo("User " + str(who) + " couldn't login to account " + username + " because the password wasn't correct.")
	else:
		rpc_id(who,"loginCompleted",Vars.accounts[username])
		Vars.accountsByIDs[who] = username
		Vars.logInfo("User " + str(who) + " logged in account " + username)
