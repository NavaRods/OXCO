extends Control

# Usamos la función nativa para obtener todos los hijos de un tipo
# @onready var anim_player = $AnimationPlayer

func _ready():
	# Iniciar todas las animaciones de los sprites
	reproducir_todo()

func reproducir_todo():
	# Buscamos en todos los PanelContainer a los AnimatedSprites
	# Esto es más eficiente que hacer 12 variables manuales
	for container in get_children():
		if container is PanelContainer:
			for sprite in container.get_children():
				if sprite is AnimatedSprite2D:
					sprite.play() # Reproduce su animación por defecto
