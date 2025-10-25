#include <Arduino.h>
#include <WiFi.h>
#include <HTTPClient.h>
#include <ArduinoJson.h>
#include <HardwareSerial.h>

// Audio (ESP8266Audio)
#include <AudioFileSourceHTTPStream.h>
#include <AudioGeneratorWAV.h>
#include <AudioOutputI2SNoDAC.h>

// Pantalla
#include <SPI.h>
#include <Adafruit_GFX.h>
#include <Adafruit_ILI9341.h>

// Imágenes
#include "robotsaludando.h"
#include "utec.h"
#include "robotcantando.h"
#include "robothablando.h"
#include "durmiendorobot.h"
#include "motoresgrandes.h"
#include "uruguay.h"
#include "logoimec.h"
#include "logoUtec.h"

// Pines para TFT
#define TFT_CS   5
#define TFT_DC   21
#define TFT_RST  4

Adafruit_ILI9341 tft(TFT_CS, TFT_DC, TFT_RST);

// Habilitar DACs internos (25 y 26)
extern "C" {
  #include "driver/i2s.h"
  #include "driver/dac.h"
}

// Config WiFi / Server
const char* WIFI_SSID = "Juanma";
const char* WIFI_PASS = "38814831";
const char* BASE_URL  = "http://choreal-kalel-directed.ngrok-free.dev";
const char* DEVICE_ID = "esp32_1";

// Audio objects
AudioGeneratorWAV*          wav       = nullptr;
AudioFileSourceHTTPStream*  file_http = nullptr;
AudioOutputI2SNoDAC*        out       = nullptr;

// Estado general
String modoActual = "ninguno";
bool sistemaMusica_activo = false;     // 0x0B - Handlers de música
bool sistemaAudioWAV_activo = false;   // 0x0C - Audio WAV streaming

// Variables música (0x0B)
String currentTrackId = "";
String currentTitle = "";
String currentArtist = "";
String currentStreamUrl = "";
bool isPlaying = false;
int currentVolume = 80;

// Comunicación con Arduino externo
HardwareSerial SerialArduino(2);
const int arduinoRX = 16;
const int arduinoTX = 17;

// Prototipos
void stopAudio();
bool playWavStream(const String& url);
bool confirmPlayback(const String& audio_id, const String& status);
static inline void enableBothDACChannels();

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
void enviarNumeroArduino(int numero);
void enviarComandoArduino(String comando, int valor);
void iniciarPantalla();

// Cierra y libera todos los objetos de audio activos
void stopAudio() {
  if (wav)        { wav->stop(); delete wav; wav = nullptr; }
  if (file_http)  { delete file_http; file_http = nullptr; }
  if (out)        { delete out; out = nullptr; }
}

// Habilita salida en ambos DACs internos mediante I2S
static inline void enableBothDACChannels() {
  i2s_set_dac_mode(I2S_DAC_CHANNEL_BOTH_EN);
}

// Reproduce un flujo WAV desde HTTP usando ESP8266Audio
bool playWavStream(const String& url) {
  stopAudio();

  Serial.print("Reproduciendo: ");
  Serial.println(url);

  file_http = new AudioFileSourceHTTPStream(url.c_str());
  file_http->SetReconnect(3, 200);

  out = new AudioOutputI2SNoDAC();
  out->SetOutputModeMono(true);
  out->SetGain(0.6);

  wav = new AudioGeneratorWAV();
  if (!wav->begin(file_http, out)) {
    Serial.println("WAV begin (stream) falló");
    stopAudio();
    return false;
  }

  enableBothDACChannels();

  Serial.println("Streaming audio...");
  while (wav->isRunning()) {
    if (!wav->loop()) break;
    delay(1);
  }
  Serial.println("Fin de reproducción (stream)");

  stopAudio();
  return true;
}

// Notifica al backend que un audio fue reproducido o falló
bool confirmPlayback(const String& audio_id, const String& status) {
  HTTPClient http;
  http.setReuse(true);
  http.setTimeout(8000);
  String url = String(BASE_URL) + "/esp32/confirmar/" + DEVICE_ID;

  if (!http.begin(url)) return false;
  http.addHeader("Content-Type", "application/x-www-form-urlencoded");
  String body = "audio_id=" + audio_id + "&status=" + status;
  int code = http.POST(body);
  http.end();
  Serial.printf("Confirmar %s -> %d\n", status.c_str(), code);
  return (code >= 200 && code < 300);
}

