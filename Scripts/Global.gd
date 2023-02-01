extends Node

var IS_BROWSER = OS.get_name() == "HTML5"
var request = HTTPRequest.new()

var partecipantManager: Partecipant = null

func _ready():
    add_child(request)
    partecipantManager = Partecipant.new()
