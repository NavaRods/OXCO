extends CanvasLayer

# --- REFERENCIAS ---
@onready var lbl_dia = $LabelDia
@onready var lbl_ventas = $VBoxContainer/LabelVentas
@onready var lbl_agua = $VBoxContainer/LabelAgua
@onready var lbl_luz = $VBoxContainer/LabelLuz
@onready var lbl_renta = $VBoxContainer/LabelRenta
@onready var lbl_abasto = $VBoxContainer/LabelAbasto
@onready var lbl_resenas = $VBoxContainer/LabelReseñas
@onready var lbl_multas = $VBoxContainer/LabelMultas
@onready var lbl_total = $LabelTotal

@onready var btn_continuar = $ButtonContinuar
@onready var btn_menu = $ButtonMenu

# --- SELLOS Y AUDIO ---
@onready var sello_victoria = $SelloVictoria
@onready var sello_derrota = $SelloDerrota

@onready var sonido_ticket = $SonidoTicket
@onready var sonido_sello = $SonidoSello
@onready var musica_vic = $SonidoVictoria
@onready var musica_der = $SonidoDerrota

# Guardamos la escala original que pusiste en el editor para que el Tween no la rompa
var escala_original_vic: Vector2
var escala_original_der: Vector2

func _ready():
	# 1. Capturar escalas del editor ANTES de que el script las toque
	escala_original_vic = sello_victoria.scale
	escala_original_der = sello_derrota.scale
	
	# 2. Estado inicial
	btn_continuar.hide()
	btn_menu.hide()
	sello_victoria.hide()
	sello_derrota.hide()
	limpiar_labels()
	
	# Conexiones
	if not btn_continuar.pressed.is_connected(_on_continuar_pressed):
		btn_continuar.pressed.connect(_on_continuar_pressed)
	if not btn_menu.pressed.is_connected(_on_menu_pressed):
		btn_menu.pressed.connect(_on_menu_pressed)
	
	animar_ticket()

func limpiar_labels():
	var labels = [lbl_dia, lbl_ventas, lbl_agua, lbl_luz, lbl_renta, lbl_abasto, lbl_resenas, lbl_multas, lbl_total]
	for l in labels: l.text = ""

