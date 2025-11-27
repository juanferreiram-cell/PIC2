#include <WiFi.h>
#include <HTTPClient.h>
#include <ArduinoJson.h>
#include <ei-esp32cam_poses-arduino-1.0.12.h>
#include "edge-impulse-sdk/dsp/image/image.hpp"
#include "esp_camera.h"

// Configuracion para conectarse al WiFi y al servidor
const char* WIFI_SSID = "Juanma";
const char* WIFI_PASS = "38814831";
const char* BASE_URL = "http://choreal-kalel-directed.ngrok-free.dev";
const char* DEVICE_ID = "esp32cam_poses";
const char* ESP32_TARGET_ID = "esp32_1";

// Configuracion del modelo de la camara
#define CAMERA_MODEL_AI_THINKER

#define PWDN_GPIO_NUM     32
#define RESET_GPIO_NUM    -1
#define XCLK_GPIO_NUM      0
#define SIOD_GPIO_NUM     26
#define SIOC_GPIO_NUM     27
#define Y9_GPIO_NUM       35
#define Y8_GPIO_NUM       34
#define Y7_GPIO_NUM       39
#define Y6_GPIO_NUM       36
#define Y5_GPIO_NUM       21
#define Y4_GPIO_NUM       19
#define Y3_GPIO_NUM       18
#define Y2_GPIO_NUM        5
#define VSYNC_GPIO_NUM    25
#define HREF_GPIO_NUM     23
#define PCLK_GPIO_NUM     22

// Constantes de Edge Impulse
#define EI_CAMERA_RAW_FRAME_BUFFER_COLS  320
#define EI_CAMERA_RAW_FRAME_BUFFER_ROWS  240
#define EI_CAMERA_FRAME_BYTE_SIZE        3

// Mapeo de comandos para cada pose
struct PoseCommand {
    const char* poseName;
    uint8_t hexCommand;
    const char* descripcion;
};

PoseCommand poseMap[] = {
    {"dab", 0x50, "Pose dab"},
    {"superman", 0x51, "Pose superman"},
    {"bicep", 0x52, "Pose biceps"},
    {"fondo", 0xFF, "Ninguna pose o solamente el fondo"}
};

const int NUM_POSES = sizeof(poseMap) / sizeof(PoseCommand);

// Control de estado
bool sistemaActivo = false;  // se activa con el comando 0x07
bool cameraInitialized = false;

// Tiempos y umbrales
float confidenceThreshold = 0.60; // Valor minimo para estar segura de que esta viendo la pose
float poseActionThreshold = 0.65; // Ejecuta la pose
const unsigned long DETECTION_COOLDOWN = 2000;
const unsigned long FONDO_TIMEOUT = 5000;
const unsigned long POLLING_INTERVAL = 1000;

//Variables de control
unsigned long lastDetection = 0;
unsigned long lastPoseTime = 0;
unsigned long lastPolling = 0;
String lastPose = "";

// Variables de la camara
uint8_t *snapshot_buf = nullptr;

static camera_config_t camera_config = {
    .pin_pwdn = PWDN_GPIO_NUM,
    .pin_reset = RESET_GPIO_NUM,
    .pin_xclk = XCLK_GPIO_NUM,
    .pin_sscb_sda = SIOD_GPIO_NUM,
    .pin_sscb_scl = SIOC_GPIO_NUM,
    .pin_d7 = Y9_GPIO_NUM,
    .pin_d6 = Y8_GPIO_NUM,
    .pin_d5 = Y7_GPIO_NUM,
    .pin_d4 = Y6_GPIO_NUM,
    .pin_d3 = Y5_GPIO_NUM,
    .pin_d2 = Y4_GPIO_NUM,
    .pin_d1 = Y3_GPIO_NUM,
    .pin_d0 = Y2_GPIO_NUM,
    .pin_vsync = VSYNC_GPIO_NUM,
    .pin_href = HREF_GPIO_NUM,
    .pin_pclk = PCLK_GPIO_NUM,
    .xclk_freq_hz = 20000000,
    .ledc_timer = LEDC_TIMER_0,
    .ledc_channel = LEDC_CHANNEL_0,
    .pixel_format = PIXFORMAT_JPEG,
    .frame_size = FRAMESIZE_QVGA,
    .jpeg_quality = 12,
    .fb_count = 1,
    .fb_location = CAMERA_FB_IN_PSRAM,
    .grab_mode = CAMERA_GRAB_WHEN_EMPTY,
};


