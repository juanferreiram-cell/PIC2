import 'package:flutter/material.dart';
import 'package:interfaz/core/colores.dart';

class Camara extends StatefulWidget {
  const Camara({super.key});

  @override
  State<Camara> createState() => _CamaraState();
}

class _CamaraState extends State<Camara> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Appcolors.background,
      appBar: AppBar(
        title: const Text("Camara"),
        backgroundColor: Appcolors.botones,
      ),
      body: const Center(
        child: Text(
          "Mirá a la cámara del robot",
          style: TextStyle(
            fontSize: 20,
            color: Colors.white,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
