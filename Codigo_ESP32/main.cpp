#include <Arduino.h>
#include <WiFi.h>
#include <HTTPClient.h>
#include <ArduinoJson.h>
#include <HardwareSerial.h>
#include "esp_wifi.h"

// Audio
#include <AudioFileSourceHTTPStream.h>
#include <AudioFileSourceBuffer.h>
#include <AudioGeneratorMP3.h>
#include <AudioOutputI2S.h>

// Pantalla
#include <SPI.h>
#include <Adafruit_GFX.h>
#include <Adafruit_ILI9341.h>

// Imágenes
#include "biomedia.h"
#include "digitales.h"
#include "electronica.h"
#include "fisica.h"
#include "hyn.h"
#include "laba.h"
#include "logistica.h"
#include "mecatronica.h"
#include "movimientohumano.h"
#include "neuroia2.h"
#include "quimica.h"
#include "tabletgigante.h"
#include "terraza.h"
#include "lti.h"
#include "mecanica.h"

// Caras
#include "caras.h"

// ============ PINES ============
#define I2S_BCLK      26
#define I2S_LRC       25
#define I2S_DOUT      22
#define TFT_CS   5
#define TFT_DC   21
#define TFT_RST  4

Adafruit_ILI9341 tft(TFT_CS, TFT_DC, TFT_RST);

// Config
const char* WIFI_SSID = "Juanma";
const char* WIFI_PASS = "38814831";
const char* BASE_URL  = "http://choreal-kalel-directed.ngrok-free.dev";
const char* DEVICE_ID = "esp32_1";

// Audio
AudioGeneratorMP3*          mp3       = nullptr;
AudioFileSourceHTTPStream*  file_http = nullptr;
AudioFileSourceBuffer*      buff      = nullptr;
AudioOutputI2S*             out       = nullptr;

// Estado
String modoActual = "ninguno";
bool sistemaMusica_activo = false;
bool sistemaAudioMP3_activo = false;
String currentTrackId = "";
String currentTitle = "";
String currentArtist = "";
String currentStreamUrl = "";
bool isPlaying = false;
int currentVolume = 80;

// Control de pantalla
bool pantallaEncendida = true;
unsigned long ultimaActividadPantalla = 0;
const unsigned long TIMEOUT_PANTALLA = 30000;
bool mostrandoImagen = false;
bool esperandoTransicion = false;
unsigned long tiempoFinAudio = 0;
const unsigned long DELAY_TRANSICION = 500;

// Animación de cara NAO
enum FaceMode {FACE_NONE=0, FACE_HAPPY=1, FACE_NEUTRAL=2, FACE_TALK=3, FACE_SING=4 };
FaceMode currentFace = FACE_NONE;
bool faceAnimating = false;
uint8_t mouthPhase = 0;
uint32_t mouthPrev = 0;
const uint16_t MOUTH_STEP_MS = 120;

// Geometría cara
int cx, cy, eyeY;
const int eyeOffsetX = 70;
const int glowR = 32;
const int eyeR  = 22;
const int pupilR = 10;

// Colores cara
uint16_t C_BG, C_WHITE, C_GLOW, C_EYE, C_MOUTH;

// Flags de control
volatile bool needStop = false;
volatile bool needChangeTrack = false;
String pendingUrl = "";

// Arduino
HardwareSerial SerialArduino(2);
const int arduinoRX = 16;
const int arduinoTX = 17;

// Audio Variables
int failedAttempts = 0;
const int MAX_FAILED_ATTEMPTS = 3;
unsigned long lastStartAttempt = 0;
unsigned long audioStartTime = 0;
const unsigned long AUDIO_TIMEOUT = 10000;

// Mutex
SemaphoreHandle_t audioMutex;

// Prototipos
void stopAudio();
bool startMp3Stream(const String& url);
void procesarComando(JsonObject cmd);
void ejecutarComandoHex(int comando);
void handlePlayMusic(JsonObject cmd);
void handleStop();
void handlePause();
void handleResume();
void handleVolume(JsonObject cmd);
void handleSeek(JsonObject cmd);
void handleFrase(JsonObject cmd);
void handleConversacion(JsonObject cmd);
void handleLoro(JsonObject cmd);
void audioTask(void* parameter);
void pollingTask(void* parameter);
void apagarPantalla();
void encenderPantalla();
void mostrarImagen(const uint16_t* imagen);

