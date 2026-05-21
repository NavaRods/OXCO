extends CanvasLayer

# --- REFERENCIAS ---
# Metemos todos los paneles en un Array en el orden exacto de aparición
@onready var paginas = [
	$Movimiento,
	$Cobro,
	$Limpieza,
	$AlertaAgua,
	$AlertaLuz,
	$ReparacionLuz,
	$ReparacionAguaP1,
	$ReparacionAguaP2
]

@onready var btn_atras = $BtnAtras
@onready var btn_sig = $BtnSiguiente

var indice_actual = 0

func _ready():
	# 1. Ocultar todos los paneles al iniciar
	for p in paginas:
		p.hide()
	
	# 2. Mostrar solo la primera página
	actualizar_navegacion()

func actualizar_navegacion():
	# Ocultar todos los paneles primero
	for p in paginas:
		p.hide()
	
	# Mostrar el panel actual
	var panel_activo = paginas[indice_actual]
	panel_activo.show()
	
	# Si el panel tiene un VideoStreamPlayer, reiniciarlo para que se vea desde el inicio
	var video = panel_activo.get_node_or_null("VideoStreamPlayer")
	if video:
		video.play()

	# --- CONTROL DE BOTONES ---
	# Ocultar "Atrás" si estamos en la primera página
	btn_atras.visible = (indice_actual > 0)

# --- SEÑALES ---

func _on_btn_siguiente_pressed():
	if indice_actual < paginas.size() - 1:
		indice_actual += 1
		actualizar_navegacion()
	else:
		# Si presiona siguiente en la última página, sale del tutorial
		_on_btn_salir_pressed()

func _on_btn_atras_pressed():
	if indice_actual > 0:
		indice_actual -= 1
		actualizar_navegacion()

func _on_btn_salir_pressed():
	# Regresar al menú o cerrar el tutorial
	get_tree().change_scene_to_file("res://Scenas/MainMenu.tscn")
	
	
	
	
