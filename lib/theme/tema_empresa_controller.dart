import 'package:flutter/material.dart';

/// Mantém o tema atual acessível sem depender de uma biblioteca externa.
final temaEmpresaController = ValueNotifier<ThemeMode>(ThemeMode.dark);

ThemeMode temaDoValor(dynamic valor) {
  return valor?.toString() == 'claro' ? ThemeMode.light : ThemeMode.dark;
}

String valorDoTema(ThemeMode tema) {
  return tema == ThemeMode.light ? 'claro' : 'escuro';
}