bool ei_camera_init(void);
void ei_camera_deinit(void);
bool ei_camera_capture(uint32_t img_width, uint32_t img_height, uint8_t *out_buf);
static int ei_camera_get_data(size_t offset, size_t length, float *out_ptr);
uint8_t findHexCommand(String poseName);
bool sendPoseToServer(uint8_t hexCommand, String poseName, float confidence);
void procesarComando(JsonObject cmd);
void activarSistema();
void desactivarSistema();
void loopDeteccion();
void loopPolling();


void setup() {
    Serial.begin(115200);
    delay(1000);
    

    Serial.println("ESP32-CAM - Deteccion de Poses");
    Serial.println("MODO: Activacion por comando 0x07");
    Serial.println();
    
    // Conectar WiFi
    WiFi.mode(WIFI_STA);
    WiFi.begin(WIFI_SSID, WIFI_PASS);
    Serial.print("Conectando a WiFi");
    
    int attempts = 0;
    while (WiFi.status() != WL_CONNECTED && attempts < 30) {
        delay(500);
        Serial.print(".");
        attempts++;
    }
    
    if (WiFi.status() != WL_CONNECTED) {
        Serial.println("\nError conectando WiFi");
        Serial.println("Verifica SSID y contraseña");
        while(1) delay(1000);
    }

    
    // Registrar en servidor
    Serial.print("Registrando en servidor");
    HTTPClient http;
    http.setTimeout(5000);
    String registerURL = String(BASE_URL) + "/esp32/register";
    
    if (http.begin(registerURL)) {
        http.addHeader("Content-Type", "application/x-www-form-urlencoded");
        String postData = "device_id=" + String(DEVICE_ID) + 
                         "&nombre=ESP32-CAM Poses&ubicacion=Vision Sistema";
        int code = http.POST(postData);
        
        if (code == HTTP_CODE_OK) {
            Serial.println("OK");
        } else {
            Serial.printf("Error %d\n", code);
        }
        http.end();
    } else {
        Serial.println("FALLO");
    }
    
    Serial.println();
    Serial.println("CONFIGURACIÓN:");
    Serial.printf("   - Device ID: %s\n", DEVICE_ID);
    Serial.printf("   - Target ESP32: %s\n", ESP32_TARGET_ID);
    Serial.printf("   - Estado inicial: INACTIVO\n");
    Serial.printf("   - Comando activacion: 0x07\n");
    Serial.printf("   - Comando desactivacion: 0x08\n");
    
    Serial.println();
    Serial.println("POSES CONFIGURADAS:");
    for (int i = 0; i < NUM_POSES; i++) {
        Serial.printf("   - %s → 0x%02X (%s)\n", 
                     poseMap[i].poseName, 
                     poseMap[i].hexCommand,
                     poseMap[i].descripcion);
    }
    
    Serial.println();
    Serial.println("Esperando comando 0x07 para activar");
    Serial.println();
    
    delay(1000);
}

void loop() {
    // Verificar WiFi
    if (WiFi.status() != WL_CONNECTED) {
        Serial.println("WiFi desconectado, reconectando");
        WiFi.reconnect();
        delay(5000);
        return;
    }
    
    // Polling para recibir los comandos
    loopPolling();
    
    // Solo hace la accion si esta prendido el sistema
    if (sistemaActivo) {
        loopDeteccion();
    } else {
        delay(100);
    }
}

