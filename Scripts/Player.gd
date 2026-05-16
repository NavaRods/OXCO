extends CharacterBody2D

@export var player_id: int = 1 
@export var speed: float = 150.0
var esta_reparando: bool = false

@onready var _animated_sprite = $AnimatedPlayer
@onready var tecla_flotante = $TeclaFlotante
@onready var sprite_tecla = $TeclaFlotante/AnimatedSprite2D

func _ready():
	# Al iniciar, forzamos la animación de 'Frente' 
	# correspondiente al ID del jugador (1 o 2)
	var nombre_inicial = "Player_" + str(player_id) + "_Frente"
	
	if _animated_sprite.sprite_frames.has_animation(nombre_inicial):
		_animated_sprite.play(nombre_inicial)
	else:
		print("Error: No se encontró la animación inicial: ", nombre_inicial)
		
	tecla_flotante.hide()

func _physics_process(_delta):
	var direction = Vector2.ZERO
	
	if esta_reparando:
		velocity = Vector2.ZERO
		# Opcional: Aquí podrías poner una animación de "Trabajando"
		move_and_slide()
		return
	
	if player_id == 1:
		direction = Input.get_vector("A", "D", "W", "S")
	else:
		direction = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	
	velocity = direction.normalized() * speed
	move_and_slide()
	
	actualizar_animacion(direction)

func actualizar_animacion(dir: Vector2):
	var prefix = "Player_" + str(player_id) + "_"
	var anim_name = ""
	
	if dir == Vector2.ZERO:
		# Lógica para ESTÁTICOS: Quitamos el "Mov_" del nombre actual
		var current = _animated_sprite.animation
		anim_name = current.replace(prefix, "").replace("Mov_", "")
	else:
		# Lógica para MOVIMIENTO: Agregamos "Mov_" al nombre de la dirección
		anim_name = "Mov_" + obtener_nombre_direccion(dir)
	
	var nombre_final = prefix + anim_name
	
	if _animated_sprite.sprite_frames.has_animation(nombre_final):
		_animated_sprite.play(nombre_final)

func obtener_nombre_direccion(dir: Vector2) -> String:
	var threshold = 0.4
	
	# Diagonales (Nombres exactos de tu lista)
	if dir.x > threshold and dir.y < -threshold: return "Diagonal_Atras_Derecha"
	if dir.x < -threshold and dir.y < -threshold: return "Diagonal_Atras_Izquierda"
	if dir.x > threshold and dir.y > threshold: return "Diagonal_Frente_Derecha"
	if dir.x < -threshold and dir.y > threshold: return "Diagonal_Frente_Izquierda"
	
	# Direcciones Simples
	if abs(dir.x) > abs(dir.y):
		return "Derecha" if dir.x > 0 else "Izquierda"
	else:
		return "Frente" if dir.y > 0 else "Atras"


func gestionar_tecla(mostrar: bool, tipo_area: String = ""):
	if not mostrar:
		tecla_flotante.hide()
		return

	# Determinamos qué animación poner
	var anim_a_poner = ""
	var es_p1 = is_in_group("Player1")
	
	match tipo_area:
		"Limpieza":
			anim_a_poner = "Accion_Player_1" if es_p1 else "Accion_Player_2"
		
		"Luz":
			# Solo P1 puede ver su tecla en Luz
			if es_p1: anim_a_poner = "Accion_Player_1"
			
		"Agua":
			# P2 ve su tecla, o P1 la ve si está solo
			if not es_p1: 
				anim_a_poner = "Accion_Player_2"
			elif GameManager.solo_un_jugador: 
				anim_a_poner = "Accion_Player_1"
				
		"Caja":
			anim_a_poner = "Accion_Player_1" if es_p1 else "Accion_Player_2"

	# Si se asignó una animación válida, mostramos
	if anim_a_poner != "":
		sprite_tecla.play(anim_a_poner)
		tecla_flotante.show()
		
		# --- Lógica del texto de cancelar ---
		var label_cancelar = tecla_flotante.get_node_or_null("LabelCancelar")
		if label_cancelar:
			# Si el jugador está reparando, mostramos el aviso
			label_cancelar.visible = esta_reparando
	else:
		tecla_flotante.hide()