// Cara animada
void initFaceColors();
void drawHappyFace();
void drawNeutralFace();
void drawTalkFrame();
void drawSingFrame();
void startFaceAnimation(FaceMode mode);
void stopFaceAnimation();
void updateFaceAnimation();

// ===== Helpers nuevos =====
void salirDeImagen() {
  if (mostrandoImagen || esperandoTransicion) {
    // Limpiar completamente el estado de imagen y transición
    mostrandoImagen = false;
    esperandoTransicion = false;
    tiempoFinAudio = 0;
    Serial.println("Saliendo de imagen - estado limpiado completamente");
  }
}

void mostrarCaraEstatica(void (*dibujarCara)()) {
  encenderPantalla();
  
  faceAnimating = false;
  currentFace = FACE_NONE;
  mostrandoImagen = false;
  esperandoTransicion = false;
  tiempoFinAudio = 0;
  
  tft.fillScreen(C_BG);
  delay(20);
  
  dibujarCara();
  Serial.println("Cara estatica mostrada");
}

// ============ FUNCIONES DE CARA ANIMADA ============

void initFaceColors() {
  C_BG    = ILI9341_WHITE;
  C_WHITE = ILI9341_WHITE;
  C_GLOW  = tft.color565(0,180,255);
  C_EYE   = tft.color565(0,150,255);
  C_MOUTH = ILI9341_BLACK;
}

uint16_t gradCyan(int r) { 
  return tft.color565(0, min(255, r*5), 255); 
}

void halosNAO(uint16_t (*colorGrad)(int)) {
  for (int r = glowR; r > eyeR; r--) {
    uint16_t c = colorGrad(r);
    tft.drawCircle(cx - eyeOffsetX, eyeY, r, c);
    tft.drawCircle(cx + eyeOffsetX, eyeY, r, c);
  }
}

void ojosBase(uint16_t fillCol, uint16_t edgeCol) {
  halosNAO(gradCyan);
  tft.fillCircle(cx - eyeOffsetX, eyeY, eyeR, fillCol);
  tft.fillCircle(cx + eyeOffsetX, eyeY, eyeR, fillCol);
  tft.drawCircle(cx - eyeOffsetX, eyeY, eyeR, edgeCol);
  tft.drawCircle(cx + eyeOffsetX, eyeY, eyeR, edgeCol);
}

void pupilas(int pr) {
  tft.fillCircle(cx - eyeOffsetX, eyeY, pr, ILI9341_BLACK);
  tft.fillCircle(cx + eyeOffsetX, eyeY, pr, ILI9341_BLACK);
  tft.fillCircle(cx - eyeOffsetX - 5, eyeY - 7, 3, C_WHITE);
  tft.fillCircle(cx + eyeOffsetX - 5, eyeY - 7, 3, C_WHITE);
}

void bocaArco(int cX, int cY, int r, int a0, int a1, uint16_t col) {
  for (int a = a0; a <= a1; a++) {
    float rad = a * 0.0174533f;
    int x = cX + r*cos(rad);
    int y = cY + r*sin(rad);
    tft.drawPixel(x, y, col);
    tft.drawPixel(x, y+1, col);
  }
}

void bocaLinea(int x0, int y, int w, uint16_t col) {
  tft.drawFastHLine(x0, y, w, col);
  tft.drawFastHLine(x0, y+1, w, col);
}

void bocaRect(int x, int y, int w, int h, uint16_t col) {
  for (int i = 0; i < 2; i++) {
    tft.drawRect(x - w/2, y - h/2, w, h, col);
    w--; h--; x++; y++;
  }
}

void bocaOval(int x, int y, int w, int h, uint16_t col) {
  for (int i = 0; i < 2; i++) {
    tft.drawRoundRect(x - w/2, y - h/2, w, h, min(w,h)/3, col);
    w--; h--; x++; y++;
  }
}

void drawHappyFace() {
  tft.fillScreen(C_BG);
  ojosBase(C_EYE, C_GLOW);
  pupilas(pupilR);
  bocaArco(cx, cy+45, 38, 20, 160, C_MOUTH);
}

void drawNeutralFace() {
  tft.fillScreen(C_BG);
  ojosBase(C_EYE, C_GLOW);
  pupilas(pupilR);
  bocaLinea(cx-35, cy+45, 70, C_MOUTH);
}

