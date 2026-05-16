extends Control

@onready var Musica_Fondo = $MusicaFondo

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	Musica_Fondo.play()
