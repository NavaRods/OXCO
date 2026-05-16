extends Button

@export var slot_index: int = 1
@export var boton_borrar_vinculado: Button 

# Referencia al nuevo Popup (Asegúrate de que la ruta sea correcta)
@onready var popup_confirmar = $"../../../ConfirmationDialog"
@onready var select = $"../../../SonidoSeleccion"
@onready var click = $"../../../SonidoClick"

func _ready():
	add_to_group("botones_slots")
	
	if boton_borrar_vinculado:
		if not boton_borrar_vinculado.pressed.is_connected(_on_btn_borrar_pressed):
			boton_borrar_vinculado.pressed.connect(_on_btn_borrar_pressed)
	
	# NUEVO: Conectar la señal de "Aceptar" del popup a nuestra función de borrado real
	# Usamos un callable para pasarle el slot_index específico
	if popup_confirmar:
		if not popup_confirmar.confirmed.is_connected(_borrar_definitivamente):
			popup_confirmar.confirmed.connect(_borrar_definitivamente)

	await get_tree().process_frame
	actualizar_info_visual()

# --- LÓGICA DE BORRADO CON CONFIRMACIÓN ---

func _on_btn_borrar_pressed():
	GameManager.slot_a_borrar = slot_index
	popup_confirmar.dialog_text = "¿Estás seguro de que quieres borrar el progreso del Slot " + str(slot_index) + "?"
	popup_confirmar.popup_centered()
	click.play()

func _borrar_definitivamente():
	# Solo el botón que coincide con el slot marcado para borrar ejecuta la acción
	if GameManager.slot_a_borrar == slot_index:
		DatabaseManager.eliminar_partida(slot_index)
		actualizar_info_visual()
		# Refrescamos todos los slots del grupo
		get_tree().call_group("botones_slots", "actualizar_info_visual")
		print("Slot ", slot_index, " borrado con éxito.")
		# Limpiamos la variable
		GameManager.slot_a_borrar = -1

# --- RESTO DEL CÓDIGO (Igual) ---

func actualizar_info_visual():
	if not DatabaseManager: return
	var datos = DatabaseManager.obtener_datos_slot(slot_index)
	
	if datos == null or datos.is_empty():
		text = "NUEVA PARTIDA\nSlot " + str(slot_index)
		if boton_borrar_vinculado: boton_borrar_vinculado.hide()
	else:
		text = str(datos["p1_name"]) + "\nDía " + str(datos["day"])
		if boton_borrar_vinculado: boton_borrar_vinculado.show()

func _on_pressed():
	if GameManager: GameManager.slot_seleccionado = slot_index
	click.play()
	var datos = DatabaseManager.obtener_datos_slot(slot_index)
	
	if datos == null or datos.is_empty():
		var nombre_popup = "/root/MainMenu/Popup" + str(slot_index)
		var popup = get_node_or_null(nombre_popup)
		if popup: popup.show()
	else:
		if GameManager: GameManager.cargar_partida(slot_index)

func _on_mouse_entered() -> void:
	select.play()
