extends Control

const uuid_util = preload('res://Scripts/uuid.gd')

var path_data_Partecipants = "user://data/partecipants/partecipants.json"
var data_Partecipants = {}

var partecipantIndex = null
var currentPartecipantData = null

var action = null

func _ready():
	data_Partecipants = Global.partecipantManager.getData();
	for currentPartecipant in data_Partecipants:
		addToPartecipantsList(data_Partecipants[currentPartecipant])

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if (partecipantIndex == null):
		$DeletePartecipantButton.visible = false
		$DeletePartecipantButton.disabled = true
		$EditPartecipantButton.visible = false
		$EditPartecipantButton.disabled = true
	else:
		$DeletePartecipantButton.visible = true
		$DeletePartecipantButton.disabled = false
		$EditPartecipantButton.visible = true
		$EditPartecipantButton.disabled = false

func clearTempFiles():
	var dir = Directory.new()
	if !dir.dir_exists("user://_tmp/"):
		dir.make_dir("user://_tmp/")
	else:
		dir.remove("user://_tmp/user_image.jpg")
		dir.remove("user://_tmp/user_image.jpeg")
		dir.remove("user://_tmp/user_image.png")
		dir.remove("user://_tmp/user_audio.ogg")

func onAddEditPartecipant(newUserName, hasPicture, tmpImagePath, hasAudio, tmpAudioPath, partecipantIndex = null, partecipantId = null):
	var validNameRegEx = RegEx.new()
	var newPartecipantId = uuid_util.v4()
	var dir = Directory.new()
	var dataFile = File.new()
	
	var error = null
	var userName = ""
	var userImage = null
	var userAudio = null
	var partecipantObject = null
	
	validNameRegEx.compile("\\s+")
	userName = validNameRegEx.sub(newUserName, " ", true)
	
	if (hasPicture):
		userImage = "user://data/partecipants/images/" + userName.replace(" ", "_") + "." + tmpImagePath.get_extension()
		error = dir.copy(tmpImagePath, userImage)
		if (error != OK):
			print("Error on save image")
			return false
	if (hasAudio):
		userAudio = "user://data/partecipants/audios/" + userName.replace(" ", "_") + "." + tmpAudioPath.get_extension()
		error = dir.copy(tmpAudioPath, userAudio)
		if (error != OK):
			print("Error on save audio")
			return false

	if (partecipantIndex == null || partecipantIndex < 0):
		partecipantObject = {
			"_id": newPartecipantId,
			"name": userName,
			"has_image": hasPicture,
			"image_path": userImage,
			"has_audio": hasAudio,
			"audio_path": userAudio,
			"active": true
		}
		data_Partecipants[newPartecipantId] = partecipantObject
		dataFile.open(path_data_Partecipants, dataFile.WRITE)
		dataFile.store_line(to_json(data_Partecipants))
		dataFile.close()
		addToPartecipantsList(partecipantObject)
	else:
		partecipantObject = {
			"_id": partecipantId,
			"name": userName,
			"has_image": hasPicture,
			"image_path": userImage,
			"has_audio": hasAudio,
			"audio_path": userAudio,
			"active": currentPartecipantData.active
		}
		
		data_Partecipants[partecipantId] = partecipantObject
		dataFile.open(path_data_Partecipants, dataFile.WRITE)
		dataFile.store_line(to_json(data_Partecipants))
		dataFile.close()
		editPartecipantOnList(partecipantObject, partecipantIndex)
	return true

func addToPartecipantsList(partecipantObject):
	var texture = Partecipant.loadAvatar(partecipantObject)
	$PartecipantsList.add_item(partecipantObject.name, texture, true)
	$PartecipantsList.set_item_metadata($PartecipantsList.get_item_count() - 1, partecipantObject)

func editPartecipantOnList(partecipantObject, partecipantIndex):
	var texture = Partecipant.loadAvatar(partecipantObject)
	$PartecipantsList.set_item_text(partecipantIndex, partecipantObject.name)
	$PartecipantsList.set_item_icon(partecipantIndex, texture)
	$PartecipantsList.set_item_metadata(partecipantIndex, partecipantObject)
	_on_PartecipantsList_item_selected(partecipantIndex, true)

func _on_DeletePartecipantButton_pressed():
	if (partecipantIndex != null && currentPartecipantData != null):
		$ShowPartecipantContainer/ShowPartecipantAudioStream.stop()
		$ShowPartecipantContainer/ShowPartecipantPlayPauseButton.texture_normal = load("res://Assets/Icons/play.svg")
		var dataFile = File.new()
		var dir = Directory.new()
		data_Partecipants.erase(currentPartecipantData._id)
		dataFile.open(path_data_Partecipants, dataFile.WRITE)
		dataFile.store_line(to_json(data_Partecipants))
		dataFile.close()
		$PartecipantsList.remove_item(partecipantIndex)
		if (currentPartecipantData.has_audio):
			dir.remove(currentPartecipantData.audio_path)
		if (currentPartecipantData.has_image):
			dir.remove(currentPartecipantData.image_path)
		_on_PartecipantsList_item_selected()

