Este proyecto es un simulador de gestión y estrategia desarrollado en Godot 4.6, desarrollado por Carlos Nava Rodríguez y César Iván Nava Topete como proyecto final de la Materia de Pragramacion 3D impartido por el Profesor Jose Luis David Bonilla Carranza de la Universidad de Guadalajara en el Centro Universitario de Ciencias Exactas e Ingenierías. El jugador asume el rol de dueño de una tienda minorista llamada OXCO, donde el objetivo principal es maximizar las ganancias diarias mientras se gestionan diversos factores críticos: atención al cliente, mantenimiento de instalaciones, pago de servicios (luz, agua, renta) y la reputación del establecimiento. El juego destaca por su sistema de resultados dinámico, donde cada acción del jugador (como descuidar la limpieza o tardar en atender) se traduce en penalizaciones financieras reales reflejadas en un ticket de cierre de jornada.

Con una jornada de 12 horas (08:00 - 20:00), ¿Podras Mantener el tu Negocio?

Desarrolado por:
- Carlos Nava Rodríguez
- César Iván Nava Topete

El sistema de controles ha sido diseñado para una interaccion fluida y centrada en la gestion de recursos:

| **Acciones** | **Controles** |
| :--- | ---: |
| **Movimiento del Jugador** | Teclas *W, A, S, D* / *Flechas Direccionales* | 
| **Interaccion (Caja/Limpieza)** | Tecla *E / Ctrl* |
| **Pausa** | Tecla *ESC* |
| **Navegacion de Menús** | Raton *(Mouse)* |

**Gestión de Fila y Caja:** 
- Los clientes llegan de forma procedural, se forman en una fila dinámica y poseen una barra de paciencia. El jugador debe procesar los pagos antes de que el cliente abandone el local por enojo.

**Sistema de Reseñas y Penalizaciones:** 
- Cada cliente que abandona la tienda sin comprar genera una "reseña negativa". Al final del día, estas se contabilizan como multas fijas que afectan el balance final.

**Mantenimiento y Servicios:** 
- Los jugadores deben re realizar el mantenimiento de la Luz y el Agua, estas se reaparar por medio de la combinacion de 5 teclas (W, A, S, D / Flechas Direccionales), se tiene la varaible se Jugardor 1 y Jugadror 2, si solo se esta en una partida con un solo jugador (Jugador 1) este puede realizar las reparacion de ambos servicios, si se juega con dos jugadores entonces el Jugador 1 solo puede reparar la Luz (W, A, S, D) y el Jugador 2 solo puede reparar el Agua (Flechas direccionales) 
- El jugador debe lidiar con eventos de suciedad en los Estantes, Refrigeradores y Verduras.
- Además, existen gastos operativos fijos (Renta, Luz, Agua) y variables (Abasto de mercancía).

**Estado de Bancarrota:** Si el balance proyectado es menor a $0 al finalizar el día, el sistema detecta la quiebra del negocio, forzando un reinicio de las estadísticas a los valores iniciales (Día 1, $500).

**Persistencia de Datos:** Sistema de guardado automático que registra el progreso (día actual y dinero total) en una base de datos local o almacenamiento del navegador (SQLite y JSON).

**Tecnologías y Métodos Utilizados**

Motor de Desarrollo: Godot Engine 4.6 (GDScript).

**Inteligencia Artificial de NPCs:**

- Navegación por Waypoints: Implementación de rutas predefinidas y aleatorias mediante nodos de posición para simular el flujo de clientes dentro de la tienda.

- Máquina de Estados Simple: Los NPCs transitan entre estados de "Caminata", "Espera en Fila", "Pago" y "Salida".

**Imagenes del Juego**

https://youtu.be/IkbZFVv3Lyw
<img width="1254" height="1254" alt="Logo OXCO" src="https://github.com/user-attachments/assets/37776d93-9d95-4191-9beb-5ea65dd5da31" />
<img width="794" height="797" alt="image" src="https://github.com/user-attachments/assets/97e2b7f3-b058-48f0-835f-03de1dcb8df4" />
<img width="791" height="792" alt="image" src="https://github.com/user-attachments/assets/d3b41ab3-d5c7-4afc-8ed4-421e7b7ff35d" />
<img width="789" height="792" alt="image" src="https://github.com/user-attachments/assets/248f5919-ec19-4e4e-9795-e845dea46beb" />
<img width="792" height="791" alt="image" src="https://github.com/user-attachments/assets/23407723-0be9-4d86-801a-a0f26bd10076" />
<img width="786" height="790" alt="image" src="https://github.com/user-attachments/assets/1c10e56b-c4c2-4a95-b5ba-a1a84ffa3554" />
<img width="742" height="736" alt="image" src="https://github.com/user-attachments/assets/9ab4b0bd-91c6-4632-a88a-f6bb14686261" />


**Creditos:**

*Musica y SFX*

- https://freesound.org/people/finneganmilla/sounds/554314/
- https://www.bfxr.net/?sfx=Footsteppr~Random4~0.848014721746663~0.485013022981358...
- https://opengameart.org/content/victory
- https://opengameart.org/content/game-over
- https://opengameart.org/content/ui-and-item-sound-effect-jingles-sample-2
- https://opengameart.org/content/ui-accept-or-forward
- https://opengameart.org/content/which-brand-of-mustard-shall-i-buy-congusbongus-...
- https://opengameart.org/content/explosion-0
- https://opengameart.org/content/8bit-menu-highlight
- https://opengameart.org/content/spell-4-fire
- https://opengameart.org/content/foot-walking-step-sounds-on-stone-water-snow-woo...
- https://opengameart.org/content/purchasing-sound-effect
- https://opengameart.org/content/door-open-door-close-set
- https://opengameart.org/content/american-interstates-from-iowa-to-california-sou...
- https://opengameart.org/content/energy-drain
- https://opengameart.org/content/jc-sounds-mechanical-pack-vol-1
- https://www.youtube.com/watch?v=EuLJv2qONRY
- https://opengameart.org/content/game-over-bad-chest-sfx
- https://opengameart.org/content/interface-sounds-starter-pack
- https://opengameart.org/content/vacuumpressure-seal-opening

*Sprites*

- https://kicked-in-teeth.itch.io/button-ui
- https://pixel-guru.itch.io/tiny-town
- https://limezu.itch.io/moderninteriors
- https://dreammixgames.itch.io/keyboard-keys-for-ui
- https://axulart.itch.io/small-8-direction-characters
- Uso de Inteligencia Artificial (Gemini) para la creacion de algunos Sprites Utilizados en el desarrollo