// Procesa un comando JSON recibido desde el servidor
void procesarComando(JsonObject cmd) {
  const char* tipo = cmd["tipo"];
  
  Serial.println();
  Serial.println("Comando entrante");
  Serial.print("Tipo: ");
  Serial.println(tipo);
  
  // Comando hexadecimal para cambiar modos/acciones
  if (strcmp(tipo, "comando_hex") == 0) {
    int comando = cmd["comando_int"];
    const char* hex_str = cmd["comando"];
    
    Serial.print("HEX: ");
    Serial.print(hex_str);
    Serial.print(" (DEC: ");
    Serial.print(comando);
    Serial.println(")");
    Serial.println();
    
    ejecutarComandoHex(comando);
    return;
  }
  
  // Reproducir voz asociada a un comando (TTS precacheado)
  if (strcmp(tipo, "reproducir_comando_voz") == 0) {
    const char* audio_id = cmd["audio_id"];
    const char* mensaje = cmd["mensaje"] | "";
    
    Serial.print("Mensaje: ");
    Serial.println(mensaje);
    Serial.print("Audio ID: ");
    Serial.println(audio_id);
    Serial.println();
    
    String wavURL = String(BASE_URL) + "/esp32/audio_raw/" + audio_id;
    bool played = playWavStream(wavURL);
    confirmPlayback(audio_id, played ? "success" : "error");
    return;
  }
  
  // Handlers del sistema de música activos
  if (sistemaMusica_activo) {
    String tipoStr = String(tipo);
    
    if (tipoStr == "reproducir_musica") {
      handlePlayMusic(cmd);
    } 
    else if (tipoStr == "musica_detener") {
      handleStop();
    }
    else if (tipoStr == "musica_pausa") {
      handlePause();
    }
    else if (tipoStr == "musica_continuar") {
      handleResume();
    }
    else if (tipoStr == "musica_volumen") {
      handleVolume(cmd);
    }
    else if (tipoStr == "musica_seek") {
      handleSeek(cmd);
    }
    
    Serial.println();
    return;
  }
  
  // Handlers del sistema de audio WAV (frases, conversación, loro)
  if (sistemaAudioWAV_activo) {
    const char* audio_id = cmd["audio_id"] | "";
    
    if (strcmp(tipo, "reproducir_frase") == 0) {
      handleFrase(cmd);
      if (audio_id && *audio_id) {
        String wavURL = String(BASE_URL) + "/esp32/audio_raw/" + audio_id;
        bool played = playWavStream(wavURL);
        confirmPlayback(audio_id, played ? "success" : "error");
      }
    }
    else if (strcmp(tipo, "reproducir_conversacion") == 0) {
      handleConversacion(cmd);
      if (audio_id && *audio_id) {
        String wavURL = String(BASE_URL) + "/esp32/audio_raw/" + audio_id;
        bool played = playWavStream(wavURL);
        confirmPlayback(audio_id, played ? "success" : "error");
      }
    }
    else if (strcmp(tipo, "reproducir_loro") == 0) {
      handleLoro(cmd);
      if (audio_id && *audio_id) {
        String wavURL = String(BASE_URL) + "/esp32/audio_raw/" + audio_id;
        bool played = playWavStream(wavURL);
        confirmPlayback(audio_id, played ? "success" : "error");
      }
    }
    
    Serial.println();
    return;
  }
  
  // Ningún sistema activo
  Serial.print("Tipo no manejado o sistema inactivo: ");
  Serial.println(tipo);
  Serial.println("Activa primero música (0x0B) o voces (0x0C)");
}

// Envía un número simple a Arduino (como decimal)
void enviarNumeroArduino(int numero) {
  SerialArduino.println(numero);
  Serial.print("Enviado a Arduino: ");
  Serial.println(numero);
}

// Envía un comando con valor a Arduino en formato clave:valor
void enviarComandoArduino(String comando, int valor) {
  String mensaje = comando + ":" + String(valor);
  SerialArduino.println(mensaje);
  Serial.print("Enviado: ");
  Serial.println(mensaje);
}

