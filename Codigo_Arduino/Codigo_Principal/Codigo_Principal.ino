#include <Dynamixel2Arduino.h>
#include <SoftwareSerial.h>

// CONFIGURACIÓN DYNAMIXEL 
#if defined(ARDUINO_AVR_UNO)
  #define DXL_SERIAL Serial
  const int DXL_DIR_PIN = 2;
#elif defined(ARDUINO_AVR_MEGA2560)
  #define DXL_SERIAL Serial
  const int DXL_DIR_PIN = 2;
#else
  #define DXL_SERIAL Serial
  const int DXL_DIR_PIN = 2;
#endif

const uint8_t XL430_1 = 100;
const uint8_t XL430_2 = 50;
const uint8_t XL320_1 = 17;
const uint8_t XL320_2 = 15;
const uint8_t XL320_3 = 16;

const long DXL_BAUDRATE = 1000000;
const float PROTO_VER = 2.0;

// Rangos de los motores
const int XL430_MIN_RAW = 0;
const int XL430_MAX_RAW = 4095;
const float XL430_RANGE_DEG = 360.0;

const int XL320_MIN_RAW = 0;
const int XL320_MAX_RAW = 1023;
const float XL320_RANGE_DEG = 300.0;

Dynamixel2Arduino dxl(DXL_SERIAL, DXL_DIR_PIN);

// Posición neutra/home
const float NEUTRO_430_1 = 180.0;
const float NEUTRO_430_2 = 180.0;
const float NEUTRO_320_1 = 150.0;
const float NEUTRO_320_2 = 150.0;
const float NEUTRO_320_3 = 150.0;

const int VELOCIDAD_NEUTRO = 50;

// Variables para posiciones iniciales
float posicionInicial430_1, posicionInicial430_2;
float posicionInicial320_1, posicionInicial320_2, posicionInicial320_3;

//COMUNICACION CON LA ESP32
SoftwareSerial espSerial(10, 11);  // RX, TX

int ultimoValorRecibido = -1;
unsigned long ultimoTiempo = 0;

// DECLARACIÓN DE FUNCIONES
// Dynamixel
void IniciarMotores(void);
void configurarVelocidad(int velocidad);
void posicionInicial(void);
void posicionNeutra(void);
void movimiento(float a, float b, float c, float d, float e);
void movimientoSuave(float a, float b, float c, float d, float e, int velocidad);
void saludar(float a, float b, float c, float d, float e);
void emergencia();
void imprimirPosicionesActuales();
void leerPosicionesActuales();
bool estaEnPosicionNeutra();
int gradosToXL430(float grados);
int gradosToXL320(float grados);
float xl430ToGrados(int rawValue);
float xl320ToGrados(int rawValue);

// Comunicación
void procesarDato(String dato);
void ejecutarAccion(int numero);
void enviarRespuesta(String mensaje);

// Inicializa serie, Dynamixel y deja el robot listo
void setup() {
  Serial.begin(115200);
  espSerial.begin(9600);
  
  delay(1000);
  Serial.println("=== INICIANDO SISTEMA ===");
  
  // Inicializar Dynamixel
  IniciarMotores();
  delay(1000);
  
  leerPosicionesActuales();
  
  // Verificar posición neutra
  if (!estaEnPosicionNeutra()) {
    Serial.println("Robot no está en posición neutra. Moviendo a home...");
    posicionNeutra();
  } else {
    Serial.println("Robot ya está en posición neutra.");
  }
  
  Serial.println("Sistema listo - Esperando comandos de ESP32");
  enviarRespuesta("LISTO");
}

// Bucle principal: lee comandos del ESP32 y mantiene el sistema
void loop() {
  // Leer comandos de ESP32
  if (espSerial.available()) {
    String dato = espSerial.readString();
    dato.trim();
    procesarDato(dato);
  }
}

// Procesa el dato recibido por serie y despacha acciones
void procesarDato(String dato) {
  Serial.print("Dato recibido: ");
  Serial.println(dato);
  
  int numero = dato.toInt();
  
  if (numero != 0 || dato == "0") {
    ultimoValorRecibido = numero;
    ultimoTiempo = millis();
    
    Serial.print("Número procesado: ");
    Serial.println(numero);
    
    ejecutarAccion(numero);
    enviarRespuesta("OK_" + String(numero));
  } else {
    Serial.print("Dato no reconocido: ");
    Serial.println(dato);
  }
}

