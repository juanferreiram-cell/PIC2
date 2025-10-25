import 'package:flutter/material.dart';
import '../core/app_config.dart';

class DeviceScreen extends StatefulWidget {
  static const route = '/device';
  const DeviceScreen({super.key});

  @override
  State<DeviceScreen> createState() => _DeviceScreenState();
}

class _DeviceScreenState extends State<DeviceScreen> {
  late final TextEditingController _deviceCtrl;
  bool _loading = false;
  String _log = '';

  @override
  void initState() {
    super.initState();
    _deviceCtrl = TextEditingController(text: AppConfig.deviceId);
  }

  @override
  void dispose() {
    _deviceCtrl.dispose();
    super.dispose();
  }

  Future<void> _guardarYRegistrar() async {
    setState(() {
      _loading = true;
      _log = '';
    });
    try {
      AppConfig.setDeviceId(_deviceCtrl.text);
      final r = await AppConfig.api.esp32Register(deviceId: AppConfig.deviceId);
      setState(() => _log = 'ESP32: ${r.success ? "registrado" : "falló"}');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('DeviceID guardado: ${AppConfig.deviceId}')),
        );
      }
    } catch (e) {
      setState(() => _log = 'Error: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Dispositivo')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _deviceCtrl,
              decoration: const InputDecoration(
                labelText: 'Device ID (ESP32)',
                hintText: 'ej: esp32_1',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _loading ? null : _guardarYRegistrar,
                    icon: const Icon(Icons.save),
                    label: _loading
                        ? const Text('Guardando...')
                        : const Text('Guardar y Registrar'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                _log,
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
