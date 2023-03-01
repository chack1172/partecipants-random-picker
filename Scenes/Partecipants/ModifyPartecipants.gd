extends Control

var node_Partecipants = null
var currentPartecipantData = null
var currentPartecipantIndex = null

enum loadingType { TYPE_EMPTY, TYPE_IMAGE, TYPE_AUDIO }

var currentLoadingType: int = loadingType.TYPE_EMPTY
var nameIsSet: bool = false
var imageIsSet: bool = false
var image64: String = ""
var imageExt: String = ""
var updateImage: bool = false
var audioIsSet: bool = false
var audio64: String = ""
var audioExt: String = ""
var updateAudio: bool = false

func _ready():
	node_Partecipants = find_parent("Partecipants")

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	if (imageIsSet):
		$ModifyPictureButton.text = ("Modificare foto")
		$RemovePictureButton.disabled = false
		$RemovePictureButton.visible = true
	else:
		$ModifyPictureButton.text = ("Aggiungere foto")
		$RemovePictureButton.disabled = true
		$RemovePictureButton.visible = false

	if (audioIsSet):
		if ($PlayPauseButton.disabled):
			$PlayPauseButton.disabled = false
		$ModifyVoiceButton.text = ("Modificare voce")
		$RemoveVoiceButton.disabled = false
		$RemoveVoiceButton.visible = true
	else:
		$PlayPauseButton.texture_normal = null
		if (!($PlayPauseButton.disabled)):
			$PlayPauseButton.disabled = true
		$ModifyVoiceButton.text = ("Aggiungere voce")
		$RemoveVoiceButton.disabled = true
		$RemoveVoiceButton.visible = false

	if(nameIsSet):
		$ModifyPartecipantFormButtons/ConfirmPartecipantButton.disabled = false
	else:
		$ModifyPartecipantFormButtons/ConfirmPartecipantButton.disabled = true

func setCurrentPartecipantImage(base64 = null, fileExt = null) -> void:
	var texture: ImageTexture = null
	if base64 != null:
		texture = Global.textureFromBase64(base64, fileExt)
		if texture == null:
			return
		image64 = base64
		imageExt = fileExt
		updateImage = true
		imageIsSet = true
	else:
		imageIsSet = currentPartecipantData.has_image
		texture = Partecipant.loadAvatar(currentPartecipantData)

	$PartecipantPictureDisplay.set_texture(texture)

func setCurrentPartecipantAudio(base64 = null, fileExt = null) -> void:
	var stream: AudioStream = null
	if base64 != null:
		audio64 = base64
		audioExt = fileExt
		updateAudio = true
		var bytes = Marshalls.base64_to_raw(base64)
		stream = AudioStreamOGGVorbis.new()
		stream.data = bytes
		audioIsSet = true
	else:
		audioIsSet = currentPartecipantData.has_audio
		stream = Partecipant.loadAudio(currentPartecipantData)

	$ModifyPartecipantAudioStream.stream = stream
	$PlayPauseButton.texture_normal = load("res://Assets/Icons/play.svg")


func _on_ModifyPictureButton_pressed():
	currentLoadingType = loadingType.TYPE_IMAGE
	var filters = ["*.png ; PNG Images","*.jpg ; JPG Images","*.jpeg ; JPEG Images"]
	file_loader_popup(filters)

func _on_ModifyVoiceButton_pressed():
	currentLoadingType = loadingType.TYPE_AUDIO
	var filters = ["*.ogg ; OGG Audio"]
	file_loader_popup(filters)

var _callback = JavaScript.create_callback(self, "_on_input_file_selected")

func file_loader_popup(filters: PoolStringArray):
	if Global.IS_BROWSER:
		var document = JavaScript.get_interface("document")
		var input = document.createElement("input")
		var accept = PoolStringArray()
		for filter in filters:
			filter = filter.split(";")[0].strip_edges().replace('*', '')
			accept.append(filter)
		input.type = "file"
		input.accept = accept.join(",")
		input.addEventListener("change", _callback)
		input.click()
		print("input clicked")
	else:
		$FileLoader.filters = PoolStringArray(filters)
		$FileLoader.popup();

var _fileReader_load_callback = JavaScript.create_callback(self, "_on_filereader_load")
var _fileReader_error_callback = JavaScript.create_callback(self, "_on_filereader_error")

