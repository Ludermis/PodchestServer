extends Node2D


func _ready():
	randomize()
	Vars.loadAccounts()
	Server.startServer()

func _process(delta):
	for i in Vars.rooms:
		Vars.rooms[i].update()

remote func playerJoined (who, msg):
	Vars.logInfo("User " + str(who) + " (" + Vars.getNameByID(who) + ") called playerJoined with " + msg)
	if msg == "quick1v1":
		var foundRoom = -1
		for i in Vars.rooms:
			if Vars.rooms[i].started == false && Vars.rooms[i].ended == false && Vars.rooms[i].type == msg && Vars.rooms[i].playerCount < Vars.rooms[i].maxPlayers:
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
			if Vars.rooms[i].started == false && Vars.rooms[i].ended == false && Vars.rooms[i].type == msg && Vars.rooms[i].playerCount < Vars.rooms[i].maxPlayers:
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

remote func buyFromStore (who, what):
	if what["type"] == "skin":
		if Vars.accounts[Vars.accountsByIDs[who]]["ownedSkins"].has(what["character"]) && Vars.accounts[Vars.accountsByIDs[who]]["ownedSkins"][what["character"]].has(what["item"]):
			Vars.logError("User " + str(who) + " (" + Vars.getNameByID(who) + ") tried to buyFromStore but already has that skin.")
			return
		if !Vars.store["skins"][what["character"]][what["item"]].has(what["currency"]):
			Vars.logError("User " + str(who) + " (" + Vars.getNameByID(who) + ") tried to buyFromStore but that skin is not sold with that currency.")
			return
		if Vars.accounts[Vars.accountsByIDs[who]][what["currency"]] >= Vars.store["skins"][what["character"]][what["item"]][what["currency"]]:
			Vars.accounts[Vars.accountsByIDs[who]][what["currency"]] -= Vars.store["skins"][what["character"]][what["item"]][what["currency"]]
			if Vars.accounts[Vars.accountsByIDs[who]]["ownedSkins"].has(what["character"]):
				Vars.accounts[Vars.accountsByIDs[who]]["ownedSkins"][what["character"]].append(what["item"])
			else:
				Vars.accounts[Vars.accountsByIDs[who]]["ownedSkins"][what["character"]] = [what["item"]]
			rpc_id(who,"accountInfoRefreshed",Vars.accounts[Vars.accountsByIDs[who]])
			rpc_id(who,"buySuccessful")
	elif what["type"] == "character":
		if Vars.accounts[Vars.accountsByIDs[who]]["ownedCharacters"].has(what["item"]):
			Vars.logError("User " + str(who) + " (" + Vars.getNameByID(who) + ") tried to buyFromStore but already has that character.")
			return
		if !Vars.store["characters"][what["character"]].has(what["currency"]):
			Vars.logError("User " + str(who) + " (" + Vars.getNameByID(who) + ") tried to buyFromStore but that character is not sold with that currency.")
			return
		if Vars.accounts[Vars.accountsByIDs[who]][what["currency"]] >= Vars.store["characters"][what["character"]][what["currency"]]:
			Vars.accounts[Vars.accountsByIDs[who]][what["currency"]] -= Vars.store["characters"][what["character"]][what["currency"]]
			Vars.accounts[Vars.accountsByIDs[who]]["ownedCharacters"].append(what["item"])
			rpc_id(who,"accountInfoRefreshed",Vars.accounts[Vars.accountsByIDs[who]])
			rpc_id(who,"buySuccessful")
	Vars.saveAccounts()

remote func demandAccountInfo (who):
	if !Vars.accountsByIDs.has(who):
		Vars.logError("User " + str(who) + "had a demandAccountInfo error")
	rpc_id(who,"accountInfoRefreshed",Vars.accounts[Vars.accountsByIDs[who]])

remote func demandStore (who):
	rpc_id(who,"updateStore",Vars.store)

remote func demandOnline(who):
	rpc_id(who,"updateStats",{"rooms": Vars.rooms.size(), "playerCount": Vars.playerCount})

remote func playerFocused (who):
	if Vars.rooms.has(Vars.players[who]["room"]):
		Vars.rooms[Vars.players[who]["room"]].playerFocused(who)
	else:
		Vars.logError("User " + str(who) + " (" + Vars.getNameByID(who) + ") tried to playerFocused but that room doesn't exists.")

remote func playerUnfocused (who):
	if Vars.rooms.has(Vars.players[who]["room"]):
		Vars.rooms[Vars.players[who]["room"]].playerUnfocused(who)
	else:
		Vars.logError("User " + str(who) + " (" + Vars.getNameByID(who) +") tried to playerUnfocused but that room doesn't exists.")

remote func leaveRoom (who):
	if Vars.rooms.has(Vars.players[who]["room"]):
		Vars.rooms[Vars.players[who]["room"]].leaveRoom(who)
	else:
		Vars.logError("User " + str(who) + " (" + Vars.getNameByID(who) + ") tried to leaveRoom but that room doesn't exists.")

remote func confirmBuild (who, build):
	if Vars.build == build:
		Vars.logInfo("User " + str(who) + " (" + Vars.getNameByID(who) + ") confirmed their build.")
	else:
		Vars.logInfo("User " + str(who) + " (" + Vars.getNameByID(who) + ") could not confirm their build. [" + build + " / " + Vars.build + "]")
		rpc_id(who,"wrongBuild",Vars.build)

