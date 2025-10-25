import 'package:flutter/material.dart';
import 'package:interfaz/core/colores.dart';
import 'package:interfaz/core/letras.dart';
import 'package:interfaz/core/app_config.dart';
import 'package:interfaz/services/robot_service.dart';
import 'package:interfaz/screens/audio/MusicScreen.dart';
import 'package:interfaz/screens/audio/voces.dart';
import 'package:interfaz/screens/screen_1.dart';

class Audioscreen extends StatefulWidget {
  const Audioscreen({super.key});

  @override
  State<Audioscreen> createState() => _AudioscreenState();
}

class _AudioscreenState extends State<Audioscreen> {
  final robot = RobotService();
  bool _enviandoComando = false;

  // ✅ Función helper para enviar comandos con feedback visual
  Future<void> _enviarComando(int hex, String nombreComando) async {
    if (_enviandoComando) return;

    setState(() => _enviandoComando = true);

    print('🎯 Enviando comando: $nombreComando (0x${hex.toRadixString(16).toUpperCase()})');
    print('📡 URL: ${robot.baseUrl}');
    print('📱 Device: ${robot.deviceId}');

    bool success = await robot.sendCommand(hex);

    setState(() => _enviandoComando = false);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success 
              ? '✅ Comando "$nombreComando" enviado correctamente' 
              : '❌ Error al enviar comando "$nombreComando"',
          ),
          backgroundColor: success ? Colors.green : Colors.red,
          duration: const Duration(seconds: 2),
        ),
      );
    }

    print(success ? '✅ Comando enviado' : '❌ Error al enviar comando');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Appcolors.background,
      appBar: AppBar(
        title: const Text("Menu Audio"),
        backgroundColor: Appcolors.botones,
        actions: [
          // ✅ Botón de debug para verificar configuración
          IconButton(
            icon: const Icon(Icons.info_outline),
            tooltip: "Info de configuración",
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('🔧 Configuración'),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('URL: ${AppConfig.baseUrl}'),
                      const SizedBox(height: 8),
                      Text('Device ID: ${AppConfig.deviceId}'),
                      const SizedBox(height: 8),
                      Text('RobotService URL: ${robot.baseUrl}'),
                      const SizedBox(height: 8),
                      Text('RobotService Device: ${robot.deviceId}'),
                    ],
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cerrar'),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _enviandoComando
            ? null
            : () async {
                await _enviarComando(0x02, "Apagar");

                if (mounted) {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (_) => const Screen1()),
                  );
                }
              },
        backgroundColor: _enviandoComando 
            ? Colors.grey 
            : Appcolors.botones,
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
              child: Text(
                "¿Que Audio quiere ponerle al Robot?",
                style: Estilo.bodyText,
                textAlign: TextAlign.center,
              ),
            ),
            
            // ✅ Botón de Música
            Padding(
              padding: const EdgeInsets.all(28),
              child: ElevatedButton(
                onPressed: _enviandoComando
                    ? null
                    : () async {
                        // ✅ Activar modo música (0x03)
                        await _enviarComando(0x0B, "Modo Música");

                        if (mounted) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const MusicScreen(),
                            ),
                          );
                        }
                      },
                style: Estilo.boton,
                child: _enviandoComando
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text("Musica", style: Estilo.botones),
              ),
            ),
            
            // ✅ Botón de Voces
            Padding(
              padding: const EdgeInsets.all(28),
              child: ElevatedButton(
                onPressed: _enviandoComando
                    ? null
                    : () async {
                        // ✅ Activar modo voz (0x01)
                        await _enviarComando(0x0C, "Modo Voz");

                        if (mounted) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const Voces(),
                            ),
                          );
                        }
                      },
                style: Estilo.boton,
                child: _enviandoComando
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text("Voces", style: Estilo.botones),
              ),
            ),

            const SizedBox(height: 40),

            // ✅ Botón de TEST (para verificar que funciona)
            Padding(
              padding: const EdgeInsets.all(28),
              child: OutlinedButton.icon(
                onPressed: _enviandoComando
                    ? null
                    : () async {
                        print('\n🧪 ===== TEST DE ROBOT SERVICE =====');
                        print('📡 URL configurada: ${robot.baseUrl}');
                        print('📱 Device ID: ${robot.deviceId}');
                        print('=====================================\n');

                        // Enviar comando de test (0x10 = decir hola)
                        await _enviarComando(0x10, "TEST - Decir Hola");
                      },
                icon: const Icon(Icons.science),
                label: const Text("🧪 TEST Conexión"),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 40,
                    vertical: 15,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}