void drawTalkFrame() {
  tft.fillScreen(C_BG);
  ojosBase(C_EYE, C_GLOW);
  pupilas(pupilR);
  int cyM = cy+45;
  if (mouthPhase==0) bocaRect(cx, cyM, 38, 6, C_MOUTH);
  else if (mouthPhase==1) bocaRect(cx, cyM, 44, 14, C_MOUTH);
  else bocaRect(cx, cyM, 42, 10, C_MOUTH);
}

void drawSingFrame() {
  tft.fillScreen(C_BG);
  ojosBase(C_EYE, C_GLOW);
  pupilas(pupilR);
  int cyM = cy+45;
  if (mouthPhase==0) bocaOval(cx, cyM, 12, 16, C_MOUTH);
  else if (mouthPhase==1) bocaOval(cx, cyM, 24, 26, C_MOUTH);
  else bocaOval(cx, cyM, 16, 22, C_MOUTH);
}

void startFaceAnimation(FaceMode mode) {
  encenderPantalla();
  
  // CRÍTICO: Forzar limpieza de TODOS los flags de imagen
  mostrandoImagen = false;
  esperandoTransicion = false;
  tiempoFinAudio = 0;
  
  currentFace = mode;
  mouthPhase = 0;
  mouthPrev = millis();

  if (mode == FACE_HAPPY) {
    faceAnimating = false;
    drawHappyFace();
    Serial.println("Cara feliz (flags limpiados)");
  } else if (mode == FACE_NEUTRAL) {
    faceAnimating = false;
    drawNeutralFace();
    Serial.println("Cara neutral (flags limpiados)");
  } else if (mode == FACE_TALK) {
    faceAnimating = true;
    drawTalkFrame();
    Serial.println("Animacion HABLAR (flags limpiados)");
  } else if (mode == FACE_SING) {
    faceAnimating = true;
    drawSingFrame();
    Serial.println("Animacion CANTAR (flags limpiados)");
  }
}

void stopFaceAnimation() {
  faceAnimating = false;
  esperandoTransicion = true;
  tiempoFinAudio = millis();
  Serial.println("Fin animacion (conservar ultimo frame)");
}

void updateFaceAnimation() {
  if (!faceAnimating) return;
  if (currentFace == FACE_NONE || currentFace == FACE_NEUTRAL || currentFace == FACE_HAPPY) return;
  if (mostrandoImagen) return;
  
  uint32_t now = millis();
  if (now - mouthPrev >= MOUTH_STEP_MS) {
    mouthPrev = now;
    mouthPhase = (mouthPhase + 1) % 3;
    if (currentFace == FACE_TALK) {
      drawTalkFrame();
    } else if (currentFace == FACE_SING) {
      drawSingFrame();
    }
  }
}

// ============ CONTROL DE PANTALLA ============

void apagarPantalla() {
  if (pantallaEncendida) {
    Serial.println("Apagando pantalla");
    stopFaceAnimation();
    currentFace = FACE_NONE;
    mostrandoImagen = false;
    esperandoTransicion = false;
    tiempoFinAudio = 0;
    tft.fillScreen(ILI9341_BLACK);
    pantallaEncendida = false;
  }
}

void encenderPantalla() {
  if (!pantallaEncendida) {
    Serial.println("Encendiendo pantalla");
    pantallaEncendida = true;
  }
  ultimaActividadPantalla = millis();
}

void mostrarImagen(const uint16_t* imagen) {
  encenderPantalla();
  
  stopFaceAnimation();
  currentFace = FACE_NONE;
  mostrandoImagen = true;
  esperandoTransicion = false;
  tiempoFinAudio = 0;
  
  tft.fillScreen(ILI9341_BLACK);
  delay(50);
  
  tft.drawRGBBitmap(0, 0, imagen, 320, 240);
  Serial.println("Imagen mostrada - pantalla limpiada");
}

// ============ AUDIO ============

void stopAudio() {
  Serial.println("Limpiando audio...");
  if (mp3) {
    if (mp3->isRunning()) mp3->stop();
    delay(100);
    delete mp3; mp3 = nullptr;
  }
  if (buff) { delay(100); delete buff; buff = nullptr; }
  if (file_http) { delay(100); delete file_http; file_http = nullptr; }
  if (out) { delay(100); delete out; out = nullptr; }
  delay(200);

  if (mostrandoImagen) {
    esperandoTransicion = true;
    tiempoFinAudio = millis();
  } else {
    stopFaceAnimation();
  }

  Serial.println("Audio limpiado");
}

