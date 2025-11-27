import 'package:flutter/material.dart';
import 'package:interfaz/core/colores.dart';
import 'package:interfaz/core/letras.dart';
import 'package:interfaz/services/robot_service.dart';

class Carreras extends StatefulWidget {
  const Carreras({super.key});

  @override
  State<Carreras> createState() => _CarrerasState();
}

class _CarrerasState extends State<Carreras> {
  final robot = RobotService();
  bool _enviandoComando = false;

  Future<void> _enviarComando(int command, String label) async {
    if (_enviandoComando) return;

    setState(() => _enviandoComando = true);

    bool success = await robot.sendCommand(command);

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
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Appcolors.background,
      appBar: AppBar(
        title: const Text("Edificio B"),
        backgroundColor: Appcolors.botones,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _enviandoComando
            ? null
            : () async {
                await _enviarComando(0x02, "Apagar Robot");
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
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.only(
                top: 80,
                right: 8,
                left: 8,
                bottom: 8,
              ),
              child: Text("¿Elige la Carrera?", style: Estilo.bodyText),
            ),
            Padding(
              padding: const EdgeInsets.all(28),
              child: ElevatedButton(
                onPressed: _enviandoComando
                    ? null
                    : () => _enviarComando(0x19, 'LTI'),
                style: Estilo.boton,
                child: _enviandoComando
                    ? const CircularProgressIndicator(strokeWidth: 2)
                    : const Text('LTI', style: Estilo.botones),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(28),
              child: ElevatedButton(
                onPressed: _enviandoComando
                    ? null
                    : () => _enviarComando(0x1A, 'IMEC'),
                style: Estilo.boton,
                child: _enviandoComando
                    ? const CircularProgressIndicator(strokeWidth: 2)
                    : const Text('IMEC', style: Estilo.botones),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(28),
              child: ElevatedButton(
                onPressed: _enviandoComando
                    ? null
                    : () => _enviarComando(0x1B, 'IBIO'),
                style: Estilo.boton,
                child: _enviandoComando
                    ? const CircularProgressIndicator(strokeWidth: 2)
                    : const Text('IBIO', style: Estilo.botones),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(28),
              child: ElevatedButton(
                onPressed: _enviandoComando
                    ? null
                    : () => _enviarComando(0x1C, 'ILOG'),
                style: Estilo.boton,
                child: _enviandoComando
                    ? const CircularProgressIndicator(strokeWidth: 2)
                    : const Text('ILOG', style: Estilo.botones),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
