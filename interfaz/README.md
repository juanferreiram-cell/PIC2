# 🤖 Interfaz de Usuario del Robot (Flutter)

Bienvenido al proyecto de la interfaz de usuario del robot, desarrollada en Flutter.
Desde esta app se controla los modos, movimientos y sistemas de voz y música del robot en tiempo real.

El código fuente principal está dentro de la carpeta:

📁 lib/

En esta carpeta esta:

🧭 main.dart → punto de entrada de la aplicación.  
📡 api/ → llamadas HTTP y endpoints del backend (FastAPI).  
⚙️ core/ → configuración, constantes y utilidades compartidas como colores y letras.  
🖥️ screens/ → todas las pantallas (interfaz gráfica, menús, controles).  
🧩 models/ → clases de datos usadas para mapear las respuestas del backend (FastAPI) y mover información dentro de la app. 
🔧 services/ → servicios de negocio (control de música/voz, sesión, etc.).
