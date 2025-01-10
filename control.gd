extends Control

# ファイルダイアログ、ボタン、テキスト編集領域への参照
@onready var open_file_dialog = $OpenFileDialog
@onready var save_file_dialog = $SaveFileDialog
@onready var open_button = $OpenButton
@onready var save_button = $SaveButton
@onready var text_edit = $TextEdit

# The URL we will connect to.
@export var websocket_url = "https://backyard.enginfo.jp:8080"
@onready var socket = WebSocketPeer.new()

#@onready var websocket = WebSocketPeer.new("https://backyard.enginfo.jp:8080")

func _ready():
	# ファイルダイアログの設定
	open_file_dialog.mode = 0  # ファイル選択モード
	open_file_dialog.access = FileDialog.ACCESS_FILESYSTEM
	open_file_dialog.filters = ["*.txt", "*.*"]

	save_file_dialog.mode = 2  # ファイル保存モード
	save_file_dialog.access = FileDialog.ACCESS_FILESYSTEM
	save_file_dialog.filters = ["*.txt", "*.*"]

	# シグナルの接続
	open_file_dialog.file_selected.connect(_on_file_open_selected)
	save_file_dialog.file_selected.connect(_on_file_save_selected)
	open_button.pressed.connect(_on_open_button_pressed)
	save_button.pressed.connect(_on_save_button_pressed)

	# Initiate connection to the given URL.
	var err = socket.connect_to_url(websocket_url)
	if err != OK:
		print("Unable to connect")
		set_process(false)
	else:
		# Wait for the socket to connect.
		await get_tree().create_timer(2).timeout

		# Send data.
		socket.send_text("Test packet")
	
func _on_open_button_pressed():
	# ファイルを開くダイアログを表示
	open_file_dialog.popup()

func _on_save_button_pressed():
	# ファイルを保存するダイアログを表示
	save_file_dialog.popup()

func _on_file_open_selected(path: String):
	# ファイルを開く
	var file = FileAccess.open(path, FileAccess.ModeFlags.READ)
	if file:
		var content = file.get_as_text()  # ファイル内容を取得
		file.close()
		text_edit.text = content  # テキスト編集領域に内容を表示
		print("File content loaded successfully.")
	else:
		text_edit.text = "Failed to open the file."
		print("Error: Unable to open the file.")

func _on_file_save_selected(path: String):
	# ファイルを保存する
	var file = FileAccess.open(path, FileAccess.ModeFlags.WRITE)
	if file:
		file.store_string(text_edit.text)  # 編集内容を保存
		file.close()
		print("File saved successfully to: ", path)
	else:
		print("Error: Unable to save the file.")


func _process(delta):
	# Call this in _process or _physics_process. Data transfer and state updates
	# will only happen when calling this function.
	socket.poll()

	# get_ready_state() tells you what state the socket is in.
	var state = socket.get_ready_state()

	# WebSocketPeer.STATE_OPEN means the socket is connected and ready
	# to send and receive data.
	if state == WebSocketPeer.STATE_OPEN:
		while socket.get_available_packet_count():
			print("Got data from server: ", socket.get_packet().get_string_from_utf8())
			$Label.text = "Got data from server: "+ socket.get_packet().get_string_from_utf8()
	# WebSocketPeer.STATE_CLOSING means the socket is closing.
	# It is important to keep polling for a clean close.
	elif state == WebSocketPeer.STATE_CLOSING:
		pass

	# WebSocketPeer.STATE_CLOSED means the connection has fully closed.
	# It is now safe to stop polling.
	elif state == WebSocketPeer.STATE_CLOSED:
		# The code will be -1 if the disconnection was not properly notified by the remote peer.
		var code = socket.get_close_code()
		print("WebSocket closed with code: %d. Clean: %s" % [code, code != -1])
		set_process(false) # Stop processing.
		$Label.text = "WebSocket closed with code: %d. Clean: %s" % [code, code != -1]
