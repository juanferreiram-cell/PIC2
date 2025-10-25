import 'package:flutter/material.dart';
import 'package:interfaz/core/colores.dart';

class Edificioc extends StatefulWidget {
  const Edificioc({super.key});

  @override
  State<Edificioc> createState() => _EdificiocState();
}

class _EdificiocState extends State<Edificioc> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Appcolors.background,
      appBar: AppBar(
        title: const Text("Edificio C"),
        backgroundColor: Appcolors.botones,
      ),
    );
  }
}