// Ejecuta acciones según el comando hexadecimal recibido
void ejecutarComandoHex(int comando) {
  switch (comando) {
    case 0x01:
      tft.drawRGBBitmap(0, 0, robotsaludando, 320, 240);
      Serial.println("1 - Robot encendido");
      Serial.println("Inicializando sistemas...");
      modoActual = "encendido";
      break;
      
    case 0x02:
      tft.drawRGBBitmap(0, 0, durmiendorobot, 320, 240);
      Serial.println("2 - Apagando robot...");
      Serial.println("Deteniendo sistemas...");
      sistemaMusica_activo = false;
      sistemaAudioWAV_activo = false;
      stopAudio();
      modoActual = "apagado";
      break;
      
    case 0x03:
      tft.drawRGBBitmap(0, 0, utec, 320, 240);
      Serial.println("3 - Modo Turismo");
      modoActual = "turismo";
      break;
      
    case 0x04:
      Serial.println("4 - Modo Movimientos");
      modoActual = "movimientos";
      break;
      
    case 0x05:
      Serial.println("5 - Modo Audio");
      modoActual = "audio";
      break;
      
    case 0x06:
      Serial.println("6 - Modo Imágenes");
      modoActual = "imagenes";
      break;
      
    case 0x07:
      Serial.println("7 - Modo Cámara");
      modoActual = "camara";
      break;
      
    case 0x08:
      Serial.println("8 - Modelos Predefinidos");
      break;
      
    case 0x09:
      Serial.println("9 - Elegir Movimientos");
      break;
      
    case 0x0A:
      Serial.println("10 - Repetir Movimientos con Cámara");
      break;
      
    // Sistema de música activado
    case 0x0B:
      Serial.println("Sistema de música ACTIVADO");
      Serial.println("Handlers: reproducir_musica, musica_detener, musica_pausa, musica_continuar, musica_volumen, musica_seek");
      sistemaMusica_activo = true;
      sistemaAudioWAV_activo = false;
      modoActual = "musica";
      break;
      
    // Sistema de voces/stream WAV activado
    case 0x0C:
      Serial.println("Sistema de voces ACTIVADO");
      Serial.println("Tipos: reproducir_frase, reproducir_conversacion, reproducir_loro");
      sistemaAudioWAV_activo = true;
      sistemaMusica_activo = false;
      modoActual = "voces";
      break;

    case 0x10:
      Serial.println("Poniendo Bandera de Uruguay");
      tft.drawRGBBitmap(0, 0, uruguay, 320, 240);
      break;
    case 0x11:
      Serial.println("Imagen de UTEC");
      tft.drawRGBBitmap(0, 0, utec, 320, 240);
      break;
    case 0x12:
      Serial.println("UTEC logo");
      tft.drawRGBBitmap(0, 0, logoutec, 320, 240);
      break;
    case 0x13:
      Serial.println("IMEC logo");
      tft.drawRGBBitmap(0, 0, logoimec, 320, 240);
      break;

    case 0x14:
      enviarNumeroArduino(0);
      Serial.println("Moviendo todos 45 grados");
      break;
        
    case 0x15:
      enviarNumeroArduino(1);
      Serial.println("Moviendo todos 90 grados");
      break; 

    case 0x16:
      enviarNumeroArduino(2);
      Serial.println("Moviendo solo XL430"); 
      break;
      
    case 0x17:
      enviarNumeroArduino(3);
      Serial.println("Moviendo solo XL320"); 
      break;
    
    case 0x18:
      enviarNumeroArduino(4);
      Serial.println("Moviendo todos 180"); 
      break;

    default:
      Serial.print("Comando no reconocido: 0x");
      Serial.print(comando, HEX);
      Serial.print(" (dec: ");
      Serial.print(comando);
      Serial.println(")");
      break;
  }
  
  Serial.println();
}

// Inicia la reproducción de música a partir de un comando
void handlePlayMusic(JsonObject cmd) {
  currentStreamUrl = cmd["url"].as<String>();
  currentTitle = cmd["titulo"].as<String>();
  currentArtist = cmd["artista"].as<String>();
  
  Serial.println("REPRODUCIR MÚSICA");
  Serial.println("Título: " + currentTitle);
  Serial.println("Artista: " + currentArtist);
  Serial.println("URL: " + currentStreamUrl);
  
  isPlaying = true;
  
  Serial.println("[SIMULADO] Reproducción iniciada");
  Serial.println("Integrar reproductor MP3/streaming aquí");
}

// Detiene cualquier reproducción en curso
void handleStop() {
  Serial.println("DETENER REPRODUCCIÓN");
  isPlaying = false;
  currentTitle = "";
  currentArtist = "";
  currentStreamUrl = "";
  stopAudio();
  Serial.println("Reproducción detenida");
}

// Pausa la reproducción (placeholder)
void handlePause() {
  Serial.println("PAUSAR REPRODUCCIÓN");
  Serial.println("Reproducción pausada");
}

// Reanuda la reproducción (placeholder)
void handleResume() {
  Serial.println("REANUDAR REPRODUCCIÓN");
  Serial.println("Reproducción reanudada");
}

// Ajusta el volumen y actualiza la ganancia del I2S
void handleVolume(JsonObject cmd) {
  int volume = cmd["volume"].as<int>();
  currentVolume = volume;
  
  Serial.printf("AJUSTAR VOLUMEN: %d%%\n", volume);
  
  if (out) {
    float gain = volume / 100.0;
    out->SetGain(gain);
  }
  
  Serial.println("Volumen ajustado");
}

