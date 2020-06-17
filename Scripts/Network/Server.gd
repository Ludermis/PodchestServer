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
	print(str("player ", id, " connected."))

func playerDisconnected (id):
	print(str("player ", id, " disconnected."))
	if Vars.playerIDS.has(id):
		Vars.playerIDS.erase(id)
	if Vars.players.has(id):
		Vars.players.erase(id)
