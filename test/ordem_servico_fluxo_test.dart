import 'package:elite_cell/services/ordem_servico_fluxo_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('converte valores de OS e expõe as etapas operacionais', () {
    expect(OrdemServicoFluxoService.valorNumerico('R\$ 125,50'), 125.5);
    expect(OrdemServicoFluxoService.quantidadeNumerica('3'), 3);
    expect(OrdemServicoFluxoService.etapas, contains('Aguardando aprovação'));
    expect(OrdemServicoFluxoService.etapas, contains('Entregue'));
  });
}
