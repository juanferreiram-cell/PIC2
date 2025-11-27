class HealthResponse {
  final String status;
  final String? mensaje;

  HealthResponse({required this.status, this.mensaje});

  factory HealthResponse.fromJson(Map<String, dynamic> j) => HealthResponse(
    status: j['status']?.toString() ?? 'unknown',
    mensaje: j['mensaje']?.toString(),
  );
}

// ---- Frases ----
class Frase {
  final String id;
  final String texto;
  final String categoria;

  Frase({required this.id, required this.texto, required this.categoria});

  factory Frase.fromJson(Map<String, dynamic> j) => Frase(
    id: j['id']?.toString() ?? '',
    texto: j['texto']?.toString() ?? '',
    categoria: j['categoria']?.toString() ?? 'otros',
  );
}

class CmdFraseResponse {
  final bool success;
  final String? mensaje;
  final String? audioId;

  CmdFraseResponse({required this.success, this.mensaje, this.audioId});

  factory CmdFraseResponse.fromJson(Map<String, dynamic> j) => CmdFraseResponse(
    success: j['success'] == true,
    mensaje: j['mensaje']?.toString(),
    audioId: j['audio_id']?.toString(),
  );
}

// ---- Conversar ----
class ConversarResponse {
  final bool success;
  final String? respuestaRobot;
  final String? audioId;

  ConversarResponse({required this.success, this.respuestaRobot, this.audioId});

  factory ConversarResponse.fromJson(Map<String, dynamic> j) =>
      ConversarResponse(
        success: j['success'] == true,
        respuestaRobot: j['respuesta_robot']?.toString(),
        audioId: j['audio_id']?.toString(),
      );
}

// ---- Loro ----
class LoroResponse {
  final bool success;
  final String? audioId;
  final String? mensaje;

  LoroResponse({required this.success, this.audioId, this.mensaje});

  factory LoroResponse.fromJson(Map<String, dynamic> j) => LoroResponse(
    success: j['success'] == true,
    audioId: j['audio_id']?.toString(),
    mensaje: j['mensaje']?.toString(),
  );
}

// ---- Admin ----
class AdminDispositivosResponse {
  final int total;
  final List<AdminDevice> dispositivos;
  final int audioCacheSize;

  AdminDispositivosResponse({
    required this.total,
    required this.dispositivos,
    required this.audioCacheSize,
  });

  factory AdminDispositivosResponse.fromJson(Map<String, dynamic> j) =>
      AdminDispositivosResponse(
        total: (j['total'] as num?)?.toInt() ?? 0,
        dispositivos: (j['dispositivos'] as List<dynamic>? ?? [])
            .map((e) => AdminDevice.fromJson(e as Map<String, dynamic>))
            .toList(),
        audioCacheSize: (j['audio_cache_size'] as num?)?.toInt() ?? 0,
      );
}

class AdminDevice {
  final String deviceId;
  final int comandosPendientes;

  AdminDevice({required this.deviceId, required this.comandosPendientes});

  factory AdminDevice.fromJson(Map<String, dynamic> j) => AdminDevice(
    deviceId: j['device_id']?.toString() ?? '',
    comandosPendientes: (j['comandos_pendientes'] as num?)?.toInt() ?? 0,
  );
}

class SimpleOkResponse {
  final bool success;
  final String? mensaje;

  SimpleOkResponse({required this.success, this.mensaje});

  factory SimpleOkResponse.fromJson(Map<String, dynamic> j) => SimpleOkResponse(
    success: j['success'] == true,
    mensaje: j['mensaje']?.toString(),
  );
}
