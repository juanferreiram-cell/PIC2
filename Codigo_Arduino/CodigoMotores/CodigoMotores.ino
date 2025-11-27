#include <Wire.h>
#include <EEPROM.h>
#include <Adafruit_PWMServoDriver.h>
#include <Dynamixel2Arduino.h>


// Configuracion del PCA9685
Adafruit_PWMServoDriver pca = Adafruit_PWMServoDriver();
#define OE_PIN 7
#define SERVO_MIN 150
#define SERVO_MAX 600

int servoPos[3]; 
int servoInicio[3] = {90, 90, 90}; 

// Configuracion de los dynamixel
#if defined(ARDUINO_AVR_UNO) || defined(ARDUINO_AVR_MEGA2560)
  #define DXL_SERIAL Serial
  const int DXL_DIR_PIN = 2;
#else
  #define DXL_SERIAL Serial
  const int DXL_DIR_PIN = 2;
#endif

const long DXL_BAUDRATE = 1000000;
const float PROTO_VER = 2.0;
Dynamixel2Arduino dxl(DXL_SERIAL, DXL_DIR_PIN);

const uint8_t XL430_1 = 47; 
const uint8_t XL430_2 = 77; 
const uint8_t XL320_1 = 17; 
const uint8_t XL320_2 = 16; 
const uint8_t XL320_3 = 18;

const uint8_t XL430_3 = 100;
const uint8_t XL430_4 = 50;
const uint8_t XL320_4 = 2;
const uint8_t XL320_5 = 1;
const uint8_t XL320_6 = 14;

const int XL430_MIN_RAW = 0; const int XL430_MAX_RAW = 4095; const float XL430_RANGE_DEG = 360.0;
const int XL320_MIN_RAW = 0; const int XL320_MAX_RAW = 1023; const float XL320_RANGE_DEG = 300.0;


void setServoAngle(uint8_t channel, int angle);
void moverMG(uint8_t channel, int targetAngle, int stepDelay); 


void IniciarMotoresDXL(void);
void movimiento(float a, float b, float c, float d, float e, float f, float g, float h, float i, float j);
int gradosXL430(float grados);
int gradosXL320(float grados);
float xl430Grados(int rawValue);
float xl320Grados(int rawValue);

void biceps();
void dab();
void superman();


void setup() {
  delay(7000);
  
  pinMode(OE_PIN, OUTPUT);
  digitalWrite(OE_PIN, HIGH);  // Apaga los MG
  
  pca.begin();
  pca.setPWMFreq(50);
  
  // Posiciones iniciales 
  setServoAngle(0, 20);
  setServoAngle(1, 72);
  setServoAngle(2, 60);
  
  servoPos[0] = 20;
  servoPos[1] = 72;
  servoPos[2] = 60;
  
  delay(100);
  
  digitalWrite(OE_PIN, LOW);  // Prende los MG una sola vez
  delay(1000);
  
  IniciarMotoresDXL();
  
  // Biceps
  biceps();
  // Superman
  superman();
  // DAB
  dab();
  moverMG(1, 120, 25);
  delay(1000);
  moverMG(0, 0, 25);
  delay(1000);
  moverMG(2, 120, 25);
  delay(1000);
  moverMG(2, 0, 25);
  delay(1000);
  moverMG(2, 60, 25);
  delay(1000);

  
}
  


void loop() {
}


// Funciones MG996R
void setServoAngle(uint8_t channel, int angle) {
  int pulse = map(angle, 0, 180, SERVO_MIN, SERVO_MAX);
  pca.setPWM(channel, 0, pulse);
}

void moverMG(uint8_t channel, int targetAngle, int stepDelay) {
  int current = servoPos[channel];
  
  if (current == targetAngle) return;

  int step = (targetAngle > current) ? 1 : -1;
  
  while (current != targetAngle) {
    current += step;
    setServoAngle(channel, current);
    delay(stepDelay); 
  }
  
  servoPos[channel] = targetAngle;
  EEPROM.update(channel, targetAngle);
}


// Funciones Dynamixel
void IniciarMotoresDXL(void){
  dxl.begin(DXL_BAUDRATE);
  dxl.setPortProtocolVersion(PROTO_VER);
  
  delay(500); 

  auto encenderMotor = [](uint8_t id) {
    dxl.torqueOff(id);
    dxl.setOperatingMode(id, OP_POSITION);
    dxl.torqueOn(id);
    delay(50);
  };

  encenderMotor(XL430_1); encenderMotor(XL430_2);
  encenderMotor(XL320_1); encenderMotor(XL320_2); encenderMotor(XL320_3);

  encenderMotor(XL430_3); encenderMotor(XL430_4);
  encenderMotor(XL320_4); encenderMotor(XL320_5); encenderMotor(XL320_6);
}


