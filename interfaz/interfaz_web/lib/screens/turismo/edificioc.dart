import 'package:flutter/material.dart';
import 'package:interfaz/core/colores.dart';
import 'package:interfaz/core/letras.dart';
import 'package:interfaz/services/robot_service.dart';
import 'package:interfaz/screens/screen_1.dart';

class Edificioc extends StatefulWidget {
  const Edificioc({super.key});

  @override
  State<Edificioc> createState() => _EdificiocState();
}

class _EdificiocState extends State<Edificioc> {
  final robot = RobotService();
  bool _enviandoComando = false;

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
          behavior: SnackBarBehavior.floating,
          backgroundColor: success ? Colors.green : Colors.red,
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Appcolors.background,
      appBar: AppBar(
        title: const Text("Edificio C"),
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
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.only(
                top: 130,
                right: 8,
                left: 8,
                bottom: 8,
              ),
              child: Text("¿Elige el destino?", style: Estilo.bodyText),
            ),
            Padding(
              padding: const EdgeInsets.all(28),
              child: ElevatedButton(
                onPressed: _enviandoComando
                    ? null
                    : () => _enviarComando(0x1D, 'Lab A'),
                style: Estilo.boton,
                child: _enviandoComando
                    ? const CircularProgressIndicator(strokeWidth: 2)
                    : const Text('Lab A', style: Estilo.botones),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(28),
              child: ElevatedButton(
                onPressed: _enviandoComando
                    ? null
                    : () => _enviarComando(0x1E, 'Humanidades Digitales'),
                style: Estilo.boton,
                child: _enviandoComando
                    ? const CircularProgressIndicator(strokeWidth: 2)
                    : const Text(
                        'Humanidades Digitales',
                        style: Estilo.botones,
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