func animar_ticket():
	# --- CÁLCULOS ---
	var ventas = GameManager.ganancias_del_dia
	var imp_agua = 60.0
	var imp_luz = 40.0
	var renta = 300.0
	var costo_abasto = ventas * 0.30
	var atendidos = GameManager.clientes_atendidos_exito
	var perdidos = GameManager.clientes_perdidos
	var balance_reputacion = atendidos - perdidos
	var monto_resenas = 0.0
	
	print("Total de clientes Atendidos: ", atendidos)
	print("Total de clientes Perdidos: ", perdidos)
	print("Balance de reputacion: ", balance_reputacion)
	
	var almacen_reputacion = GameManager.reputacion_total
	
	if balance_reputacion >= 0:
		# GANANCIA: Por cada cliente neto positivo, gana $10 (ajusta el valor a tu gusto)
		monto_resenas = balance_reputacion * 10.0
		GameManager.reputacion_total += atendidos
		if GameManager.dificultad_manual: GameManager.reputacion_total = almacen_reputacion
	else:
		# PÉRDIDA: Si hay más perdidos que atendidos, aplicamos penalización
		# Usamos tu lógica original de tasas pero basada en el déficit
		var deficit = abs(balance_reputacion)
		var tasa = 0.05 if deficit <= 5 else (0.10 if deficit <= 9 else 0.15)
		monto_resenas = -(deficit * tasa * 10.0) # Valor negativo para el balance
		GameManager.reputacion_total -= perdidos
		if GameManager.dificultad_manual: GameManager.reputacion_total = almacen_reputacion
		if GameManager.reputacion_total < 0: GameManager.reputacion_total = 0
	
	print("REPUTACION ACTUAL: ", GameManager.reputacion_total)
	
	var total_multas = GameManager.total_dinero_multas
	# print("CANTIDAD TOTAL DE RESEÑAS" + str(penalizacion_resenas))
	
	# El balance es sobre lo ganado HOY. 
	# Los 500 iniciales están en GameManager.dinero_actual, no deben sumarse al Label de "Ventas"
	var balance_final = GameManager.dinero_actual - (imp_agua + imp_luz + renta + costo_abasto + total_multas) + monto_resenas
	var dinero_proyectado = GameManager.dinero_actual + balance_final
	
	# --- SECUENCIA DE APARICIÓN ---
	if sonido_ticket: sonido_ticket.play()
	
	lbl_dia.add_theme_color_override("font_color", Color.BLACK)
	await mostrar_linea(lbl_dia, "" + str(GameManager.dia_actual))
	
	lbl_ventas.add_theme_color_override("font_color", Color.SPRING_GREEN)
	await mostrar_linea(lbl_ventas, "$" + str(snapped(GameManager.dinero_actual, 0.01)))
	
	# Gastos Fijos (Rojo)
	lbl_agua.add_theme_color_override("font_color", Color.RED)
	await mostrar_linea(lbl_agua, "$" + str(imp_agua))
	
	lbl_luz.add_theme_color_override("font_color", Color.RED)
	await mostrar_linea(lbl_luz, "$" + str(imp_luz))
	
	lbl_renta.add_theme_color_override("font_color", Color.RED)
	await mostrar_linea(lbl_renta, "$" + str(renta))
	
	# Abasto (Rojo)
	lbl_abasto.add_theme_color_override("font_color", Color.RED)
	await mostrar_linea(lbl_abasto, "$" + str(snapped(costo_abasto, 0.01)))
	
	# Reseñas (Dinámico: Verde o Rojo)
	lbl_resenas.text = ("+" if monto_resenas >= 0 else "-") + "$" + str(snapped(abs(monto_resenas), 0.01))
	if monto_resenas >= 0:
		lbl_resenas.add_theme_color_override("font_color", Color.SPRING_GREEN)
	else:
		lbl_resenas.add_theme_color_override("font_color", Color.RED)
	await get_tree().create_timer(0.4).timeout
	
	# Multas (Rojo)
	lbl_multas.add_theme_color_override("font_color", Color.RED)
	await mostrar_linea(lbl_multas, "$" + str(total_multas))
	
	if sonido_ticket: sonido_ticket.stop()
	
	await get_tree().create_timer(0.8).timeout
	
	lbl_total.text = "$" + str(snapped(balance_final, 0.01))
	lbl_total.add_theme_color_override("font_color", Color.GREEN if balance_final >= 0 else Color.RED)
	
	await get_tree().create_timer(1.2).timeout

	# --- SELLO FINAL Y LÓGICA DE BOTONES ---
	if balance_final >= 0:
		# 1. ACTUALIZAMOS LOS DATOS EN EL MANAGER ANTES DE GUARDAR
		GameManager.dinero_actual = balance_final
		GameManager.dia_actual += 1  # <--- SUBIMOS EL DÍA AQUÍ
		GameManager.reloj_jornada_horas = 8
		GameManager.reloj_jornada_minutos = 0
		GameManager.luz_global = true
		GameManager.agua_global = true
		
		# 2. GUARDAMOS EN LA DB (Ahora se guardará con el nuevo día y dinero acumulado)
		guardar_progreso_en_db()
		
		if musica_vic: musica_vic.play()
		await aparecer_sello(sello_victoria, escala_original_vic)
		
		btn_continuar.show()
		btn_menu.show()
	else:
		# CASO PERDER: Reset, NO guardamos el negativo, solo Menu
		if musica_der: musica_der.play()
		await aparecer_sello(sello_derrota, escala_original_der)
		
		# Reset de datos (se aplicará cuando cree partida nueva o reintente)
		GameManager.resetear_a_estado_inicial()
		
		guardar_progreso_en_db()
		# NO se sobreescriba con el fracaso y pueda reintentar.
		
		btn_menu.show() # Solo mostramos el botón de Menú

func aparecer_sello(nodo_sello, escala_destino):
	nodo_sello.show()
	if sonido_sello: sonido_sello.play(0.77)
	
	var tween = create_tween().set_parallel(true)
	# Multiplicamos la escala original por 3 para el efecto de caída
	nodo_sello.scale = escala_destino * 3.0
	nodo_sello.modulate.a = 0
	
	tween.tween_property(nodo_sello, "scale", escala_destino, 0.15).set_trans(Tween.TRANS_QUINT).set_ease(Tween.EASE_OUT)
	tween.tween_property(nodo_sello, "modulate:a", 1.0, 0.05)
	
	await tween.finished
	sacudir_pantalla()

func mostrar_linea(label, texto):
	label.text = texto
	await get_tree().create_timer(0.4).timeout

func sacudir_pantalla():
	var shake = create_tween()
	shake.tween_property(self, "offset", Vector2(5, 5), 0.05)
	shake.tween_property(self, "offset", Vector2(-5, -5), 0.05)
	shake.tween_property(self, "offset", Vector2(0, 0), 0.05)

func guardar_progreso_en_db():
	# Añadimos la reputación al final de la llamada
	'''DatabaseManager.actualizar_progreso(
		GameManager.slot_seleccionado, 
		GameManager.dinero_actual, 
		GameManager.dia_actual,
		GameManager.reputacion_total  # <--- Este es el dato que faltaba
	)'''
	DatabaseManager.actualizar_progreso(GameManager.slot_seleccionado)
	if OS.has_feature("web"):
		JavaScriptBridge.eval("FS.syncfs(false, function (err) { });")

func _on_continuar_pressed():
	# Guardado extra por seguridad
	# guardar_progreso_en_db()
	
	GameManager.ganancias_del_dia = 0.0
	GameManager.clientes_perdidos = 0
	GameManager.clientes_atendidos_exito = 0
	GameManager.total_dinero_multas = 0
	get_tree().change_scene_to_file("res://Scenas/Tienda.tscn")

func _on_menu_pressed():
	# Si el jugador ganó, guardamos antes de salir
	get_tree().change_scene_to_file("res://Scenas/Menu.tscn")
