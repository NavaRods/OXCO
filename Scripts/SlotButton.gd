extends Button

@export var slot_index: int = 1
@export var boton_borrar_vinculado: Button 

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
	popup_confirmar.dialog_text = "¿Estás seguro de que quieres renunciar al progreso de la CAJA " + str(slot_index) + "?"
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
	
	if datos == null or datos.is_empty():
		# --- ESTILO SLOT VACÍO ---
		text = "\n\n➕\nNUEVA PARTIDA\n(CAJA " + str(slot_index) + ")"
		
		# (Configuración de estilo vacío)
		estilo.bg_color = Color(0.2, 0.2, 0.2, 0.5)
		estilo.set_corner_radius_all(10)
		estilo_hover.bg_color = Color(0.3, 0.3, 0.3, 0.6)
		estilo_hover.set_corner_radius_all(10)
		
		add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
		if boton_borrar_vinculado: boton_borrar_vinculado.hide()
	else:
		# --- EXTRAER DATOS DE TU TABLA ---
		var nombre = str(datos.get("p1_name", "---")).to_upper()
		var p2_name = str(datos.get("p2_name", "N/A"))
		var dia = str(datos.get("day", 1))
		var dinero = str(snapped(datos.get("money", 0), 0.01))
		var reputacion = datos.get("reputation", 0.0) # Nota: revisa si en tu DB es 'reputatin' por el typo que pusiste o 'reputation'
		
		# --- LÓGICA DE JUGADORES (Basado en p2_name) ---
		var texto_jugadores = ""
		if p2_name == "N/A":
			texto_jugadores = "👤 SOLO"
		else:
			texto_jugadores = "👥 COOP"
		
		# --- LÓGICA DE ESTRELLAS Y DIFICULTAD ---
		var estrellas = int(clamp(reputacion / 50.0, 0, 5))
		var dificultad_texto = ""
		var iconos_estrellas = ""
		
		for i in range(5):
			iconos_estrellas += "★" if i < estrellas else "☆"

		if estrellas <= 2:
			dificultad_texto = "NORMAL"
		elif estrellas <= 4:
			dificultad_texto = "POPULAR"
		else:
			dificultad_texto = "A LO LOCO"

		# --- CONSTRUCCIÓN DEL TEXTO ---
		text = "CAJA " + nombre + "\n"
		text += "━━━━━━━━━━━━━\n"
		text += texto_jugadores + "\n"
		text += "☀️ DÍA: " + dia + "\n"
		text += "💰 $" + dinero + "\n"
		text += iconos_estrellas + "\n[" + dificultad_texto + "]\n"

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
