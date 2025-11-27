import 'package:flutter/material.dart';
import 'package:interfaz/core/colores.dart';
import 'screen_2.dart';
import 'package:interfaz/services/robot_service.dart';

class Screen1 extends StatefulWidget {
  const Screen1({super.key});

  @override
  State<Screen1> createState() => _Screen1State();
}

class _Screen1State extends State<Screen1> {
  final robot = RobotService();
  bool _enviandoComando = false;

  Future<void> _enviarComando(int hex, String nombreComando) async {
    if (_enviandoComando) return;

    setState(() => _enviandoComando = true);

    bool success = await robot.sendCommand(hex);

    setState(() => _enviandoComando = false);

    if (mounted) {
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

    print(success ? '✅ Comando enviado' : '❌ Error al enviar comando');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Appcolors.background,
      body: Center(
        child: Column(
          children: [
            const Spacer(),
            const Text(
              "Bienvenido a la interfaz de Turi",
              style: TextStyle(color: Appcolors.texto, fontSize: 22),
              textAlign: TextAlign.center,
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: ElevatedButton(
                onPressed: _enviandoComando
                    ? null
                    : () async {
                        await _enviarComando(0x01, "Encender");

                        if (mounted) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const Screen2(),
                            ),
                          );
                        }
                      },
                style: ButtonStyle(
                  backgroundColor: WidgetStateProperty.all(Appcolors.botones),
                  minimumSize: WidgetStateProperty.all(const Size(200, 60)),
                ),
                child: _enviandoComando
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text(
                        "Encender Robot",
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 18,
                          color: Colors.black,
                        ),
                      ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(4),
              child: Column(
                children: const [
                  Text(
                    "Desarrollado por Lucas Elizalde, Juan Manuel Ferreira y Felipe Morrudo",
                    style: TextStyle(color: Appcolors.texto, fontSize: 22),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 10),
                ],
              ),
            ),
            const Spacer(),
          ],
        ),
      ),
    );
  }
}
