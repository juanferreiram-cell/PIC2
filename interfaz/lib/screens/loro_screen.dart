// lib/screens/loro_screen.dart
import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:permission_handler/permission_handler.dart';
import '../core/app_config.dart';
import 'package:interfaz/core/colores.dart';
import 'package:speech_to_text/speech_recognition_result.dart' as stt;

class LoroScreen extends StatefulWidget {
  static const route = '/loro';
  const LoroScreen({super.key});

  @override
  State<LoroScreen> createState() => _LoroScreenState();
}

class _LoroScreenState extends State<LoroScreen> {
  final stt.SpeechToText _stt = stt.SpeechToText();
  bool _sttReady = false;
  bool _listening = false;
  bool _sending = false;

  final _efectos = const [
    'normal',
    'rapido',
    'lento',
    'agudo',
    'grave',
    'robot',
  ];
  String _efecto = 'normal';

  String _partial = '';
  String _lastText = '';
  String _status = 'Toca el micrófono y di una frase';

  @override
  void initState() {
    super.initState();
    _initStt();
  }

  @override
  void dispose() {
    _stt.stop();
    super.dispose();
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
    await _startListening();
  }

  Future<void> _startListening() async {
    setState(() {
      _partial = '';
      _status = 'Escuchando...';
      _listening = true;
    });

    // Forzar español si hay uno disponible
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
      listenMode: stt.ListenMode.dictation, // Frases completas
      cancelOnError: true,
      pauseFor: const Duration(seconds: 3), // más tolerancia a silencios
      listenFor: const Duration(seconds: 30), // tiempo máximo de dictado
      localeId: localeId,
    );
  }

  Future<void> _onResult(stt.SpeechRecognitionResult r) async {
    // speech_to_text va acumulando recognizedWords; mostramos el parcial
    setState(() => _partial = r.recognizedWords);
    if (r.finalResult && r.recognizedWords.trim().isNotEmpty) {
      await _stt.stop();
      setState(() {
        _listening = false;
        _lastText = r.recognizedWords.trim(); // frase completa
      });
      await _send(_lastText);
    }
  }

  Future<void> _send(String text) async {
    if (_sending) return;
    setState(() {
      _sending = true;
      _status = 'Enviando al servidor...';
    });
    try {
      final r = await AppConfig.api.repetir(
        deviceId: AppConfig.deviceId,
        texto: text,
        efecto: _efecto,
      );
      setState(
        () => _status = r.success
            ? 'Audio encolado (audio_id: ${r.audioId})'
            : 'Falló el envío',
      );
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(_status)));
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
        title: const Text('Modo Loro'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                const Text(
                  'Efecto:',
                  style: TextStyle(
                    color: Colors.white,
                  ), // <-- Texto "Efecto:" en blanco
                ),
                const SizedBox(width: 12),
                DropdownButton<String>(
                  value: _efecto,
                  dropdownColor:
                      Appcolors.botones, // <-- Fondo azul del menú desplegable
                  iconEnabledColor:
                      Colors.white, // <-- Ícono del dropdown en blanco
                  style: const TextStyle(
                    color: Colors.white, // <-- Texto seleccionado en blanco
                  ),
                  items: _efectos
                      .map(
                        (e) => DropdownMenuItem(
                          value: e,
                          child: Text(
                            e,
                            style: const TextStyle(
                              color: Colors
                                  .white, // <-- Texto dentro del menú en blanco
                            ),
                          ),
                        ),
                      )
                      .toList(),
                  onChanged: (v) => setState(() => _efecto = v ?? 'normal'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              _status,
              style: const TextStyle(fontSize: 12, color: Colors.white),
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
                    style: TextStyle(color: Colors.white),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _partial,
                    style: const TextStyle(
                      color: Colors.white, // 👈 Texto reconocido en blanco
                      fontSize: 16,
                    ),
                  ),
                ],
              ),

            const Divider(height: 32),
            if (_lastText.isNotEmpty)
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Último texto: $_lastText',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            const Spacer(),
          ],
        ),
      ),
    );
  }
}
