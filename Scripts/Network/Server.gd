extends Node

var PORT = 27015
var server

func _ready():
	pass

func startServer():
	Vars.logInfo("Server starting...")
	server = WebSocketServer.new();
	server.listen(PORT, PoolStringArray(), true);
	get_tree().set_network_peer(server);
	get_tree().connect("network_peer_connected", self, "playerConnected")
	get_tree().connect("network_peer_disconnected", self, "playerDisconnected")
	Vars.logInfo("Server started!")

func _process(delta):
	if server.is_listening():
		server.poll();

func playerConnected (id):
	Vars.playerCount += 1
	Vars.players[id] = {"room": -1, "inGame": false}
	Vars.logInfo(str("User ", id, " (", Vars.getNameByID(id), ") connected with IP : " , server.get_peer_address(id)))

func playerDisconnected (id):
	if Vars.players[id]["room"] != -1 && Vars.rooms.has(Vars.players[id]["room"]):
		Vars.rooms[Vars.players[id]["room"]].playerDisconnected(id)
	Vars.playerCount -= 1
	Vars.players.erase(id)
	Vars.logInfo(str("User ", id, " (",Vars.getNameByID(id),") ", "disconnected."))
	
	if Vars.accountsByIDs.has(id):
		Vars.logInfo("User " + str(id) + " (" + Vars.getNameByID(id) + ") logged out from " + Vars.accountsByIDs[id] + " via disconnection")
		Vars.IDsByAccounts.erase(Vars.accountsByIDs[id])
		Vars.accountsByIDs.erase(id)
	
