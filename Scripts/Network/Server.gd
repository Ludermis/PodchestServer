extends Node

var PORT = 27015
var server

func _ready():
	pass

func startServer():
	print("Server starting...")
	server = WebSocketServer.new();
	server.listen(PORT, PoolStringArray(), true);
	get_tree().set_network_peer(server);
	get_tree().connect("network_peer_connected", self, "playerConnected")
	get_tree().connect("network_peer_disconnected", self, "playerDisconnected")
	print("Server started.")
	

func _process(delta):
	if server.is_listening():
		server.poll();

func playerConnected (id):
	Vars.playerCount += 1
	Vars.players[id] = {"room": -1}
	print(str("player ", id, " connected."))

func playerDisconnected (id):
	print(str("player ", id, " disconnected."))
	if Vars.players[id]["room"] != -1 && Vars.rooms.has(Vars.players[id]["room"]):
		Vars.rooms[Vars.players[id]["room"]].playerDisconnected(id)
	Vars.playerCount -= 1
	Vars.players.erase(id)
