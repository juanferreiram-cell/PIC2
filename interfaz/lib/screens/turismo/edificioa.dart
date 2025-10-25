import 'package:flutter/material.dart';
import 'package:interfaz/core/colores.dart';

class Edificioa extends StatefulWidget {
  const Edificioa({super.key});

  @override
  State<Edificioa> createState() => _EdificioaState();
}

class _EdificioaState extends State<Edificioa> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Appcolors.background,
      appBar: AppBar(
        title: const Text("Edificio A"),
        backgroundColor: Appcolors.botones,
      ),
    );
  }
}
