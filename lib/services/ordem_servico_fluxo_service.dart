import 'package:cloud_firestore/cloud_firestore.dart';

import '../utils/valor_monetario.dart';

class OrdemServicoFluxoService {
  OrdemServicoFluxoService({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  static const etapas = <String>[
    'Em análise',
    'Aguardando aprovação',
    'Aprovado',
    'Aguardando peça',
    'Em reparo',
    'Pronto',
    'Entregue',
    'Cancelado',
  ];

  static double valorNumerico(dynamic valor) {
    return ValorMonetario.paraDouble(valor);
  }

  static int quantidadeNumerica(dynamic valor) =>
      int.tryParse(valor.toString()) ?? 0;

  Future<void> salvar({
    required DocumentReference<Map<String, dynamic>> osRef,
    required String empresaId,
    required Map<String, dynamic> dadosAtuais,
    required Map<String, dynamic> campos,
  }) async {
    final statusAnterior = (dadosAtuais['status'] ?? 'Em análise').toString();
    final novoStatus = (campos['status'] ?? statusAnterior).toString();
    if (statusAnterior == 'Entregue' && novoStatus != 'Entregue') {
      throw StateError(
        'Uma OS entregue não pode voltar para uma etapa anterior.',
      );
    }

    final peca = (dadosAtuais['peca_usada'] ?? '').toString();
    final quantidade = quantidadeNumerica(dadosAtuais['quantidade_peca']);
    final deveBaixarEstoque =
        <String>{'Em reparo', 'Pronto', 'Entregue'}.contains(novoStatus) &&
        dadosAtuais['estoque_baixado'] != true &&
        peca.isNotEmpty &&
        quantidade > 0;

    DocumentReference<Map<String, dynamic>>? estoqueRef;
    if (deveBaixarEstoque) {
      final estoque = await _firestore
          .collection('estoque')
          .where('empresaId', isEqualTo: empresaId)
          .where('nome', isEqualTo: peca)
          .limit(1)
          .get();
      if (estoque.docs.isEmpty) {
        throw StateError('A peça selecionada não foi encontrada no estoque.');
      }
      estoqueRef = estoque.docs.first.reference;
    }

    await _firestore.runTransaction((transacao) async {
      final osAtual = await transacao.get(osRef);
      final dadosOs = osAtual.data();
      if (!osAtual.exists || dadosOs?['empresaId'] != empresaId) {
        throw StateError('Você não tem acesso a esta OS.');
      }

      final statusPersistido = (dadosOs?['status'] ?? 'Em análise').toString();
      if (statusPersistido == 'Entregue' && novoStatus != 'Entregue') {
        throw StateError(
          'Uma OS entregue não pode voltar para uma etapa anterior.',
        );
      }

      final atualizacoes = <String, dynamic>{
        ...campos,
        'atualizado_em': FieldValue.serverTimestamp(),
      };
      final historico = List<Map<String, dynamic>>.from(
        (dadosOs?['historico_status'] as List? ?? const [])
            .whereType<Map>()
            .map((item) => Map<String, dynamic>.from(item)),
      );
      if (statusPersistido != novoStatus) {
        historico.add({
          'de': statusPersistido,
          'para': novoStatus,
          'em': Timestamp.now(),
        });
        atualizacoes['historico_status'] = historico;
      }

      if (estoqueRef != null && dadosOs?['estoque_baixado'] != true) {
        final estoqueAtual = await transacao.get(estoqueRef);
        final dadosEstoque = estoqueAtual.data();
        final quantidadeAtual = quantidadeNumerica(dadosEstoque?['quantidade']);
        if (!estoqueAtual.exists || quantidadeAtual < quantidade) {
          throw StateError('Estoque insuficiente para iniciar o reparo.');
        }
        final quantidadeNova = quantidadeAtual - quantidade;
        transacao.update(estoqueRef as DocumentReference<Object?>, {
          'quantidade': dadosEstoque?['quantidade'] is num
              ? quantidadeNova
              : quantidadeNova.toString(),
        });
        atualizacoes['estoque_baixado'] = true;
        atualizacoes['estoque_baixado_em'] = FieldValue.serverTimestamp();
      }

      if (novoStatus == 'Entregue' && dadosOs?['financeiro_lancado'] != true) {
        final valorCobrado = valorNumerico(
          campos['valor'] ?? dadosOs?['valor'],
        );
        final custoPecas = valorNumerico(dadosOs?['custo_pecas']);
        final financeiroRef = _firestore.collection('financeiro').doc();
        transacao.set(financeiroRef, {
          'empresaId': empresaId,
          'descricao': 'Recebimento ${dadosOs?['numero_os'] ?? 'da OS'}',
          'valor': valorCobrado.toStringAsFixed(2),
          'tipo': 'Entrada',
          'pagamento': dadosOs?['forma_pagamento'] ?? 'Não informado',
          'origem': 'ordem_servico',
          'ordemServicoId': osRef.id,
          'data': Timestamp.now(),
          'criadoEm': FieldValue.serverTimestamp(),
        });
        atualizacoes['financeiro_lancado'] = true;
        atualizacoes['financeiro_lancado_em'] = FieldValue.serverTimestamp();
        atualizacoes['lucro_bruto'] = valorCobrado - custoPecas;
      }

      transacao.update(osRef, atualizacoes);
    });
  }
}
