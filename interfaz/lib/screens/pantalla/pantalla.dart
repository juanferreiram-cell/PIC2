import 'package:flutter/material.dart';
import 'package:interfaz/core/colores.dart';
import 'package:interfaz/services/robot_service.dart';
import 'package:interfaz/screens/screen_1.dart';

class Pantalla extends StatefulWidget {
  const Pantalla({super.key});

  @override
  State<Pantalla> createState() => _PantallaState();
}

class _PantallaState extends State<Pantalla> {
  final robot = RobotService();

  Future<void> _handleImageTap(int command) async {
    await robot.sendCommand(command);
  }

  Widget _buildImageButton({required String assetPath, required int command}) {
    return GestureDetector(
      onTap: () => _handleImageTap(command),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 6,
                offset: const Offset(2, 4),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.asset(
              assetPath,
              width: 130,
              height: 130,
              fit: BoxFit.contain,
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Appcolors.background,
      appBar: AppBar(
        title: const Text("Poner Imagenes"),
        backgroundColor: Appcolors.botones,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await robot.sendCommand(0x02);
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
            const Padding(
              padding: EdgeInsets.only(top: 30, right: 8, left: 8, bottom: 8),
              child: Text(
                "Elegí una imagen para mostrar",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
            Wrap(
              alignment: WrapAlignment.center,
              children: [
                _buildImageButton(
                  assetPath: 'assets/images/uruguay.jpg',
                  command: 0x10,
                ),
                _buildImageButton(
                  assetPath: 'assets/images/utec.jpg',
                  command: 0x11,
                ),
                _buildImageButton(
                  assetPath: 'assets/images/logoutec.jpg',
                  command: 0x12,
                ),
                _buildImageButton(
                  assetPath: 'assets/images/logoimec.png',
                  command: 0x13,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