remote func demandGameTime (who, unixTime):
	if Vars.rooms.has(Vars.players[who]["room"]):
		Vars.rooms[Vars.players[who]["room"]].demandGameTime(who, unixTime)
	else:
		Vars.logError("User " + str(who) + " (" + Vars.getNameByID(who) + ") tried to demandGameTime but that room doesn't exists.")

remote func readyToGetObjects(who):
	if Vars.rooms.has(Vars.players[who]["room"]):
		Vars.rooms[Vars.players[who]["room"]].readyToGetObjects(who)
	else:
		Vars.logError("User " + str(who) + " (" + Vars.getNameByID(who) + ") tried to readyToGetObjects but that room doesn't exists.")

remote func dirtCreated (who, pos, team):
	if Vars.rooms.has(Vars.players[who]["room"]):
		Vars.rooms[Vars.players[who]["room"]].dirtCreated(who,pos,team)
	else:
		Vars.logError("User " + str(who) + " (" + Vars.getNameByID(who) + ") tried to dirtCreated but that room doesn't exists.")

remote func dirtChanged (who, pos, team):
	if Vars.rooms.has(Vars.players[who]["room"]):
		Vars.rooms[Vars.players[who]["room"]].dirtChanged(who,pos,team)
	else:
		Vars.logError("User " + str(who) + " (" + Vars.getNameByID(who) + ") tried to dirtChanged but that room doesn't exists.")

remote func objectCreated (who, obj, data):
	if Vars.rooms.has(Vars.players[who]["room"]):
		Vars.rooms[Vars.players[who]["room"]].objectCreated(who, obj, data)
	else:
		Vars.logError("User " + str(who) + " (" + Vars.getNameByID(who) + ") tried to objectCreated but that room doesn't exists.")

remote func selectCharacter (who, which, characterName, skin):
	if Vars.rooms.has(Vars.players[who]["room"]):
		Vars.rooms[Vars.players[who]["room"]].selectCharacter(who, which, characterName, skin)
	else:
		Vars.logError("User " + str(who) + " (" + Vars.getNameByID(who) + ") tried to selectCharacter but that room doesn't exists.")

remote func objectUpdated (who, obj, data):
	if Vars.rooms.has(Vars.players[who]["room"]):
		Vars.rooms[Vars.players[who]["room"]].objectUpdated(who, obj, data)
	else:
		Vars.logError("User " + str(who) + " (" + Vars.getNameByID(who) + ") tried to objectUpdated but that room doesn't exists.")

remote func objectRemoved (who, obj):
	if Vars.rooms.has(Vars.players[who]["room"]):
		Vars.rooms[Vars.players[who]["room"]].objectRemoved(who, obj)
	else:
		Vars.logError("User " + str(who) + " (" + Vars.getNameByID(who) + ") tried to objectRemoved but that room doesn't exists.")

remote func registerAccount (who, username, password):
	Vars.logInfo("User " + str(who) + " (" + Vars.getNameByID(who) + ") tried to register a account with " + username + ":" + password)
	if Vars.accounts.has(username):
		rpc_id(who,"registerFailed","That username already exists.")
		Vars.logInfo("User " + str(who) + " (" + Vars.getNameByID(who) + ") couldn't register the account because username " + username + " already exists.")
	else:
		Vars.accounts[username] = {"password": password}
		Vars.saveAccounts()
		rpc_id(who,"registerCompleted")
		Vars.logInfo("User " + str(who) + " (" + Vars.getNameByID(who) + ") registered account " + username)

remote func logoutAccount (who):
	if !Vars.accountsByIDs.has(who):
		Vars.logError("User " + str(who) + " (" + Vars.getNameByID(who) + ") tried to logout, but is not logged in. WTF ?")
	else:
		Vars.logInfo("User " + str(who) + " (" + Vars.getNameByID(who) + ") logged out from " + Vars.accountsByIDs[who] + " via manual logout")
		Vars.IDsByAccounts.erase(Vars.accountsByIDs[who])
		Vars.accountsByIDs.erase(who)

remote func loginAccount (who, username, password):
	Vars.logInfo("User " + str(who) + " (" + Vars.getNameByID(who) + ") tried to login a account with " + username + ":" + password)
	if !Vars.accounts.has(username):
		rpc_id(who,"loginFailed")
		Vars.logInfo("User " + str(who) + " (" + Vars.getNameByID(who) + ") couldn't login to account " + username + " because it doesn't exist.")
	elif Vars.accounts[username]["password"] != password:
		rpc_id(who,"loginFailed")
		Vars.logInfo("User " + str(who) + " (" + Vars.getNameByID(who) + ") couldn't login to account " + username + " because the password wasn't correct.")
	elif Vars.IDsByAccounts.has(username):
		rpc_id(who,"loginFailed")
		Vars.logInfo("User " + str(who) + " (" + Vars.getNameByID(who) + ") couldn't login to account " + username + " because someone is already at that account.")
	elif Vars.accountsByIDs.has(who):
		rpc_id(who,"loginFailed")
		Vars.logInfo("User " + str(who) + " (" + Vars.getNameByID(who) + ") couldn't login to account " + username + " because he is already at some account.")
	else:
		Vars.accountInfoCompleter(username)
		rpc_id(who,"loginCompleted",Vars.accounts[username])
		Vars.accountsByIDs[who] = username
		Vars.IDsByAccounts[username] = who
		Vars.logInfo("User " + str(who) + " (" + Vars.getNameByID(who) + ") logged in account " + username)
