extends Button

@export var slot_index: int = 1
@export var boton_borrar_vinculado: Button 
@export var contenedor_estrellas: HBoxContainer
@export var estrellas_recurso: AnimatedSprite2D

# Referencia al nuevo Popup (Asegúrate de que la ruta sea correcta)
@onready var popup_confirmar = $"../../../ConfirmationDialog"
@onready var select = $"../../../SonidoSeleccion"
@onready var click = $"../../../SonidoClick"

var estilo_ocupado: StyleBoxFlat
var estilo_vacio: StyleBoxFlat

func _ready():
	add_to_group("botones_slots")
	# Configuración de Estilo Ocupado (Verde o Azul con bordes)
	estilo_ocupado = StyleBoxFlat.new()
	estilo_ocupado.bg_color = Color("2e3c50") # Un azul oscuro elegante
	estilo_ocupado.border_width_bottom = 5
	estilo_ocupado.border_color = Color("4a90e2") # Borde brillante
	estilo_ocupado.set_corner_radius_all(10)
	
	# Configuración de Estilo Vacío (Gris translúcido)
	estilo_vacio = StyleBoxFlat.new()
	estilo_vacio.bg_color = Color(0.1, 0.1, 0.1, 0.4) # Casi transparente
	estilo_vacio.set_border_width_all(2)
	estilo_vacio.border_color = Color(0.3, 0.3, 0.3)
	estilo_vacio.set_corner_radius_all(10)
	
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
	popup_confirmar.dialog_text = "¿Estas seguro de que quieres renunciar al progreso de la CAJA " + str(slot_index) + "?"
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
	
	var estilo = StyleBoxFlat.new()
	var estilo_hover = StyleBoxFlat.new()
	
	if contenedor_estrellas:
		for child in contenedor_estrellas.get_children():
			child.queue_free()
	
	if datos == null or datos.is_empty():
		# --- ESTILO SLOT VACÍO ---
		text = "\n\n+\nNUEVA PARTIDA\n(CAJA " + str(slot_index) + ")"
		
		# (Configuración de estilo vacío)
		estilo.bg_color = Color(0.2, 0.2, 0.2, 0.5)
		estilo.set_corner_radius_all(10)
		estilo_hover.bg_color = Color(0.3, 0.3, 0.3, 0.6)
		estilo_hover.set_corner_radius_all(10)
		
		add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
		if boton_borrar_vinculado: boton_borrar_vinculado.hide()
		if contenedor_estrellas: contenedor_estrellas.hide()
	else:
		if contenedor_estrellas: contenedor_estrellas.show()
		# --- EXTRAER DATOS DE TU TABLA ---
		var nombre_completo = str(datos.get("p1_name", "---")).to_upper()
		var nombre = nombre_completo if nombre_completo.length() <= 6 else nombre_completo.left(6) + ".."
		var p2_name = str(datos.get("p2_name", "N/A"))
		var dia = str(datos.get("day", 1))
		var dinero = str(snapped(datos.get("money", 0), 0.01))
		var reputacion = datos.get("reputation", 0.0) # Nota: revisa si en tu DB es 'reputatin' por el typo que pusiste o 'reputation'
		
		# --- LÓGICA DE JUGADORES (Basado en p2_name) ---
		var texto_jugadores = "MODO: SOLO" if p2_name == "N/A" else "MODO: COOP"
		
		# --- LÓGICA DE ESTRELLAS Y DIFICULTAD ---
		var cantidad_estrellas = int(clamp(reputacion / 50.0, 0, 5))
		var dificultad_texto = "NORMAL"
		if cantidad_estrellas >= 3 and cantidad_estrellas <= 4: dificultad_texto = "POPULAR"
		elif cantidad_estrellas >= 5: dificultad_texto = "A LO LOCO"
		
		_generar_estrellas_visuales(cantidad_estrellas)
		
		# --- CONSTRUCCIÓN DEL TEXTO ---
		text = "CAJA " + nombre + "\n"
		text += "___________\n"
		text += texto_jugadores + "\n"
		text += "DIA: " + dia + "\n"
		text += "$" + dinero + "\n"
		text += "\n[                  ]" 
		text += "\n[" + dificultad_texto + "]\n"

		# --- CONFIGURACIÓN DE ESTILO ---
		estilo.bg_color = Color(0.15, 0.45, 0.25) 
		estilo.border_width_bottom = 5 
		estilo.border_color = Color(0.1, 0.3, 0.15)
		estilo.set_corner_radius_all(10)
		estilo.shadow_size = 8
		
		estilo_hover.bg_color = Color(0.21, 0.611, 0.345, 1.0)
		estilo_hover.border_width_bottom = 5 
		estilo_hover.set_corner_radius_all(10)
		
		add_theme_color_override("font_color", Color(1, 1, 1))
		if boton_borrar_vinculado: boton_borrar_vinculado.show()

	add_theme_stylebox_override("normal", estilo)
	add_theme_stylebox_override("hover", estilo_hover)
	add_theme_stylebox_override("pressed", estilo)

func _generar_estrellas_visuales(cantidad_llenas: int):
	if not contenedor_estrellas or not estrellas_recurso: return
	
	# Ajustes visuales (puedes tocarlos según tu diseño)
	var tamaño_celda = Vector2(25, 25) 
	var escala_visual = Vector2(0.06, 0.06) 

	for i in range(1, 6):
		var wrapper = Control.new()
		wrapper.custom_minimum_size = tamaño_celda
		
		var estrella_nueva = AnimatedSprite2D.new()
		estrella_nueva.sprite_frames = estrellas_recurso.sprite_frames
		estrella_nueva.position = tamaño_celda / 2
		estrella_nueva.scale = escala_visual
		
		wrapper.add_child(estrella_nueva)
		contenedor_estrellas.add_child(wrapper)

		if i <= cantidad_llenas:
			estrella_nueva.play("llena")
		else:
			estrella_nueva.play("vacia")
			estrella_nueva.modulate.a = 0.5 # Un poco transparente la vacía

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
