extends Node

var slot_seleccionado: int = 1
var solo_un_jugador: bool = true
var p1_actual: String = ""
var p2_actual: String = ""
var dinero_actual: float = 500.0
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

# Reloj de la Jornada (El que usará la Tienda)
var reloj_jornada_horas: int = 8
var reloj_jornada_minutos: int = 0

func cargar_partida(slot):
	var datos = get_node("/root/DatabaseManager").obtener_datos_slot(slot)
	if not datos.is_empty():
		p1_actual = datos["p1_name"]
		p2_actual = datos["p2_name"]
		dinero_actual = datos["money"]
		dia_actual = datos["day"]
		
		# --- CAMBIO AQUÍ: Determinamos si es un solo jugador según el nombre guardado ---
		if p2_actual == "N/A" or p2_actual == "":
			solo_un_jugador = true
		else:
			solo_un_jugador = false
		
		print("Cargando partida de: ", p1_actual, " | Solo un jugador: ", solo_un_jugador)
		get_tree().change_scene_to_file("res://Scenas/Tienda.tscn")