func _on_EditPartecipantButton_pressed():
	if (partecipantIndex != null && currentPartecipantData != null):
		$ShowPartecipantContainer/ShowPartecipantAudioStream.stop()
		$ShowPartecipantContainer/ShowPartecipantPlayPauseButton.texture_normal = load("res://Assets/Icons/play.svg")
		$PopupModifyPartecipant.popup()

func _on_AddNewPartecipantButton_pressed():
	$PopupAddPartecipant.popup()
	
func abortAddPartecipant():
	clearTempFiles()
	$PopupAddPartecipant.hide()

func abortModifyPartecipant():
	clearTempFiles()
	$PopupModifyPartecipant.hide()

func _on_PartecipantsList_item_selected(index = -1, forced = false):
	$ShowPartecipantContainer/ShowPartecipantAudioStream.stop()
	if (index == -1 || (partecipantIndex == index && forced == false)):
		partecipantIndex = null
		$PartecipantsList.unselect(index)
		$ShowPartecipantContainer.visible = false
	else:
		partecipantIndex = index
		$ShowPartecipantContainer.visible = true
		currentPartecipantData = data_Partecipants[($PartecipantsList.get_item_metadata(partecipantIndex)._id)]
		$ShowPartecipantContainer/LabelShowPartecipant.text = currentPartecipantData.name
		var texture = Partecipant.loadAvatar(currentPartecipantData)
		$ShowPartecipantContainer/ShowPartecipantPicture.set_texture(texture)
		# Load partecipant audio in preview
		if (currentPartecipantData.has_audio):
			var stream = Partecipant.loadAudio(currentPartecipantData)
			$ShowPartecipantContainer/ShowPartecipantAudioStream.stream = stream
			$ShowPartecipantContainer/ShowPartecipantPlayPauseButton.texture_normal = load("res://Assets/Icons/play.svg")
			$ShowPartecipantContainer/ShowPartecipantPlayPauseButton.visible = true
			$ShowPartecipantContainer/ShowPartecipantPlayPauseButton.disabled = false
		else:
			$ShowPartecipantContainer/ShowPartecipantPlayPauseButton.visible = false
			$ShowPartecipantContainer/ShowPartecipantPlayPauseButton.disabled = true
		$ShowPartecipantContainer/PartecipantActiveCheckbox.visible = true
		if(currentPartecipantData.has("active")):
			$ShowPartecipantContainer/PartecipantActiveCheckbox.pressed = currentPartecipantData.active
		else:
			$ShowPartecipantContainer/PartecipantActiveCheckbox.pressed = true

func _on_PartecipantActiveCheckbox_toggled(button_pressed):
	if not (partecipantIndex == null || partecipantIndex < 0):
		var dataFile = File.new()
		var partecipantObject = {
			"_id": currentPartecipantData._id,
			"name": currentPartecipantData.name,
			"has_audio": currentPartecipantData.has_audio,
			"has_image": currentPartecipantData.has_image,
			"image_path": currentPartecipantData.image_path,
			"audio_path": currentPartecipantData.audio_path,
			"active": button_pressed
		}
		data_Partecipants[currentPartecipantData._id] = partecipantObject
		dataFile.open(path_data_Partecipants, dataFile.WRITE)
		dataFile.store_line(to_json(data_Partecipants))
		dataFile.close()
		editPartecipantOnList(partecipantObject, partecipantIndex)

func _on_ShowPartecipantAudioStream_finished():
	$ShowPartecipantContainer/ShowPartecipantPlayPauseButton.texture_normal = load("res://Assets/Icons/play.svg")

func _on_ShowPartecipantPlayPauseButton_pressed():
	if ($ShowPartecipantContainer/ShowPartecipantAudioStream.playing):
		$ShowPartecipantContainer/ShowPartecipantAudioStream.stop()
		$ShowPartecipantContainer/ShowPartecipantPlayPauseButton.texture_normal = load("res://Assets/Icons/play.svg")
	else:
		$ShowPartecipantContainer/ShowPartecipantAudioStream.play()
		$ShowPartecipantContainer/ShowPartecipantPlayPauseButton.texture_normal = load("res://Assets/Icons/pause.svg")

func _on_GoBackButton_pressed():
	CommonScene.goto_scene("res://Scenes/Menu/Menu.tscn")
