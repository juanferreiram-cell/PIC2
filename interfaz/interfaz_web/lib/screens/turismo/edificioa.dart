import 'package:flutter/material.dart';
import 'package:interfaz/core/colores.dart';
import 'package:interfaz/core/letras.dart';
import 'package:interfaz/screens/screen_1.dart';
import 'package:interfaz/screens/turismo/piso1.dart';
import 'package:interfaz/screens/turismo/piso2.dart';

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
        title: const Text("Menu Edificio A"),
        backgroundColor: Appcolors.botones,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const Screen1()),
          );
        },
        backgroundColor: Appcolors.botones,
        tooltip: "Volver al inicio",
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
              child: Text("¿Elige el Piso?", style: Estilo.bodyText),
            ),
            Padding(
              padding: const EdgeInsets.all(28),
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const Piso1()),
                  );
                },
                style: Estilo.boton,
                child: const Text("Piso 1", style: Estilo.botones),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(28),
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const Piso2()),
                  );
                },
                style: Estilo.boton,
                child: const Text("Piso 2", style: Estilo.botones),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
