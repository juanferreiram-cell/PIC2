import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:interfaz/screens/screen_1.dart';
import 'dart:convert';
import 'dart:async';
import 'package:interfaz/services/robot_service.dart';
import 'package:interfaz/core/colores.dart';

// ========== CONFIGURACIÓN ==========
class MusicConfig {
  // Cambia esto por la URL de tu servidor (ngrok o IP local)
  static const String BASE_URL = "http://choreal-kalel-directed.ngrok-free.dev";
  static const String DEVICE_ID = "esp32_1";
}

// ========== MODELO DE DATOS ==========
class Track {
  final String trackId;
  final String titulo;
  final String artista;
  final int duracion;

  Track({
    required this.trackId,
    required this.titulo,
    required this.artista,
    required this.duracion,
  });

  factory Track.fromJson(Map<String, dynamic> json) {
    return Track(
      trackId: json['track_id'] ?? '',
      titulo: json['titulo'] ?? 'Sin título',
      artista: json['artista'] ?? 'Desconocido',
      duracion: json['duracion'] ?? 0,
    );
  }
}

class PlaybackState {
  final String status;
  final String titulo;
  final String artista;
  final String trackId;
  final int volume;
  final bool preview;

  PlaybackState({
    this.status = 'stopped',
    this.titulo = '',
    this.artista = '',
    this.trackId = '',
    this.volume = 80,
    this.preview = false,
  });

  factory PlaybackState.fromJson(Map<String, dynamic> json) {
    return PlaybackState(
      status: json['status'] ?? 'stopped',
      titulo: json['titulo'] ?? '',
      artista: json['artista'] ?? '',
      trackId: json['track_id'] ?? '',
      volume: json['volume'] ?? 80,
      preview: json['preview'] ?? false,
    );
  }
}

// ========== SERVICIO API ==========
class MusicService {
  static final http.Client _client = http.Client();

  // Buscar canciones
  static Future<List<Track>> searchTracks(
    String query, {
    String? artist,
  }) async {
    try {
      final uri = Uri.parse('${MusicConfig.BASE_URL}/control/musica_buscar');

      final body = {
        'q': artist != null && artist.isNotEmpty ? '$query $artist' : query,
        'limit': '10',
      };

      final response = await _client
          .post(
            uri,
            headers: {'Content-Type': 'application/x-www-form-urlencoded'},
            body: body,
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List items = data['items'] ?? [];
        return items.map((item) => Track.fromJson(item)).toList();
      } else {
        print('Error búsqueda: ${response.statusCode} - ${response.body}');
        return [];
      }
    } catch (e) {
      print('Error en búsqueda: $e');
      return [];
    }
  }

  // Reproducir canción
  static Future<bool> playTrack(Track track) async {
    try {
      final uri = Uri.parse(
        '${MusicConfig.BASE_URL}/control/musica_reproducir',
      );

      final body = {
        'device_id': MusicConfig.DEVICE_ID,
        'track_id': track.trackId,
        'titulo': track.titulo,
        'artista': track.artista,
      };

      final response = await _client
          .post(
            uri,
            headers: {'Content-Type': 'application/x-www-form-urlencoded'},
            body: body,
          )
          .timeout(const Duration(seconds: 15));

      return response.statusCode == 200;
    } catch (e) {
      print('Error al reproducir: $e');
      return false;
    }
  }

  // Control de reproducción
  static Future<bool> pauseMusic() async {
    return _sendControlCommand('musica_pausa');
  }

  static Future<bool> resumeMusic() async {
    return _sendControlCommand('musica_continuar');
  }

  static Future<bool> stopMusic() async {
    return _sendControlCommand('musica_detener');
  }

  static Future<bool> setVolume(int volume) async {
    try {
      final uri = Uri.parse('${MusicConfig.BASE_URL}/control/musica_volumen');

      final body = {
        'device_id': MusicConfig.DEVICE_ID,
        'volume': volume.toString(),
      };

      final response = await _client
          .post(
            uri,
            headers: {'Content-Type': 'application/x-www-form-urlencoded'},
            body: body,
          )
          .timeout(const Duration(seconds: 10));

      return response.statusCode == 200;
    } catch (e) {
      print('Error al ajustar volumen: $e');
      return false;
    }
  }

