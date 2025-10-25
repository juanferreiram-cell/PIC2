import 'package:flutter/material.dart';
import 'package:interfaz/core/colores.dart';
//import 'package:interfaz/core/globals.dart';
import 'package:interfaz/core/letras.dart';
import 'package:interfaz/screens/screen_1.dart';
import 'package:interfaz/screens/turismo/edificioa.dart';
import 'package:interfaz/screens/turismo/edificiob.dart';
import 'package:interfaz/screens/turismo/edificioc.dart';

class Turismo extends StatefulWidget {
  const Turismo({super.key});

  @override
  State<Turismo> createState() => _TurismoState();
}

class _TurismoState extends State<Turismo> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Appcolors.background,
      appBar: AppBar(
        title: const Text("Menu Turismo"),
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
              child: Text("¿Elige el Edificio?", style: Estilo.bodyText),
            ),
            Padding(
              padding: const EdgeInsets.all(28),
              child: ElevatedButton(
                onPressed: () {
                  // ble.sendCommand(0x03);
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const Edificioa()),
                  );
                },
                style: Estilo.boton,
                child: const Text("Edificio A", style: Estilo.botones),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(28),
              child: ElevatedButton(
                onPressed: () {
                  // ble.sendCommand(0x04);
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const Edificiob()),
                  );
                },
                style: Estilo.boton,
                child: const Text("Edificio B", style: Estilo.botones),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(28),
              child: ElevatedButton(
                onPressed: () {
                  // ble.sendCommand(0x04);
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const Edificioc()),
                  );
                },
                style: Estilo.boton,
                child: const Text("Edificio C", style: Estilo.botones),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
