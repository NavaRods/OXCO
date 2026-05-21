extends Panel

# Ajustamos las rutas según tu nuevo orden de nodos
@onready var input_p1 = $PopupPanel/MarginContainer/VBoxContainer/InputP1
@onready var input_p2 = $PopupPanel/MarginContainer/VBoxContainer/InputP2
@onready var check_multi = $PopupPanel/MarginContainer/VBoxContainer/CheckMultiplayer
@onready var btn_confirmar = $PopupPanel/MarginContainer/VBoxContainer/BtnConfirmar
@onready var btn_cancelar = $PopupPanel/MarginContainer/VBoxContainer/BtnCancelar
@onready var estrellas_preview = $PopupPanel/MarginContainer/VBoxContainer/SelectorDificultad/EstrellasPreview
@onready var popup_advertencia = $"../ConfirmationDialog"

@export var estrellas_referencia: AnimatedSprite2D
var estrellas_locales: int = 0

func _ready():
	input_p2.visible = false
	self.hide()
	await get_tree().process_frame
	actualizar_estrellas_ui()

# Usamos este evento para avisarle al GameManager cuál popup está activo
func _on_visibility_changed():
	if self.visible:
		GameManager.popup_creacion = self
		estrellas_locales = 0
		actualizar_estrellas_ui()

func _on_check_multiplayer_toggled(button_pressed):
	input_p2.visible = button_pressed

func _on_btn_cancelar_pressed():
	estrellas_locales = 0
	self.hide()

func _on_btn_confirmar_pressed():
	var p1 = input_p1.text.strip_edges()
	if p1 == "": return # Evitar partidas sin nombre
	
	# REGLA: Si las estrellas son > 0, advertir sobre la dificultad fija
	if estrellas_locales > 0:
		popup_advertencia.dialog_text = "Una vez seleccionada una dificultad, \nesta no podra ser cambiada\n y tampoco cambiara en el transcurso del Juego. \n¿Deseas continuar?"
		
		# Conectar la señal 'confirmed' una sola vez para ejecutar el guardado real
		if popup_advertencia.confirmed.is_connected(_ejecutar_guardado_final):
			popup_advertencia.confirmed.disconnect(_ejecutar_guardado_final)
		
		popup_advertencia.confirmed.connect(_ejecutar_guardado_final, CONNECT_ONE_SHOT)
		popup_advertencia.popup_centered()
	else:
		# Si es 0 estrellas, guarda normal sin avisar
		_ejecutar_guardado_final()


func _on_btn_menos_pressed() -> void:
	if estrellas_locales > 0:
			estrellas_locales -= 1
			actualizar_estrellas_ui()


func _on_btn_mas_pressed() -> void:
	if estrellas_locales < 5:
		estrellas_locales += 1
		actualizar_estrellas_ui()

func actualizar_estrellas_ui():
	if not estrellas_preview: return
	
	# Limpiar
	for child in estrellas_preview.get_children():
		child.queue_free()
	
	# Dibujar
	for i in range(1, 6):
		var wrapper = Control.new()
		wrapper.custom_minimum_size = Vector2(20, 20)
		
		var star = AnimatedSprite2D.new()
		if estrellas_referencia:
			star.sprite_frames = estrellas_referencia.sprite_frames
		
		star.play("llena" if i <= estrellas_locales else "vacia")
		star.scale = Vector2(0.04, 0.04) # Ajusta según tu popup
		star.position = Vector2(10, 10)
		
		wrapper.add_child(star)
		estrellas_preview.add_child(wrapper)

func _ejecutar_guardado_final():
	var p1 = input_p1.text.strip_edges()
	var p2 = input_p2.text.strip_edges() if input_p2.visible else "N/A"
	
	# Preparamos variables para la base de datos
	var es_manual = 1 if estrellas_locales > 0 else 0
	
	# Guardamos con las nuevas columnas
	DatabaseManager.guardar_nueva_partida(
		GameManager.slot_seleccionado, 
		p1, 
		p2, 
		estrellas_locales, 
		es_manual
	)
	
	self.hide()
	
	# Actualizar UI y cambiar escena
	get_tree().call_group("botones_slots", "actualizar_info_visual")
	GameManager.dinero_actual = 0
	GameManager.dia_actual = 1
	GameManager.cargar_partida(GameManager.slot_seleccionado)
