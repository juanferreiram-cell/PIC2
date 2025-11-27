import 'package:flutter/material.dart';
import 'package:interfaz/core/colores.dart';
import 'package:interfaz/core/letras.dart';
import 'package:interfaz/screens/screen_1.dart';
import 'package:interfaz/services/robot_service.dart';

class Piso2 extends StatefulWidget {
  const Piso2({super.key});

  @override
  State<Piso2> createState() => _Piso2State();
}

class _Piso2State extends State<Piso2> {
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

  Widget _buildButton({required String label, required int command}) {
    return ElevatedButton(
      onPressed: () => _send(command, label),
      style: Estilo.boton.copyWith(
        padding: WidgetStateProperty.all(
          const EdgeInsets.symmetric(vertical: 18.0, horizontal: 12.0),
        ),
      ),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.visible,
          textAlign: TextAlign.center,
          style: Estilo.botones.copyWith(fontSize: 18),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isWideScreen = MediaQuery.of(context).size.width > 600;

    return Scaffold(
      backgroundColor: Appcolors.background,
      appBar: AppBar(
        title: const Text('Piso 2'),
        backgroundColor: Appcolors.botones,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await robot.sendCommand(0x02);
          if (!mounted) return;
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const Screen1()),
          );
        },
        backgroundColor: Appcolors.botones,
        tooltip: 'Apagar/Volver',
        child: const Icon(Icons.bedtime, color: Colors.black),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Text(
                  '¿Qué quieres hacer en el Piso 2?',
                  style: Estilo.bodyText,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 18),
                GridView.count(
                  shrinkWrap: true,
                  crossAxisCount: isWideScreen ? 3 : 2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  physics: const NeverScrollableScrollPhysics(),
                  childAspectRatio: 1.4,
                  children: [
                    _buildButton(label: 'Lab Mecatronica', command: 0x25),
                    _buildButton(label: 'Lab Electronica', command: 0x26),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