bool startMp3Stream(const String& url) {
  Serial.println("================================");
  Serial.println("INICIANDO STREAM");
  Serial.println("================================");
  
  if (url.length() < 10 || (!url.startsWith("http://") && !url.startsWith("https://"))) {
    Serial.println("URL invalida: " + url);
    return false;
  }
  
  Serial.println("URL: " + url.substring(0, 70) + "...");
  Serial.printf("Heap libre: %d bytes\n", ESP.getFreeHeap());
  
  if (ESP.getFreeHeap() < 75000) {
    Serial.println("Memoria insuficiente");
    return false;
  }

  Serial.println("HTTP stream...");
  file_http = new AudioFileSourceHTTPStream(url.c_str());
  if (!file_http) {
    Serial.println("HTTP stream fallo");
    return false;
  }
  file_http->SetReconnect(3, 500);
  Serial.println("HTTP stream OK");
  
  Serial.println("Buffer (16KB)...");
  buff = new AudioFileSourceBuffer(file_http, 16384);
  if (!buff) {
    Serial.println("Buffer fallo");
    delete file_http; file_http = nullptr;
    return false;
  }
  Serial.println("Buffer OK");

  Serial.println("I2S output...");
  out = new AudioOutputI2S();
  if (!out) {
    Serial.println("I2S fallo");
    delete buff; buff = nullptr;
    delete file_http; file_http = nullptr;
    return false;
  }
  out->SetPinout(I2S_BCLK, I2S_LRC, I2S_DOUT);
  out->SetGain(currentVolume / 100.0);
  Serial.println("I2S OK");

  Serial.println("MP3 generator...");
  mp3 = new AudioGeneratorMP3();
  if (!mp3) {
    Serial.println("MP3 fallo");
    delete out; out = nullptr;
    delete buff; buff = nullptr;
    delete file_http; file_http = nullptr;
    return false;
  }
  Serial.println("MP3 OK");

  Serial.println("Iniciando reproduccion...");
  if (!mp3->begin(buff, out)) {
    Serial.println("begin() fallo");
    stopAudio();
    return false;
  }

  delay(200);
  if (!mp3->isRunning()) {
    Serial.println("MP3 no esta corriendo");
    stopAudio();
    return false;
  }

  // CRÍTICO: Solo mostrar cara si NO hay imagen activa
  if (!mostrandoImagen) {
    if (sistemaMusica_activo) {
      startFaceAnimation(FACE_SING);
    } else if (sistemaAudioMP3_activo || url.indexOf("audio_raw") > 0) {
      startFaceAnimation(FACE_TALK);
    }
  } else {
    Serial.println("Imagen activa - no dibujar cara");
  }

  Serial.println("REPRODUCIENDO");
  Serial.printf("Heap final: %d bytes\n", ESP.getFreeHeap());
  Serial.println("================================\n");
  return true;
}

// ============ COMANDOS ============

