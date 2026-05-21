extends Panel

# Ajustamos las rutas según tu nuevo orden de nodos
@onready var input_p1 = $PopupPanel/MarginContainer/VBoxContainer/InputP1
@onready var input_p2 = $PopupPanel/MarginContainer/VBoxContainer/InputP2
@onready var check_multi = $PopupPanel/MarginContainer/VBoxContainer/CheckMultiplayer
@onready var btn_confirmar = $PopupPanel/MarginContainer/VBoxContainer/BtnConfirmar
@onready var btn_cancelar = $PopupPanel/MarginContainer/VBoxContainer/BtnCancelar

func _ready():
	input_p2.visible = false
	self.hide()

# Usamos este evento para avisarle al GameManager cuál popup está activo
func _on_visibility_changed():
	if self.visible:
		GameManager.popup_creacion = self

func _on_check_multiplayer_toggled(button_pressed):
	input_p2.visible = button_pressed

func _on_btn_cancelar_pressed():
	self.hide()

func _on_btn_confirmar_pressed():
	var p1 = input_p1.text.strip_edges()
	var p2 = input_p2.text.strip_edges() if input_p2.visible else "N/A"
	
	if p1 == "": return
		
	GameManager.solo_un_jugador = !check_multi.button_pressed
	GameManager.p1_actual = p1
	GameManager.p2_actual = p2
	
	DatabaseManager.guardar_nueva_partida(GameManager.slot_seleccionado, p1, p2)
	self.hide()
	
	get_tree().call_group("botones_slots", "actualizar_info_visual")
	GameManager.dinero_actual = 0
	GameManager.dia_actual = 1
	get_tree().change_scene_to_file("res://Scenas/Tienda.tscn")
