import 'package:flutter/material.dart';
import 'package:interfaz/core/colores.dart';

class Imgpredefinidas extends StatefulWidget {
  const Imgpredefinidas({super.key});

  @override
  State<Imgpredefinidas> createState() => _ImgpredefinidasState();
}

class _ImgpredefinidasState extends State<Imgpredefinidas> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Appcolors.background,
      appBar: AppBar(
        title: const Text("Poner Imaganes"),
        backgroundColor: Appcolors.botones,
      ),
    );
  }
}
