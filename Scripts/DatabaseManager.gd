extends Node

# --- CAMBIO AQUÍ ---
# Ya no usamos 'const SQLite = preload(...)'. 
# El plugin registra la clase 'SQLite' automáticamente. 
# Para evitar el error de "shadowing", llamaremos a nuestra variable 'db_instancia'.

var db: SQLite # Usamos el tipo de dato nativo del plugin
# var db_path: String = "user://tienda_database.db" # Estoy usando esto para ver la tabla de datos
var db_path: String = "user://tienda_db.save"

func _ready():
	# Inicializar la base de datos usando la clase global del plugin
	db = SQLite.new()
	db.path = db_path
	
	# El resto de tu código se mantiene igual, pero asegúrate de abrir la DB
	if db.open_db():
		var table_dict = {
			"id": {"data_type": "int", "primary_key": true},
			"p1_name": {"data_type": "text"},
			"p2_name": {"data_type": "text"},
			"money": {"data_type": "float"},
			"day": {"data_type": "int"},
			"reputation": {"data_type": "float"},
			"cantidad_estrellas": {"data_type": "int"}, # Nueva columna
			"select_dificult": {"data_type": "int"},      # Nueva columna (0 o 1)
			"hora": {"data_type": "int"},
			"minutos": {"data_type": "int"},
			"luz_activa": {"data_type": "int"}, # 1 para true, 0 para false
			"agua_activa": {"data_type": "int"}
		}
		db.create_table("save_slots", table_dict)
		_sync_db_web()
		print("Base de Datos: Inicializada correctamente.")
	else:
		print("ERROR: No se pudo abrir la base de datos.")

# --- PERSISTENCIA WEB ---
func _sync_db_web():
	if OS.has_feature("web"):
		JavaScriptBridge.eval("FS.syncfs(false, function(err) { });")

# --- OBTENER DATOS ---
func obtener_datos_slot(index: int) -> Dictionary:
	# Buscamos la fila que coincida con el ID del slot
	db.query("SELECT * FROM save_slots WHERE id = " + str(index) + ";")
	
	if db.query_result.size() > 0:
		# SQLite devuelve una lista de diccionarios, tomamos el primero [0]
		return db.query_result[0]
	
	return {}

# --- GUARDAR / CREAR NUEVA PARTIDA ---
func guardar_nueva_partida(index: int, p1: String, p2: String, estrellas: int, manual: int):
	# Preparamos los datos
	var row = {
		"id": index,
		"p1_name": p1,
		"p2_name": p2 if p2 != "" else "N/A",
		# "money": GameManager.dinero_actual,
		# "day": GameManager.dia_actual,
		"money": 0.0,
		"day": 1,
		"reputation": float(estrellas * 50), # Inicializamos la reputación según las estrellas elegidas
		"cantidad_estrellas": estrellas,
		"select_dificult": manual,
		"hora": 8, # Hora de inicio por defecto
		"minutos": 0,
		"luz_activa": 1,
		"agua_activa": 1
	}
	
	# Verificamos si el slot ya existe
	db.query("SELECT id FROM save_slots WHERE id = " + str(index) + ";")
	
	if db.query_result.size() > 0:
		# Si existe, actualizamos (UPDATE)
		db.update_rows("save_slots", "id = " + str(index), row)
		_sync_db_web()
		print("Base de Datos: Slot ", index, " actualizado.")
	else:
		# Si no existe, insertamos (INSERT)
		db.insert_row("save_slots", row)
		_sync_db_web()
		print("Base de Datos: Nueva partida creada en Slot ", index)

# --- GUARDAR PROGRESO (Fin de día o Resultados) ---
# Esta función es la que llamarás desde el GameManager al final del día
'''func actualizar_progreso(index: int, dinero: float, dia: int, reputacion: float):
	var query = "UPDATE save_slots SET money = %f, day = %d, reputation = %f WHERE id = %d;" % [dinero, dia, reputacion, index]
	db.query(query)
	_sync_db_web()
'''
func actualizar_progreso(index: int):
	var query = "UPDATE save_slots SET money = %f, day = %d, reputation = %f, hora = %d, minutos = %d, luz_activa = %d, agua_activa = %d WHERE id = %d;" % [
		GameManager.dinero_actual, 
		GameManager.dia_actual, 
		GameManager.reputacion_total,
		GameManager.reloj_jornada_horas,
		GameManager.reloj_jornada_minutos,
		1 if GameManager.luz_global else 0,
		1 if GameManager.agua_global else 0,
		index
	]
	db.query(query)
	_sync_db_web()

# --- ELIMINAR PARTIDA ---
func eliminar_partida(index: int) -> bool:
	db.query("DELETE FROM save_slots WHERE id = " + str(index) + ";")
	_sync_db_web()
	# En SQLite, si no hay error la consulta es exitosa aunque no haya borrado nada,
	# pero para tu lógica devolveremos true.
	print("Base de Datos: Partida eliminada del Slot: ", index)
	return true
