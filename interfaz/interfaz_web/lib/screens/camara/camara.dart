import 'package:flutter/material.dart';
import 'package:interfaz/core/colores.dart';
import 'package:interfaz/screens/screen_1.dart';
import 'package:interfaz/services/robot_service.dart';

class Camara extends StatefulWidget {
  const Camara({super.key});

  @override
  State<Camara> createState() => _CamaraState();
}

class _CamaraState extends State<Camara> {
  final robot = RobotService();
  bool _enviando = false;

  Future<void> _apagarCamara() async {
    if (_enviando) return;

    setState(() => _enviando = true);
    await robot.sendCommand(0x08); // Comando de apagar cámara
    if (!mounted) return;
    setState(() => _enviando = false);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('✅ Cámara apagada correctamente'),
        backgroundColor: Colors.green,
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Appcolors.background,
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await robot.sendCommand(0x02); // Apagar/Volver
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
      appBar: AppBar(
        title: const Text("Cámara"),
        backgroundColor: Appcolors.botones,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Text(
                "Mirá a la cámara del robot ubicada en la cabeza",
                style: TextStyle(fontSize: 20, color: Colors.white),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 40),
            ElevatedButton(
              onPressed: _enviando ? null : _apagarCamara,
              style: ElevatedButton.styleFrom(
                shape: const CircleBorder(),
                padding: const EdgeInsets.all(40),
                backgroundColor: Appcolors.botones,
              ),
              child: _enviando
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.videocam_off, size: 40, color: Colors.black),
            ),
            const SizedBox(height: 12),
            const Text(
              'Apagar',
              style: TextStyle(
                fontSize: 18,
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
