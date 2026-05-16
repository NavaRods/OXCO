extends Node

var reintentos: int = 0
const MAX_REINTENTOS: int = 3
const API_URL = "https://open.er-api.com/v6/latest/USD" # API de ejemplo gratuita

func consultar_tipo_cambio():
	var http = HTTPRequest.new()
	add_child(http)
	http.request_completed.connect(_on_request_completed)
	
	print("Consultando API de tipo de cambio...")
	var error = http.request(API_URL)
	if error != OK:
		manejar_error()

func _on_request_completed(result, response_code, headers, body):
	if result == HTTPRequest.RESULT_SUCCESS and response_code == 200:
		var json = JSON.parse_string(body.get_string_from_utf8())
		if json and json.has("rates"):
			GameManager.precio_dolar = json["rates"]["MXN"]
			print("Tipo de cambio actualizado: $", GameManager.precio_dolar, " MXN")
			reintentos = 0
		else:
			manejar_error()
	else:
		manejar_error()

func manejar_error():
	reintentos += 1
	if reintentos <= MAX_REINTENTOS:
		print("Error en API. Reintento ", reintentos, "...")
		consultar_tipo_cambio()
	else:
		print("API Fallida tras 3 intentos. Usando valores locales (MXN 18.0)")
		GameManager.precio_dolar = 18.0 # Respaldo local (Requisito 6)
