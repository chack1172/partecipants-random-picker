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

func setCurrentPartecipantImage(path = null) -> void:
	var texture: ImageTexture = null
	if path != null:
		var file: File = File.new()
		var newImage: Image = Image.new()
		var error = newImage.load(path)
		if error != OK:
			print("Error on load image")
			return
		error = file.open(path, File.READ);
		if error != OK:
			print("Error on load image")
			return
		var image = file.get_buffer(file.get_len())
		imageExt = path.get_extension()
		image64 = Marshalls.raw_to_base64(image)
		file.close()
		texture = ImageTexture.new()
		texture.create_from_image(newImage)
		imageIsSet = true
		updateImage = true
	else:
		imageIsSet = currentPartecipantData.has_image
		texture = Partecipant.loadAvatar(currentPartecipantData)

	$PartecipantPictureDisplay.set_texture(texture)

func setCurrentPartecipantAudio(path = null) -> void:
	var stream: AudioStream = null
	if path != null:
		var ogg_file = File.new()
		ogg_file.open(path, File.READ)
		var bytes = ogg_file.get_buffer(ogg_file.get_len())
		audio64 = Marshalls.raw_to_base64(bytes)
		audioExt = path.get_extension()
		stream = AudioStreamOGGVorbis.new()
		stream.data = bytes
		ogg_file.close()
		audioIsSet = true
		updateAudio = true
	else:
		audioIsSet = currentPartecipantData.has_audio
		stream = Partecipant.loadAudio(currentPartecipantData)

	$ModifyPartecipantAudioStream.stream = stream
	$PlayPauseButton.texture_normal = load("res://Assets/Icons/play.svg")


func _on_ModifyPictureButton_pressed():
	currentLoadingType = loadingType.TYPE_IMAGE
	$FileLoader.filters = PoolStringArray(["*.png ; PNG Images","*.jpg ; JPG Images","*.jpeg ; JPEG Images"])
	$FileLoader.popup();

func _on_ModifyVoiceButton_pressed():
	currentLoadingType = loadingType.TYPE_AUDIO
	$FileLoader.filters = PoolStringArray(["*.ogg ; OGG Audio"])
	$FileLoader.popup();

func _on_FileLoader_file_selected(path):
	if currentLoadingType == loadingType.TYPE_IMAGE:
		setCurrentPartecipantImage(path)
	if currentLoadingType == loadingType.TYPE_AUDIO:
		setCurrentPartecipantAudio(path)
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
