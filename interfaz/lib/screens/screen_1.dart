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
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Appcolors.background,
      body: Center(
        child: Column(
          children: [
            const Spacer(),
            const Text(
              "Bienvenido al Interfaz de Usuario del Robot",
              style: TextStyle(color: Appcolors.texto, fontSize: 22),
              textAlign: TextAlign.center,
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: ElevatedButton(
                onPressed: () async {
                  await robot.sendCommand(0x01);
                  if (mounted) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const Screen2()),
                    );
                  }
                },
                style: ButtonStyle(
                  backgroundColor: WidgetStateProperty.all(Appcolors.botones),
                  minimumSize: WidgetStateProperty.all(const Size(200, 60)),
                ),
                child: const Text(
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
                  Text(
                    "Listo para comenzar",
                    style: TextStyle(color: Appcolors.texto),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 20),
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
