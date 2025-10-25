import 'package:flutter/material.dart';
import 'package:interfaz/core/colores.dart';
import 'package:interfaz/screens/camara/camara.dart';
import 'package:interfaz/services/robot_service.dart';
import 'package:interfaz/core/letras.dart';
import 'package:interfaz/screens/Turismo.dart';
import 'package:interfaz/screens/audio/audioscreen.dart';
import 'package:interfaz/screens/movimientos/menumov.dart';
import 'package:interfaz/screens/pantalla/pantalla.dart';
import 'package:interfaz/screens/screen_1.dart';

class Screen2 extends StatefulWidget {
  const Screen2({super.key});

  @override
  State<Screen2> createState() => _Screen2State();
}

class _Screen2State extends State<Screen2> {
  final robot = RobotService();
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Appcolors.background,
      appBar: AppBar(
        title: const Text("Menu Principal"),
        backgroundColor: Appcolors.botones,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await robot.sendCommand(0x02);
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
          // mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Padding(
              padding: const EdgeInsets.only(
                top: 30,
                right: 8,
                left: 8,
                bottom: 8,
              ),
              child: Text(
                "¿Que quieres hacer con el Robot?",
                style: Estilo.bodyText,
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(28),
              child: ElevatedButton(
                onPressed: () async {
                  await robot.sendCommand(0x03);
                  if (mounted) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const Turismo()),
                    );
                  }
                },
                style: Estilo.boton,
                child: const Text("Turismo", style: Estilo.botones),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(28),
              child: ElevatedButton(
                onPressed: () async {
                  await robot.sendCommand(0x04);

                  if (mounted) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const Menumov()),
                    );
                  }
                },
                style: Estilo.boton,
                child: const Text("Movimientos", style: Estilo.botones),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(28),
              child: ElevatedButton(
                onPressed: () async {
                  await robot.sendCommand(0x05);
                  if (mounted) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const Audioscreen(),
                      ),
                    );
                  }
                },
                style: Estilo.boton,
                child: const Text("Audio", style: Estilo.botones),
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
                      MaterialPageRoute(builder: (context) => const Pantalla()),
                    );
                  }
                },
                style: Estilo.boton,
                child: const Text("Poner Imagenes", style: Estilo.botones),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(28),
              child: ElevatedButton(
                onPressed: () async {
                  await robot.sendCommand(0x07);
                  if (mounted) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const Camara()),
                    );
                  }
                },
                style: Estilo.boton,
                child: const Text("Camara", style: Estilo.botones),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
