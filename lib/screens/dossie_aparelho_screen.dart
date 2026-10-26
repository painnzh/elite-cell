import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class DossieAparelhoScreen extends StatefulWidget {
  final String empresaId;
  final String aparelhoId;

  const DossieAparelhoScreen({
    super.key,
    required this.empresaId,
    required this.aparelhoId,
  });

  @override
  State<DossieAparelhoScreen> createState() => _DossieAparelhoScreenState();
}

class _DossieAparelhoScreenState extends State<DossieAparelhoScreen> {
  static const dourado = Color(0xFFD4AF37);
  final aparelho = FirebaseFirestore.instance.collection('celulares_usados');

  DocumentReference<Map<String, dynamic>> get documento =>
      aparelho.doc(widget.aparelhoId);

  double valor(dynamic valor) =>
      double.tryParse(valor?.toString().replaceAll(',', '.') ?? '') ?? 0;

  String dinheiro(double valor) => 'R\$ ${valor.toStringAsFixed(2)}';

  Future<void> adicionarMovimento() async {
    final descricao = TextEditingController();
    final valorController = TextEditingController();
    final fornecedor = TextEditingController();
    final responsavel = TextEditingController();
    String tipo = 'Peça';

    final confirmou = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setModalState) => AlertDialog(
          backgroundColor: const Color(0xFF111111),
          title: const Text(
            'Adicionar ao processo',
            style: TextStyle(color: dourado),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  initialValue: tipo,
                  dropdownColor: const Color(0xFF111111),
                  style: const TextStyle(color: Colors.white),
                  decoration: _decoracao('Tipo'),
                  items: const ['Diagnóstico', 'Peça', 'Mão de obra', 'Ajuste']
                      .map(
                        (item) =>
                            DropdownMenuItem(value: item, child: Text(item)),
                      )
                      .toList(),
                  onChanged: (novo) => setModalState(() => tipo = novo!),
                ),
                const SizedBox(height: 12),
                _campo(descricao, 'Descrição *'),
                _campo(
                  valorController,
                  'Custo (R\$)',
                  keyboardType: TextInputType.number,
                ),
                _campo(fornecedor, 'Fornecedor / origem'),
                _campo(responsavel, 'Técnico responsável'),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () {
                if (descricao.text.trim().isEmpty ||
                    valor(valorController.text) < 0) {
                  return;
                }
                Navigator.pop(dialogContext, true);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: dourado,
                foregroundColor: Colors.black,
              ),
              child: const Text('Adicionar'),
            ),
          ],
        ),
      ),
    );

    if (confirmou != true || !mounted) return;
    try {
      await documento.collection('processo').add({
        'empresaId': widget.empresaId,
        'tipo': tipo,
        'descricao': descricao.text.trim(),
        'valor': valor(valorController.text),
        'fornecedor': fornecedor.text.trim(),
        'responsavel': responsavel.text.trim(),
        'criadoEm': Timestamp.now(),
        'criadoPor': FirebaseAuth.instance.currentUser?.uid,
      });
      if (mounted) _mensagem('Item adicionado ao processo.');
    } catch (_) {
      if (mounted) _mensagem('Não foi possível adicionar este item.');
    }
  }

  Future<void> registrarTermo() async {
    final nome = TextEditingController();
    final documentoVendedor = TextEditingController();
    final contato = TextEditingController();
    bool declarou = false;
    final assinatura = _AssinaturaController();

    final confirmou = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setModalState) => AlertDialog(
          backgroundColor: const Color(0xFF111111),
          title: const Text(
            'Termo de compra e cessão',
            style: TextStyle(color: dourado),
          ),
          content: SizedBox(
            width: 440,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _campo(nome, 'Nome do vendedor *'),
                  _campo(documentoVendedor, 'CPF/RG (opcional)'),
                  _campo(contato, 'Contato (opcional)'),
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Declaração: o vendedor afirma possuir legitimidade para vender o aparelho e que as informações fornecidas são verdadeiras.',
                      style: TextStyle(color: Colors.white70),
                    ),
                  ),
                  CheckboxListTile(
                    contentPadding: EdgeInsets.zero,
                    activeColor: dourado,
                    value: declarou,
                    title: const Text(
                      'Li e concordo com a declaração.',
                      style: TextStyle(color: Colors.white),
                    ),
                    onChanged: (novo) =>
                        setModalState(() => declarou = novo ?? false),
                  ),
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Assinatura do vendedor',
                      style: TextStyle(
                        color: dourado,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  _AssinaturaPad(controller: assinatura),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton.icon(
                      onPressed: () => setModalState(assinatura.limpar),
                      icon: const Icon(Icons.refresh),
                      label: const Text('Limpar assinatura'),
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () {
                if (nome.text.trim().isEmpty || !declarou || assinatura.vazia) {
                  return;
                }
                Navigator.pop(dialogContext, true);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: dourado,
                foregroundColor: Colors.black,
              ),
              child: const Text('Registrar termo'),
            ),
          ],
        ),
      ),
    );

    if (confirmou != true || !mounted) return;
    try {
      final agora = Timestamp.now();
      await FirebaseFirestore.instance.runTransaction((transacao) async {
        final atual = await transacao.get(documento);
        if (!atual.exists || atual.data()?['empresaId'] != widget.empresaId) {
          throw StateError('Você não tem acesso a este aparelho.');
        }
        final termo = documento.collection('termo_compra').doc('atual');
        transacao.set(termo, {
          'empresaId': widget.empresaId,
          'versao': 1,
          'vendedor': {
            'nome': nome.text.trim(),
            'documento': documentoVendedor.text.trim(),
            'contato': contato.text.trim(),
          },
          'declaracaoAceita': true,
          'assinatura': assinatura.serializar(),
          'assinadoEm': agora,
          'assinadoPor': FirebaseAuth.instance.currentUser?.uid,
          'metodoAssinatura': 'desenho_na_tela',
        });
        transacao.update(documento, {
          'termoCompraRegistrado': true,
          'termoCompraAtualizadoEm': agora,
        });
      });
      if (mounted) _mensagem('Termo e assinatura registrados no dossiê.');
    } on StateError catch (erro) {
      if (mounted) _mensagem(erro.message.toString());
    } catch (_) {
      if (mounted) _mensagem('Não foi possível registrar o termo.');
    }
  }

  Future<void> atualizarStatus(String status) async {
    try {
      await FirebaseFirestore.instance.runTransaction((transacao) async {
        final atual = await transacao.get(documento);
        if (!atual.exists || atual.data()?['empresaId'] != widget.empresaId) {
          throw StateError('Você não tem acesso a este aparelho.');
        }
        transacao.update(documento, {
          'status': status,
          'atualizadoEm': Timestamp.now(),
        });
      });
    } on StateError catch (erro) {
      if (mounted) _mensagem(erro.message.toString());
    } catch (_) {
      if (mounted) _mensagem('Não foi possível atualizar o status.');
    }
  }

  void _mensagem(String texto) => ScaffoldMessenger.of(
    context,
  ).showSnackBar(SnackBar(content: Text(texto)));

  InputDecoration _decoracao(String label) => InputDecoration(
    labelText: label,
    labelStyle: const TextStyle(color: dourado),
    enabledBorder: OutlineInputBorder(
      borderSide: const BorderSide(color: dourado),
      borderRadius: BorderRadius.circular(12),
    ),
    focusedBorder: OutlineInputBorder(
      borderSide: const BorderSide(color: dourado, width: 2),
      borderRadius: BorderRadius.circular(12),
    ),
  );

  Widget _campo(
    TextEditingController controller,
    String label, {
    TextInputType? keyboardType,
  }) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: TextField(
      controller: controller,
      keyboardType: keyboardType,
      style: const TextStyle(color: Colors.white),
      decoration: _decoracao(label),
    ),
  );

  Widget _resumo(String titulo, String dado, Color cor) => Expanded(
    child: Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF111111),
        border: Border.all(color: cor),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          Text(
            titulo,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white60, fontSize: 12),
          ),
          const SizedBox(height: 4),
          Text(
            dado,
            style: TextStyle(color: cor, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    ),
  );

  @override
  Widget build(
    BuildContext context,
  ) => StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
    stream: documento.snapshots(),
    builder: (context, aparelhoSnapshot) {
      if (!aparelhoSnapshot.hasData) {
        return const Scaffold(body: Center(child: CircularProgressIndicator()));
      }
      final dados = aparelhoSnapshot.data!.data();
      if (dados == null || dados['empresaId'] != widget.empresaId) {
        return const Scaffold(
          body: Center(child: Text('Aparelho não encontrado.')),
        );
      }
      return Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: Colors.black,
          iconTheme: const IconThemeData(color: dourado),
          title: const Text(
            'Dossiê do aparelho',
            style: TextStyle(color: dourado),
          ),
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: adicionarMovimento,
          backgroundColor: dourado,
          foregroundColor: Colors.black,
          icon: const Icon(Icons.add),
          label: const Text('Adicionar custo'),
        ),
        body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: documento
              .collection('processo')
              .orderBy('criadoEm', descending: true)
              .snapshots(),
          builder: (context, processoSnapshot) {
            final movimentos = processoSnapshot.data?.docs ?? [];
            final compra = valor(dados['valor_compra']);
            final custos = movimentos.fold<double>(
              0,
              (total, doc) => total + valor(doc.data()['valor']),
            );
            final venda = valor(dados['valor_venda']);
            final total = compra + custos;
            final lucro = venda - total;
            final margem = venda == 0 ? 0 : (lucro / venda) * 100;
            return ListView(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 92),
              children: [
                Text(
                  '${dados['marca'] ?? ''} ${dados['modelo'] ?? ''}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'IMEI: ${dados['imei'] ?? 'Não informado'}',
                  style: const TextStyle(color: Colors.white70),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    _resumo('Compra', dinheiro(compra), Colors.orangeAccent),
                    const SizedBox(width: 8),
                    _resumo('Processo', dinheiro(custos), Colors.blueAccent),
                    const SizedBox(width: 8),
                    _resumo('Custo total', dinheiro(total), dourado),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _resumo('Preço de venda', dinheiro(venda), Colors.white),
                    const SizedBox(width: 8),
                    _resumo(
                      'Lucro previsto',
                      dinheiro(lucro),
                      lucro >= 0 ? Colors.greenAccent : Colors.redAccent,
                    ),
                    const SizedBox(width: 8),
                    _resumo(
                      'Margem',
                      '${margem.toStringAsFixed(1)}%',
                      lucro >= 0 ? Colors.greenAccent : Colors.redAccent,
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    OutlinedButton.icon(
                      onPressed: registrarTermo,
                      icon: Icon(
                        dados['termoCompraRegistrado'] == true
                            ? Icons.verified
                            : Icons.draw,
                      ),
                      label: Text(
                        dados['termoCompraRegistrado'] == true
                            ? 'Termo registrado'
                            : 'Registrar termo',
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: dourado,
                        side: const BorderSide(color: dourado),
                      ),
                    ),
                    if (dados['status'] == 'Vendido')
                      const Chip(
                        label: Text('Vendido'),
                        avatar: Icon(Icons.check_circle, color: Colors.green),
                      )
                    else
                      DropdownButton<String>(
                        value:
                            const [
                              'Em avaliação',
                              'Em reparo',
                              'Pronto para venda',
                              'Disponível',
                              'Reservado',
                            ].contains(dados['status'])
                            ? dados['status']
                            : 'Em avaliação',
                        dropdownColor: const Color(0xFF111111),
                        style: const TextStyle(color: Colors.white),
                        items:
                            const [
                                  'Em avaliação',
                                  'Em reparo',
                                  'Pronto para venda',
                                  'Disponível',
                                  'Reservado',
                                ]
                                .map(
                                  (status) => DropdownMenuItem(
                                    value: status,
                                    child: Text(status),
                                  ),
                                )
                                .toList(),
                        onChanged: (status) {
                          if (status != null) atualizarStatus(status);
                        },
                      ),
                  ],
                ),
                const SizedBox(height: 22),
                const Text(
                  'Histórico do processo',
                  style: TextStyle(
                    color: dourado,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                if (!processoSnapshot.hasData)
                  const Center(child: CircularProgressIndicator(color: dourado))
                else if (movimentos.isEmpty)
                  const Card(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Text(
                        'Nenhum diagnóstico, peça ou serviço registrado ainda.',
                      ),
                    ),
                  )
                else
                  ...movimentos.map((doc) {
                    final item = doc.data();
                    return Card(
                      color: const Color(0xFF111111),
                      child: ListTile(
                        leading: const Icon(Icons.build_circle, color: dourado),
                        title: Text(
                          '${item['tipo'] ?? 'Item'} · ${item['descricao'] ?? ''}',
                          style: const TextStyle(color: Colors.white),
                        ),
                        subtitle: Text(
                          [item['fornecedor'], item['responsavel']]
                              .where((e) => e?.toString().isNotEmpty == true)
                              .join(' · '),
                          style: const TextStyle(color: Colors.white60),
                        ),
                        trailing: Text(
                          dinheiro(valor(item['valor'])),
                          style: const TextStyle(
                            color: dourado,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    );
                  }),
              ],
            );
          },
        ),
      );
    },
  );
}

