extends CanvasLayer

# Referencias a los Sliders
@onready var slider_master = $Panel/VBoxContainer/SliderMaster
@onready var slider_musica = $Panel/VBoxContainer/SliderMusica
@onready var slider_sfx = $Panel/VBoxContainer/SliderSFX
@onready var lbl_master = $Panel/VBoxContainer/HBoxContainer/LabelMaster
@onready var lbl_musica = $Panel/VBoxContainer/HBoxContainer2/LabelMusica
@onready var lbl_sfx = $Panel/VBoxContainer/HBoxContainer3/LabelSFX

func _ready():
	# Conectar señal para sincronizar cada vez que se abra
	self.visibility_changed.connect(_sincronizar_valores)
	
	# Conexiones de señales
	slider_master.value_changed.connect(_on_volume_changed.bind("Master"))
	slider_musica.value_changed.connect(_on_volume_changed.bind("Musica"))
	slider_sfx.value_changed.connect(_on_volume_changed.bind("SFX"))
	
	_sincronizar_valores()
	hide()

func _sincronizar_valores():
	if visible:
		var m_val = db_to_linear(AudioServer.get_bus_volume_db(AudioServer.get_bus_index("Master")))
		var mu_val = db_to_linear(AudioServer.get_bus_volume_db(AudioServer.get_bus_index("Musica")))
		var s_val = db_to_linear(AudioServer.get_bus_volume_db(AudioServer.get_bus_index("SFX")))
		
		slider_master.value = m_val
		slider_musica.value = mu_val
		slider_sfx.value = s_val
		
		_actualizar_labels_pausa("Master", m_val)
		_actualizar_labels_pausa("Musica", mu_val)
		_actualizar_labels_pausa("SFX", s_val)

# Función universal para cambiar volumen
func _on_volume_changed(value: float, bus_name: String):
	var bus_index = AudioServer.get_bus_index(bus_name)
	AudioServer.set_bus_volume_db(bus_index, linear_to_db(value))
	AudioServer.set_bus_mute(bus_index, value == 0)
	_actualizar_labels_pausa(bus_name, value)

func _actualizar_labels_pausa(bus_name: String, valor: float):
	var porcentaje = str(round(valor * 100)) + "%"
	match bus_name:
		"Master": lbl_master.text = porcentaje
		"Musica": lbl_musica.text = porcentaje
		"SFX": lbl_sfx.text = porcentaje

# --- BOTONES ---

func _on_replay_pressed():
	GameManager.juego_pausado = false
	# print(GameManager.juego_pausado, " VARIABLE GLOBAL PAUSA - Configuracion")
	# Retoma el juego
	get_tree().paused = false
	hide()
	
	var btn = get_parent().get_node("BotonConfig")
	if btn:
		btn.show()

func _on_salir_menu_pressed():
	# IMPORTANTE: Despausar antes de cambiar de escena
	get_tree().paused = false
	get_tree().change_scene_to_file("res://Scenas/Menu.tscn")

# Lógica para abrir/cerrar con la tecla ESC
func _input(event):
	# Usamos el Singleton global 'Input'
	if Input.is_action_just_pressed("ui_cancel"): 
		if not visible:
			abrir_pausa()
		else:
			_on_replay_pressed()

func abrir_pausa():
	show()
	get_tree().paused = true
