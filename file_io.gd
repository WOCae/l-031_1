extends Control

@onready var text_edit = $TextEdit
@onready var open_button = $OpenFileButton

func _ready():
	open_button.text = "Open File"
	open_button.pressed.connect(_on_open_file_button_pressed)

func _on_open_file_button_pressed():
	# JavaScriptでファイル選択ダイアログを開く
	JavaScript.eval("window.openFileDialog('on_file_selected');", true)

# JavaScriptからのコールバック
func on_file_selected(file_content: String):
	if file_content:
		text_edit.text = file_content
		print("File content loaded successfully.")
	else:
		print("No file selected or failed to load file content.")
