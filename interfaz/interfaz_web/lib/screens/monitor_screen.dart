import 'package:flutter/material.dart';
import '../core/app_config.dart';
import '../models/nao_models.dart';

class MonitorScreen extends StatefulWidget {
  static const route = '/monitor';
  const MonitorScreen({super.key});

  @override
  State<MonitorScreen> createState() => _MonitorScreenState();
}

class _MonitorScreenState extends State<MonitorScreen> {
  AdminDispositivosResponse? _data;
  bool _loading = false;
  String _log = '';

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _log = '';
    });
    try {
      final r = await AppConfig.api.listarDispositivos();
      setState(() => _data = r);
    } catch (e) {
      setState(() => _log = 'Error: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _limpiarCache() async {
    setState(() => _loading = true);
    try {
      final r = await AppConfig.api.limpiarCacheAudio();
      setState(
        () => _log = r.success
            ? 'Cache limpiada'
            : (r.mensaje ?? 'No se pudo limpiar'),
      );
      await _load();
    } catch (e) {
      setState(() => _log = 'Error: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  Widget build(BuildContext context) {
    final d = _data;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Monitor'),
        actions: [
          IconButton(
            onPressed: _loading ? null : _load,
            icon: const Icon(Icons.refresh),
          ),
          IconButton(
            onPressed: _loading ? null : _limpiarCache,
            icon: const Icon(Icons.delete_sweep),
          ),
        ],
      ),
      body: d == null
          ? Center(
              child: _loading
                  ? const CircularProgressIndicator()
                  : Text(_log.isEmpty ? 'Sin datos' : _log),
            )
          : Column(
              children: [
                ListTile(
                  title: const Text('Dispositivos'),
                  subtitle: Text(
                    'Total: ${d.total}   •   Audio cache: ${d.audioCacheSize}',
                  ),
                ),
                const Divider(height: 1),
                Expanded(
                  child: ListView.separated(
                    itemCount: d.dispositivos.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, i) {
                      final it = d.dispositivos[i];
                      return ListTile(
                        leading: const Icon(Icons.memory),
                        title: Text(it.deviceId),
                        subtitle: Text(
                          'Comandos pendientes: ${it.comandosPendientes}',
                        ),
                      );
                    },
                  ),
                ),
                if (_log.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text(
                      _log,
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ),
              ],
            ),
    );
  }
}
