import 'package:flutter/material.dart';
import 'package:interfaz/core/colores.dart';
import 'package:speech_to_text/speech_recognition_result.dart' as stt;
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:permission_handler/permission_handler.dart';
import '../core/app_config.dart';

class ConversarScreen extends StatefulWidget {
  static const route = '/conversar';
  const ConversarScreen({super.key});

  @override
  State<ConversarScreen> createState() => _ConversarScreenState();
}

class _ConversarScreenState extends State<ConversarScreen> {
  final stt.SpeechToText _stt = stt.SpeechToText();
  bool _sttReady = false;
  bool _listening = false;
  bool _sending = false;
  String _partial = '';
  String _lastUser = '';
  String _lastBot = '';
  String _status = 'Toca el micrófono para hablar';

  @override
  void initState() {
    super.initState();
    _initStt();
  }

  Future<void> _initStt() async {
    final mic = await Permission.microphone.request();
    if (!mic.isGranted) {
      setState(() => _status = 'Permiso de micrófono denegado');
      return;
    }
    final ok = await _stt.initialize(
      onStatus: (s) => setState(() => _status = s),
      onError: (e) => setState(() => _status = 'Error STT: ${e.errorMsg}'),
    );
    setState(() => _sttReady = ok);
  }

  Future<void> _toggle() async {
    if (!_sttReady) {
      await _initStt();
      if (!_sttReady) return;
    }
    if (_listening) {
      await _stt.stop();
      setState(() => _listening = false);
      return;
    }
    setState(() {
      _partial = '';
      _status = 'Escuchando...';
      _listening = true;
    });
    // Elegí un locale de español si está disponible, si no, usa default.
    String? localeId;
    final locales = await _stt.locales();
    final esLocale = locales.firstWhere(
      (l) => l.localeId.toLowerCase().startsWith('es'),
      orElse: () => locales.isNotEmpty
          ? locales.first
          : stt.LocaleName('default', 'default'),
    );
    localeId = esLocale.localeId == 'default' ? null : esLocale.localeId;

    await _stt.listen(
      onResult: _onResult,
      partialResults: true,
      listenMode: stt.ListenMode.dictation,
      cancelOnError: true,
      pauseFor: const Duration(seconds: 2),
      localeId: localeId,
    );
  }

  Future<void> _onResult(stt.SpeechRecognitionResult r) async {
    setState(() => _partial = r.recognizedWords);
    if (r.finalResult && r.recognizedWords.trim().isNotEmpty) {
      await _stt.stop();
      setState(() {
        _listening = false;
        _lastUser = r.recognizedWords.trim();
      });
      await _sendToServer(_lastUser);
    }
  }

  Future<void> _sendToServer(String text) async {
    if (_sending) return;
    setState(() {
      _sending = true;
      _status = 'Enviando al servidor...';
    });
    try {
      final resp = await AppConfig.api.conversar(
        deviceId: AppConfig.deviceId,
        texto: text,
        mantenerContexto: AppConfig.mantenerContexto,
      );
      setState(() {
        _lastBot = resp.respuestaRobot ?? '(sin respuesta)';
        _status = 'Respuesta enviada al ESP32';
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Comando encolado para el ESP32')),
      );
    } catch (e) {
      setState(() => _status = 'Error: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final micColor = _listening ? Colors.red : Appcolors.botones;
    return Scaffold(
      backgroundColor: Appcolors.background,
      appBar: AppBar(
        backgroundColor: Appcolors.botones,
        title: const Text('Conversar'),
        actions: [
          Row(
            children: [
              const Text('Contexto', style: TextStyle(fontSize: 12)),
              Switch(
                value: AppConfig.mantenerContexto,
                onChanged: (v) =>
                    setState(() => AppConfig.setMantenerContexto(v)),
              ),
            ],
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const SizedBox(height: 8),
            Text(
              _status,
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 24),
            Center(
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: micColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 22,
                    vertical: 14,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(28),
                  ),
                ),
                onPressed: _sending ? null : _toggle,
                icon: Icon(_listening ? Icons.mic : Icons.mic_none, size: 28),
                label: Text(
                  _listening
                      ? 'Escuchando... toca para detener'
                      : 'Tocar para hablar',
                ),
              ),
            ),
            const SizedBox(height: 18),
            if (_partial.isNotEmpty)
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Reconocimiento:', 
                    style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  const SizedBox(height: 6),
                  Text(_partial, style: const TextStyle(color: Colors.white)),
                ],
              ),
            const Divider(height: 32),
            if (_lastUser.isNotEmpty || _lastBot.isNotEmpty)
              Expanded(
                child: ListView(
                  children: [
                    if (_lastUser.isNotEmpty)
                      _bubble(
                        'Tú',
                        _lastUser,
                        alignEnd: true,
                        color: Appcolors.botones,
                      ),
                    if (_lastBot.isNotEmpty)
                      _bubble(
                        'Robot',
                        _lastBot,
                        alignEnd: false,
                        color: Colors.white,
                      ),
                  ],
                ),
              )
            else
              const Spacer(),
          ],
        ),
      ),
    );
  }

  Widget _bubble(
    String who,
    String text, {
    required bool alignEnd,
    required Color color,
  }) {
    return Align(
      alignment: alignEnd ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              who,
              style: const TextStyle(fontSize: 11, color: Colors.black54),
            ),
            const SizedBox(height: 4),
            Text(text),
          ],
        ),
      ),
    );
  }
}
