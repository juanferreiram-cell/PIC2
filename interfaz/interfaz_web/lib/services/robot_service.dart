import 'package:http/http.dart' as http;
import 'package:interfaz/core/app_config.dart';

class RobotService {
  static final RobotService _instance = RobotService._internal();
  factory RobotService() => _instance;
  RobotService._internal();
  
  // ✅ Lee directamente de AppConfig
  String get baseUrl => AppConfig.baseUrl;
  String get deviceId => AppConfig.deviceId;
  
  Future<bool> sendCommand(int hexValue) async {
    try {
      final hexString = '0x${hexValue.toRadixString(16).toUpperCase().padLeft(2, '0')}';
      
      print('📤 Enviando comando $hexString a $deviceId');
      print('🌐 URL: $baseUrl/control/comando_hex');
      
      final response = await http.post(
        Uri.parse('$baseUrl/control/comando_hex'),
        body: {
          'device_id': deviceId,
          'comando_hex': hexString,
        },
      );
      
      if (response.statusCode == 200) {
        print('✅ Comando enviado exitosamente');
        return true;
      } else {
        print('❌ Error ${response.statusCode}: ${response.body}');
        return false;
      }
      
    } catch (e) {
      print('❌ Error de conexión: $e');
      return false;
    }
  }
  
  // ========== MODOS PRINCIPALES ==========
  Future<void> modoVoz() => sendCommand(0x01);
  Future<void> modoLoro() => sendCommand(0x02);
  Future<void> modoMusica() => sendCommand(0x03);
  Future<void> modoMovimiento() => sendCommand(0x04);
  Future<void> modoArduino() => sendCommand(0x05);
  Future<void> modoConversacion() => sendCommand(0x06);
  
  // ========== FRASES (requiere modo voz 0x01 activo) ==========
  Future<void> decirHola() => sendCommand(0x10);
  Future<void> decirAdios() => sendCommand(0x11);
  Future<void> decirGracias() => sendCommand(0x12);
  Future<void> decirComoEstas() => sendCommand(0x13);
  
  // ========== LORO (requiere modo loro 0x02 activo) ==========
  Future<void> loroNormal() => sendCommand(0x20);
  Future<void> loroRapido() => sendCommand(0x21);
  Future<void> loroLento() => sendCommand(0x22);
  Future<void> loroAgudo() => sendCommand(0x23);
  Future<void> loroGrave() => sendCommand(0x24);
  
  // ========== MÚSICA (requiere modo música 0x03 activo) ==========
  Future<void> reproducirMusica() => sendCommand(0x30);
  Future<void> pausarMusica() => sendCommand(0x31);
  Future<void> detenerMusica() => sendCommand(0x32);
  Future<void> siguienteCancion() => sendCommand(0x33);
  Future<void> anteriorCancion() => sendCommand(0x34);
  Future<void> volumenSubir() => sendCommand(0x35);
  Future<void> volumenBajar() => sendCommand(0x36);
  
  // ========== MOVIMIENTOS (requiere modo movimiento 0x04 activo) ==========
  Future<void> brazoIzqArriba() => sendCommand(0x40);
  Future<void> brazoIzqAbajo() => sendCommand(0x41);
  Future<void> brazoDerArriba() => sendCommand(0x42);
  Future<void> brazoDerAbajo() => sendCommand(0x43);
  Future<void> cabezaIzquierda() => sendCommand(0x44);
  Future<void> cabezaDerecha() => sendCommand(0x45);
  Future<void> secuenciaSaludo() => sendCommand(0x46);
  Future<void> secuenciaBaile() => sendCommand(0x47);
  
  // ========== ARDUINO (requiere modo arduino 0x05 activo) ==========
  Future<void> arduinoLedOn() => sendCommand(0x50);
  Future<void> arduinoLedOff() => sendCommand(0x51);
  Future<void> arduinoSensorLeer() => sendCommand(0x52);
  Future<void> arduinoMotorAdelante() => sendCommand(0x53);
  Future<void> arduinoMotorAtras() => sendCommand(0x54);
  
  // ========== CONVERSACIÓN (requiere modo conversación 0x06 activo) ==========
  Future<void> iniciarEscucha() => sendCommand(0x60);
  Future<void> detenerEscucha() => sendCommand(0x61);
  Future<void> limpiarContexto() => sendCommand(0x62);
}