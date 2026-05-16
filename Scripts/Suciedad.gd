extends Node2D

var niveles = {
	"Estanteria1": 0, "Estanteria2": 0, "Estanteria3": 0,
	"Refrigerador1": 0, "Refrigerador2": 0, "Refrigerador3": 0,
	"Verduras": 0
}

func _ready():
	# IMPORTANTE: Asegurarnos de que el timer se cree y se añada correctamente
	var timer_suciedad = Timer.new()
	timer_suciedad.name = "TimerSuciedadInterno"
	add_child(timer_suciedad)
	
	timer_suciedad.wait_time = 3.0 # Prueba con 3 segundos para ver resultados rápido
	timer_suciedad.one_shot = false
	timer_suciedad.autostart = true
	timer_suciedad.timeout.connect(_on_timer_suciedad)
	
	# Forzamos el inicio por si acaso
	timer_suciedad.start()
	
	print("SISTEMA SUCIEDAD: Activo. Timer configurado a: ", timer_suciedad.wait_time, "s")

func _on_timer_suciedad():
	print("--- EVENTO: Intentando ensuciar algo ---") # Si no ves esto, el timer no sirve
	var opciones = niveles.keys()
	var elegido = opciones.pick_random()
	ensuciar_mueble(elegido)

func ensuciar_mueble(nombre_mueble: String):
	if niveles[nombre_mueble] < 3:
		niveles[nombre_mueble] += 1
		var nivel_actual = niveles[nombre_mueble]
		print("SUCIEDAD: ", nombre_mueble, " sube a nivel ", nivel_actual)
		actualizar_visual(nombre_mueble, nivel_actual)

func actualizar_visual(nombre: String, nivel: int):
	var nodo_padre = get_node_or_null(nombre)
	
	if not nodo_padre:
		print("ERROR: No encontré el nodo padre: ", nombre)
		return

	if nombre == "Verduras":
		var hongo = nodo_padre.get_node_or_null("Hongo")
		if hongo:
			hongo.visible = true
			hongo.play("Hongo")
	else:
		var nombre_sprite = "Sprite2D" + str(nivel)
		var sprite = nodo_padre.get_node_or_null(nombre_sprite)
		
		if sprite:
			sprite.visible = true
			print("VISIBILIDAD: ", nombre, "/", nombre_sprite, " ahora es VISIBLE")
		else:
			print("ERROR: No encontré el sprite: ", nombre, "/", nombre_sprite)

func limpiar_mueble(nombre_mueble: String):
	if niveles.has(nombre_mueble):
		# Reseteamos el nivel a 0
		niveles[nombre_mueble] = 0
		
		# Buscamos el nodo padre (ej. Estanteria1) y ocultamos todos sus hijos
		var nodo_padre = get_node_or_null(nombre_mueble)
		if nodo_padre:
			for hijo in nodo_padre.get_children():
				hijo.visible = false
				if hijo is AnimatedSprite2D:
					hijo.stop()
			print("SUCIEDAD: ", nombre_mueble, " reseteado a limpio.")
			$"../SonidoLimpiar".play()
