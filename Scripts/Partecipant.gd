extends Node

class_name Partecipant

const DATA_PATH = "user://data/partecipants/partecipants.json";
const API_DATA_PATH = "http://localhost:1000/data.php";

const DEFAULT_AVATAR = "res://Assets/Images/default_avatar.png";
const DEFAULT_AUDIO = "res://Assets/Sounds/default_audio.ogg";

# signal partecipants_loaded()

# var USE_API = OS.get_name() == "HTML5"
var _data = null

func _init():
	if !Global.IS_BROWSER:
		_checkFolders()
	# yield(CommonScene.currentScene.get_tree().create_timer(0.1), "timeout")
	# loadData()

func getData() -> Dictionary:
	return _data

func loadData():
	if Global.IS_BROWSER:
		_data = yield(_loadDataFromAPI(), "completed")
	else:
		_data = yield(_loadDataFromLocal(), "completed")

func _checkFolders():
	var dir = Directory.new()
	# var dataFile = File.new()
	#Check if folders for partecipant main data file exists
	if !dir.dir_exists("user://data/partecipants/"):
		dir.make_dir_recursive("user://data/partecipants/")
	#Check if folders for partecipants files exists
	if !dir.dir_exists("user://data/partecipants/audios/"):
		dir.make_dir_recursive("user://data/partecipants/audios/")
	if !dir.dir_exists("user://data/partecipants/images/"):
		dir.make_dir_recursive("user://data/partecipants/images/")

func _loadDataFromLocal() -> Dictionary:
	yield()
	var dataFile = File.new()
	var data = []
	if (dataFile.file_exists(DATA_PATH)):
		dataFile.open(DATA_PATH, dataFile.READ)
		data = parse_json(dataFile.get_as_text())
		dataFile.close()
	return data

func _loadDataFromAPI() -> Dictionary:
	var request = Global.request

	var error = request.request(API_DATA_PATH)
	if error != OK:
		push_error("An error occured loading data.")
	else:
		var result = yield(request, "request_completed")
		result = JSON.parse(result[3].get_string_from_utf8());
		if result.error != 0 or typeof(result.result) != TYPE_DICTIONARY:
			push_error("An error occured loading data.")
		else:
			return result.result
	return {}


static func loadAvatar(partecipant) -> Texture:
	var texture: Texture = null
	if (partecipant.has_image):
		var image = Image.new()
		texture = ImageTexture.new()
		var error = image.load(partecipant.image_path)
		if error != OK:
			print("Error on load image")
			texture = load(DEFAULT_AVATAR)
		else:
			texture.create_from_image(image)
	else:
		texture = load(DEFAULT_AVATAR)

	return texture

static func loadAudio(partecipant) -> AudioStream :
	var stream: AudioStream = null
	if (partecipant.has_audio):
		var ogg_file = File.new()
		var error = ogg_file.open(partecipant.audio_path, File.READ)
		if error != OK:
			stream = load(DEFAULT_AUDIO)
		else:
			var bytes = ogg_file.get_buffer(ogg_file.get_len())
			stream = AudioStreamOGGVorbis.new()
			stream.data = bytes
			ogg_file.close()
	else:
		stream = load(DEFAULT_AUDIO)

	stream.loop = false
	return stream
