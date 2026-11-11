import 'package:elite_cell/services/acesso_empresa_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('identifica permissões dos perfis administrativos', () {
    expect(
      AcessoEmpresa(empresaId: 'empresa', papel: 'dono').podeGerirEmpresa,
      isTrue,
    );
    expect(
      AcessoEmpresa(
        empresaId: 'empresa',
        papel: 'administrador',
      ).podeGerirEmpresa,
      isTrue,
    );
    expect(
      AcessoEmpresa(empresaId: 'empresa', papel: 'tecnico').podeGerirEmpresa,
      isFalse,
    );
  });

  test('preserva informações de plano no acesso do dono', () {
    const acesso = AcessoEmpresa(
      empresaId: 'empresa',
      papel: 'dono',
      plano: 'teste',
      statusAssinatura: 'teste',
    );

    expect(acesso.plano, 'teste');
    expect(acesso.statusAssinatura, 'teste');
  });
}
