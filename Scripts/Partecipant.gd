extends Node

class_name Partecipant

const DEFAULT_AVATAR = "res://Assets/Images/default_avatar.png";
const DEFAULT_AUDIO = "res://Assets/Sounds/default_audio.ogg";

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
