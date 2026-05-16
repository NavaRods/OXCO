extends CanvasLayer

# Referencias a los Sliders
@onready var slider_master = $Panel/VBoxContainer/SliderMaster
@onready var slider_musica = $Panel/VBoxContainer/SliderMusica
@onready var slider_sfx = $Panel/VBoxContainer/SliderSFX

func _ready():
	# Configuramos los sliders al valor actual del sistema al abrir el menú
	slider_master.value = db_to_linear(AudioServer.get_bus_volume_db(AudioServer.get_bus_index("Master")))
	slider_musica.value = db_to_linear(AudioServer.get_bus_volume_db(AudioServer.get_bus_index("Musica")))
	slider_sfx.value = db_to_linear(AudioServer.get_bus_volume_db(AudioServer.get_bus_index("SFX")))
	
	# Conectamos las señales de cambio de valor
	slider_master.value_changed.connect(_on_volume_changed.bind("Master"))
	slider_musica.value_changed.connect(_on_volume_changed.bind("Musica"))
	slider_sfx.value_changed.connect(_on_volume_changed.bind("SFX"))
	
	# Ocultamos el menú al iniciar (opcional, dependiendo de cómo lo llames)
	hide()

# Función universal para cambiar volumen
func _on_volume_changed(value: float, bus_name: String):
	var bus_index = AudioServer.get_bus_index(bus_name)
	# linear_to_db convierte el 0.0-1.0 del slider a decibelios correctamente
	AudioServer.set_bus_volume_db(bus_index, linear_to_db(value))

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