// Ejecuta la acción correspondiente al número recibido
void ejecutarAccion(int numero) {
  Serial.print("Ejecutando acción: ");
  Serial.println(numero);
  
  switch(numero) {
    case 0:
      // Mover 45 grados todos
      Serial.println("Mover 45 grados cada uno°");
      movimiento(45.0, 45.0, 45.0, 45.0, 45.0);
      break;
      
    case 1:
      // Mover 90 grados todos
      Serial.println("Mover 90 grados cada uno°");
      movimiento(90.0, 90.0, 90.0, 90.0, 90.0);
      break;
      
    case 2:
      // Mover parte XL430 a 90°, ignorar XL320
      Serial.println("Acción 2: Mover XL320_1 a 45°");
      movimiento(90.0, 90.0, -1, -1, -1);
      break;
      
    case 3:
      // Mover solo XL320 a 90°
      Serial.println("Acción 3: Mover XL320_2 a 45°");
      movimiento(-1, -1, 90.0, 90.0, 90.0);
      break;
      
    case 4:
      // Mover todos a 180°
      Serial.println("Acción 4: Mover XL320_3 a 45°");
      movimiento(180.0, 180.0, 180.0, 180.0, 180.0);
      break;
      
    default:
      Serial.print("Valor no reconocido: ");
      Serial.println(numero);
      enviarRespuesta("ERROR_COMANDO");
  }
}

// Envía una respuesta al ESP32 por puerto serie
void enviarRespuesta(String mensaje) {
  espSerial.println(mensaje);
  Serial.print("Enviado a ESP32: ");
  Serial.println(mensaje);
}

// Convierte grados a unidad RAW del XL430
int gradosToXL430(float grados) {
  int rawValue = (grados / XL430_RANGE_DEG) * (XL430_MAX_RAW - XL430_MIN_RAW);
  if (rawValue < XL430_MIN_RAW) rawValue = XL430_MIN_RAW;
  if (rawValue > XL430_MAX_RAW) rawValue = XL430_MAX_RAW;
  return rawValue;
}

// Convierte grados a unidad RAW del XL320
int gradosToXL320(float grados) {
  int rawValue = (grados / XL320_RANGE_DEG) * (XL320_MAX_RAW - XL320_MIN_RAW);
  if (rawValue < XL320_MIN_RAW) rawValue = XL320_MIN_RAW;
  if (rawValue > XL320_MAX_RAW) rawValue = XL320_MAX_RAW;
  return rawValue;
}

// Convierte RAW del XL430 a grados
float xl430ToGrados(int rawValue) {
  return (rawValue * XL430_RANGE_DEG) / (XL430_MAX_RAW - XL430_MIN_RAW);
}

// Convierte RAW del XL320 a grados
float xl320ToGrados(int rawValue) {
  return (rawValue * XL320_RANGE_DEG) / (XL320_MAX_RAW - XL320_MIN_RAW);
}

// Inicializa buses, protocolo y torque de los Dynamixel
void IniciarMotores(void) {
  DXL_SERIAL.begin(DXL_BAUDRATE);
  dxl.begin(DXL_BAUDRATE);
  dxl.setPortProtocolVersion(PROTO_VER);
  delay(1000);
  
  dxl.torqueOff(XL430_1);
  dxl.setOperatingMode(XL430_1, OP_POSITION);
  dxl.torqueOn(XL430_1);

  dxl.torqueOff(XL430_2);
  dxl.setOperatingMode(XL430_2, OP_POSITION);
  dxl.torqueOn(XL430_2);

  dxl.torqueOn(XL320_1);
  dxl.torqueOn(XL320_2);
  dxl.torqueOn(XL320_3);

  Serial.println("Motores inicializados");
}

// Configura la velocidad objetivo para todos los motores
void configurarVelocidad(int velocidad) {
  dxl.setGoalVelocity(XL430_1, velocidad, UNIT_RPM);
  dxl.setGoalVelocity(XL430_2, velocidad, UNIT_RPM);
  dxl.setGoalVelocity(XL320_1, velocidad, UNIT_RPM);
  dxl.setGoalVelocity(XL320_2, velocidad, UNIT_RPM);
  dxl.setGoalVelocity(XL320_3, velocidad, UNIT_RPM);
}

// Lleva todos los motores a 0 grados
void posicionInicial(void) {
  dxl.setGoalPosition(XL430_1, gradosToXL430(0.0), UNIT_RAW);
  dxl.setGoalPosition(XL430_2, gradosToXL430(0.0), UNIT_RAW);
  dxl.setGoalPosition(XL320_1, gradosToXL320(0.0), UNIT_RAW);
  dxl.setGoalPosition(XL320_2, gradosToXL320(0.0), UNIT_RAW);
  dxl.setGoalPosition(XL320_3, gradosToXL320(0.0), UNIT_RAW);
  delay(1000);
}

