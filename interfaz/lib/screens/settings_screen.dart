import 'package:flutter/material.dart';
import '../core/app_config.dart';

class SettingsScreen extends StatefulWidget {
  static const route = '/settings';
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late final TextEditingController _urlCtrl;
  late final TextEditingController _devCtrl;
  bool _checking = false;
  String _status = '';

  @override
  void initState() {
    super.initState();
    _urlCtrl = TextEditingController(text: AppConfig.baseUrl);
    _devCtrl = TextEditingController(text: AppConfig.deviceId);
  }

  @override
  void dispose() {
    _urlCtrl.dispose();
    _devCtrl.dispose();
    super.dispose();
  }

  Future<void> _guardar() async {
    setState(() {
      _checking = true;
      _status = '';
    });
    try {
      AppConfig.setBaseUrl(_urlCtrl.text);
      AppConfig.setDeviceId(_devCtrl.text);
      final h = await AppConfig.api.health();
      setState(() => _status = 'Servidor OK: ${h.status}');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Ajustes guardados')));
      }
    } catch (e) {
      setState(() => _status = 'Error: $e');
    } finally {
      if (mounted) setState(() => _checking = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Ajustes')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            controller: _urlCtrl,
            decoration: const InputDecoration(
              labelText: 'Base URL (ngrok/Colab)',
              hintText: 'https://tu-dominio.ngrok-free.app',
              border: OutlineInputBorder(),
            ),
            keyboardType: TextInputType.url,
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _devCtrl,
            decoration: const InputDecoration(
              labelText: 'Device ID',
              hintText: 'esp32_1',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          SwitchListTile(
            value: AppConfig.mantenerContexto,
            onChanged: (v) => setState(() => AppConfig.setMantenerContexto(v)),
            title: const Text('Mantener contexto en Conversar'),
            subtitle: const Text('Usa últimos 5 turnos'),
          ),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: _checking ? null : _guardar,
            icon: const Icon(Icons.save),
            label: _checking
                ? const Text('Guardando...')
                : const Text('Guardar y probar'),
          ),
          if (_status.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              _status,
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ],
      ),
    );
  }
}