func _on_input_file_selected(args):
	var window = JavaScript.get_interface("window")
	var jsFile = args[0].target.files[0];
	window.readFileBase64Async(jsFile).then(_fileReader_load_callback).catch(_fileReader_error_callback)

func _on_filereader_load(args):
	var result = args[0]
	print(result.base64);
	var base64 = result.base64.split(",", true, 1)[1]
	var jsFile = result.file
	var ext = jsFile.name.get_extension()
	_on_file_selected(base64, ext)

func _on_filereader_error(_args):
	print("Error reading file")

func _on_FileLoader_file_selected(path):
	var file: File = File.new()
	var error = file.open(path, File.READ);
	if error != OK:
		print("Error on load file")
		return
	var content = file.get_buffer(file.get_len())
	file.close()
	var base64 = Marshalls.raw_to_base64(content)
	var fileExt = path.get_extension()

	_on_file_selected(base64, fileExt)

func _on_file_selected(base64: String, fileExt: String):
	if currentLoadingType == loadingType.TYPE_IMAGE:
		setCurrentPartecipantImage(base64, fileExt)
	if currentLoadingType == loadingType.TYPE_AUDIO:
		setCurrentPartecipantAudio(base64, fileExt)
	currentLoadingType = loadingType.TYPE_EMPTY

func _on_AudioStreamPlayer_finished():
	$PlayPauseButton.texture_normal = load("res://Assets/Icons/play.svg")

func _on_TextureButton_pressed():
	$ModifyPartecipantAudioStream.play()

func _on_PlayPauseButton_pressed():
	if ($ModifyPartecipantAudioStream.playing):
		$ModifyPartecipantAudioStream.stop()
		$PlayPauseButton.texture_normal = load("res://Assets/Icons/play.svg")
	else:
		$ModifyPartecipantAudioStream.play()
		$PlayPauseButton.texture_normal = load("res://Assets/Icons/pause.svg")

func _on_NameInput_text_changed(_new_text):
	if ($NameInput.text.strip_edges().length() >= 3):
		nameIsSet = true
	else:
		nameIsSet = false

func resetPartecipantData():
	updateImage = false
	updateAudio = false
	if (currentPartecipantData.has_audio):
		setCurrentPartecipantAudio()
	else:
		resetAudio()
	if (currentPartecipantData.has_image):
		setCurrentPartecipantImage()
	else:
		resetImage()
	$NameInput.text = currentPartecipantData.name
	nameIsSet = true

func clearPartecipantData():
	nameIsSet = false
	$NameInput.text = ""
	updateImage = false
	updateAudio = false
	resetImage()
	resetAudio()

func resetImage():
	imageIsSet = false
	image64 = ""
	imageExt = ""
	$PartecipantPictureDisplay.set_texture(load(Partecipant.DEFAULT_AVATAR))

func resetAudio():
	audioIsSet = false
	audio64 = ""
	audioExt = ""
	$ModifyPartecipantAudioStream.stream = null


func _on_RemoveVoiceButton_pressed():
	updateAudio = true
	resetAudio()

func _on_RemovePictureButton_pressed():
	updateImage = true
	resetImage()

func _on_ResetPartecipantButton_pressed():
	if node_Partecipants.action == node_Partecipants.actions.MODIFY:
		resetPartecipantData()
	else:
		clearPartecipantData()

func _on_ConfirmPartecipantButton_pressed():
	var partecipantModifyed = node_Partecipants.onAddEditPartecipant($NameInput.text.strip_edges(), imageIsSet, image64, imageExt, audioIsSet, audio64, audioExt, currentPartecipantIndex, currentPartecipantData._id, updateImage, updateAudio)
	if (partecipantModifyed):
		clearPartecipantData()
		node_Partecipants.abortModifyPartecipant()

func _on_CancelPartecipantButton_pressed():
	clearPartecipantData()
	currentPartecipantData = null
	node_Partecipants.abortModifyPartecipant()

func _on_PopupModifyPartecipant_about_to_show():
	if node_Partecipants.action == node_Partecipants.actions.MODIFY:
		currentPartecipantData = node_Partecipants.currentPartecipantData
		currentPartecipantIndex = node_Partecipants.partecipantIndex
		$LabelModifyPartecipant.text = "Modifica partecipante"
		resetPartecipantData()
	else:
		currentPartecipantData = {
			"_id": null
		}
		currentPartecipantIndex = null
		$LabelModifyPartecipant.text = "Aggiungere partecipante"
		clearPartecipantData()
