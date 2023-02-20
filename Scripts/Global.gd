extends Control

var IS_BROWSER = OS.get_name() == "HTML5"
var CONFIG_PATH = "res://config.json";
var config = {
	"use_api": true,
	"api_path": "http://localhost:8082"
};
var arguments = {}

var partecipantManager: Partecipant = null
var request: HTTPRequest = HTTPRequest.new()

func _ready():
	add_child(request)
	# Commented because json file is not included in res://
	# Manually change config variable
	# loadConfig()

	_parseArguments()
	if 'use_api' in arguments:
		config.use_api = arguments['use_api']
	if 'api_path' in arguments:
		config.api_path = arguments['api_path']

	# Force use of api if run in browser
	if IS_BROWSER:
		config.use_api = true;

	partecipantManager = Partecipant.new()

func loadConfig():
	var file = File.new();
	if file.open(CONFIG_PATH, File.READ):
		var jsonConfig = JSON.parse(file.get_as_text()).result;
		for key in jsonConfig:
			config[key.to_lower()] = jsonConfig[key];
		file.close();


func _parseArguments():
	for argument in OS.get_cmdline_args():
		# Parse valid command-line arguments into a dictionary
		if argument.find("=") > -1:
			var key_value = argument.split("=")
			arguments[key_value[0].lstrip("--")] = key_value[1]

func createTimer(time):
	return get_tree().create_timer(time)