void procesarComando(JsonObject cmd) {
  const char* tipo = cmd["tipo"];
  
  // ⭐ NUEVO: Comandos de pose desde cámara
  if (strcmp(tipo, "comando_pose") == 0) {
    int comando = cmd["comando_int"];
    const char* poseName = cmd["pose_name"] | "unknown";
    float confidence = cmd["confidence"] | 0.0;
    const char* cameraId = cmd["camera_id"] | "unknown";
    
    Serial.println("\n📷 COMANDO DE POSE RECIBIDO");
    Serial.printf("   Cámara: %s\n", cameraId);
    Serial.printf("   Pose: %s\n", poseName);
    Serial.printf("   Confianza: %.1f%%\n", confidence * 100);
    Serial.printf("   Comando: 0x%02X\n", comando);
    Serial.println();
    
    ejecutarComandoHex(comando);
    return;
  }
  
  if (strcmp(tipo, "comando_hex") == 0) {
    int comando = cmd["comando_int"];
    ejecutarComandoHex(comando);
    return;
  }
  
  if (strcmp(tipo, "reproducir_comando_voz") == 0) {
    const char* audio_id = cmd["audio_id"];
    if (xSemaphoreTake(audioMutex, pdMS_TO_TICKS(100))) {
      pendingUrl = String(BASE_URL) + "/esp32/audio_raw/" + audio_id;
      needChangeTrack = true;
      xSemaphoreGive(audioMutex);
    }
    return;
  }
  
  if (sistemaMusica_activo) {
    String tipoStr = String(tipo);
    if (tipoStr == "reproducir_musica") {
      handlePlayMusic(cmd);
    } else if (tipoStr == "musica_detener") {
      handleStop();
    } else if (tipoStr == "musica_pausa") {
      handlePause();
    } else if (tipoStr == "musica_continuar") {
      handleResume();
    } else if (tipoStr == "musica_volumen") {
      handleVolume(cmd);
    } else if (tipoStr == "musica_seek") {
      handleSeek(cmd);
    }
    return;
  }
  
  if (sistemaAudioMP3_activo) {
    const char* audio_id = cmd["audio_id"] | "";
    if (strcmp(tipo, "reproducir_frase") == 0 ||
        strcmp(tipo, "reproducir_conversacion") == 0 ||
        strcmp(tipo, "reproducir_loro") == 0) {
      if (audio_id && *audio_id) {
        if (xSemaphoreTake(audioMutex, pdMS_TO_TICKS(100))) {
          pendingUrl = String(BASE_URL) + "/esp32/audio_raw/" + audio_id;
          needChangeTrack = true;
          xSemaphoreGive(audioMutex);
        }
      }
    }
    return;
  }
}

