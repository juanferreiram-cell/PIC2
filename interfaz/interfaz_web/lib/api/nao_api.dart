import 'package:dio/dio.dart';
import '../models/nao_models.dart';

class NaoApiException implements Exception {
  final String message;
  final int? statusCode;
  NaoApiException(this.message, {this.statusCode});
  @override
  String toString() => 'NaoApiException($statusCode): $message';
}

class NaoApi {
  final Dio _dio;

  NaoApi({required String baseUrl, Dio? dio})
    : _dio =
          dio ??
          Dio(
            BaseOptions(
              baseUrl: baseUrl,
              connectTimeout: const Duration(seconds: 10),
              receiveTimeout: const Duration(seconds: 30),
              headers: {'Accept': 'application/json'},
            ),
          );

  // Permite cambiar baseUrl en runtime (desde Settings)
  void setBaseUrl(String baseUrl) {
    _dio.options.baseUrl = baseUrl;
  }

  // ---- Helpers ----
  Never _throwDioErr(DioException e) {
    final data = e.response?.data;
    final detail = (data is Map && data['detail'] != null)
        ? data['detail'].toString()
        : e.message ?? 'Error de red';
    throw NaoApiException(detail, statusCode: e.response?.statusCode);
  }

  // ---- API calls ----

  Future<HealthResponse> health() async {
    try {
      final r = await _dio.get('/');
      return HealthResponse.fromJson(r.data);
    } on DioException catch (e) {
      _throwDioErr(e);
    }
  }

  Future<List<Frase>> listarFrases() async {
    try {
      final r = await _dio.get('/frases/lista');
      final list = (r.data['frases'] as List<dynamic>? ?? [])
          .map((e) => Frase.fromJson(e as Map<String, dynamic>))
          .toList();
      return list;
    } on DioException catch (e) {
      _throwDioErr(e);
    }
  }

  Future<CmdFraseResponse> reproducirFrase({
    required String deviceId,
    required String nombreFrase,
  }) async {
    try {
      final r = await _dio.post(
        '/control/frase',
        data: FormData.fromMap({
          'device_id': deviceId,
          'nombre_frase': nombreFrase,
        }),
      );
      return CmdFraseResponse.fromJson(r.data as Map<String, dynamic>);
    } on DioException catch (e) {
      _throwDioErr(e);
    }
  }

  Future<ConversarResponse> conversar({
    required String deviceId,
    required String texto,
    bool mantenerContexto = true,
  }) async {
    try {
      final r = await _dio.post(
        '/control/conversar',
        data: FormData.fromMap({
          'device_id': deviceId,
          'texto': texto,
          // FastAPI Form(...) espera string; enviamos "true"/"false"
          'mantener_contexto': mantenerContexto.toString(),
        }),
      );
      return ConversarResponse.fromJson(r.data as Map<String, dynamic>);
    } on DioException catch (e) {
      _throwDioErr(e);
    }
  }

  Future<LoroResponse> repetir({
    required String deviceId,
    required String texto,
    String efecto = 'normal',
  }) async {
    try {
      final r = await _dio.post(
        '/control/repetir',
        data: FormData.fromMap({
          'device_id': deviceId,
          'texto': texto,
          'efecto': efecto,
        }),
      );
      return LoroResponse.fromJson(r.data as Map<String, dynamic>);
    } on DioException catch (e) {
      _throwDioErr(e);
    }
  }

  Future<AdminDispositivosResponse> listarDispositivos() async {
    try {
      final r = await _dio.get('/admin/dispositivos');
      return AdminDispositivosResponse.fromJson(r.data as Map<String, dynamic>);
    } on DioException catch (e) {
      _throwDioErr(e);
    }
  }

  Future<SimpleOkResponse> limpiarCacheAudio() async {
    try {
      final r = await _dio.post('/admin/limpiar_cache_audio');
      return SimpleOkResponse.fromJson(r.data as Map<String, dynamic>);
    } on DioException catch (e) {
      _throwDioErr(e);
    }
  }

  // Opcional: simular ESP32 desde la app (debug)
  Future<SimpleOkResponse> esp32Register({
    required String deviceId,
    String? nombre,
    String? ubicacion,
  }) async {
    try {
      final r = await _dio.post(
        '/esp32/register',
        data: FormData.fromMap({
          'device_id': deviceId,
          if (nombre != null) 'nombre': nombre,
          if (ubicacion != null) 'ubicacion': ubicacion,
        }),
      );
      return SimpleOkResponse.fromJson(r.data as Map<String, dynamic>);
    } on DioException catch (e) {
      _throwDioErr(e);
    }
  }
}