// Mueve todos los motores a la posición neutra
void posicionNeutra(void) {
  Serial.println("Moviendo a posición neutra...");
  configurarVelocidad(VELOCIDAD_NEUTRO);
  
  dxl.setGoalPosition(XL430_1, gradosToXL430(NEUTRO_430_1), UNIT_RAW);
  dxl.setGoalPosition(XL430_2, gradosToXL430(NEUTRO_430_2), UNIT_RAW);
  dxl.setGoalPosition(XL320_1, gradosToXL320(NEUTRO_320_1), UNIT_RAW);
  dxl.setGoalPosition(XL320_2, gradosToXL320(NEUTRO_320_2), UNIT_RAW);
  dxl.setGoalPosition(XL320_3, gradosToXL320(NEUTRO_320_3), UNIT_RAW);
  
  delay(2000);
  Serial.println("Posición neutra alcanzada");
  imprimirPosicionesActuales();
}

// Mueve cada motor a los grados indicados (usar -1 para no mover)
void movimiento(float a, float b, float c, float d, float e){
  // Solo mover si el valor es >= 0
  if (a >= 0) {
    dxl.setGoalPosition(XL430_1, gradosToXL430(a), UNIT_RAW);
  }
  if (b >= 0) {
    dxl.setGoalPosition(XL430_2, gradosToXL430(b), UNIT_RAW);
  }
  if (c >= 0) {
    dxl.setGoalPosition(XL320_1, gradosToXL320(c), UNIT_RAW);
  }
  if (d >= 0) {
    dxl.setGoalPosition(XL320_2, gradosToXL320(d), UNIT_RAW);
  }
  if (e >= 0) {
    dxl.setGoalPosition(XL320_3, gradosToXL320(e), UNIT_RAW);
  }
  delay(1000);
}

// Igual que movimiento pero ajustando velocidad antes
void movimientoSuave(float a, float b, float c, float d, float e, int velocidad) {
  configurarVelocidad(velocidad);
  movimiento(a, b, c, d, e);
}

// Secuencia de saludo básica reutilizando movimiento
void saludar(float a, float b, float c, float d, float e) {
  movimiento(a, b, c, d, e);
}

// Imprime en serial las posiciones actuales en grados
void imprimirPosicionesActuales() {
  Serial.print("Posiciones actuales - ");
  Serial.print("XL430_1: ");
  Serial.print(xl430ToGrados(dxl.getPresentPosition(XL430_1, UNIT_RAW)));
  Serial.print("° | ");
  
  Serial.print("XL430_2: ");
  Serial.print(xl430ToGrados(dxl.getPresentPosition(XL430_2, UNIT_RAW)));
  Serial.print("° | ");
  
  Serial.print("XL320_1: ");
  Serial.print(xl320ToGrados(dxl.getPresentPosition(XL320_1, UNIT_RAW)));
  Serial.print("° | ");
  
  Serial.print("XL320_2: ");
  Serial.print(xl320ToGrados(dxl.getPresentPosition(XL320_2, UNIT_RAW)));
  Serial.print("° | ");
  
  Serial.print("XL320_3: ");
  Serial.print(xl320ToGrados(dxl.getPresentPosition(XL320_3, UNIT_RAW)));
  Serial.println("°");
}

// Lee posiciones al iniciar y las guarda como referencia
void leerPosicionesActuales() {
  posicionInicial430_1 = xl430ToGrados(dxl.getPresentPosition(XL430_1, UNIT_RAW));
  posicionInicial430_2 = xl430ToGrados(dxl.getPresentPosition(XL430_2, UNIT_RAW));
  posicionInicial320_1 = xl320ToGrados(dxl.getPresentPosition(XL320_1, UNIT_RAW));
  posicionInicial320_2 = xl320ToGrados(dxl.getPresentPosition(XL320_2, UNIT_RAW));
  posicionInicial320_3 = xl320ToGrados(dxl.getPresentPosition(XL320_3, UNIT_RAW));
  
  Serial.println("Posiciones al iniciar:");
  imprimirPosicionesActuales();
}

// Verifica si las posiciones medidas están dentro de la posición neutra
bool estaEnPosicionNeutra() {
  float tolerancia = 5.0;
  
  return (abs(posicionInicial430_1 - NEUTRO_430_1) < tolerancia &&
          abs(posicionInicial430_2 - NEUTRO_430_2) < tolerancia &&
          abs(posicionInicial320_1 - NEUTRO_320_1) < tolerancia &&
          abs(posicionInicial320_2 - NEUTRO_320_2) < tolerancia &&
          abs(posicionInicial320_3 - NEUTRO_320_3) < tolerancia);
}

// Corta torque de todos los motores para emergencia
void emergencia() {
  dxl.torqueOff(XL430_1);
  dxl.torqueOff(XL430_2);
  dxl.torqueOff(XL320_1);
  dxl.torqueOff(XL320_2);
  dxl.torqueOff(XL320_3);
  Serial.println("EMERGENCIA: Todos los motores detenidos");
}
