extends Control

# --- CONSTANTES Y CONFIGURACIÓN ---
const DESPLAZAMIENTO_AJUSTES = 638
const ZOOM_FINAL = Vector2(10.0, 10.0)

# --- NODOS DEL "ASCENSOR" (PANEL) ---
@onready var panel_contenido = $PanelContenido

# --- ELEMENTOS DE LA FACHADA (PARTE INFERIOR) ---
@onready var puerta_anim = $PanelContenido/FondoInferior
@onready var sprite_play = $PanelContenido/SpritesPlay
@onready var boton_puerta = $PanelContenido/BotonPuerta
@onready var botonconf = $PanelContenido/BotonConfiguracion
@onready var botonret = $PanelContenido/BotonReturn

# --- ELEMENTOS DE AJUSTES (PARTE SUPERIOR) ---
@onready var sprite_ajustes = $PanelContenido/SpriteAjustes
@onready var slider_master = $PanelContenido/VBoxContainer/SliderMaster
@onready var slider_musica = $PanelContenido/VBoxContainer/SliderMusica
@onready var slider_sfx = $PanelContenido/VBoxContainer/SliderSFX
@onready var lbl_master = $PanelContenido/VBoxContainer/HBoxContainer/LabelMaster
@onready var lbl_musica = $PanelContenido/VBoxContainer/HBoxContainer2/LabelMusica
@onready var lbl_sfx = $PanelContenido/VBoxContainer/HBoxContainer3/LabelSFX

# --- AUDIO ---
@onready var musica_fondo = $MusicaFondo
@onready var musica_ambiente_1 = $MusicaAmbiente_1
@onready var sonidos_puerta = $SonidosPuerta
@onready var sonido_conf = $SonidoCartel

var audios_abrir = [
	preload("res://Sounds/SonidosExternos/Puerta/qubodup-DoorOpen01.ogg"),
	preload("res://Sounds/SonidosExternos/Puerta/qubodup-DoorOpen02.ogg"),
	preload("res://Sounds/SonidosExternos/Puerta/qubodup-DoorOpen03.ogg"),
	preload("res://Sounds/SonidosExternos/Puerta/qubodup-DoorOpen04.ogg"),
	preload("res://Sounds/SonidosExternos/Puerta/qubodup-DoorOpen05.ogg"),
	preload("res://Sounds/SonidosExternos/Puerta/qubodup-DoorOpen06.ogg"),
	preload("res://Sounds/SonidosExternos/Puerta/qubodup-DoorOpen07.ogg"),
	preload("res://Sounds/SonidosExternos/Puerta/qubodup-DoorOpen08.ogg")
]

var audios_cerrar = [
	preload("res://Sounds/SonidosExternos/Puerta/qubodup-DoorClose01.ogg"),
	preload("res://Sounds/SonidosExternos/Puerta/qubodup-DoorClose02.ogg"),
	preload("res://Sounds/SonidosExternos/Puerta/qubodup-DoorClose03.ogg"),
	preload("res://Sounds/SonidosExternos/Puerta/qubodup-DoorClose04.ogg"),
	preload("res://Sounds/SonidosExternos/Puerta/qubodup-DoorClose05.ogg"),
	preload("res://Sounds/SonidosExternos/Puerta/qubodup-DoorClose06.ogg"),
	preload("res://Sounds/SonidosExternos/Puerta/qubodup-DoorClose07.ogg"),
	preload("res://Sounds/SonidosExternos/Puerta/qubodup-DoorClose08.ogg")
]

# --- CICLO DE VIDA ---

func _ready():
	_configurar_estado_inicial()
	_cargar_valores_audio()

func _configurar_estado_inicial():
	puerta_anim.play("Menu1")
	sprite_play.visible = true
	panel_contenido.position.y = 0
	pivot_offset = Vector2(576, 324)
	botonret.hide()

func _cargar_valores_audio():
	var master_val = db_to_linear(AudioServer.get_bus_volume_db(AudioServer.get_bus_index("Master")))
	var musica_val = db_to_linear(AudioServer.get_bus_volume_db(AudioServer.get_bus_index("Musica")))
	var sfx_val = db_to_linear(AudioServer.get_bus_volume_db(AudioServer.get_bus_index("SFX")))
	
	slider_master.value = master_val
	slider_musica.value = musica_val
	slider_sfx.value = sfx_val
	
	# Actualizar etiquetas al cargar
	_actualizar_texto_porcentaje("Master", master_val)
	_actualizar_texto_porcentaje("Musica", musica_val)
	_actualizar_texto_porcentaje("SFX", sfx_val)
# --- INTERACCIÓN: FACHADA (PUERTA) ---

func _on_boton_puerta_mouse_entered():
	puerta_anim.play("Menu2")
	sprite_play.visible = false
	reproducir_sonido_puerta(true) # Sonido al abrir

func _on_boton_puerta_mouse_exited():
	puerta_anim.play("Menu1")
	sprite_play.visible = true
	reproducir_sonido_puerta(false) # Sonido al cerrar

func _on_boton_puerta_pressed():
	boton_puerta.disabled = true
	pivot_offset = boton_puerta.position + (boton_puerta.size / 2)

	var tween = create_tween().set_parallel(true)
	tween.set_trans(Tween.TRANS_QUINT).set_ease(Tween.EASE_IN)
	
	tween.tween_property(self, "scale", ZOOM_FINAL, 1.0)
	tween.tween_property(self, "modulate:a", 0.0, 0.8)
	
	tween.chain().tween_callback(_cambiar_escena)
	$SonidosPuerta.stop()

# --- INTERACCIÓN: AJUSTES (DESPLAZAMIENTO) ---

func _on_boton_configuracion_pressed():
	botonconf.hide()
	botonret.show()
	sonido_conf.play()
	_desplazar_panel(DESPLAZAMIENTO_AJUSTES)
	

func _on_boton_return_pressed():
	botonret.hide()
	botonconf.show()
	sonido_conf.play()
	_desplazar_panel(0)

func _desplazar_panel(destino_y: float):
	var tween = create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(panel_contenido, "position:y", destino_y, 0.5)

# --- SISTEMA DE AUDIO (SLIDERS Y SFX) ---

func _on_slider_master_value_changed(value: float):
	_actualizar_bus_audio("Master", value)

func _on_slider_musica_value_changed(value: float):
	_actualizar_bus_audio("Musica", value)

func _on_slider_sfx_value_changed(value: float):
	_actualizar_bus_audio("SFX", value)

func _actualizar_bus_audio(nombre_bus: String, valor: float):
	var index = AudioServer.get_bus_index(nombre_bus)
	AudioServer.set_bus_volume_db(index, linear_to_db(valor))
	AudioServer.set_bus_mute(index, valor == 0)
	_actualizar_texto_porcentaje(nombre_bus, valor)

func _actualizar_texto_porcentaje(nombre_bus: String, valor: float):
	var porcentaje = str(round(valor * 100)) + "%"
	match nombre_bus:
		"Master": lbl_master.text = porcentaje
		"Musica": lbl_musica.text = porcentaje
		"SFX": lbl_sfx.text = porcentaje

func reproducir_sonido_puerta(abriendo: bool):
	var lista = audios_abrir if abriendo else audios_cerrar
	sonidos_puerta.stream = lista.pick_random()
	sonidos_puerta.pitch_scale = randf_range(0.9, 1.1)
	sonidos_puerta.play()

# --- NAVEGACIÓN ---

func _cambiar_escena():
	# Cambia a la escena del juego principal
	get_tree().change_scene_to_file("res://Scenas/MainMenu.tscn")
