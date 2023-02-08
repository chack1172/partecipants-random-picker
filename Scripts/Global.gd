extends Control

var IS_BROWSER = OS.get_name() == "HTML5"
var CONFIG_PATH = "res://config.json";
var config = {
	"use_api": true,
	"api_path": "http://localhost:8082"
};

var partecipantManager: Partecipant = null
var request = HTTPRequest.new()

func _ready():
	add_child(request)
	# Commented because json file is not included in res://
	# Manually change config variable
	# loadConfig()
	# Force use of api if run in browser
	if IS_BROWSER:
		config.use_api = true;
	print(config)
	partecipantManager = Partecipant.new()

func loadConfig():
	var file = File.new();
	if file.open(CONFIG_PATH, File.READ):
		var jsonConfig = JSON.parse(file.get_as_text()).result;
		for key in jsonConfig:
			config[key.to_lower()] = jsonConfig[key];
		file.close();


func createTimer(time):
	return get_tree().create_timer(time)
