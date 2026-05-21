extends CharacterBody2D

@export var velocidad = 120.0
var puntos_ruta: Array[Vector2] = []
var objetivo_actual: Vector2 = Vector2.ZERO
var indice_punto_actual: int = 0

@onready var tienda = get_parent()
# var tienda: Node = null
@onready var barra_paciencia = get_node_or_null("BarraPaciencia")

@export var tipo_npc: int = 1 
@onready var sprite = $AnimatedNPC

# --- VARIABLES DE CONTROL ---
var pago_completado: bool = false
var esperando_en_caja: bool = false
var paciencia: float = 100.0
var velocidad_paciencia: float = 8.0 # Baja este número si se van muy rápido
var multiplicador_calidad: float = 1.0
var presupuesto_inicial: float = 50.0
var muebles_visitados: Dictionary = {} # Guarda {"Estanteria1": nivel_suciedad}

func _ready():
	await get_tree().process_frame 
	tienda = get_tree()
	
	if not tienda or not tienda.has_method("registrar_cliente_perdido"):
		# Si la raíz no es, buscamos por grupo (debes añadir el grupo "Tienda" al nodo raíz de Tienda.tscn)
		tienda = get_tree().get_first_node_in_group("Tienda")

	if tienda:
		print("DEBUG NPC: Tienda encontrada correctamente: ", tienda.name)
		puntos_ruta = tienda.obtener_ruta_aleatoria()
		# ... resto de tu código de inicio ...
	else:
		print("ERROR CRÍTICO NPC: No se pudo encontrar el nodo Tienda. Revisa los grupos.")
	
	if barra_paciencia:
		barra_paciencia.max_value = 100.0
		barra_paciencia.value = 100.0
		barra_paciencia.visible = false
	
	if tienda:
		puntos_ruta = tienda.obtener_ruta_aleatoria()
		if puntos_ruta.size() > 0:
			global_position = puntos_ruta[0]
			# Empezamos el recorrido
			indice_punto_actual = 0
			ir_al_siguiente_punto()

func ir_al_siguiente_punto():
	# Si ya no hay más puntos, terminar
	if indice_punto_actual >= puntos_ruta.size():
		_finalizar_recorrido()
		return

	# DETECCIÓN DE LA CAJA: Penúltimo punto (puntos_ruta.size() - 2)
	var indice_caja = puntos_ruta.size() - 2
	
	if indice_punto_actual == indice_caja:
		if not pago_completado:
			# Llegó a la caja por primera vez
			if not esperando_en_caja:
				tienda.registrar_en_caja(self)
				esperando_en_caja = true
				if barra_paciencia: barra_paciencia.visible = true
			
			# Calculamos su sitio en la fila
			actualizar_posicion_en_fila()
			return # DETENER AQUÍ: No incrementamos el índice hasta pagar
		else:
			# Ya pagó, ahora sí puede avanzar al último punto (la salida)
			esperando_en_caja = false
			if barra_paciencia: barra_paciencia.visible = false
			indice_punto_actual += 1
	else:
		# Puntos normales del camino
		indice_punto_actual += 1

	# Actualizar el objetivo real
	if indice_punto_actual < puntos_ruta.size():
		objetivo_actual = puntos_ruta[indice_punto_actual]

func actualizar_posicion_en_fila():
	var indice_fila = tienda.fila_caja.find(self)
	if indice_fila != -1:
		var indice_caja = puntos_ruta.size() - 2
		# Separación de 30px hacia la IZQUIERDA (ajusta según tu mapa)
		var separacion = Vector2(indice_fila * 30, 0) 
		objetivo_actual = puntos_ruta[indice_caja] + separacion

func _process(delta):
	# --- DETECCIÓN DE SUCIEDAD CON RAYCAST ---
	if $RayCast2D.is_colliding():
		var objeto_detectado = $RayCast2D.get_collider()
		
		# Verificamos que sea un Area2D y que esté en el grupo correcto
		if objeto_detectado and objeto_detectado.is_in_group("ZonasLimpieza"):
			if tienda and tienda.has_method("registrar_suciedad_npc"):
				tienda.registrar_suciedad_npc(self, objeto_detectado.name)

	# Lógica de paciencia (Ya la tienes)
	procesar_paciencia(delta)
	
	# Actualizar animaciones
	actualizar_animaciones()

