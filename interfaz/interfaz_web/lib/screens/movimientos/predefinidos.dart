import 'package:flutter/material.dart';
import 'package:interfaz/core/colores.dart';
import 'package:interfaz/services/robot_service.dart';
import 'package:interfaz/core/letras.dart';
import 'package:interfaz/screens/screen_1.dart';

class Predefinidos extends StatefulWidget {
  const Predefinidos({super.key});

  @override
  State<Predefinidos> createState() => _PredefinidosState();
}

class _PredefinidosState extends State<Predefinidos> {
  final robot = RobotService();
  bool _enviandoComando = false;

  final List<Map<String, dynamic>> movimientos = [
    {"label": "Bíceps", "code": 0x14},
    {"label": "Dab", "code": 0x15},
    {"label": "Superman", "code": 0x16},
    {"label": "Sí y No", "code": 0x17},
    {"label": "Girar Base", "code": 0x18},
  ];

  Future<void> _enviarComando(int command, String label) async {
    if (_enviandoComando) return;

    setState(() => _enviandoComando = true);
    final success = await robot.sendCommand(command);
    setState(() => _enviandoComando = false);

    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            success
                ? '✅ Comando "$label" enviado correctamente'
                : '❌ Error al enviar comando "$label"',
          ),
          backgroundColor: success ? Colors.green : Colors.red,
          duration: const Duration(seconds: 2),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Appcolors.background,
      appBar: AppBar(
        title: const Text("Movimientos"),
        backgroundColor: Appcolors.botones,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _enviandoComando
            ? null
            : () async {
                await _enviarComando(0x02, "Apagar Robot");
                if (mounted) {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (_) => const Screen1()),
                  );
                }
              },
        backgroundColor: _enviandoComando ? Colors.grey : Appcolors.botones,
        tooltip: "Apagar Robot",
        child: _enviandoComando
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : const Icon(Icons.bedtime, color: Colors.black),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
            child: Column(
              children: [
                Text(
                  "¿Qué movimiento quiere hacer?",
                  style: Estilo.bodyText,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                for (final mov in movimientos)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: ElevatedButton(
                      onPressed: _enviandoComando
                          ? null
                          : () => _enviarComando(mov["code"], mov["label"]),
                      style: Estilo.boton,
                      child: _enviandoComando
                          ? const CircularProgressIndicator(strokeWidth: 2)
                          : Text(mov["label"], style: Estilo.botones),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