// Polling para recibir los comandos del server
void loopPolling() {
    if (millis() - lastPolling < POLLING_INTERVAL) {
        return;
    }
    
    lastPolling = millis();
    
    HTTPClient http;
    http.setReuse(true);
    http.setTimeout(2000);
    
    String pollURL = String(BASE_URL) + "/esp32/poll/" + DEVICE_ID;
    
    if (http.begin(pollURL)) {
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

// Procesar los comandos del servidor
void procesarComando(JsonObject cmd) {
    const char* tipo = cmd["tipo"];
    
    if (strcmp(tipo, "comando_hex") == 0) {
        int comando = cmd["comando_int"];
        
        Serial.println();
        Serial.printf("Comando recibido: 0x%02X\n", comando);
        
        switch(comando) {
            case 0x07: // Prende el sistema
                Serial.println("ACTIVANDO SISTEMA DE DETECCION");
                activarSistema();
                break;
                
            case 0x08: // Lo apaga
                Serial.println("DESACTIVANDO SISTEMA DE DETECCION");
                desactivarSistema();
                break;
                
            default:
                Serial.printf("Comando 0x%02X no reconocido\n", comando);
                break;
        }
        
        Serial.println();
    }
}


void activarSistema() {
    if (sistemaActivo) {
        Serial.println("Sistema ya esta activo");
        return;
    }
    
    // Inicia la camara si no esta inicializada
    if (!cameraInitialized) {
        Serial.print("Inicializando cámara");
        if (ei_camera_init()) {
            cameraInitialized = true;
            Serial.println(" OK");
        } else {
            Serial.println("FALLO");
            return;
        }
    }
    
    sistemaActivo = true;
    lastPose = "";
    lastPoseTime = 0;
    lastDetection = 0;
    
    Serial.println("Sistema de detección ACTIVO");
    Serial.println("Comenzando detección de poses");
}


void desactivarSistema() {
    if (!sistemaActivo) {
        Serial.println("Sistema ya está inactivo");
        return;
    }
    
    sistemaActivo = false;
    lastPose = "";
    lastPoseTime = 0;
    
    // Liberar memoria si hay snapshot
    if (snapshot_buf != nullptr) {
        free(snapshot_buf);
        snapshot_buf = nullptr;
    }
    
    Serial.println("Sistema de deteccion DESACTIVADO");
    Serial.println("Esperando comando 0x07 para reactivar");
}

// Deteccion de pose
void loopDeteccion() {
    // Tiempo entre detecciones
    if (millis() - lastDetection < DETECTION_COOLDOWN) {
        delay(50);
        return;
    }
    
    snapshot_buf = (uint8_t*)malloc(EI_CAMERA_RAW_FRAME_BUFFER_COLS * 
                                    EI_CAMERA_RAW_FRAME_BUFFER_ROWS * 
                                    EI_CAMERA_FRAME_BYTE_SIZE);
    
    if (snapshot_buf == nullptr) {
        Serial.println("Error: No hay memoria para snapshot");
        delay(1000);
        return;
    }
    
    // Crear señal para Edge Impulse
    ei::signal_t signal;
    signal.total_length = EI_CLASSIFIER_INPUT_WIDTH * EI_CLASSIFIER_INPUT_HEIGHT;
    signal.get_data = &ei_camera_get_data;
    
    // Capturar imagen
    if (!ei_camera_capture((size_t)EI_CLASSIFIER_INPUT_WIDTH, 
                          (size_t)EI_CLASSIFIER_INPUT_HEIGHT, 
                          snapshot_buf)) {
        Serial.println("Error capturando imagen");
        free(snapshot_buf);
        snapshot_buf = nullptr;
        delay(500);
        return;
    }
    
    ei_impulse_result_t result = {0};
    EI_IMPULSE_ERROR err = run_classifier(&signal, &result, false);
    
    if (err != EI_IMPULSE_OK) {
        Serial.printf("Error en clasificación: %d\n", err);
        free(snapshot_buf);
        snapshot_buf = nullptr;
        delay(500);
        return;
    }
    
    // Procesar resultado
    String detectedPose = "";
    float maxConfidence = 0.0;
    
    for (size_t i = 0; i < EI_CLASSIFIER_LABEL_COUNT; i++) {
        if (result.classification[i].value > maxConfidence) {
            maxConfidence = result.classification[i].value;
            detectedPose = result.classification[i].label;
        }
    }
    
    // Muestra predicciones
    if (maxConfidence > 0.3) {
        Serial.println("Predicciones");
        for (size_t i = 0; i < EI_CLASSIFIER_LABEL_COUNT; i++) {
            Serial.printf("  %s: %.2f%%\n", 
                         result.classification[i].label, 
                         result.classification[i].value * 100);
        }
    }
    
    // Flags
    bool esFondo = (detectedPose == "fondo");
    bool cumpleUmbral = (maxConfidence >= confidenceThreshold);
    bool esNuevaPose = (detectedPose != lastPose);
    
    // Logica para la deteccion
    if (!esFondo && cumpleUmbral && esNuevaPose) {
        Serial.println();
        Serial.println("POSE DETECTADA");
        Serial.printf("   Pose: %s\n", detectedPose.c_str());
        Serial.printf("   Confianza: %.1f%%\n", maxConfidence * 100);
        
        uint8_t hexCommand = findHexCommand(detectedPose);
        
        if (hexCommand != 0xFF) {
            Serial.printf("   Comando: 0x%02X\n", hexCommand);
            
            if (maxConfidence >= poseActionThreshold) {
                if (sendPoseToServer(hexCommand, detectedPose, maxConfidence)) {
                    lastPose = detectedPose;
                    lastPoseTime = millis();
                    lastDetection = millis();
                    Serial.println("Enviado al servidor");
                } else {
                    Serial.println("Error enviando");
                }
            } else {
                Serial.printf("Confianza insuficiente (%.1f%% < %.1f%%)\n", 
                             maxConfidence * 100, 
                             poseActionThreshold * 100);
            }
        }
        Serial.println();
    }
    else if (esFondo && lastPose != "fondo" && lastPose != "") {
        Serial.println("ℹ️ Volvió a fondo");
        lastPose = "fondo";
        lastPoseTime = 0;
    }
    
    // Auto-reset
    if (lastPose != "fondo" && lastPose != "" && lastPoseTime > 0 &&
        (millis() - lastPoseTime > FONDO_TIMEOUT)) {
        Serial.println("⏱️ Timeout - Auto-reset a fondo");
        lastPose = "fondo";
        lastPoseTime = 0;
    }
    
    // Liberar memoria
    free(snapshot_buf);
    snapshot_buf = nullptr;
    
    delay(100);
}

// Funciones auxiliares

uint8_t findHexCommand(String poseName) {
    for (int i = 0; i < NUM_POSES; i++) {
        if (poseName.equals(poseMap[i].poseName)) {
            return poseMap[i].hexCommand;
        }
    }
    return 0xFF;
}

bool sendPoseToServer(uint8_t hexCommand, String poseName, float confidence) {
    HTTPClient http;
    String url = String(BASE_URL) + "/camera/pose_detected";
    
    http.setTimeout(5000); 
    
    if (!http.begin(url)) {
        Serial.println("Error: No se pudo conectar al servidor");
        return false;
    }
    
    http.addHeader("Content-Type", "application/x-www-form-urlencoded");
    
    char hexStr[5];
    sprintf(hexStr, "%02X", hexCommand);
    
    String postData = "device_id=" + String(DEVICE_ID) + 
                     "&comando_hex=" + String(hexStr) +
                     "&pose_name=" + poseName +
                     "&confidence=" + String(confidence, 3) +
                     "&target_device=" + String(ESP32_TARGET_ID);
    
    
    int httpCode = http.POST(postData);
    
    
    if (httpCode == HTTP_CODE_OK) {
        String response = http.getString();
        Serial.println("Respuesta: " + response);
        http.end();
        return true;
    } else if (httpCode > 0) {
        String response = http.getString();
        Serial.printf("Error HTTP %d: %s\n", httpCode, response.c_str());
        http.end();
        return false;
    } else {
        Serial.printf("Error de conexión: %s\n", http.errorToString(httpCode).c_str());
        http.end();
        return false;
    }
}

bool ei_camera_init(void) {
    if (cameraInitialized) return true;

    esp_err_t err = esp_camera_init(&camera_config);
    if (err != ESP_OK) {
        Serial.printf("\nCamera init error: 0x%x\n", err);
        return false;
    }

    sensor_t *s = esp_camera_sensor_get();
    if (s->id.PID == OV3660_PID) {
        s->set_vflip(s, 1);
        s->set_brightness(s, 1);
        s->set_saturation(s, 0);
    }

    return true;
}

void ei_camera_deinit(void) {
    esp_err_t err = esp_camera_deinit();
    if (err == ESP_OK) {
        cameraInitialized = false;
    }
}

bool ei_camera_capture(uint32_t img_width, uint32_t img_height, uint8_t *out_buf) {
    if (!cameraInitialized) {
        return false;
    }

    camera_fb_t *fb = esp_camera_fb_get();
    if (!fb) {
        return false;
    }

    bool converted = fmt2rgb888(fb->buf, fb->len, PIXFORMAT_JPEG, snapshot_buf);
    esp_camera_fb_return(fb);

    if (!converted) {
        return false;
    }

    bool do_resize = (img_width != EI_CAMERA_RAW_FRAME_BUFFER_COLS) ||
                     (img_height != EI_CAMERA_RAW_FRAME_BUFFER_ROWS);

    if (do_resize) {
        ei::image::processing::crop_and_interpolate_rgb888(
            out_buf,
            EI_CAMERA_RAW_FRAME_BUFFER_COLS,
            EI_CAMERA_RAW_FRAME_BUFFER_ROWS,
            out_buf,
            img_width,
            img_height);
    }

    return true;
}

static int ei_camera_get_data(size_t offset, size_t length, float *out_ptr) {
    size_t pixel_ix = offset * 3;
    size_t pixels_left = length;
    size_t out_ptr_ix = 0;

    while (pixels_left != 0) {
        out_ptr[out_ptr_ix] = (snapshot_buf[pixel_ix + 2] << 16) + 
                              (snapshot_buf[pixel_ix + 1] << 8) + 
                              snapshot_buf[pixel_ix];
        out_ptr_ix++;
        pixel_ix += 3;
        pixels_left--;
    }
    
    return 0;
}