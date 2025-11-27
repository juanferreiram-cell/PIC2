import 'package:flutter/material.dart';
import 'package:interfaz/screens/screen_1.dart';
import 'package:interfaz/core/app_config.dart';
import 'dart:io'; // 1. IMPORTAR ESTO

// 2. AÑADIR ESTA CLASE
class MyHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..badCertificateCallback =
          (X509Certificate cert, String host, int port) => true;
  }
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  HttpOverrides.global = MyHttpOverrides(); // 3. AÑADIR ESTA LÍNEA

  // ✅ Configurar AppConfig (como antes)
  AppConfig.setBaseUrl('https://choreal-kalel-directed.ngrok-free.dev');
  AppConfig.setDeviceId('esp32_1');
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TURI',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(colorSchemeSeed: Colors.indigo, useMaterial3: true),
      home: const Screen1(),
    );
  }
}
