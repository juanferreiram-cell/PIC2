import 'package:flutter/material.dart';
import 'package:interfaz/core/colores.dart';

class Edificiob extends StatefulWidget {
  const Edificiob({super.key});

  @override
  State<Edificiob> createState() => _EdificiobState();
}

class _EdificiobState extends State<Edificiob> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Appcolors.background,
      appBar: AppBar(
        title: const Text("Edificio B"),
        backgroundColor: Appcolors.botones,
      ),
    );
  }
}
