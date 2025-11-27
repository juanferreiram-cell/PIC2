import 'package:flutter/material.dart';
import 'package:interfaz/core/colores.dart';
import 'package:interfaz/core/letras.dart';
import 'package:interfaz/screens/screen_1.dart';
import 'package:interfaz/services/robot_service.dart';

class Piso1 extends StatefulWidget {
  const Piso1({super.key});

  @override
  State<Piso1> createState() => _Piso1State();
}

class _Piso1State extends State<Piso1> {
  final robot = RobotService();
  bool _enviandoComando = false;

  Future<void> _enviarComando(int command, String label) async {
    if (_enviandoComando) return;

    setState(() => _enviandoComando = true);
    final success = await robot.sendCommand(command);
    setState(() => _enviandoComando = false);

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success
              ? '✅ Comando "$label" enviado correctamente'
              : '❌ Error al enviar "$label"',
        ),
        backgroundColor: success ? Colors.green : Colors.red,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Widget _buildButton({required String label, required int command}) {
    return ElevatedButton(
      onPressed: _enviandoComando ? null : () => _enviarComando(command, label),
      style: Estilo.boton.copyWith(
        padding: WidgetStateProperty.all(
          const EdgeInsets.symmetric(vertical: 12.0, horizontal: 8.0),
        ),
      ),
      child: _enviandoComando
          ? const CircularProgressIndicator(strokeWidth: 2)
          : FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                label,
                maxLines: 1,
                textAlign: TextAlign.center,
                style: Estilo.botones.copyWith(fontSize: 18),
              ),
            ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Appcolors.background,
      appBar: AppBar(
        title: const Text('Piso 1'),
        backgroundColor: Appcolors.botones,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _enviandoComando
            ? null
            : () async {
                await _enviarComando(0x02, "Apagar/Volver");
                if (mounted) {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (_) => const Screen1()),
                  );
                }
              },
        backgroundColor: _enviandoComando ? Colors.grey : Appcolors.botones,
        tooltip: 'Apagar/Volver',
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
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Text(
                  '¿Qué quieres hacer en el Piso 1?',
                  style: Estilo.bodyText,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 18),
                GridView.count(
                  shrinkWrap: true,
                  crossAxisCount: MediaQuery.of(context).size.width > 600
                      ? 3
                      : 2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  physics: const NeverScrollableScrollPhysics(),
                  childAspectRatio: 1.4,
                  children: [
                    _buildButton(label: 'Lab Física', command: 0x1F),
                    _buildButton(label: 'Lab Química', command: 0x20),
                    _buildButton(label: 'Lab Biomédica', command: 0x21),
                    _buildButton(label: 'Movimiento Humano', command: 0x22),
                    _buildButton(label: 'Tablet Gigante', command: 0x24),
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
