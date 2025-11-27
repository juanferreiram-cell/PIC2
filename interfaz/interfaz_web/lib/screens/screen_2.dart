import 'package:flutter/material.dart';
import 'package:interfaz/core/colores.dart';
import 'package:interfaz/screens/camara/camara.dart';
import 'package:interfaz/screens/movimientos/predefinidos.dart';
import 'package:interfaz/services/robot_service.dart';
import 'package:interfaz/core/letras.dart';
import 'package:interfaz/screens/Turismo.dart';
import 'package:interfaz/screens/audio/audioscreen.dart';
import 'package:interfaz/screens/pantalla/pantalla.dart';
import 'package:interfaz/screens/screen_1.dart';

class Screen2 extends StatefulWidget {
  const Screen2({super.key});

  @override
  State<Screen2> createState() => _Screen2State();
}

class _Screen2State extends State<Screen2> {
  final robot = RobotService();
  bool _enviandoComando = false;

  Future<void> _enviarComando(int hex, String nombreComando) async {
    if (_enviandoComando) return;

    setState(() => _enviandoComando = true);

    bool success = await robot.sendCommand(hex);

    setState(() => _enviandoComando = false);

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success
              ? '✅ Comando "$nombreComando" enviado correctamente'
              : '❌ Error al enviar comando "$nombreComando"',
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
        title: const Text("Menu Principal"),
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
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
            child: Column(
              children: [
                Text(
                  "¿Qué quieres hacer con el Robot?",
                  style: Estilo.bodyText,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 30),
                _buildBoton("Turismo", 0x03, const Turismo()),
                _buildBoton("Movimientos", 0x04, const Predefinidos()),
                _buildBoton("Audio", 0x05, const Audioscreen()),
                _buildBoton("Poner Caritas", 0x06, const Pantalla()),
                _buildBoton("Camara", 0x07, const Camara()),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBoton(String label, int hex, Widget pantalla) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: ElevatedButton(
        onPressed: _enviandoComando
            ? null
            : () async {
                await _enviarComando(hex, label);
                if (mounted) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => pantalla),
                  );
                }
              },
        style: Estilo.boton,
        child: _enviandoComando
            ? const CircularProgressIndicator(strokeWidth: 2)
            : Text(label, style: Estilo.botones),
      ),
    );
  }
}
