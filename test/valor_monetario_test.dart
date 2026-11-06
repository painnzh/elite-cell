import 'package:flutter_test/flutter_test.dart';
import 'package:elite_cell/utils/valor_monetario.dart';

void main() {
  group('ValorMonetario.paraDouble', () {
    test('preserva ponto decimal de valores carregados do Firestore', () {
      expect(ValorMonetario.paraDouble('5000.0'), 5000);
      expect(ValorMonetario.paraDouble('70.50'), 70.5);
    });

    test('aceita formatação monetária brasileira', () {
      expect(ValorMonetario.paraDouble('R\$ 5.000,00'), 5000);
      expect(ValorMonetario.paraDouble('1.234,56'), 1234.56);
      expect(ValorMonetario.paraDouble('880,00'), 880);
    });

    test('mantém números recebidos diretamente', () {
      expect(ValorMonetario.paraDouble(5000), 5000);
      expect(ValorMonetario.paraDouble(70.5), 70.5);
    });

    test('formata valores para apresentação em reais', () {
      expect(ValorMonetario.formatar(1234.5), 'R\$ 1.234,50');
      expect(ValorMonetario.formatar(-12.3), '-R\$ 12,30');
    });

    test('distingue campo vazio de valor zero', () {
      expect(ValorMonetario.tentarParaDouble(''), isNull);
      expect(ValorMonetario.tentarParaDouble('0'), 0);
    });
  });
}
