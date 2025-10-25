import 'package:flutter/material.dart';
import 'package:interfaz/core/colores.dart';
import 'package:interfaz/core/letras.dart';
import 'package:interfaz/screens/conversar_screen.dart';
import 'package:interfaz/screens/frases_screen.dart';
import 'package:interfaz/screens/loro_screen.dart';
import 'package:interfaz/screens/screen_1.dart';
import 'package:interfaz/services/robot_service.dart';

class Voces extends StatefulWidget {
  const Voces({super.key});

  @override
  State<Voces> createState() => _VocesState();
}

class _VocesState extends State<Voces> {
  final robot = RobotService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Appcolors.background,
      appBar: AppBar(
        title: const Text("Voces del Robot"),
        backgroundColor: Appcolors.botones,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          // await robot.sendCommand(0x02);
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
                top: 30,
                right: 8,
                left: 8,
                bottom: 8,
              ),
              child: Text(
                "Selecciona una opción de voz:",
                style: Estilo.bodyText,
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(50),
              child: ElevatedButton(
                onPressed: () async {
                  // await robot.sendCommand(0x10);
                  if (mounted) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const FrasesScreen()),
                    );
                  }
                },
                style: Estilo.boton,
                child: const Text("Frases", style: Estilo.botones),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(50),
              child: ElevatedButton(
                onPressed: () async {
                  // await robot.sendCommand(0x11);
                  if (mounted) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const ConversarScreen(),
                      ),
                    );
                  }
                },
                style: Estilo.boton,
                child: const Text("Conversar", style: Estilo.botones),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(50),
              child: ElevatedButton(
                onPressed: () async {
                  await robot.sendCommand(0x12);
                  if (mounted) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const LoroScreen()),
                    );
                  }
                },
                style: Estilo.boton,
                child: const Text("Modo Loro", style: Estilo.botones),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
