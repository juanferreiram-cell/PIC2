import 'package:flutter/material.dart';
import 'package:interfaz/core/colores.dart';
import 'package:interfaz/screens/screen_1.dart';

class Eligeusuario extends StatefulWidget {
  const Eligeusuario({super.key});

  @override
  State<Eligeusuario> createState() => _EligeusuarioState();
}

class _EligeusuarioState extends State<Eligeusuario> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Appcolors.background,
      appBar: AppBar(
        title: const Text("Eliga sus movimientos"),
        backgroundColor: Appcolors.botones,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // ble.sendCommand(0x02);
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const Screen1()),
          );
        },
        backgroundColor: Appcolors.botones,
        tooltip: "Apagar Robot",

        child: const Icon(Icons.bedtime, color: Colors.black),
      ),
    );
  }
}