void ejecutarComandoHex(int comando) {
  switch (comando) {
    case 0x01: // encendido
      mostrandoImagen = false;
      esperandoTransicion = false;
      tiempoFinAudio = 0;
      salirDeImagen();
      startFaceAnimation(FACE_TALK);
      modoActual = "encendido";
      Serial.println("Robot encendido - imagen limpiada");
      break;
      
    case 0x02: // apagado
      sistemaMusica_activo = false;
      sistemaAudioMP3_activo = false;
      modoActual = "apagado";
      if (xSemaphoreTake(audioMutex, pdMS_TO_TICKS(100))) {
        needStop = true;
        xSemaphoreGive(audioMutex);
      }
      delay(5000);
      apagarPantalla();
      Serial.println("Robot apagado");
      break;
      
    case 0x03:
      modoActual = "turismo";
      Serial.println("Modo turismo");
      break;
      
    case 0x04:
      salirDeImagen();
      startFaceAnimation(FACE_TALK);
      modoActual = "movimientos";
      Serial.println("Modo movimientos");
      break;
      
    case 0x05:
      salirDeImagen();
      startFaceAnimation(FACE_TALK);
      modoActual = "audio";
      Serial.println("Modo audio");
      break;
      
    case 0x06:
      salirDeImagen();
      startFaceAnimation(FACE_TALK);
      encenderPantalla();
      modoActual = "imagenes";
      Serial.println("Modo imagenes");
      break;
      
    case 0x07: // ⭐ Modo cámara (activa ESP32-CAM automáticamente desde servidor)
      salirDeImagen();
      startFaceAnimation(FACE_TALK);
      encenderPantalla();
      modoActual = "camara";
      Serial.println("Modo camara - ESP32-CAM activada");
      break;
      
    case 0x08: // ⭐ Desactivar cámara
      salirDeImagen();
      startFaceAnimation(FACE_NEUTRAL);
      modoActual = "modelos";
      Serial.println("Modelos - ESP32-CAM desactivada");
      break;
      
    case 0x09:
      salirDeImagen();
      startFaceAnimation(FACE_TALK);
      modoActual = "elegir_movimientos";
      Serial.println("Elegir movimientos");
      break;
      
    case 0x0A:
      salirDeImagen();
      startFaceAnimation(FACE_TALK);
      modoActual = "repetir_movimientos";
      Serial.println("Repetir movimientos");
      break;
      
    case 0x0B: // Musica ON
      mostrandoImagen = false;
      esperandoTransicion = false;
      tiempoFinAudio = 0;
      salirDeImagen();
      sistemaMusica_activo = true;
      sistemaAudioMP3_activo = false;
      modoActual = "musica";
      Serial.println("Musica ON - imagen limpiada");
      break;
      
    case 0x0C: // Voces ON
      mostrandoImagen = false;
      esperandoTransicion = false;
      tiempoFinAudio = 0;
      salirDeImagen();
      startFaceAnimation(FACE_TALK);
      sistemaAudioMP3_activo = true;
      sistemaMusica_activo = false;
      modoActual = "voces";
      Serial.println("Voces ON - imagen limpiada");
      break;
      
    case 0x0D:
    case 0x0E:
      Serial.println(String("Comando ") + String(comando, HEX));
      break;

    case 0x14:
      salirDeImagen();
      SerialArduino.println(0);
      Serial.println("Arduino 0");
      break;
      
    case 0x15:
      salirDeImagen();
      SerialArduino.println(1);
      Serial.println("Arduino 1");
      break;
      
    case 0x16:
      salirDeImagen();
      SerialArduino.println(2);
      Serial.println("Arduino 2");
      break;
      
    case 0x17:
      salirDeImagen();
      SerialArduino.println(3);
      Serial.println("Arduino 3");
      break;
      
    case 0x18:
      salirDeImagen();
      SerialArduino.println(4);
      Serial.println("Arduino 4");
      break;
    
    case 0x19:
      mostrarImagen(lti);
      Serial.println("LTI");
      break;
    
    case 0x1A:
      mostrarImagen(mecatronica);
      Serial.println("Mecatronica");
      break;
    
    case 0x1B:
      mostrarImagen(biomedia);
      Serial.println("Biomedica");
      break;
    
    case 0x1C:
      mostrarImagen(logistica);
      Serial.println("Logistica");
      break;
    
    case 0x1D:
      mostrarImagen(laba);
      Serial.println("LAB A");
      break;
    
    case 0x1E:
      mostrarImagen(digitales);
      Serial.println("Humanidades Digitales");
      break;
    
    case 0x1F:
      mostrarImagen(fisica);
      Serial.println("Fisica");
      break;
    
    case 0x20:
      mostrarImagen(quimica);
      Serial.println("Quimica");
      break;
    
    case 0x21:
      mostrarImagen(biomedia);
      Serial.println("Biomedica");
      break;
    
    case 0x22:
      mostrarImagen(movimientohumano);
      Serial.println("Analisis Movimiento");
      break;
    
    case 0x24:
      mostrarImagen(tabletgigante);
      Serial.println("Tablet Gigante");
      break;
    
    case 0x25:
      mostrarImagen(mecatronica);
      Serial.println("Mecatronica");
      break;
    
    case 0x26:
      mostrarImagen(electronica);
      Serial.println("Electronica");
      break;
    
    case 0x29:
      mostrarImagen(mecanica);
      Serial.println("Mecanica");
      break;
    
    case 0x2A:
      mostrarImagen(hyn);
      Serial.println("Hidraulica");
      break;
    
    case 0x2B:
      mostrarImagen(logistica);
      Serial.println("Logistica");
      break;
    
    case 0x2C:
      mostrarCaraEstatica(caraFelizBasica);
      break;

    case 0x2D:
      mostrarCaraEstatica(caraTristeBasica);
      break;

    case 0x2E:
      mostrarCaraEstatica(caraSorpresaBasica);
      break;

    case 0x2F:
      mostrarCaraEstatica(caraGuinoBasica);
      break;

    case 0x30:
      mostrarCaraEstatica(caraEnfermoBasica);
      break;

    case 0x31:
      mostrarCaraEstatica(caraPreocupadoBasica);
      break;

    case 0x32:
      mostrarCaraEstatica(caraNeutraBasica);
      break;

    case 0x33:
      mostrarCaraEstatica(caraEnamoradoCorazonesRojos);
      break;

    case 0x34:
      mostrarCaraEstatica(caraDormidoBasica);
      break;

    // ⭐ NUEVOS COMANDOS DE POSES (0x50-0x52)
    case 0x50: // DAB
      salirDeImagen();
      startFaceAnimation(FACE_HAPPY);
      Serial.println("🕺 Pose DAB detectada");
      // Aquí puedes agregar movimientos del robot con SerialArduino
      break;
      
    case 0x51: // Superman
      salirDeImagen();
      startFaceAnimation(FACE_TALK);
      Serial.println("🦸 Pose Superman detectada");
      // Aquí puedes agregar movimientos del robot
      break;
      
    case 0x52: // Bíceps
      salirDeImagen();
      startFaceAnimation(FACE_HAPPY);
      Serial.println("💪 Pose Bíceps detectada");
      // Aquí puedes agregar movimientos del robot
      break;

    default:
      Serial.println(String("Desconocido: 0x") + String(comando, HEX));
      break;
  }
}