void movimiento(float a, float b, float c, float d, float e, float f, float g, float h, float i, float j){
  if (a >= 0) dxl.setGoalPosition(XL430_1, gradosXL430(a), UNIT_RAW);
  if (b >= 0) dxl.setGoalPosition(XL430_2, gradosXL430(b), UNIT_RAW);
  if (c >= 0) dxl.setGoalPosition(XL320_1, gradosXL320(c), UNIT_RAW);
  if (d >= 0) dxl.setGoalPosition(XL320_2, gradosXL320(d), UNIT_RAW);
  if (e >= 0) dxl.setGoalPosition(XL320_3, gradosXL320(e), UNIT_RAW);
  
  if (f >= 0) dxl.setGoalPosition(XL430_3, gradosXL430(f), UNIT_RAW);
  if (g >= 0) dxl.setGoalPosition(XL430_4, gradosXL430(g), UNIT_RAW);
  if (h >= 0) dxl.setGoalPosition(XL320_4, gradosXL320(h), UNIT_RAW);
  if (i >= 0) dxl.setGoalPosition(XL320_5, gradosXL320(i), UNIT_RAW);
  if (j >= 0) dxl.setGoalPosition(XL320_6, gradosXL320(j), UNIT_RAW);
}

int gradosXL430(float grados) {
  int rawValue = (grados / XL430_RANGE_DEG) * (XL430_MAX_RAW - XL430_MIN_RAW);
  return constrain(rawValue, XL430_MIN_RAW, XL430_MAX_RAW);
}

int gradosXL320(float grados) {
  int rawValue = (grados / XL320_RANGE_DEG) * (XL320_MAX_RAW - XL320_MIN_RAW);
  return constrain(rawValue, XL320_MIN_RAW, XL320_MAX_RAW);
}

float xl430Grados(int rawValue) {
  return (rawValue * XL430_RANGE_DEG) / (XL430_MAX_RAW - XL430_MIN_RAW);
}

float xl320Grados(int rawValue) {
  return (rawValue * XL320_RANGE_DEG) / (XL320_MAX_RAW - XL320_MIN_RAW);
}



void biceps(void){
  // Pose Biceps
   movimiento(270,   -1,  -1,   -1,   -1,   90,   -1,   -1,   -1,   -1); // Sube
   delay(2000);

   movimiento(-1,   -1,  75,   -1,   -1,   -1,   -1,   80,   -1,   -1); // Codo
   delay(2000);

   movimiento(-1,   0,  -1,   -1,   -1,   -1,   360,   -1,   -1,   -1); //Lateral
   delay(2000);

   
   movimiento(-1,   -1,  -1,   360,   -1,   -1,   -1,   -1,   60,   -1); // Bicep
   delay(5000);

  // Posicion Inicial

   movimiento(-1,   -1,  -1,   230,   -1,   -1,   -1,   -1,   150,   -1); // Bicep
   delay(2000);

   movimiento(-1,   80,  -1,   -1,   -1,   -1,   275,   -1,   -1,   -1); //Lateral
   delay(2000);

   movimiento(-1,   -1,  0,   -1,   -1,   -1,   -1,   360,   -1,   -1); // Codo
   delay(2000);
   
   movimiento(90,   -1,  -1,   -1,   -1,   270,   -1,   -1,   -1,   -1); // Sube
   delay(2000);
}


void dab(void){
  movimiento(-1,   -1,  -1,   -1,   -1,   360,   -1,   -1,   -1,   -1); // Sube
  delay(500);

  movimiento(-1,   -1,  -1,   -1,   -1,   -1,   305,   -1,   -1,   -1); //Lateral
  delay(500);

  movimiento(-1,   -1,  -1,   -1,   -1,   -1,   -1,   -1,   170,   -1); //Biceps
  delay(1000);

  // brazo izquierdo
  movimiento(0,   -1,  -1,   -1,   -1,   -1,   -1,   -1,   -1,   -1); // Sube
  delay(2000);
  
  movimiento(-1,   -1,  75,   -1,   -1,   -1,   -1,   -1,   -1,   -1); // Codo
  delay(2000);

  movimiento(-1,   -1,  -1,  360,   -1,   -1,   -1,   -1,   -1,   -1); // Bicep
  delay(2000);  


}

void superman (void){

  movimiento(-1,   40,  -1,   -1,   -1,   -1,   315,   -1,   -1,   -1); //Lateral
  delay(2000);

  movimiento(-1,   -1,  235,   -1,   -1,   -1,   -1,   255,   -1,   -1); // Codo
  delay(2000);

  movimiento(-1,   -1,  -1,   160,   -1,   -1,   -1,   -1,   230,   -1); // Bicep
  delay(2000);

  movimiento(-1,   70,  -1,   -1,   -1,   -1,   290,   -1,   -1,   -1); //Lateral
  delay(2000);

  // Posicion inicial

  movimiento(-1,   40,  -1,   -1,   -1,   -1,   315,   -1,   -1,   -1); //Lateral
  delay(2000);

  movimiento(-1,   -1,  -1,   230,   -1,   -1,   -1,   -1,   150,   -1); // Bicep
  delay(2000);
  
  movimiento(-1,   -1,  0,   -1,   -1,   -1,   -1,   360,   -1,   -1); // Codo
  delay(2000);

  movimiento(-1,   80,  -1,   -1,   -1,   -1,   275,   -1,   -1,   -1); //Lateral
  delay(2000);
  
}