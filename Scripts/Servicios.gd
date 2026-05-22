extends Node2D

var luz_activa: bool = true
var agua_activa: bool = true

# Diccionario para guardar los estados de ambas reparaciones por separado
# Estructura: "LUZ": { "secuencia": [], "actual": 0 }, "AGUA": { ... }
var reparaciones_activas: Dictionary = {}

@onready var filtro_luz = $"../FiltroLuz" 
@onready var ui = $"../RaizUI"

@onready var luz_hogera = $"../LuzHogera" # Ajusta la ruta si es necesario
@onready var fugas = [$"../Fuga1", $"../Fuga2", $"../Fuga3"] # Lista de las 3 fugas

@onready var sfx_reparar_luz = $"../SonidoReparacionLuz"

var reparando_luz_loop: bool = false # Control del bucle

var reparar_luz = [
	preload("res://Sounds/SonidosInternos/Sonido_Reparando_Luz_1.wav"),
	preload("res://Sounds/SonidosInternos/Sonido_Reparando_Luz_2.wav"),
	preload("res://Sounds/SonidosInternos/Sonido_Reparando_Luz_3.wav"),
	preload("res://Sounds/SonidosInternos/Sonido_Reparando_Luz_4.wav")
]

func _ready():
	await get_tree().process_frame
	
	if filtro_luz: filtro_luz.visible = false
	
	# Inicializamos el estado de los nuevos elementos
	if luz_hogera: luz_hogera.enabled = true
	
	for fuga in fugas:
		if fuga:
			fuga.visible = false
			fuga.stop() # Aseguramos que no consuman recursos si no se ven
			
	luz_activa = GameManager.luz_global
	agua_activa = GameManager.agua_global
	
	print(luz_activa, " : LUZ GLOBAL")
	
	if not luz_activa:
		averiar_luz(true) 
	else:
		esperar_averia_luz()

	if not agua_activa:
		averiar_agua(true)
	else:
		esperar_averia_agua()
	'''if not agua_activa:
		averiar_agua()
	else:
		esperar_averia_agua()'''

# --- TEMPORIZADORES Y AVERÍAS (Sin cambios) ---
func esperar_averia_luz():
	
	# El segundo parámetro 'false' hace que el timer se DETENGA en pausa
	await get_tree().create_timer(randf_range(20.0, 40.0), false).timeout
	# Doble seguridad: si al terminar el tiempo estamos en pausa, no averiar
	if not GameManager.juego_pausado:
		averiar_luz()
	else:
		# Reintentar en un momento si justo estábamos en pausa
		await get_tree().create_timer(2.0, false).timeout
		esperar_averia_luz()

func esperar_averia_agua():
	await get_tree().create_timer(randf_range(25.0, 50.0), false).timeout
	if not GameManager.juego_pausado:
		averiar_agua()
	else:
		await get_tree().create_timer(2.0, false).timeout
		esperar_averia_agua()

func averiar_luz(forzar: bool = false):
	if not luz_activa and not forzar: print("Saliendo de Averiar Luz"); return # Evitar duplicados
	luz_activa = false
	GameManager.luz_global = false
	if filtro_luz: filtro_luz.visible = true
	print("Se mostro el filtro de luz")
	if luz_hogera: luz_hogera.enabled = false 
	$"../SonidoLuzFuera".play()
	ui.mostrar_falla("LUZ")

func averiar_agua(forzar: bool = false):
	if not agua_activa and not forzar: return
	agua_activa = false
	GameManager.agua_global = false
	ui.mostrar_falla("AGUA")
	for fuga in fugas:
		if fuga:
			fuga.visible = true
			fuga.play()
	$"../SonidoFuga".play()

# --- LÓGICA DE REPARACIÓN MULTITAREA ---

func iniciar_reparacion(tipo: String):
	# Si ya se está reparando este servicio específico, no hacer nada
	if reparaciones_activas.has(tipo): return
	
	var jugador = null
	if tipo == "LUZ":
		jugador = get_tree().get_first_node_in_group("Player1")
		reparando_luz_loop = true
		_reproducir_sfx_luz_aleatorio()
	else:
		# Si es agua, puede ser P2 o P1 (en modo solitario)
		if GameManager.solo_un_jugador:
			jugador = get_tree().get_first_node_in_group("Player1")
			$"../SonidoReparacionAgua".play()
		else:
			jugador = get_tree().get_first_node_in_group("Player2")
			$"../SonidoReparacionAgua".play()
	
	if jugador:
		jugador.esta_reparando = true
		# Forzamos la actualización visual para que aparezca el "LabelCancelar"
		jugador.gestionar_tecla(true, tipo)
	
	
	var nueva_secuencia = []
	for i in range(5):
		if tipo == "LUZ":
			nueva_secuencia.append(["W", "A", "S", "D"].pick_random())
		else:
			nueva_secuencia.append(["Up", "Down", "Left", "Right"].pick_random())
	
	# Guardamos los datos de ESTA reparación sin tocar la otra
	reparaciones_activas[tipo] = {
		"secuencia": nueva_secuencia,
		"actual": 0,
		"jugador_referencia": jugador # Guardamos la referencia para desbloquearlo luego
	}
	
	ui.actualizar_secuencia(tipo, nueva_secuencia, 0)

