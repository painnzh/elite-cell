import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AcessoEmpresa {
  const AcessoEmpresa({required this.empresaId, required this.papel});

  final String empresaId;
  final String papel;

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

    final empresaDona = await _db
        .collection('empresas')
        .where('uidDono', isEqualTo: usuario.uid)
        // A regra do Firestore também exige que a empresa esteja ativa.
        // O filtro precisa fazer parte da consulta para ela ser autorizada.
        .where('status', isEqualTo: 'ativo')
        .limit(1)
        .get();
    if (empresaDona.docs.isNotEmpty) {
      return AcessoEmpresa(empresaId: empresaDona.docs.first.id, papel: 'dono');
    }

    final convite = await _db
        .collectionGroup('membros')
        .where('email', isEqualTo: _emailAtual())
        .limit(1)
        .get();
    if (convite.docs.isEmpty) return null;

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
      return null;
    }
    return AcessoEmpresa(
      empresaId: documento.reference.parent.parent!.id,
      papel: dados['papel']?.toString() ?? 'tecnico',
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
