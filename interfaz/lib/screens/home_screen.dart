import 'package:flutter/material.dart';
import 'device_screen.dart';
import 'frases_screen.dart';
import 'conversar_screen.dart';
import 'loro_screen.dart';
import 'monitor_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends StatelessWidget {
  static const route = '/home';
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final entries = <_Entry>[
      _Entry('Dispositivo', Icons.memory, DeviceScreen.route),
      _Entry('Frases', Icons.library_music, FrasesScreen.route),
      _Entry('Conversar', Icons.forum, ConversarScreen.route),
      _Entry('Loro', Icons.speaker, LoroScreen.route),
      _Entry('Monitor', Icons.monitor_heart, MonitorScreen.route),
      _Entry('Ajustes', Icons.settings, SettingsScreen.route),
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('UTECO · Control de Voz')),
      body: ListView.separated(
        padding: const EdgeInsets.all(12),
        itemCount: entries.length,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (context, i) {
          final e = entries[i];
          return ListTile(
            leading: Icon(e.icon),
            title: Text(e.title),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.pushNamed(context, e.route),
          );
        },
      ),
    );
  }
}

class _Entry {
  final String title;
  final IconData icon;
  final String route;
  _Entry(this.title, this.icon, this.route);
}
