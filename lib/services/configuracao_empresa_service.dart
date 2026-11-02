import 'package:cloud_firestore/cloud_firestore.dart';

class ConfiguracaoEmpresaService {
  ConfiguracaoEmpresaService(this.empresaId);

  final String empresaId;

  DocumentReference<Map<String, dynamic>> get _referencia => FirebaseFirestore
      .instance
      .collection('empresas')
      .doc(empresaId)
      .collection('configuracoes')
      .doc('geral');

  Stream<Map<String, dynamic>> observar() {
    return _referencia.snapshots().map((snapshot) => snapshot.data() ?? {});
  }

  Future<Map<String, dynamic>> carregar() async {
    return (await _referencia.get()).data() ?? {};
  }

  Future<void> salvar(Map<String, dynamic> dados) {
    return _referencia.set({
      ...dados,
      'atualizadoEm': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }
}
