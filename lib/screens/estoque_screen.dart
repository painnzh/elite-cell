import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'estoque_detalhes_screen.dart';

class EstoqueScreen extends StatefulWidget {
  final String empresaId;

  const EstoqueScreen({super.key, required this.empresaId});

  @override
  State<EstoqueScreen> createState() => _EstoqueScreenState();
}

class _EstoqueScreenState extends State<EstoqueScreen> {
  final Color dourado = Color(0xFFD4AF37);

  final nomeController = TextEditingController();
  final modeloController = TextEditingController();
  final quantidadeController = TextEditingController();
  final custoController = TextEditingController();
  final vendaController = TextEditingController();
  final fornecedorController = TextEditingController();

  String busca = '';

  final estoque = FirebaseFirestore.instance.collection('estoque');

  double converterValor(dynamic valor) {
    return double.tryParse(valor.toString().replaceAll(',', '.')) ?? 0;
  }

  Future<void> salvarPeca() async {
    await estoque.add({
      'empresaId': widget.empresaId,
      'nome': nomeController.text,
      'modelo': modeloController.text,
      'quantidade': quantidadeController.text,
      'custo': custoController.text,
      'venda': vendaController.text,
      'fornecedor': fornecedorController.text,
      'data': DateTime.now(),
    });

    nomeController.clear();
    modeloController.clear();
    quantidadeController.clear();
    custoController.clear();
    vendaController.clear();
    fornecedorController.clear();

    Navigator.pop(context);
  }