func _input(event):
	# Si el juego está pausado, ignorar las teclas de reparación
	if GameManager.juego_pausado: return
	
	if reparaciones_activas.is_empty(): return
	
	if event is InputEventKey and event.pressed and not event.is_echo():
		var tecla = OS.get_keycode_string(event.key_label)
		# ... (tu lógica de normalización de flechas se mantiene igual)
		if "Up" in tecla: tecla = "Up"
		elif "Down" in tecla: tecla = "Down"
		elif "Left" in tecla: tecla = "Left"
		elif "Right" in tecla: tecla = "Right"

		procesar_tecla_reparacion("LUZ", tecla)
		procesar_tecla_reparacion("AGUA", tecla)

func procesar_tecla_reparacion(tipo: String, tecla_presionada: String):
	if not reparaciones_activas.has(tipo): return
	
	var datos = reparaciones_activas[tipo]
	var teclas_p1 = ["W", "A", "S", "D"]
	var teclas_p2 = ["Up", "Down", "Left", "Right"]
	
	# Filtro: ¿Esta tecla pertenece al jugador que repara este servicio?
	if tipo == "LUZ" and not tecla_presionada in teclas_p1: return
	if tipo == "AGUA" and not tecla_presionada in teclas_p2: return

	var tecla_necesaria = datos["secuencia"][datos["actual"]]

	if tecla_presionada == tecla_necesaria:
		datos["actual"] += 1
		if datos["actual"] >= datos["secuencia"].size():
			finalizar_reparacion(tipo)
		else:
			ui.actualizar_secuencia(tipo, datos["secuencia"], datos["actual"])
	else:
		# Error: Solo reiniciar si la tecla pulsada es del set correcto
		datos["actual"] = 0 
		ui.actualizar_secuencia(tipo, datos["secuencia"], 0)
	$"../SonidoTecla".play()

func finalizar_reparacion(tipo: String):
	if reparaciones_activas.has(tipo):
		var datos = reparaciones_activas[tipo]
		if datos["jugador_referencia"] != null:
			datos["jugador_referencia"].esta_reparando = false
			datos["jugador_referencia"].gestionar_tecla(true, tipo)
	
	ui.ocultar_secuencia(tipo)
	ui.mostrar_reparado(tipo)
	
	if tipo == "LUZ":
		luz_activa = true
		GameManager.luz_global = true
		reparando_luz_loop = false
		sfx_reparar_luz.stop()
		if filtro_luz: filtro_luz.visible = false 
		if luz_hogera: luz_hogera.enabled = true # REACTIVAMOS la luz de la hoguera
		esperar_averia_luz() 
	else:
		agua_activa = true
		GameManager.agua_global = true
		$"../SonidoFuga".stop()
		$"../SonidoReparacionAgua".stop()
		
		# DESACTIVAMOS las fugas de agua
		for fuga in fugas:
			if fuga:
				fuga.visible = false
				fuga.stop()
				
		esperar_averia_agua()
	
	reparaciones_activas.erase(tipo)


func cancelar_reparacion(tipo: String):
	if not reparaciones_activas.has(tipo): return
	
	var datos = reparaciones_activas[tipo]
	
	if tipo == "LUZ":
		reparando_luz_loop = false
		sfx_reparar_luz.stop()
	else:
		$"../SonidoReparacionAgua".stop()
	
	# 1. Liberar al jugador
	if datos["jugador_referencia"] != null:
		datos["jugador_referencia"].esta_reparando = false
		# Al cancelar, refrescamos la visual del jugador
		datos["jugador_referencia"].gestionar_tecla(true, tipo)
	
	# 2. Limpiar la UI
	ui.ocultar_secuencia(tipo)
	
	# 3. Eliminar del diccionario de activos
	reparaciones_activas.erase(tipo)
	print("SISTEMA: Reparación de ", tipo, " cancelada.")

func _reproducir_sfx_luz_aleatorio():
	if not reparando_luz_loop: return
	
	# Elegimos un clip al azar de tu array
	sfx_reparar_luz.stream = reparar_luz.pick_random()
	sfx_reparar_luz.pitch_scale = randf_range(0.9, 1.1) # Variedad extra
	sfx_reparar_luz.play()

# Conecta la señal 'finished' de tu nodo SonidoReparacionLuz a esta función
func _on_sonido_reparacion_luz_finished():
	if reparando_luz_loop:
		_reproducir_sfx_luz_aleatorio()
