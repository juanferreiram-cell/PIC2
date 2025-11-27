import '../api/nao_api.dart';

class AppConfig {
  static String baseUrl =
      'https://choreal-kalel-directed.ngrok-free.dev'; // <-- Cambiá esto
  static String deviceId = 'esp32_1';
  static bool mantenerContexto = true;

  static final NaoApi api = NaoApi(baseUrl: baseUrl);

  static void setBaseUrl(String url) {
    baseUrl = url.trim();
    api.setBaseUrl(baseUrl);
  }

  static void setDeviceId(String id) {
    deviceId = id.trim();
  }

  static void setMantenerContexto(bool v) {
    mantenerContexto = v;
  }
}
