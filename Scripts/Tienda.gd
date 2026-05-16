extends Node2D

@onready var contenedor_caminos = $Caminos
@onready var spawn_timer = $SpawnTimer
@onready var zona_cobro = $ZonaCobro
@export var npc_escena: PackedScene

var fila_caja: Array = []
var jugador_en_posicion: bool = false

@onready var servicios = $Servicios
@onready var ui = $RaizUI
@onready var timer_reloj = $TimerReloj # Debes crear este nodo Timer en tu escena
@onready var suciedad_escena = $Suciedad # El nombre que le diste a la escena de sprites
@onready var fundido_negro = $CanvasLayer/Fundido
@onready var menu_config = $MenuConfiguracion # Asegúrate de que el nombre coincida
@onready var btn_config = $BotonConfig      # Tu botón en la interfaz de la tienda
@onready var sonido_caja = $SonidoCaja

var p1_en_caja: bool = false
var p2_en_caja: bool = false
var jugador_en_panel_luz: bool = false
var jugador_en_zona_agua: bool = false
var p1_en_luz: bool = false
var p2_en_agua: bool = false
var zona_donde_esta_p1 = ""
var zona_donde_esta_p2 = ""
var jornada_finalizada: bool = false

var zona_limpieza_actual: String = ""

func _ready():
	$MusicaTienda.play()
	menu_config.hide()
	if fundido_negro: fundido_negro.modulate.a = 0 # Empezamos con pantalla clara
	
	btn_config.pressed.connect(_on_boton_config_pressed)
	GameManager.clientes_perdidos = 0
	GameManager.reloj_jornada_horas = 8
	GameManager.reloj_jornada_minutos = 0
	GameManager.ganancias_del_dia = 0 # Reset ganancias al empezar el día
	GameManager.juego_pausado = false
	GameManager.total_dinero_multas = 0
	
	if ui:
		ui.actualizar_datos_generales()
	# Zona Luz (Solo para el grupo Player1)
	$ZonaLuz.body_entered.connect(func(body): 
		if body.is_in_group("Player1"):
			p1_en_luz = true
			if body.has_method("gestionar_tecla"): body.gestionar_tecla(true, "Luz")
	)
	$ZonaLuz.body_exited.connect(func(body): 
		if body.is_in_group("Player1"):
			p1_en_luz = false
			if body.has_method("gestionar_tecla"): body.gestionar_tecla(false)
	)
	
	# Zona Agua (Solo para Player2, o Player1 si es solo un jugador)
	$ZonaAgua.body_entered.connect(func(body): 
		var es_p2 = body.is_in_group("Player2")
		var es_p1_solo = GameManager.solo_un_jugador and body.is_in_group("Player1")
		
		if es_p2 or es_p1_solo:
			p2_en_agua = true
			if body.has_method("gestionar_tecla"): body.gestionar_tecla(true, "Agua")
	)
	$ZonaAgua.body_exited.connect(func(body): 
		if body.is_in_group("Player2") or (GameManager.solo_un_jugador and body.is_in_group("Player1")):
			p2_en_agua = false
			if body.has_method("gestionar_tecla"): body.gestionar_tecla(false)
	)
	
	# Si es un solo jugador, permitimos que P1 haga AMBAS cosas
	if GameManager.solo_un_jugador:
		$ZonaAgua.body_entered.connect(func(body): if body.name == "Player1": p2_en_agua = true)
		$ZonaAgua.body_exited.connect(func(body): if body.name == "Player1": p2_en_agua = false)
	
	
	if spawn_timer:
		spawn_timer.one_shot = true # Lo manejaremos nosotros manualmente
		spawn_timer.start(2.0) # El primer NPC saldrá a los 2 segundos
		print("SISTEMA: Timer de NPCs iniciado manualmente.")
		
	if GameManager.solo_un_jugador:
		var j2 = get_node_or_null("Player2") # Asegúrate que el nodo se llame así
		if j2:
			j2.queue_free()
			print("Modo un solo jugador: Jugador 2 eliminado.")
	# Conexiones de la Caja
	$ZonaCobro.body_entered.connect(func(body): 
		if body.is_in_group("jugadores"):
			if body.has_method("gestionar_tecla"): body.gestionar_tecla(true, "Caja")
	)
	$ZonaCobro.body_exited.connect(func(body): 
		if body.is_in_group("jugadores"):
			if body.has_method("gestionar_tecla"): body.gestionar_tecla(false)
	)
	
	# Conexiones del Panel de Luz
	$ZonaCobro.body_entered.connect(func(body): 
		if body.is_in_group("Player1"): 
			p1_en_caja = true
			body.gestionar_tecla(true, "Caja")
		if body.is_in_group("Player2"): 
			p2_en_caja = true
			body.gestionar_tecla(true, "Caja")
	)

	$ZonaCobro.body_exited.connect(func(body): 
		if body.is_in_group("Player1"): 
			p1_en_caja = false
			body.gestionar_tecla(false)
		if body.is_in_group("Player2"): 
			p2_en_caja = false
			body.gestionar_tecla(false)
	)
	for zona in get_tree().get_nodes_in_group("ZonasLimpieza"):
		zona.body_entered.connect(_on_zona_limpieza_entrada.bind(zona.name))
		zona.body_exited.connect(_on_zona_limpieza_salida.bind(zona.name))