class _AssinaturaController extends ChangeNotifier {
  final List<List<Offset>> tracos = [];
  bool get vazia => tracos.isEmpty || tracos.every((traco) => traco.isEmpty);
  void iniciar(Offset ponto) {
    tracos.add([ponto]);
    notifyListeners();
  }

  void adicionar(Offset ponto) {
    if (tracos.isNotEmpty) {
      tracos.last.add(ponto);
      notifyListeners();
    }
  }

  void limpar() {
    tracos.clear();
    notifyListeners();
  }

  List<Map<String, dynamic>> serializar() => tracos
      .map(
        (traco) => {
          'pontos': traco
              .map((ponto) => {'x': ponto.dx, 'y': ponto.dy})
              .toList(),
        },
      )
      .toList();
}

class _AssinaturaPad extends StatelessWidget {
  final _AssinaturaController controller;
  const _AssinaturaPad({required this.controller});
  @override
  Widget build(BuildContext context) => SizedBox(
    height: 130,
    child: AnimatedBuilder(
      animation: controller,
      builder: (_, _) => GestureDetector(
        onPanStart: (detalhes) => controller.iniciar(detalhes.localPosition),
        onPanUpdate: (detalhes) => controller.adicionar(detalhes.localPosition),
        child: CustomPaint(
          foregroundPainter: _AssinaturaPainter(controller.tracos),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
      ),
    ),
  );
}

class _AssinaturaPainter extends CustomPainter {
  final List<List<Offset>> tracos;
  _AssinaturaPainter(this.tracos);
  @override
  void paint(Canvas canvas, Size size) {
    final tinta = Paint()
      ..color = Colors.black
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    for (final traco in tracos) {
      for (var i = 1; i < traco.length; i++) {
        canvas.drawLine(traco[i - 1], traco[i], tinta);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _AssinaturaPainter oldDelegate) => true;
}