// Simula un seek en la pista actual (placeholder)
void handleSeek(JsonObject cmd) {
  int position_ms = cmd["position_ms"].as<int>();
  int position_sec = position_ms / 1000;
  
  Serial.printf("BUSCAR POSICIÓN: %d segundos\n", position_sec);
  Serial.println("Posición ajustada");
}

// Muestra datos de una frase a reproducir
void handleFrase(JsonObject cmd) {
  String audio_id = cmd["audio_id"].as<String>();
  String nombre = cmd["nombre"].as<String>();
  
  Serial.println("REPRODUCIR FRASE");
  Serial.println("Nombre: " + nombre);
  Serial.println("Audio ID: " + audio_id);
}

// Muestra datos de conversación TTS
void handleConversacion(JsonObject cmd) {
  String audio_id = cmd["audio_id"].as<String>();
  String texto_usuario = cmd["texto_usuario"].as<String>();
  String texto_robot = cmd["texto_robot"].as<String>();
  
  Serial.println("CONVERSACIÓN");
  Serial.println("Usuario: " + texto_usuario);
  Serial.println("Robot: " + texto_robot);
  Serial.println("Audio ID: " + audio_id);
}

// Modo loro: muestra texto y efecto aplicados
void handleLoro(JsonObject cmd) {
  String audio_id = cmd["audio_id"].as<String>();
  String texto = cmd["texto"].as<String>();
  String efecto = cmd["efecto"].as<String>();
  
  Serial.println("MODO LORO");
  Serial.println("Texto: " + texto);
  Serial.println("Efecto: " + efecto);
  Serial.println("Audio ID: " + audio_id);
}

// Configura periféricos, WiFi y registra el dispositivo en el backend
void setup() {
  Serial.begin(115200);
  tft.begin();
  tft.setRotation(1);
  tft.fillScreen(ILI9341_BLACK);

  SerialArduino.begin(9600, SERIAL_8N1, arduinoRX, arduinoTX);
  delay(1000);
  
  Serial.println();
  Serial.println("Robot NAO con Musica, Voces, Comunicacion con Arduino y Pantalla");

  // WiFi
  WiFi.mode(WIFI_STA);
  WiFi.setAutoReconnect(true);
  WiFi.begin(WIFI_SSID, WIFI_PASS);
  Serial.print("Conectando WiFi");
  
  while (WiFi.status() != WL_CONNECTED) {
    delay(250);
    Serial.print(".");
  }
  
  Serial.printf("\nWiFi conectado\n");
  Serial.printf("   IP: %s\n", WiFi.localIP().toString().c_str());
  Serial.printf("   RSSI: %d dBm\n", WiFi.RSSI());

  // Registro en backend
  Serial.println("\nRegistrando dispositivo...");
  {
    HTTPClient http;
    http.setReuse(true);
    http.setTimeout(8000);
    String url = String(BASE_URL) + "/esp32/register";
    
    if (http.begin(url)) {
      http.addHeader("Content-Type", "application/x-www-form-urlencoded");
      String body = String("device_id=") + DEVICE_ID + "&nombre=NAO_Robot&ubicacion=Lab";
      int code = http.POST(body);
      String resp = http.getString();
      http.end();
      
      if (code >= 200 && code < 300) {
        Serial.println("Dispositivo registrado");
      } else {
        Serial.printf("Registro: %d\n", code);
      }
    }
  }
  
  Serial.println("\nSistema Listo");
}

// Bucle principal: lee Arduino, hace poll al backend y mantiene audio
void loop() {
  if (SerialArduino.available()) {
    String respuesta = SerialArduino.readString();
    respuesta.trim();
    
    Serial.print("Arduino responde: ");
    Serial.println(respuesta);
    
    if (respuesta == "OK") {
      // Acción al recibir OK (opcional)
    }
  }

  // Poll al backend cada 200 ms
  static unsigned long tPoll = 0;
  if (millis() - tPoll > 200) {
    tPoll = millis();

    HTTPClient http;
    http.setReuse(true);
    http.setTimeout(5000);
    String url = String(BASE_URL) + "/esp32/poll/" + DEVICE_ID;

    if (!http.begin(url)) {
      return;
    }

    int code = http.GET();
    
    if (code == HTTP_CODE_OK) {
      DynamicJsonDocument doc(4096);
      DeserializationError e = deserializeJson(doc, http.getStream());
      http.end();

      if (!e) {
        JsonArray cmds = doc["comandos"].as<JsonArray>();
        if (!cmds.isNull() && cmds.size() > 0) {
          for (JsonObject cmd : cmds) {
            procesarComando(cmd);
          }
        }
      }
    }
  }

  // Mantener el generador WAV corriendo
  if (wav && wav->isRunning()) {
    if (!wav->loop()) {
      stopAudio();
    }
  }

  delay(1);
}
