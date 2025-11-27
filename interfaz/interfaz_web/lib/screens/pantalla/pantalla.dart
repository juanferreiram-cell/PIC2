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
  bool _enviandoComando = false;

  final List<_FaceItem> _caras = const [
    _FaceItem('assets/images/caras/feliz.jpg', 0x2C, 'Feliz'),
    _FaceItem('assets/images/caras/triste.jpg', 0x2D, 'Triste'),
    _FaceItem('assets/images/caras/sorpresa.jpg', 0x2E, 'Sorpresa'),
    _FaceItem('assets/images/caras/guino.jpg', 0x2F, 'Guiño'),
    _FaceItem('assets/images/caras/enfermo.jpg', 0x30, 'Enfermo'),
    _FaceItem('assets/images/caras/preocupado.jpg', 0x31, 'Preocupado'),
    _FaceItem('assets/images/caras/neutra.jpg', 0x32, 'Neutra'),
    _FaceItem('assets/images/caras/enamorado.jpg', 0x33, 'Enamorado'),
    _FaceItem('assets/images/caras/dormido.jpg', 0x34, 'Dormido'),
  ];

  Future<void> _enviarComando(int command, String label) async {
    if (_enviandoComando) return;

    setState(() => _enviandoComando = true);
    final success = await robot.sendCommand(command);
    if (!mounted) return;
    setState(() => _enviandoComando = false);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success
              ? '✅ Cara "$label" enviada correctamente'
              : '❌ Error al enviar "$label"',
        ),
        backgroundColor: success ? Colors.green : Colors.red,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Widget _buildImageButton({
    required String assetPath,
    required int command,
    required String label,
  }) {
    return GestureDetector(
      onTap: _enviandoComando ? null : () => _enviarComando(command, label),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                Container(
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
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                if (_enviandoComando)
                  Container(
                    width: 130,
                    height: 130,
                    decoration: BoxDecoration(
                      color: Colors.black45,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Center(
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: const TextStyle(color: Colors.white, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Appcolors.background,
      appBar: AppBar(
        title: const Text("Caras NAO"),
        backgroundColor: Appcolors.botones,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _enviandoComando
            ? null
            : () async {
                await _enviarComando(0x02, "Apagar Robot");
                if (mounted) {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (_) => const Screen1()),
                  );
                }
              },
        backgroundColor: _enviandoComando ? Colors.grey : Appcolors.botones,
        tooltip: "Apagar Robot",
        child: _enviandoComando
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : const Icon(Icons.bedtime, color: Colors.black),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Center(
          child: Column(
            children: [
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                child: Text(
                  "Elegí una cara para mostrar",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              Wrap(
                alignment: WrapAlignment.center,
                children: _caras
                    .map((f) => _buildImageButton(
                          assetPath: f.asset,
                          command: f.command,
                          label: f.label,
                        ))
                    .toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FaceItem {
  final String asset;
  final int command;
  final String label;
  const _FaceItem(this.asset, this.command, this.label);
}