  // Obtener estado actual
  static Future<PlaybackState> getPlaybackState() async {
    try {
      final uri = Uri.parse(
        '${MusicConfig.BASE_URL}/control/musica_estado/${MusicConfig.DEVICE_ID}',
      );

      final response = await _client
          .get(uri)
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return PlaybackState.fromJson(data);
      }
      return PlaybackState();
    } catch (e) {
      print('Error obteniendo estado: $e');
      return PlaybackState();
    }
  }

  // Helper para comandos simples
  static Future<bool> _sendControlCommand(String endpoint) async {
    try {
      final uri = Uri.parse('${MusicConfig.BASE_URL}/control/$endpoint');

      final body = {'device_id': MusicConfig.DEVICE_ID};

      final response = await _client
          .post(
            uri,
            headers: {'Content-Type': 'application/x-www-form-urlencoded'},
            body: body,
          )
          .timeout(const Duration(seconds: 10));

      return response.statusCode == 200;
    } catch (e) {
      print('Error en comando $endpoint: $e');
      return false;
    }
  }
}

// ========== PANTALLA DE MÚSICA ==========
class MusicScreen extends StatefulWidget {
  const MusicScreen({super.key});

  @override
  _MusicScreenState createState() => _MusicScreenState();
}

class _MusicScreenState extends State<MusicScreen> {
  final TextEditingController _songController = TextEditingController();
  final TextEditingController _artistController = TextEditingController();

  List<Track> _searchResults = [];
  PlaybackState _playbackState = PlaybackState();
  bool _isSearching = false;
  bool _hasSearched = false;
  double _volume = 80.0;
  Timer? _statusTimer;

  @override
  void initState() {
    super.initState();
    _loadPlaybackState();
    // Actualizar estado cada 2 segundos
    _statusTimer = Timer.periodic(const Duration(seconds: 2), (_) {
      _loadPlaybackState();
    });
  }

  @override
  void dispose() {
    _statusTimer?.cancel();
    _songController.dispose();
    _artistController.dispose();
    super.dispose();
  }

  Future<void> _loadPlaybackState() async {
    final state = await MusicService.getPlaybackState();
    if (mounted) {
      setState(() {
        _playbackState = state;
        _volume = state.volume.toDouble();
      });
    }
  }

  Future<void> _searchMusic() async {
    final query = _songController.text.trim();
    if (query.isEmpty) return;

    setState(() {
      _isSearching = true;
      _hasSearched = true;
    });

    final results = await MusicService.searchTracks(
      query,
      artist: _artistController.text.trim(),
    );

    setState(() {
      _searchResults = results;
      _isSearching = false;
    });
  }

