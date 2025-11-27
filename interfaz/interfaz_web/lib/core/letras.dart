import 'package:flutter/material.dart';
import 'package:interfaz/core/colores.dart';

class Estilo {
  static const TextStyle bodyText = TextStyle(
    color: Appcolors.texto,
    fontSize: 22,
  );
  static const TextStyle botones = TextStyle(
    fontWeight: FontWeight.w800,
    fontSize: 18,
    color: Appcolors.textobotones,
  );
  static ButtonStyle boton = ButtonStyle(
    backgroundColor: WidgetStateProperty.all(Appcolors.botones),
    minimumSize: WidgetStateProperty.all(const Size(200, 60)),
  );
}
