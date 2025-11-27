import 'package:flutter/material.dart';
import 'package:interfaz/core/colores.dart';
import 'package:interfaz/core/letras.dart';
import 'package:interfaz/services/robot_service.dart';

class Piso3 extends StatefulWidget {
  const Piso3({super.key});

  @override
  State<Piso3> createState() => _Piso3State();
}

class _Piso3State extends State<Piso3> {
  final robot = RobotService();

  Future<void> _send(int command, String label) async {
    await robot.sendCommand(command);
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            'Comando enviado: $label (0x${command.toRadixString(16).padLeft(2, '0').toUpperCase()})',
          ),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Appcolors.botones,
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Appcolors.background,
      appBar: AppBar(
        title: const Text('Piso 3'),
        backgroundColor: Appcolors.botones,
      ),
      body: Center(
        child: SizedBox(
          width: 260, // ancho cómodo para un solo botón
          height: 90, // alto más grande para mejor toque
          child: ElevatedButton(
            onPressed: () => _send(0x28, 'Piso 3 - Acción'),
            style: Estilo.boton.copyWith(
              minimumSize: WidgetStateProperty.all(
                const Size(double.infinity, 90),
              ),
              padding: WidgetStateProperty.all(
                const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
              ),
            ),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                'Hablar Piso 3',
                maxLines: 1,
                style: Estilo.botones.copyWith(fontSize: 20),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
