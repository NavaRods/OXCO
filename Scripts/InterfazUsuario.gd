extends Control

# Nodos configurados en el editor
@onready var notif_luz = $NotificadorLuz
@onready var notif_agua = $NotificadorAgua
@onready var pago_caja = $PagoCaja
@onready var label_dia = $VBoxContainer/HBoxContainer/Dia
@onready var label_horario = $VBoxContainer/HBoxContainer/Horario
@onready var label_dinero = $VBoxContainer/DineroTotal
@onready var container_luz = $ReparacionLuz
@onready var container_agua = $ReparacionAgua
@onready var timer_parpadeo = $TimerParpadeo

# --- NUEVOS: Arrastra aquí tus AnimatedSprite2D desde el inspector ---
@export var fuente_luz: AnimatedSprite2D 
@export var fuente_agua: AnimatedSprite2D

func _ready():
	_limpiar_ui()
	actualizar_datos_generales()
	if fuente_luz: fuente_luz.hide()
	if fuente_agua: fuente_agua.hide()

func _limpiar_ui():
	notif_luz.text = ""
	notif_agua.text = ""
	pago_caja.text = ""
	container_luz.hide()
	container_agua.hide()

func actualizar_datos_generales():
	label_dia.text = "DÍA: " + str(GameManager.dia_actual)
	label_horario.text = "%02d:%02d" % [GameManager.reloj_jornada_horas, GameManager.reloj_jornada_minutos]
	label_dinero.text = "TOTAL: $%.2f" % GameManager.dinero_actual

# --- SISTEMA DE REPARACIÓN ---

func actualizar_secuencia(tipo: String, secuencia: Array, actual: int):
	var container = container_luz if tipo == "LUZ" else container_agua
	var fuente = fuente_luz if tipo == "LUZ" else fuente_agua
	var prefijo = "Luz_" if tipo == "LUZ" else "Agua_"
	
	if fuente == null: return
	
	container.show()
	
	# Corregido: Ahora pasamos el prefijo como 4to argumento
	if actual == 0 or container.get_child_count() != secuencia.size():
		_dibujar_base_secuencia(container, secuencia, fuente, prefijo)
		# Esperamos un frame para que los nodos se registren en el árbol
		await get_tree().process_frame
	
	# Actualizar estados
	var teclas_nodos = container.get_children()
	for i in range(teclas_nodos.size()):
		if teclas_nodos[i].get_child_count() > 0:
			var anim_sprite = teclas_nodos[i].get_child(0) as AnimatedSprite2D
			var tecla_id = secuencia[i].to_upper()
			tecla_id == "RIGHT"
			
			if i < actual:
				anim_sprite.play(prefijo + tecla_id + "_down")
				anim_sprite.modulate = Color(0.6, 0.6, 0.6)
			elif i == actual:
				anim_sprite.play(prefijo + tecla_id + "_up")
				anim_sprite.modulate = Color(1.5, 1.5, 1.5) # Resaltado
			else:
				anim_sprite.play(prefijo + tecla_id + "_up")
				anim_sprite.modulate = Color(1, 1, 1, 0.4)
			

func _dibujar_base_secuencia(container: HBoxContainer, secuencia: Array, fuente: AnimatedSprite2D, prefijo: String):
	# Limpieza instantánea para evitar duplicados
	for child in container.get_children():
		child.free() 
	
	# --- AJUSTES DE DISEÑO ---
	# Cuanto más pequeño sea el tamaño_tecla, más juntas estarán
	var tamaño_tecla = Vector2(50, 50) 
	var escala_sprite = Vector2(2.8, 2.8) # Ahora son más grandes
	# -------------------------

	for tecla in secuencia:
		var wrapper = Control.new()
		wrapper.custom_minimum_size = tamaño_tecla 
		
		var nuevo_sprite = AnimatedSprite2D.new()
		nuevo_sprite.sprite_frames = fuente.sprite_frames
		nuevo_sprite.position = tamaño_tecla / 2
		nuevo_sprite.scale = escala_sprite 
		
		var t_id = tecla.to_upper()
		t_id == "RIGHT"
		nuevo_sprite.play(prefijo + t_id + "_up")
		
		wrapper.add_child(nuevo_sprite)
		container.add_child(wrapper)

# --- RESTO DE FUNCIONES (Sin cambios) ---

func ocultar_secuencia(tipo: String):
	if tipo == "LUZ": container_luz.hide()
	else: container_agua.hide()

func mostrar_falla(tipo: String):
	var label = notif_luz if tipo == "LUZ" else notif_agua
	label.text = "¡ALERTA: FALLO EN " + tipo + "!"
	label.modulate = Color.RED
	label.visible = true # Aseguramos que inicie visible
	
	# Si el timer no está corriendo, lo iniciamos
	if timer_parpadeo.is_stopped():
		# Conectamos la señal solo una vez si no está conectada
		if not timer_parpadeo.timeout.is_connected(_procesar_parpadeo):
			timer_parpadeo.timeout.connect(_procesar_parpadeo)
		timer_parpadeo.start()

func _efecto_parpadeo(label: Label):
	while label.text != "" and "ALERTA" in label.text:
		label.visible = !label.visible
		await get_tree().create_timer(0.5, false).timeout

func mostrar_reparado(tipo: String):
	var label = notif_luz if tipo == "LUZ" else notif_agua
	label.text = "¡" + tipo + " REPARADA!"
	label.modulate = Color.GREEN
	label.visible = true
	
	# Esperar 3 segundos respetando la pausa
	await get_tree().create_timer(3.0, false).timeout
	
	label.text = "" # Al vaciar el texto, _procesar_parpadeo lo detectará
	label.visible = false

func mostrar_pago(monto: float):
	pago_caja.text = "+ $%.2f" % monto
	pago_caja.modulate = Color.SPRING_GREEN
	await get_tree().create_timer(1.5).timeout
	pago_caja.text = ""

func _procesar_parpadeo():
	# REGLA DE ORO: Si el GameManager dice que hay pausa, no hacemos nada
	if GameManager.juego_pausado:
		return
	# print(GameManager.juego_pausado, " VARIABLE GLOBAL PAUSA - Usuario")
	# Si no está pausado, ejecutamos la lógica normal
	if notif_luz.text != "":
		notif_luz.visible = !notif_luz.visible
	if notif_agua.text != "":
		notif_agua.visible = !notif_agua.visible
	
	if notif_luz.text == "" and notif_agua.text == "":
		timer_parpadeo.stop()

func _notification(what):
	# Esta función detecta cuando el juego entra o sale de pausa
	if what == NOTIFICATION_PAUSED:
		timer_parpadeo.paused = true # Forzamos el congelamiento del timer
		print("UI: Timer de parpadeo congelado por pausa")
	elif what == NOTIFICATION_UNPAUSED:
		timer_parpadeo.paused = false # Lo reactivamos
		print("UI: Timer de parpadeo reactivado")