# Detectar cuando un jugador entra a una zona de estante/refri
func _on_zona_body_entered(body, nombre_zona: String):
	if body.is_in_group("Player1"):
		zona_donde_esta_p1 = nombre_zona.replace("Zona", "") # "ZonaEstanteria1" -> "Estanteria1"
	if body.is_in_group("Player2"):
		zona_donde_esta_p2 = nombre_zona.replace("Zona", "")
	if body.is_in_group("NPC"):
		var nombre_mueble = nombre_zona.replace("Zona", "")
		# Obtenemos el nivel actual desde el script de Suciedad
		var nivel = $Suciedad.niveles[nombre_mueble]
		print(nivel)
		
		# El NPC registra la suciedad de este mueble específico
		# Si vuelve a pasar, se queda con el nivel más alto registrado
		if not body.muebles_visitados.has(nombre_mueble) or nivel > body.muebles_visitados[nombre_mueble]:
			body.muebles_visitados[nombre_mueble] = nivel
			print("NPC ", body.name, " vio suciedad nivel ", nivel, " en ", nombre_mueble)

func _on_zona_body_exited(body, nombre_zona: String):
	if body.is_in_group("Player1"): zona_donde_esta_p1 = ""
	if body.is_in_group("Player2"): zona_donde_esta_p2 = ""

func _on_zona_limpieza_entrada(body, nombre_zona: String):
	# Lógica de registro que ya tenías para NPCs
	if body.is_in_group("NPC"):
		_on_zona_body_entered(body, nombre_zona) # Llamamos a tu lógica original
		return

	# Lógica para jugadores
	if body.is_in_group("jugadores"):
		var mueble = nombre_zona.replace("Zona", "")
		if body.is_in_group("Player1"): zona_donde_esta_p1 = mueble
		if body.is_in_group("Player2"): zona_donde_esta_p2 = mueble
		
		if body.has_method("gestionar_tecla"): 
			body.gestionar_tecla(true, "Limpieza")

func _on_zona_limpieza_salida(body, nombre_zona: String):
	if body.is_in_group("Player1"): 
		zona_donde_esta_p1 = ""
		if body.has_method("gestionar_tecla"): body.gestionar_tecla(false)
	if body.is_in_group("Player2"): 
		zona_donde_esta_p2 = ""
		if body.has_method("gestionar_tecla"): body.gestionar_tecla(false)


func _on_timer_reloj_timeout():
	if jornada_finalizada: return
	GameManager.reloj_jornada_minutos += 1
	if GameManager.reloj_jornada_minutos >= 60:
		GameManager.reloj_jornada_minutos = 0
		GameManager.reloj_jornada_horas += 1
	
	if ui:
		ui.actualizar_datos_generales()
	
	# 1. PRE-CIERRE (19:50): Dejan de aparecer NPCs
	if GameManager.reloj_jornada_horas == 19 and GameManager.reloj_jornada_minutos == 50:
		spawn_timer.stop()
		print("SISTEMA: No más clientes por hoy.")

	# 2. CIERRE TOTAL (20:00)
	if GameManager.reloj_jornada_horas >= 20:
		iniciar_secuencia_cierre()

