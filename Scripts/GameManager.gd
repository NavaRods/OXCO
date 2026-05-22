extends Node

var slot_seleccionado: int = 1
var solo_un_jugador: bool = true
var p1_actual: String = ""
var p2_actual: String = ""
var dinero_actual: float = 0
var popup_creacion = null
var hora_actual: int = 8
var minutos_actuales: int = 0
var dia_actual: int = 1
var temperatura_actual: float = 25.0
var clima_actual: String = "Soleado" # Soleado, Lluvioso, Frío, Calor
var precio_dolar: float = 18.0 # Valor base MXN
var juego_pausado: bool = false
var slot_a_borrar: int = -1
var ganancias_del_dia: float = 0.0
var clientes_perdidos: int = 0
var niveles_suciedad_acumulados: int = 0
var total_dinero_multas: int = 0
var clientes_atendidos_exito: int = 0
var reputacion_total: float = 0.0 # Persistente entre días
var estrellas_seleccionadas: int = 0
var dificultad_manual: int = 0 # 0 no, 1 sí
var luz_global: bool = true
var agua_global: bool = true

# Reloj de la Jornada (El que usará la Tienda)
var reloj_jornada_horas: int = 8
var reloj_jornada_minutos: int = 0

func cargar_partida(slot):
	var datos = get_node("/root/DatabaseManager").obtener_datos_slot(slot)
	if not datos.is_empty():
		p1_actual = datos["p1_name"]
		p2_actual = datos["p2_name"]
		dinero_actual = float(datos.get("money", 0.0))
		dia_actual = int(datos.get("day", 1))
		reputacion_total = datos["reputation"]
		estrellas_seleccionadas = datos.get("cantidad_estrellas", 0)
		dificultad_manual = datos.get("select_dificult", 0)
		reloj_jornada_horas = int(datos.get("hora", 8))
		reloj_jornada_minutos = int(datos.get("minutos", 0))
		luz_global = bool(datos.get("luz_activa", 1))
		agua_global = bool(datos.get("agua_activa", 1))
		
		# --- CAMBIO AQUÍ: Determinamos si es un solo jugador según el nombre guardado ---
		if p2_actual == "N/A" or p2_actual == "":
			solo_un_jugador = true
		else:
			solo_un_jugador = false
		
		print("Cargando partida de: ", p1_actual, " | Solo un jugador: ", solo_un_jugador)
		get_tree().change_scene_to_file("res://Scenas/Tienda.tscn")

func resetear_a_estado_inicial():
	GameManager.dinero_actual = 0.0
	GameManager.dia_actual = 1
	# La reputación vuelve a ser 50 puntos por cada estrella elegida al inicio
	GameManager.reputacion_total = float(estrellas_seleccionadas * 50)
	GameManager.luz_global = true
	GameManager.agua_global = true
	GameManager.reloj_jornada_horas = 8
	GameManager.reloj_jornada_minutos = 0

func obtener_estrellas_actuales() -> int:
	return int(clamp(reputacion_total / 50.0, 0, 5))

# Dificultad basada en las estrellas (3 o más = Difícil, 5 = Extremo)
func obtener_nivel_dificultad() -> int:
	var estrellas = obtener_estrellas_actuales()
	if estrellas >= 5: return 2 # Extremo
	if estrellas >= 3: return 1 # Difícil
	return 0 # Normal

func obtener_multiplicador_spawn() -> float:
	var nivel = obtener_nivel_dificultad()
	if nivel == 2: return 0.5 # NPCs salen el doble de rápido
	if nivel == 1: return 0.75 # NPCs salen 25% más rápido
	return 1.0

func obtener_multiplicador_averias() -> float:
	var nivel = obtener_nivel_dificultad()
	if nivel == 2: return 0.6
	if nivel == 1: return 0.8
	return 1.0

func obtener_multiplicador_paciencia() -> float:
	var estrellas = obtener_estrellas_actuales()
	if estrellas >= 5: return 1.8  # Casi el doble de rápido (Extremo)
	if estrellas >= 3: return 1.4  # 40% más rápido (Difícil)
	return 1.0                     # Paciencia normal (0-2 estrellas)
