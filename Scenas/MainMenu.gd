extends Control

@onready var Musica_Fondo = $MusicaFondo

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	Musica_Fondo.play()



func _on_btn_salir_pressed() -> void:
	print("Saliendo de la Tienda")
	get_tree().change_scene_to_file("res://Scenas/Menu.tscn")


func _on_button_tutorial_pressed() -> void:
	print("Entrando al Tutorial")
	get_tree().change_scene_to_file("res://Scenas/Tutorial.tscn")