void handlePlayMusic(JsonObject cmd) {
  currentStreamUrl = cmd["url"].as<String>();
  currentTitle = cmd["titulo"].as<String>();
  currentArtist = cmd["artista"].as<String>();
  
  Serial.println("NUEVA CANCION");
  Serial.println("   " + currentTitle + " - " + currentArtist);
  
  if (xSemaphoreTake(audioMutex, pdMS_TO_TICKS(100))) {
    pendingUrl = currentStreamUrl;
    needChangeTrack = true;
    xSemaphoreGive(audioMutex);
  }
}

void handleStop() {
  Serial.println("STOP");
  if (xSemaphoreTake(audioMutex, pdMS_TO_TICKS(100))) {
    needStop = true;
    xSemaphoreGive(audioMutex);
  }
}

void handlePause() {
  Serial.println("PAUSE");
  handleStop();
}

void handleResume() {
  Serial.println("RESUME");
  if (!currentStreamUrl.isEmpty()) {
    if (xSemaphoreTake(audioMutex, pdMS_TO_TICKS(100))) {
      pendingUrl = currentStreamUrl;
      needChangeTrack = true;
      xSemaphoreGive(audioMutex);
    }
  }
}

void handleVolume(JsonObject cmd) {
  int volume = cmd["volume"].as<int>();
  Serial.printf("Volumen: %d%%\n", volume);
  currentVolume = volume;
  if (out) out->SetGain(volume / 100.0);
}

void handleSeek(JsonObject cmd) {}
void handleFrase(JsonObject cmd) {}
void handleConversacion(JsonObject cmd) {}
void handleLoro(JsonObject cmd) {}

// ============ TASKS ============

void audioTask(void* parameter) {
  Serial.println("Audio task nucleo 1");
  while (true) {
    bool shouldStop = false;
    bool shouldChange = false;
    String urlToPlay = "";
    
    if (xSemaphoreTake(audioMutex, pdMS_TO_TICKS(10))) {
      shouldStop = needStop;
      shouldChange = needChangeTrack;
      if (shouldChange) {
        urlToPlay = pendingUrl;
        pendingUrl = "";
        needChangeTrack = false;
      }
      if (shouldStop) {
        needStop = false;
      }
      xSemaphoreGive(audioMutex);
    }
    
    if (shouldStop) {
      Serial.println("STOP pedido");
      stopAudio();
      isPlaying = false;
      failedAttempts = 0;
      audioStartTime = 0;
      delay(100);
    }
    
    if (shouldChange && !urlToPlay.isEmpty()) {
      Serial.println("Cambio de pista/stream");
      if (failedAttempts >= MAX_FAILED_ATTEMPTS) {
        Serial.println("Demasiados intentos fallidos, omitiendo");
        failedAttempts = 0;
        stopAudio();
        delay(500);
        continue;
      }
      unsigned long now = millis();
      if (now - lastStartAttempt < 2000) {
        delay(2000 - (now - lastStartAttempt));
      }
      lastStartAttempt = millis();
      if (mp3 && mp3->isRunning()) {
        stopAudio();
        delay(400);
      }
      if (ESP.getFreeHeap() < 75000) {
        stopAudio();
        delay(500);
      }
      bool success = startMp3Stream(urlToPlay);
      if (success) {
        isPlaying = true;
        failedAttempts = 0;
        audioStartTime = millis();
      } else {
        isPlaying = false;
        failedAttempts++;
        audioStartTime = 0;
        stopAudio();
        delay(500);
      }
    }
    
    if (mp3 && mp3->isRunning()) {
      if (audioStartTime > 0 && (millis() - audioStartTime > AUDIO_TIMEOUT)) {
        Serial.println("Timeout de audio");
        stopAudio();
        isPlaying = false;
        failedAttempts++;
        audioStartTime = 0;
        vTaskDelay(pdMS_TO_TICKS(10));
        continue;
      }
      if (!mp3->loop()) {
        Serial.println("Fin de reproduccion");
        stopAudio();
        isPlaying = false;
        failedAttempts = 0;
        audioStartTime = 0;
      } else {
        if (audioStartTime > 0) audioStartTime = 0;
      }
    } else {
      vTaskDelay(pdMS_TO_TICKS(10));
    }
    taskYIELD();
  }
}

