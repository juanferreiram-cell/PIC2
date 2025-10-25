import 'package:flutter/material.dart';
import 'package:interfaz/core/colores.dart';
import 'package:interfaz/services/robot_service.dart';
import 'package:interfaz/core/letras.dart';
import 'package:interfaz/screens/movimientos/eligeusuario.dart';
import 'package:interfaz/screens/movimientos/predefinidos.dart';
import 'package:interfaz/screens/screen_1.dart';

class Menumov extends StatefulWidget {
  const Menumov({super.key});

  @override
  State<Menumov> createState() => _MenumovState();
}

class _MenumovState extends State<Menumov> {
  final robot = RobotService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Appcolors.background,
      appBar: AppBar(
        title: const Text("Menu Movimientos"),
        backgroundColor: Appcolors.botones,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          //ble.sendCommand(0x02);
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const Screen1()),
          );
        },
        backgroundColor: Appcolors.botones,
        tooltip: "Apagar Robot",

        child: const Icon(Icons.bedtime, color: Colors.black),
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
              child: Text(
                "¿Como quiere realizar los movimientos del Robot?",
                style: Estilo.bodyText,
                textAlign: TextAlign.center,
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(28),
              child: ElevatedButton(
                onPressed: () async {
                  await robot.sendCommand(0x06);
                  if (mounted) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const Predefinidos(),
                      ),
                    );
                  }
                },
                style: Estilo.boton,
                child: const Text("Predefinidos", style: Estilo.botones),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(28),
              child: ElevatedButton(
                onPressed: () async {
                  await robot.sendCommand(0x08);
                  if (mounted) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const Eligeusuario(),
                      ),
                    );
                  }
                },
                style: Estilo.boton,
                child: const Text("Elegir Movimiento", style: Estilo.botones),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
