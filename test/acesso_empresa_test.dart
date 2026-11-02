import 'package:elite_cell/services/acesso_empresa_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('identifica permissões dos perfis administrativos', () {
    expect(
      AcessoEmpresa(empresaId: 'empresa', papel: 'dono').podeGerirEmpresa,
      isTrue,
    );
    expect(
      AcessoEmpresa(empresaId: 'empresa', papel: 'administrador')
          .podeGerirEmpresa,
      isTrue,
    );
    expect(
      AcessoEmpresa(empresaId: 'empresa', papel: 'tecnico').podeGerirEmpresa,
      isFalse,
    );
  });
}
