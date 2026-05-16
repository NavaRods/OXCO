extends Node

@onready var http_request = $HTTPRequest

# Esta función ahora devuelve el número directamente usando await
func obtener_presupuesto_nuevo() -> float:
	var post_id = randi_range(1, 100)
	var url = "https://jsonplaceholder.typicode.com/posts/" + str(post_id)
	
	var error = http_request.request(url)
	if error != OK:
		return 50.0 # Valor de seguridad si la petición ni siquiera sale
	
	# Esperamos a que la señal interna del HTTPRequest termine
	var resultado = await http_request.request_completed
	
	# El array de resultado contiene: [result, response_code, headers, body]
	var response_code = resultado[1]
	var body = resultado[3]
	
	if response_code == 200:
		var json = JSON.parse_string(body.get_string_from_utf8())
		if json and json.has("title"):
			var titulo = json["title"]
			var presupuesto = titulo.length() * 1.5
			return float(presupuesto)
	
	return 50.0 # Valor por defecto si falla algo
