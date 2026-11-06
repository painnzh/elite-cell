/// Conversão de valores monetários digitados tanto no padrão brasileiro
/// (`1.234,56`) quanto no decimal (`1234.56`).
///
/// Nunca remove o ponto quando ele é o separador decimal. Isso é importante
/// para campos preenchidos novamente a partir de números salvos no Firestore.
class ValorMonetario {
  const ValorMonetario._();

  static double paraDouble(Object? valor) {
    return tentarParaDouble(valor) ?? 0;
  }

  static double? tentarParaDouble(Object? valor) {
    if (valor is num) return valor.toDouble();

    var texto = valor?.toString().trim() ?? '';
    if (texto.isEmpty) return null;

    texto = texto
        .replaceAll('R\$', '')
        .replaceAll(RegExp(r'\s'), '')
        .replaceAll(RegExp(r'[^0-9,.-]'), '');

    final ultimaVirgula = texto.lastIndexOf(',');
    final ultimoPonto = texto.lastIndexOf('.');

    if (ultimaVirgula != -1 && ultimoPonto != -1) {
      // O último separador é decimal; o outro representa milhar.
      if (ultimaVirgula > ultimoPonto) {
        texto = texto.replaceAll('.', '').replaceAll(',', '.');
      } else {
        texto = texto.replaceAll(',', '');
      }
    } else if (ultimaVirgula != -1) {
      texto = texto.replaceAll(',', '.');
    }

    return double.tryParse(texto);
  }

  static String formatar(Object? valor) {
    final centavos = (paraDouble(valor) * 100).round();
    final negativo = centavos < 0;
    final absoluto = centavos.abs();
    final inteiro = (absoluto ~/ 100).toString();
    final decimal = (absoluto % 100).toString().padLeft(2, '0');
    final grupos = <String>[];

    for (var fim = inteiro.length; fim > 0; fim -= 3) {
      final inicio = fim - 3 < 0 ? 0 : fim - 3;
      grupos.add(inteiro.substring(inicio, fim));
    }

    return '${negativo ? '-' : ''}R\$ ${grupos.reversed.join('.')},$decimal';
  }
}
