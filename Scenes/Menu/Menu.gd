extends Control

# Called when the node enters the scene tree for the first time.
func _ready():
	# Disable exit button if run in browser
	if Global.IS_BROWSER:
		$ExitButton.visible = false
	# Wait for complete of loadData before continuing
	yield(Global.partecipantManager.loadData(), "completed")
	var data_Partecipants = Global.partecipantManager.getData()
	var counter = 0
	for currentPartecipant in data_Partecipants:
		if (data_Partecipants[currentPartecipant].active == true):
			counter = counter + 1
	if (counter <= 1):
		$StartMeetingButton.disabled = true
		$StartMeetingButton.hint_tooltip = "Per comminciare ci serve un elenco di almeno 2 partecipanti"
	else:
		$StartMeetingButton.disabled = false
		$StartMeetingButton.hint_tooltip = ""
	$GoToPartecipantsListButton.disabled = false
	$GoToPartecipantsListButton.hint_tooltip = ""

# Called every frame. 'delta' is the elapsed time since the previous frame.
# func _process(_delta):
#	pass


func _on_GoToPartecipantsListButton_pressed():
	CommonScene.goto_scene("res://Scenes/Partecipants/Partecipants.tscn")

func _on_ExitButton_pressed():
	CommonScene.quitGame()

func _on_StartMeetingButton_pressed():
	CommonScene.goto_scene("res://Scenes/Meeting/LoteryShow.tscn")
