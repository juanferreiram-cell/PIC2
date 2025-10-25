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
          children: [
            Padding(
              padding: const EdgeInsets.only(
                top: 30,
                right: 8,
                left: 8,
                bottom: 8,
              ),
              child: Text(
                "¿Que movimientos quiere hacer?",
                style: Estilo.bodyText,
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(28),
              child: ElevatedButton(
                onPressed: () async {
                  await robot.sendCommand(0x14);
                },
                style: Estilo.boton,
                child: const Text("Todos 45 grados", style: Estilo.botones),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(28),
              child: ElevatedButton(
                onPressed: () async {
                  await robot.sendCommand(0x15);
                },
                style: Estilo.boton,
                child: const Text("Todos 90 grados", style: Estilo.botones),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(28),
              child: ElevatedButton(
                onPressed: () async {
                  await robot.sendCommand(0x16);
                },
                style: Estilo.boton,
                child: const Text("Solo XL430", style: Estilo.botones),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(28),
              child: ElevatedButton(
                onPressed: () async {
                  await robot.sendCommand(0x17);
                },
                style: Estilo.boton,
                child: const Text("Solo XL320", style: Estilo.botones),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(28),
              child: ElevatedButton(
                onPressed: () async {
                  await robot.sendCommand(0x18);
                },
                style: Estilo.boton,
                child: const Text("Todos 180", style: Estilo.botones),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
