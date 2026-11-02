import 'package:elite_cell/theme/tema_empresa_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('interpreta a preferência de tema da empresa', () {
    expect(temaDoValor('claro'), ThemeMode.light);
    expect(temaDoValor('escuro'), ThemeMode.dark);
    expect(valorDoTema(ThemeMode.dark), 'escuro');
  });
}
