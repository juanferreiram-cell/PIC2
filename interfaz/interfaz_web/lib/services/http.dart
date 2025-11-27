import 'package:http/http.dart' as http;

class HttpController {
  final String esp32ip = "http://192.168.1.100"; // ⚠️ Cambia a tu IP real

  Future<void> sendCommand(int command) async {
    final url = Uri.parse("$esp32ip/comando/$command");
    try {
      final response = await http.get(url);
      print("Respuesta ESP32: ${response.body}");
    } catch (e) {
      print("Error enviando comando: $e");
    }
  }
}