  InputDecoration decoracaoCampo(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(color: dourado),
      enabledBorder: OutlineInputBorder(
        borderSide: BorderSide(color: dourado),
        borderRadius: BorderRadius.circular(14),
      ),
      focusedBorder: OutlineInputBorder(
        borderSide: BorderSide(color: dourado, width: 2),
        borderRadius: BorderRadius.circular(14),
      ),
    );
  }

  Widget campoFormulario(TextEditingController controller, String label) {
    return Padding(
      padding: EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: controller,
        style: TextStyle(color: Colors.white),
        decoration: decoracaoCampo(label),
      ),
    );
  }

  void abrirFormulario() {
    showDialog(
      context: context,
      builder: (_) {
        return AlertDialog(
          backgroundColor: Color(0xFF111111),
          title: Text(
            'Nova Peça',
            style: TextStyle(color: dourado),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                campoFormulario(nomeController, 'Nome da peça'),
                campoFormulario(modeloController, 'Modelo compatível'),
                campoFormulario(quantidadeController, 'Quantidade'),
                campoFormulario(custoController, 'Valor de custo'),
                campoFormulario(vendaController, 'Valor de venda'),
                campoFormulario(fornecedorController, 'Fornecedor'),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Cancelar',
                style: TextStyle(color: Colors.white70),
              ),
            ),
            ElevatedButton(
              onPressed: salvarPeca,
              style: ElevatedButton.styleFrom(
                backgroundColor: dourado,
                foregroundColor: Colors.black,
              ),
              child: Text('Salvar'),
            ),
          ],
        );
      },
    );
  }

  int converterQuantidade(dynamic valor) {
    return int.tryParse(valor.toString()) ?? 0;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,

      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: IconThemeData(color: dourado),
        centerTitle: true,
        title: Image.asset(
          'assets/images/elite_cell_logo.png',
          height: 45,
        ),
      ),

      floatingActionButton: FloatingActionButton(
        backgroundColor: dourado,
        foregroundColor: Colors.black,
        onPressed: abrirFormulario,
        child: Icon(Icons.add),
      ),

      body: Column(
        children: [
          Container(
            padding: EdgeInsets.only(
              left: 16,
              right: 16,
              top: 18,
              bottom: 8,
            ),
            child: Column(
              children: [
                Text(
                  'ESTOQUE',
                  style: TextStyle(
                    color: dourado,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2,
                  ),
                ),

                SizedBox(height: 4),

                Text(
                  'Controle de peças e fornecedores',
                  style: TextStyle(
                    color: Colors.white60,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),

          Padding(
            padding: EdgeInsets.all(12),
            child: TextField(
              style: TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Pesquisar peça...',
                hintStyle: TextStyle(color: Colors.white54),
                prefixIcon: Icon(Icons.search, color: dourado),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: dourado),
                  borderRadius: BorderRadius.circular(14),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: dourado, width: 2),
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              onChanged: (valor) {
                setState(() {
                  busca = valor.toLowerCase();
                });
              },
            ),
          ),

          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: estoque
                  .where('empresaId', isEqualTo: widget.empresaId)
 		  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return Center(
                    child: CircularProgressIndicator(color: dourado),
                  );
                }

                final dados = snapshot.data!.docs.where((doc) {
                  final peca = doc.data() as Map<String, dynamic>;

                  return (peca['nome'] ?? '')
                          .toString()
                          .toLowerCase()
                          .contains(busca) ||
                      (peca['modelo'] ?? '')
                          .toString()
                          .toLowerCase()
                          .contains(busca) ||
                      (peca['fornecedor'] ?? '')
                          .toString()
                          .toLowerCase()
                          .contains(busca);
                }).toList();

                if (dados.isEmpty) {
                  return Center(
                    child: Text(
                      'Nenhuma peça encontrada',
                      style: TextStyle(color: Colors.white70),
                    ),
                  );
                }

                return ListView.builder(
                  itemCount: dados.length,
                  itemBuilder: (context, index) {
                    final doc = dados[index];
                    final peca = doc.data() as Map<String, dynamic>;

                    peca['id'] = doc.id;

                    final quantidade = converterQuantidade(peca['quantidade']);
                    final custo = converterValor(peca['custo']);
                    final venda = converterValor(peca['venda']);
                    final lucro = venda - custo;

                    final estoqueBaixo = quantidade <= 1;

                    return GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => EstoqueDetalhesScreen(
                              dados: peca,
                            ),
                          ),
                        );
                      },
                      child: Card(
                        elevation: 8,
                        shadowColor: estoqueBaixo
                            ? Colors.redAccent.withOpacity(0.4)
                            : dourado.withOpacity(0.3),
                        color: Color(0xFF111111),
                        margin: EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 7,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                          side: BorderSide(
                            color: estoqueBaixo ? Colors.redAccent : dourado,
                            width: 1,
                          ),
                        ),
                        child: ListTile(
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          leading: CircleAvatar(
                            backgroundColor:
                                estoqueBaixo ? Colors.redAccent : dourado,
                            child: Icon(
                              Icons.inventory,
                              color: Colors.black,
                            ),
                          ),
                          title: Text(
                            peca['nome'] ?? '',
                            style: TextStyle(
                              color: estoqueBaixo
                                  ? Colors.redAccent
                                  : dourado,
                              fontWeight: FontWeight.bold,
                              fontSize: 17,
                            ),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SizedBox(height: 4),
                              Text(
                                'Modelo: ${peca['modelo'] ?? ''}',
                                style: TextStyle(color: Colors.white70),
                              ),
                              Text(
                                'Qtd: ${peca['quantidade'] ?? ''} | Lucro: R\$ ${lucro.toStringAsFixed(2)}',
                                style: TextStyle(
                                  color: estoqueBaixo
                                      ? Colors.redAccent
                                      : Colors.white54,
                                  fontSize: 12,
                                ),
                              ),
                              if ((peca['fornecedor'] ?? '')
                                  .toString()
                                  .isNotEmpty)
                                Text(
                                  'Fornecedor: ${peca['fornecedor']}',
                                  style: TextStyle(
                                    color: Colors.white38,
                                    fontSize: 12,
                                  ),
                                ),
                            ],
                          ),
                          trailing: Icon(
                            Icons.chevron_right,
                            color: estoqueBaixo ? Colors.redAccent : dourado,
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}