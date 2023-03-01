extends Node

class_name Partecipant

const DATA_PATH = "user://data/partecipants/partecipants.json";
const IMAGES_PATH = "user://data/partecipants/images/";
const AUDIOS_PATH = "user://data/partecipants/audios/";

const API_DATA_PATH = "/data.php";
const API_UPDATE_PATH = "/update.php?id=:id";
const API_DELETE_PATH = "/delete.php?id=:id";

const DEFAULT_AVATAR = "res://Assets/Images/default_avatar.png";
const DEFAULT_AUDIO = "res://Assets/Sounds/default_audio.ogg";

# signal partecipants_loaded()

# var USE_API = OS.get_name() == "HTML5"
var _data = null

func _init():
	if !Global.config.use_api:
		_checkFolders()
	# yield(CommonScene.currentScene.get_tree().create_timer(0.1), "timeout")
	# loadData()

func getData() -> Dictionary:
	return _data

func loadData():
	if Global.config.use_api:
		_data = yield(_loadDataFromAPI(), "completed")
	else:
		_data = yield(_loadDataFromLocal(), "completed")

func update(id: String, data: Dictionary, image: String = "", audio: String = "") -> Dictionary:
	data.erase('image')
	data.erase('audio')
	print("Update " + id)
	print(data)
	var updated = null
	if Global.config.use_api:
		updated = yield(_updateAPI(id, data, image, audio), "completed")
	else:
		updated = yield(_updateLocal(id, data, image, audio), "completed")
	_data[id] = updated
	return updated

func delete(id: String) -> bool:
	var deleted = false;
	if Global.config.use_api:
		deleted = yield(_deleteAPI(id), "completed")
	else:
		deleted = yield(_deleteLocal(id), "completed")
	return deleted

func _updateAPI(id: String, data: Dictionary, image: String, audio: String) -> Dictionary:
	data["_id"] = id
	data.image = image;
	data.audio = audio;

	var request = Global.request
	var path = Global.config.api_path + API_UPDATE_PATH.replace(":id", id);
	var headers = ["Content-Type: application/json"]
	var error = request.request(path, headers, true, HTTPClient.METHOD_POST, JSON.print(data))
	if error == OK:
		var result = yield(request, "request_completed")
		result = JSON.parse(result[3].get_string_from_utf8());
		if result.error == OK and typeof(result.result) == TYPE_DICTIONARY:
			return result.result

	return {"error": "An error occured updating data."}

func _updateLocal(id: String, data: Dictionary, image: String, audio: String) -> Dictionary:
	yield(Global.createTimer(0.1), "timeout")
	# store image file
	if (data.has_image && image.length()):
		var imagePath = IMAGES_PATH + data.image_path
		var file: File = File.new()
		var error = file.open(imagePath, File.WRITE)
		if (error != OK):
			print("Error on save image")
			return {}
		file.store_buffer(Marshalls.base64_to_raw(image))
		file.close()
	# store audio file
	if (data.has_audio && audio.length()):
		var audioPath = AUDIOS_PATH + data.audio_path
		var file: File = File.new()
		var error = file.open(audioPath, File.WRITE)
		if (error != OK):
			print("Error on save audio")
			return {}
		file.store_buffer(Marshalls.base64_to_raw(audio))
		file.close()
	# Update partecipant data
	data["_id"] = id
	_data[id] = data
	# Update partecipants file
	_updateFile()
	return data

func _deleteAPI(id: String) -> bool:
	var request = Global.request
	var path = Global.config.api_path + API_DELETE_PATH.replace(":id", id);
	var error = request.request(path, [], true, HTTPClient.METHOD_DELETE)
	if error == OK:
		var result = yield(request, "request_completed")
		result = JSON.parse(result[3].get_string_from_utf8());
		if result.error == OK and typeof(result.result) == TYPE_DICTIONARY and !('error' in result.result):
			return true

	return false

func _deleteLocal(id: String) -> bool:
	yield(Global.createTimer(0.1), "timeout")
	var dir = Directory.new()
	var partecipant = _data[id];
	if (partecipant.has_audio):
		dir.remove(partecipant.audio_path)
	if (partecipant.has_image):
		dir.remove(partecipant.image_path)
	_data.erase(id)
	_updateFile()
	return true;

func _updateFile():
	var dataFile: File = File.new()
	var error = dataFile.open(DATA_PATH, dataFile.WRITE)
	if error != OK:
		print("Error updating partecipants file list")
		return false
	dataFile.store_line(to_json(_data))
	dataFile.close()

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
	yield(Global.createTimer(0.1), "timeout")
	var dataFile = File.new()
	var data = []
	if (dataFile.file_exists(DATA_PATH)):
		dataFile.open(DATA_PATH, dataFile.READ)
		data = parse_json(dataFile.get_as_text())
		dataFile.close()
	return data

func _loadDataFromAPI() -> Dictionary:
	var request = Global.request

	var error = request.request(Global.config.api_path + API_DATA_PATH)
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
		if Global.config.use_api:
			var ext = partecipant.image_path.get_extension()
			texture = Global.textureFromBase64(partecipant.image, ext)
			if texture == null:
				print("Error on load image")
		else:
			var image = Image.new()
			var path = partecipant.image_path
			if !path.begins_with(IMAGES_PATH):
				path = IMAGES_PATH + path
			var error = image.load(path)
			if error != OK:
				print("Error on load image")
			else:
				texture = ImageTexture.new()
				texture.create_from_image(image)

	if texture == null:
		texture = load(DEFAULT_AVATAR)

	return texture

static func loadAudio(partecipant) -> AudioStream :
	var stream: AudioStream = null
	if (partecipant.has_audio):
		var bytes = []
		if Global.config.use_api:
			bytes = Marshalls.base64_to_raw(partecipant.audio)
		else:
			var ogg_file = File.new()
			var error = ogg_file.open(partecipant.audio_path, File.READ)
			if error == OK:
				bytes = ogg_file.get_buffer(ogg_file.get_len())
			ogg_file.close()
		stream = AudioStreamOGGVorbis.new()
		stream.data = bytes

	if stream == null:
		stream = load(DEFAULT_AUDIO)

	stream.loop = false
	return stream
