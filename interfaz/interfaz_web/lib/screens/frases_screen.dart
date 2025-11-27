import 'package:flutter/material.dart';
import '../core/app_config.dart';
import '../models/nao_models.dart';
import 'package:interfaz/core/colores.dart';

class FrasesScreen extends StatefulWidget {
  static const route = '/frases';
  const FrasesScreen({super.key});

  @override
  State<FrasesScreen> createState() => _FrasesScreenState();
}

class _FrasesScreenState extends State<FrasesScreen> {
  late Future<List<Frase>> _future;

  @override
  void initState() {
    super.initState();
    _future = AppConfig.api.listarFrases();
  }

  Future<void> _reproducir(String nombreFrase) async {
    try {
      final r = await AppConfig.api.reproducirFrase(
        deviceId: AppConfig.deviceId,
        nombreFrase: nombreFrase,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            r.success ? 'Enviado (audio_id: ${r.audioId})' : 'Fallo al enviar',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  Future<void> _refresh() async {
    setState(() => _future = AppConfig.api.listarFrases());
    await _future;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Appcolors.background,
      appBar: AppBar(
        backgroundColor: Appcolors.botones,
        title: const Text('Frases'),
        actions: [
          IconButton(onPressed: _refresh, icon: const Icon(Icons.refresh)),
        ],
      ),
      body: FutureBuilder<List<Frase>>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const Center(
              child: CircularProgressIndicator(color: Colors.white),
            );
          }
          if (snap.hasError) {
            return Center(
              child: Text(
                'Error: ${snap.error}',
                style: const TextStyle(color: Colors.white),
              ),
            );
          }
          final frases = snap.data ?? [];
          if (frases.isEmpty) {
            return const Center(
              child: Text(
                'No hay frases disponibles.',
                style: TextStyle(color: Colors.white),
              ),
            );
          }
          return ListView.separated(
            itemCount: frases.length,
            separatorBuilder: (_, __) =>
                const Divider(height: 1, color: Colors.white24),
            itemBuilder: (context, i) {
              final f = frases[i];
              return ListTile(
                title: Text(
                  f.texto,
                  style: const TextStyle(color: Colors.white, fontSize: 16),
                ),
                subtitle: Text(
                  '${f.id}  •  ${f.categoria}',
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.play_arrow, color: Colors.white),
                  onPressed: () => _reproducir(f.id),
                  tooltip: 'Enviar a ESP32',
                ),
              );
            },
          );
        },
      ),
    );
  }
}
