import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AcessoEmpresaException implements Exception {
  const AcessoEmpresaException(this.mensagem);

  final String mensagem;

  @override
  String toString() => mensagem;
}

class AcessoEmpresa {
  const AcessoEmpresa({
    required this.empresaId,
    required this.papel,
    this.plano,
    this.statusAssinatura,
  });

  final String empresaId;
  final String papel;
  final String? plano;
  final String? statusAssinatura;

  bool get podeGerirEmpresa => papel == 'dono' || papel == 'administrador';
  bool get podeVerFinanceiro =>
      papel == 'dono' || papel == 'administrador' || papel == 'gerente';
}

class AcessoEmpresaService {
  static const papeis = ['administrador', 'gerente', 'tecnico', 'caixa'];

  final FirebaseFirestore _db;
  final FirebaseAuth _auth;

  AcessoEmpresaService({FirebaseFirestore? db, FirebaseAuth? auth})
    : _db = db ?? FirebaseFirestore.instance,
      _auth = auth ?? FirebaseAuth.instance;

  String _emailAtual() {
    final email = _auth.currentUser?.email?.trim().toLowerCase();
    if (email == null || email.isEmpty) {
      throw StateError('Não foi possível identificar o e-mail da conta.');
    }
    return email;
  }

  Future<AcessoEmpresa?> acessoAtual() async {
    final usuario = _auth.currentUser;
    if (usuario == null) return null;

    // Empresas criadas pelas versões atuais usam o UID como ID do documento.
    // A leitura direta funciona inclusive quando a assinatura está pendente,
    // permitindo explicar o bloqueio em vez de tratá-lo como falha genérica.
    final empresaDoUid = await _db
        .collection('empresas')
        .doc(usuario.uid)
        .get();
    if (empresaDoUid.exists && empresaDoUid.data()?['uidDono'] == usuario.uid) {
      return _acessoDono(empresaDoUid.id, empresaDoUid.data()!);
    }

    // Mantém compatibilidade com cadastros antigos, cujos documentos podem
    // não ter sido criados com o UID como ID.
    final empresaDona = await _db
        .collection('empresas')
        .where('uidDono', isEqualTo: usuario.uid)
        .limit(1)
        .get();
    if (empresaDona.docs.isNotEmpty) {
      final documento = empresaDona.docs.first;
      return _acessoDono(documento.id, documento.data());
    }

    final convite = await _db
        .collectionGroup('membros')
        .where('email', isEqualTo: _emailAtual())
        .limit(1)
        .get();
    if (convite.docs.isEmpty) {
      throw const AcessoEmpresaException(
        'Nenhuma empresa ativa ou convite foi encontrado para esta conta.',
      );
    }

    final documento = convite.docs.first;
    final dados = documento.data();
    if (dados['status'] == 'convidado') {
      await documento.reference.update({
        'status': 'ativo',
        'uid': usuario.uid,
        'ativadoEm': FieldValue.serverTimestamp(),
      });
    }
    if (dados['status'] != 'ativo' && dados['status'] != 'convidado') {
      throw const AcessoEmpresaException(
        'Seu acesso de colaborador está inativo. Fale com o responsável da empresa.',
      );
    }
    return AcessoEmpresa(
      empresaId: documento.reference.parent.parent!.id,
      papel: dados['papel']?.toString() ?? 'tecnico',
    );
  }

  AcessoEmpresa _acessoDono(String empresaId, Map<String, dynamic> dados) {
    final status = dados['status']?.toString().toLowerCase();
    final statusAssinatura = dados['statusAssinatura']?.toString();

    if (status != 'ativo') {
      final mensagem = statusAssinatura == 'pendente'
          ? 'A assinatura da empresa está pendente de ativação.'
          : 'A empresa está inativa. Entre em contato com o suporte.';
      throw AcessoEmpresaException(mensagem);
    }

    return AcessoEmpresa(
      empresaId: empresaId,
      papel: 'dono',
      plano: dados['plano']?.toString(),
      statusAssinatura: statusAssinatura,
    );
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> membros(String empresaId) => _db
      .collection('empresas')
      .doc(empresaId)
      .collection('membros')
      .orderBy('email')
      .snapshots();

  Future<void> convidar({
    required String empresaId,
    required String email,
    required String papel,
  }) {
    final emailNormalizado = email.trim().toLowerCase();
    if (emailNormalizado.isEmpty || !emailNormalizado.contains('@')) {
      throw ArgumentError('Informe um e-mail válido.');
    }
    if (!papeis.contains(papel)) throw ArgumentError('Perfil inválido.');
    return _db
        .collection('empresas')
        .doc(empresaId)
        .collection('membros')
        .doc(emailNormalizado)
        .set({
          'email': emailNormalizado,
          'papel': papel,
          'status': 'convidado',
          'uid': null,
          'criadoEm': FieldValue.serverTimestamp(),
        });
  }
}