func iniciar_secuencia_cierre():
	jornada_finalizada = true
	timer_reloj.stop()
	GameManager.juego_pausado = true # Esto debe bloquear el movimiento en el script del Player
	
	# Reparar todo automáticamente por lore de fin de día
	servicios.luz_activa = true
	servicios.agua_activa = true
	
	print("SISTEMA: Alarma de cierre.")
	if has_node("SonidoAlerta"): $SonidoAlerta.play()
	
	# Esperar 2 segundos antes del fundido
	await get_tree().create_timer(2.0).timeout
	
	# Fundido a negro y cambio de escena
	var tween = create_tween()
	tween.tween_property(fundido_negro, "modulate:a", 1.0, 1.5)
	tween.tween_callback(_ir_a_resultados)

func _ir_a_resultados():
	get_tree().change_scene_to_file("res://Scenas/Resultados.tscn")

func _on_spawn_timer_timeout():
	spawn_npc()

func spawn_npc():
	if jornada_finalizada: return
	if npc_escena:
		
		var presupuesto_api = await $Servicios/EconomiaAPI.obtener_presupuesto_nuevo()
		var nuevo_npc = npc_escena.instantiate()
		nuevo_npc.presupuesto_inicial = presupuesto_api
		print(nuevo_npc.presupuesto_inicial)
		nuevo_npc.tipo_npc = randi_range(1, 4) 
		add_child(nuevo_npc)
		
		
		
		# --- LA CLAVE ESTÁ AQUÍ ---
		# Al final de la función, reiniciamos el timer manualmente
		# Esto hace que el ciclo se repita una y otra vez
		var nuevo_tiempo = randf_range(3.0, 7.0)
		spawn_timer.start(nuevo_tiempo) 
		
		print("NPC generado. Próximo en: ", nuevo_tiempo, " segundos.")


func registrar_en_caja(npc):
	if not fila_caja.has(npc):
		fila_caja.append(npc)

func _process(_delta):
	# --- SECCIÓN PLAYER 1 ---
	var p1 = get_tree().get_first_node_in_group("Player1")
	if p1:
		if p1.esta_reparando:
			# Si YA está reparando, la tecla solo sirve para CANCELAR
			if Input.is_action_just_pressed("cobrar_p1"):
				if servicios.reparaciones_activas.has("LUZ"):
					servicios.cancelar_reparacion("LUZ")
				elif GameManager.solo_un_jugador and servicios.reparaciones_activas.has("AGUA"):
					servicios.cancelar_reparacion("AGUA")
		else:
			# Si NO está reparando, la tecla sirve para iniciar acciones
			if Input.is_action_just_pressed("cobrar_p1"):
				if p1_en_luz and not servicios.luz_activa:
					servicios.iniciar_reparacion("LUZ")
				elif zona_donde_esta_p1 != "":
					ejecutar_limpieza(zona_donde_esta_p1)
				elif p1_en_caja and fila_caja.size() > 0 and servicios.luz_activa:
					realizar_cobro()
				elif GameManager.solo_un_jugador and p2_en_agua and not servicios.agua_activa:
					servicios.iniciar_reparacion("AGUA")

	# --- SECCIÓN PLAYER 2 ---
	var p2 = get_tree().get_first_node_in_group("Player2")
	if p2:
		if p2.esta_reparando:
			# Si YA está reparando, la tecla solo sirve para CANCELAR
			if Input.is_action_just_pressed("cobrar_p2"):
				if servicios.reparaciones_activas.has("AGUA"):
					servicios.cancelar_reparacion("AGUA")
		else:
			# Si NO está reparando, la tecla sirve para iniciar acciones
			if Input.is_action_just_pressed("cobrar_p2"):
				if p2_en_agua and not servicios.agua_activa:
					servicios.iniciar_reparacion("AGUA")
				elif zona_donde_esta_p2 != "":
					ejecutar_limpieza(zona_donde_esta_p2)
				elif p2_en_caja and fila_caja.size() > 0 and servicios.luz_activa:
					realizar_cobro()