func actualizar_animaciones():
	var prefijo = "NPC_" + str(tipo_npc) + "_"
	
	# 1. Si está pagando (Animación especial)
	if pago_completado and esperando_en_caja:
		sprite.play(prefijo + "Pago")
		return

	# 2. Si está quieto (Idle)
	if velocity.length() < 10:
		# Si no se mueve, buscamos la versión "Quieto" de la última dirección
		var anim_actual = sprite.animation
		if "Mov_" in anim_actual:
			sprite.play(anim_actual.replace("Mov_", ""))
		return

	# 3. Determinar dirección de movimiento
	if abs(velocity.x) > abs(velocity.y):
		if velocity.x > 0:
			sprite.play(prefijo + "Mov_Derecho")
		else:
			sprite.play(prefijo + "Mov_Izquierdo")
	else:
		if velocity.y > 0:
			sprite.play(prefijo + "Mov_Frente")
		else:
			sprite.play(prefijo + "Mov_Atras")

func procesar_paciencia(delta):
	if esperando_en_caja and not pago_completado:
		var servicios = tienda.get_node("Servicios")
		
		# --- MULTIPLICADORES DE DIFICULTAD ---
		
		# 1. Multiplicador por falta de servicios (Agua)
		var mult_servicios = 1.0
		if servicios and not servicios.agua_activa:
			mult_servicios = 2.0
			
		# 2. Multiplicador por Reputación (Estrellas)
		# A más fama, menos paciencia tienen los clientes
		var mult_reputacion = GameManager.obtener_multiplicador_paciencia()
		
		# Aplicamos ambos multiplicadores a la velocidad base
		var reduccion = velocidad_paciencia * mult_servicios * mult_reputacion
		
		paciencia -= reduccion * delta
		
		# --- ACTUALIZACIÓN VISUAL ---
		if barra_paciencia:
			barra_paciencia.value = paciencia
			
			# Opcional: Cambiar color de la barra según el estrés
			if paciencia < 30:
				barra_paciencia.modulate = Color.RED
			elif paciencia < 60:
				barra_paciencia.modulate = Color.ORANGE
			else:
				barra_paciencia.modulate = Color.GREEN

		if paciencia <= 0:
			abandonar_por_enojo()

func abandonar_por_enojo():
	# 1. Avisamos a la tienda que registre la mala reseña
	if tienda and tienda.has_method("registrar_cliente_perdido"):
		tienda.registrar_cliente_perdido()
	
	# 2. Lo sacamos de la fila de la caja
	mostrar_feedback_visual("😡 Reseña -1", Color.RED)
	tienda.quitar_de_fila(self)
	
	# 3. Marcamos como "completado" para que la lógica de ir_al_siguiente_punto
	# lo deje avanzar hacia el último punto (la salida)
	pago_completado = true 
	
	# Opcional: Cambiar color a rojo o mostrar un emoji de enojo
	modulate = Color(1, 0.5, 0.5) 
	
	ir_al_siguiente_punto()

func mostrar_feedback_visual(texto: String, color: Color):
	var label = get_node_or_null("LabelFeedback")
	if not label: return
	
	# Configurar el texto y color
	label.text = texto
	label.modulate = color
	label.visible = true
	label.modulate.a = 1.0 # Asegurar que sea opaco al inicio
	
	# Reiniciar posición por si acaso (un poco arriba de su cabeza)
	# label.position = Vector2(-20, -60) 
	
	# Crear la animación de flotar y desvanecerse
	var tween = create_tween().set_parallel(true)
	# Sube 40 píxeles
	tween.tween_property(label, "position:y", label.position.y - 40, 1.2)
	# Se vuelve transparente
	tween.parallel().tween_property(label, "modulate:a", 0.0, 1.2)
	
	# Al terminar, lo ocultamos de nuevo
	await tween.finished
	label.visible = false

func cobrar_exitoso(monto: float, es_buena_resena: bool):
	# Si fue una buena reseña (menos del 50% de descuento)
	if es_buena_resena:
		mostrar_feedback_visual("+1 Reseña\n+$" + str(snapped(monto, 0.01)), Color.GOLD)
	else:
		mostrar_feedback_visual("+$" + str(snapped(monto, 0.01)), Color.SPRING_GREEN)

func _physics_process(_delta):
	if objetivo_actual == Vector2.ZERO or puntos_ruta.size() == 0: 
		return
	
	if esperando_en_caja and not pago_completado:
		actualizar_posicion_en_fila()
		
	var direccion = global_position.direction_to(objetivo_actual)
	
	if direccion != null:
		# Si está en la fila y muy cerca de su sitio, frenar totalmente
		if global_position.distance_to(objetivo_actual) < 5.0:
			velocity = Vector2.ZERO
			if not esperando_en_caja or pago_completado:
				ir_al_siguiente_punto()
		else:
			velocity = direccion * velocidad
			move_and_slide()
		



func _finalizar_recorrido():
	queue_free()
