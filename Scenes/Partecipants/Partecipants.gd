extends Control

const uuid_util = preload('res://Scripts/uuid.gd')

var path_data_Partecipants = "user://data/partecipants/partecipants.json"
var data_Partecipants = {}

var partecipantIndex = null
var currentPartecipantData = null

enum actions { ADD, MODIFY }

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

func onAddEditPartecipant(
	newUserName: String,
	hasPicture: bool,
	image64: String,
	imageExt: String,
	hasAudio: bool,
	audio64: String,
	audioExt: String,
	partecipantIndex = null,
	partecipantId = null,
	updateImage: bool = false,
	updateAudio: bool = false
):
	var validNameRegEx = RegEx.new()
	var newPartecipantId = uuid_util.v4()

	validNameRegEx.compile("\\s+")
	var userName = validNameRegEx.sub(newUserName, " ", true)
	var userImage = userName.replace(" ", "_") + "." + imageExt
	var userAudio = userName.replace(" ", "_") + "." + audioExt

	# if !Global.config.use_api:
	var partecipantObject = {
		"name": userName,
		"active": true,
		"has_image": false,
		"image_path": '',
		"has_audio": false,
		"audio_path": ''
	}
	if updateImage:
		partecipantObject.has_image = hasPicture
		if hasPicture:
			partecipantObject.image_path = userImage
	else:
		image64 = ''

	if updateAudio:
		partecipantObject.has_audio = hasAudio
		if hasAudio:
			partecipantObject.audio_path = userAudio
	else:
		audio64 = ''

	if (partecipantIndex == null || partecipantIndex < 0):
		partecipantObject = yield(Global.partecipantManager.update(newPartecipantId, partecipantObject, image64, audio64), "completed")
		if !('error' in partecipantObject):
			addToPartecipantsList(partecipantObject)
	else:
		var currentPartecipant = data_Partecipants[partecipantId]
		if !updateImage:
			partecipantObject.has_image = currentPartecipant.has_image
			partecipantObject.image_path = currentPartecipant.image_path
		if !updateAudio:
			partecipantObject.has_audio = currentPartecipant.has_audio
			partecipantObject.audio_path = currentPartecipant.audio_path
		partecipantObject.active = currentPartecipantData.active
		partecipantObject = yield(Global.partecipantManager.update(partecipantId, partecipantObject, image64, audio64), "completed")
		if !('error' in partecipantObject):
			editPartecipantOnList(partecipantObject, partecipantIndex)
	data_Partecipants = Global.partecipantManager.getData()
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
		Global.partecipantManager.delete(currentPartecipantData._id)
		data_Partecipants.erase(currentPartecipantData._id)
		$PartecipantsList.remove_item(partecipantIndex)
		_on_PartecipantsList_item_selected()

func _on_EditPartecipantButton_pressed():
	if (partecipantIndex != null && currentPartecipantData != null):
		$ShowPartecipantContainer/ShowPartecipantAudioStream.stop()
		$ShowPartecipantContainer/ShowPartecipantPlayPauseButton.texture_normal = load("res://Assets/Icons/play.svg")
		action = actions.MODIFY
		$PopupModifyPartecipant.popup()

func _on_AddNewPartecipantButton_pressed():
#	$PopupAddPartecipant.popup()
	action = actions.ADD
	$PopupModifyPartecipant.popup()

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
	if not (partecipantIndex == null || partecipantIndex < 0 || currentPartecipantData.active == button_pressed):
		currentPartecipantData.active = button_pressed
		data_Partecipants[currentPartecipantData._id].active = button_pressed
		Global.partecipantManager.update(currentPartecipantData._id, currentPartecipantData, "", "")
		editPartecipantOnList(currentPartecipantData, partecipantIndex)

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