func registrar_suciedad_npc(npc, nombre_zona: String):
	var nombre_mueble = nombre_zona.replace("Zona", "")
	var precio_multa = 0
	
	if suciedad_escena.niveles.has(nombre_mueble):
		var nivel = suciedad_escena.niveles[nombre_mueble]
		
		if nivel > 0:
			# Solo procesamos si el NPC NO ha visto este mueble antes, 
			# O si el nivel actual es mayor al que ya había visto.
			if not npc.muebles_visitados.has(nombre_mueble) or nivel > npc.muebles_visitados[nombre_mueble]:
				
				# Calculamos la diferencia de multa si es que el nivel subió
				var nivel_previo = npc.muebles_visitados.get(nombre_mueble, 0)
				
				# Guardamos el nuevo nivel en el NPC
				npc.muebles_visitados[nombre_mueble] = nivel
				
				# Determinamos el precio basado en el nivel
				match nivel:
					1: precio_multa = 6
					2: precio_multa = 10
					3: precio_multa = 20
				
				# IMPORTANTE: Si el NPC ya había visto nivel 1 y ahora ve nivel 2, 
				# podrías restarle lo anterior para no cobrar doble, pero lo más 
				# justo para un juego de este tipo es que cada "avistamiento" nuevo 
				# cuente como una infracción detectada.
				
				GameManager.total_dinero_multas += precio_multa
				print("SISTEMA: NPC detectó suciedad. Multa acumulada hoy: $", GameManager.total_dinero_multas)

func ejecutar_limpieza(nombre_mueble: String):
	# 1. COMPROBAR AGUA (Crucial para supervivencia)
	if not servicios.agua_activa:
		print("AVISO: No puedes limpiar, ¡no hay agua!")
		if ui: ui.mostrar_falla("AGUA") # Feedback visual en la UI
		return

	# 2. MANDAR A LIMPIAR
	# Llamamos a la función limpiar_mueble que ya tienes en Suciedad.gd
	if suciedad_escena.has_method("limpiar_mueble"):
		suciedad_escena.limpiar_mueble(nombre_mueble)
		print("LOG: ", nombre_mueble, " ha sido limpiado por el jugador.")

func realizar_cobro():
	if fila_caja.size() > 0:
		var npc = fila_caja[0]
		var subtotal = npc.presupuesto_inicial
		var descuento_total_porcentaje = 0.0
		
		# Sumamos los descuentos de cada zona visitada
		for mueble in npc.muebles_visitados:
			var nivel = npc.muebles_visitados[mueble]
			if nivel == 1: descuento_total_porcentaje += 0.10
			elif nivel == 2: descuento_total_porcentaje += 0.20
			elif nivel == 3: descuento_total_porcentaje += 0.30
		
		# Limitamos el descuento máximo al 90% para no dar dinero gratis
		descuento_total_porcentaje = min(descuento_total_porcentaje, 0.9)
		
		var total_pagado = subtotal * (1.0 - descuento_total_porcentaje)
		
		GameManager.dinero_actual += total_pagado
		GameManager.ganancias_del_dia += total_pagado
		print("PAGO: Presupuesto original $", subtotal, " | Descuento: ", descuento_total_porcentaje*100, "% | Total: $", total_pagado)
		
		if ui: ui.mostrar_pago(total_pagado)
		
		sonido_caja.play()
		
		npc.pago_completado = true
		fila_caja.pop_front()

func quitar_de_fila(npc):
	if fila_caja.has(npc):
		fila_caja.erase(npc)

func _on_zona_cobro_body_entered(body):
	if body.is_in_group("jugadores"):
		jugador_en_posicion = true

func _on_zona_cobro_body_exited(body):
	if body.is_in_group("jugadores"):
		jugador_en_posicion = false

func obtener_ruta_aleatoria() -> Array[Vector2]:
	var ruta_puntos: Array[Vector2] = []
	if contenedor_caminos == null: contenedor_caminos = get_node_or_null("Caminos")
	var rutas_disponibles = contenedor_caminos.get_children()
	if rutas_disponibles.size() > 0:
		var camino_elegido = rutas_disponibles.pick_random()
		for marker in camino_elegido.get_children():
			if marker is Marker2D:
				ruta_puntos.append(marker.global_position)
	return ruta_puntos

func _on_boton_config_pressed():
	GameManager.juego_pausado = true
	# print(GameManager.juego_pausado, " VARIABLE GLOBAL PAUSADO - Tienda")
	# 1. Ponemos el juego en pausa (congela movimientos, timers y NPCs)
	get_tree().paused = true
	
	# 2. Mostramos el menú
	menu_config.show()
	
	# 3. Opcional: Ocultar el botón de config para que no se presione dos veces
	btn_config.hide()

func registrar_cliente_perdido():
	GameManager.clientes_perdidos += 1
	print("SISTEMA: Cliente se fue molesto. Total hoy: ", GameManager.clientes_perdidos)
