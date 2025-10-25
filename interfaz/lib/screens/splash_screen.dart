import 'package:flutter/material.dart';
import '../core/app_config.dart';
import 'home_screen.dart';
import 'settings_screen.dart';

class SplashScreen extends StatefulWidget {
  static const route = '/splash';
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  String _status = 'Inicializando...';

  @override
  void initState() {
    super.initState();
    _boot();
  }

  Future<void> _boot() async {
    if (!AppConfig.baseUrl.startsWith('http')) {
      setState(() => _status = 'Configura la URL en Ajustes');
      await Future.delayed(const Duration(milliseconds: 900));
      if (!mounted) return;
      Navigator.pushReplacementNamed(context, SettingsScreen.route);
      return;
    }

    setState(() => _status = 'Verificando servidor...');
    try {
      final health = await AppConfig.api.health();
      setState(() => _status = 'Servidor: ${health.status}');
      await Future.delayed(const Duration(milliseconds: 600));
      if (!mounted) return;
      Navigator.pushReplacementNamed(context, HomeScreen.route);
    } catch (e) {
      setState(() => _status = 'Error: $e');
      await Future.delayed(const Duration(milliseconds: 1200));
      if (!mounted) return;
      Navigator.pushReplacementNamed(context, SettingsScreen.route);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(_status),
            const SizedBox(height: 8),
            Text(
              'Base URL: ${AppConfig.baseUrl}',
              style: const TextStyle(fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}