void pollingTask(void* parameter) {
  Serial.println("Polling task nucleo 0");
  unsigned long lastPoll = 0;
  unsigned long lastArduino = 0;
  unsigned long lastPantallaCheck = 0;
  unsigned long lastFaceUpdate = 0;
  
  while (true) {
    if (millis() - lastPoll > 1000) {
      lastPoll = millis();
      HTTPClient http;
      http.setReuse(true);
      http.setTimeout(1500);
      if (http.begin(String(BASE_URL) + "/esp32/poll/" + DEVICE_ID)) {
        int code = http.GET();
        if (code == HTTP_CODE_OK) {
          DynamicJsonDocument doc(2048);
          DeserializationError error = deserializeJson(doc, http.getStream());
          if (!error) {
            JsonArray cmds = doc["comandos"];
            if (cmds.size() > 0) {
              Serial.printf("Comandos recibidos: %d\n", cmds.size());
              for (JsonObject cmd : cmds) {
                procesarComando(cmd);
              }
            }
          }
        }
        http.end();
      }
    }

    if (millis() - lastArduino > 100) {
      lastArduino = millis();
      if (SerialArduino.available()) {
        SerialArduino.readString();
      }
    }
    
    if (millis() - lastFaceUpdate > 50) {
      lastFaceUpdate = millis();
      if (!mostrandoImagen) {
        updateFaceAnimation();
      }
    }
    
    if (millis() - lastPantallaCheck > 5000) {
      lastPantallaCheck = millis();
      if (pantallaEncendida && 
          modoActual != "musica" && 
          modoActual != "apagado" &&
          modoActual != "audio" &&
          modoActual != "voces" &&
          modoActual != "encendido" &&
          modoActual != "camara") {  // ⭐ Añadido
        if (millis() - ultimaActividadPantalla > TIMEOUT_PANTALLA) {
          Serial.println("Timeout de pantalla");
          apagarPantalla();
        }
      }
    }
    vTaskDelay(pdMS_TO_TICKS(50));
  }
}

// ============ SETUP ============

void setup() {
  setCpuFrequencyMhz(240);
  Serial.begin(115200);
  delay(1000);
  
  tft.begin();
  tft.setRotation(1);
  tft.fillScreen(ILI9341_BLACK);

  cx = tft.width()/2;
  cy = tft.height()/2;
  eyeY = cy - 40;
  initFaceColors();

  SerialArduino.begin(9600, SERIAL_8N1, arduinoRX, arduinoTX);
  
  Serial.println("=======================================");
  Serial.println("Nao Sistema");
  Serial.println("=======================================");

  WiFi.mode(WIFI_STA);
  WiFi.setAutoReconnect(true);
  WiFi.begin(WIFI_SSID, WIFI_PASS);
  while (WiFi.status() != WL_CONNECTED) {
    delay(250);
  }
  esp_wifi_set_ps(WIFI_PS_NONE);
  esp_wifi_set_max_tx_power(84);
  Serial.println("WiFi OK");

  HTTPClient http;
  http.setTimeout(3000);
  if (http.begin(String(BASE_URL) + "/esp32/register")) {
    http.addHeader("Content-Type", "application/x-www-form-urlencoded");
    http.POST("device_id=" + String(DEVICE_ID));
    http.end();
  }
  
  audioMutex = xSemaphoreCreateMutex();
  if (audioMutex == NULL) {
    Serial.println("Error creando mutex");
    while(1);
  }
  
  xTaskCreatePinnedToCore(audioTask, "Audio", 8192, NULL, 2, NULL, 1);
  xTaskCreatePinnedToCore(pollingTask, "Poll", 4096, NULL, 1, NULL, 0);
  
  Serial.println("Sistema listo");
  Serial.println("Comando 0x07 activa ESP32-CAM automáticamente");
  Serial.println("Poses: dab (0x50), superman (0x51), biceps (0x52)");
}

void loop() {
  vTaskDelay(pdMS_TO_TICKS(1000));
}