  Future<void> _playTrack(Track track) async {
    final success = await MusicService.playTrack(track);
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Reproduciendo: ${track.titulo}'),
          backgroundColor: Colors.green,
        ),
      );
      _loadPlaybackState();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error al reproducir'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  String _getStatusText() {
    switch (_playbackState.status) {
      case 'playing':
        return 'Reproduciendo';
      case 'paused':
        return 'Pausado';
      case 'stopped':
        return 'Detenido';
      default:
        return 'Estado: ${_playbackState.status}';
    }
  }

  @override
  Widget build(BuildContext context) {
    final robot = RobotService();
    return Scaffold(
      backgroundColor: Color.fromARGB(195, 22, 5, 77),
      appBar: AppBar(
        backgroundColor: const Color(0xFF7DD3FC),
        title: const Text('Música', style: TextStyle(color: Colors.black)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await robot.sendCommand(0x02);
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const Screen1()),
          );
        },
        backgroundColor: Appcolors.botones,
        tooltip: "Apagar Robot",

        child: const Icon(Icons.bedtime, color: Colors.black),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Sección de búsqueda
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color.fromARGB(255, 47, 22, 130),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Nombre de la canción',
                    style: TextStyle(color: Colors.white, fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _songController,
                          style: const TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            hintText: 'Ingresa el nombre',
                            hintStyle: TextStyle(color: Colors.white),
                            fillColor: const Color(0xFF1A0B2E),
                            filled: true,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 14,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton(
                        onPressed: _isSearching ? null : _searchMusic,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF7DD3FC),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 32,
                            vertical: 16,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(25),
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.search, color: Colors.black),
                            const SizedBox(width: 8),
                            Text(
                              _isSearching ? 'Buscando...' : 'Buscar',
                              style: const TextStyle(
                                color: Colors.black,
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Artista (opcional)',
                    style: TextStyle(color: Colors.white, fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _artistController,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'Para afinar resultados',
                      hintStyle: TextStyle(color: Colors.white),
                      fillColor: const Color(0xFF1A0B2E),
                      filled: true,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Resultados de búsqueda
                  Container(
                    constraints: BoxConstraints(
                      minHeight: 100,
                      maxHeight: MediaQuery.of(context).size.height * 0.25,
                    ),
                    child: _isSearching
                        ? const Center(
                            child: CircularProgressIndicator(
                              color: Color(0xFF7DD3FC),
                            ),
                          )
                        : _searchResults.isEmpty
                        ? Center(
                            child: Text(
                              _hasSearched ? 'Sin resultados' : '',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                              ),
                            ),
                          )
                        : ListView.builder(
                            itemCount: _searchResults.length,
                            itemBuilder: (context, index) {
                              final track = _searchResults[index];
                              return ListTile(
                                title: Text(
                                  track.titulo,
                                  style: const TextStyle(color: Colors.white),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                subtitle: Text(
                                  track.artista,
                                  style: TextStyle(color: Colors.white54),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                trailing: IconButton(
                                  icon: const Icon(
                                    Icons.play_circle_fill,
                                    color: Color(0xFF7DD3FC),
                                    size: 32,
                                  ),
                                  onPressed: () => _playTrack(track),
                                ),
                                onTap: () => _playTrack(track),
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // Sección de reproducción actual
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color.fromARGB(255, 47, 22, 130),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Ahora suena:',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _playbackState.titulo.isEmpty
                        ? '—'
                        : '${_playbackState.titulo} - ${_playbackState.artista}',
                    style: const TextStyle(color: Colors.white, fontSize: 16),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 20),
                  // Estado
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      _getStatusText(),
                      style: const TextStyle(
                        color: Colors.black,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Botones de control
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      ElevatedButton.icon(
                        onPressed: _playbackState.status == 'playing'
                            ? () async {
                                await MusicService.pauseMusic();
                                _loadPlaybackState();
                              }
                            : null,
                        icon: const Icon(Icons.pause),
                        label: const Text('Pausa'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF7DD3FC),
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 12,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(25),
                          ),
                        ),
                      ),
                      ElevatedButton.icon(
                        onPressed: _playbackState.status == 'paused'
                            ? () async {
                                await MusicService.resumeMusic();
                                _loadPlaybackState();
                              }
                            : null,
                        icon: const Icon(Icons.play_arrow),
                        label: const Text('Continuar'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF7DD3FC),
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 12,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(25),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Center(
                    child: ElevatedButton.icon(
                      onPressed: _playbackState.status != 'stopped'
                          ? () async {
                              await MusicService.stopMusic();
                              _loadPlaybackState();
                            }
                          : null,
                      icon: const Icon(Icons.stop),
                      label: const Text('Detener'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red[400],
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 32,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(25),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Control de volumen
                  Row(
                    children: [
                      const Icon(Icons.volume_down, color: Colors.white70),
                      Expanded(
                        child: Slider(
                          value: _volume,
                          min: 0,
                          max: 100,
                          activeColor: const Color(0xFF7DD3FC),
                          inactiveColor: Colors.white,
                          onChanged: (value) {
                            setState(() {
                              _volume = value;
                            });
                          },
                          onChangeEnd: (value) async {
                            await MusicService.setVolume(value.round());
                            _loadPlaybackState();
                          },
                        ),
                      ),
                      const Icon(Icons.volume_up, color: Colors.white),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20), // Espacio extra al final para scroll
          ],
        ),
      ),
    );
  }
}
