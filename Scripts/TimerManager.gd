extends Node

signal hora_cambiada(hora, minutos)
signal dia_terminado

var tiempo_transcurrido: float = 0.0
const SEGUNDOS_POR_MINUTO_VIRTUAL: float = 1.0 # 1 hora = 60 segundos real. 12 horas = 12 min.

func _process(delta):
	# Primero verificamos que la escena no sea nula
	var escena_actual = get_tree().current_scene
	
	if escena_actual != null and escena_actual.name == "Tienda":
		tiempo_transcurrido += delta
		
		if tiempo_transcurrido >= SEGUNDOS_POR_MINUTO_VIRTUAL:
			tiempo_transcurrido = 0
			GameManager.minutos_actuales += 1
			
			if GameManager.minutos_actuales >= 60:
				GameManager.minutos_actuales = 0
				GameManager.hora_actual += 1
				emit_signal("hora_cambiada", GameManager.hora_actual, GameManager.minutos_actuales)
				
			if GameManager.hora_actual >= 20: # Cierre a las 8 PM
				finalizar_dia()

func finalizar_dia():
	set_process(false) # Pausamos el tiempo
	emit_signal("dia_terminado")
	# Aquí es donde se abriría el menú de reabastecimiento
