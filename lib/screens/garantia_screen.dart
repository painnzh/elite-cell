import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class GarantiaScreen extends StatefulWidget {
  @override
  State<GarantiaScreen> createState() => _GarantiaScreenState();
}

class _GarantiaScreenState extends State<GarantiaScreen> {
  final Color dourado = Color(0xFFD4AF37);

  final clienteController = TextEditingController();
  final aparelhoController = TextEditingController();
  final servicoController = TextEditingController();

  String garantiaSelecionada = '30 Dias';
  String busca = '';

  final garantias = FirebaseFirestore.instance.collection('garantias');

  Future<void> salvarGarantia() async {
    int dias = 30;

    if (garantiaSelecionada == '60 Dias') dias = 60;
    if (garantiaSelecionada == '90 Dias') dias = 90;

    final vencimento = DateTime.now().add(Duration(days: dias));

    await garantias.add({
      'cliente': clienteController.text,
      'aparelho': aparelhoController.text,
      'servico': servicoController.text,
      'garantia': garantiaSelecionada,
      'vencimento': vencimento,
      'data': DateTime.now(),
    });

    clienteController.clear();
    aparelhoController.clear();
    servicoController.clear();

    Navigator.pop(context);
  }

  Future<void> excluirGarantia(String id) async {
    await garantias.doc(id).delete();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Garantia excluída com sucesso')),
    );
  }

  Future<void> gerarPDF(Map<String, dynamic> item) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        build: (context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'ELITE CELL ASSISTÊNCIA',
                style: pw.TextStyle(
                  fontSize: 24,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 10),
              pw.Text(
                'CERTIFICADO DE GARANTIA',
                style: pw.TextStyle(
                  fontSize: 20,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 20),
              pw.Text('Cliente: ${item['cliente'] ?? ''}'),
              pw.Text('Aparelho: ${item['aparelho'] ?? ''}'),
              pw.Text('Serviço: ${item['servico'] ?? ''}'),
              pw.Text('Garantia: ${item['garantia'] ?? ''}'),
              pw.SizedBox(height: 30),
              pw.Text('A garantia cobre apenas o serviço realizado.'),
              pw.Text('Não cobre queda, mau uso, oxidação ou dano físico.'),
              pw.SizedBox(height: 40),
              pw.Text('Assinatura: ______________________________'),
              pw.SizedBox(height: 20),
              pw.Text('Elite Cell - Assistência Técnica'),
            ],
          );
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (format) async => pdf.save(),
    );
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
            'Nova Garantia',
            style: TextStyle(color: dourado),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                campoFormulario(clienteController, 'Cliente'),
                campoFormulario(aparelhoController, 'Aparelho'),
                campoFormulario(servicoController, 'Serviço realizado'),

                SizedBox(height: 10),

                DropdownButtonFormField<String>(
                  value: garantiaSelecionada,
                  dropdownColor: Color(0xFF111111),
                  style: TextStyle(color: Colors.white),
                  decoration: decoracaoCampo('Prazo da garantia'),
                  items: [
                    '30 Dias',
                    '60 Dias',
                    '90 Dias',
                  ].map((item) {
                    return DropdownMenuItem(
                      value: item,
                      child: Text(item),
                    );
                  }).toList(),
                  onChanged: (valor) {
                    setState(() {
                      garantiaSelecionada = valor!;
                    });
                  },
                ),
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
              onPressed: salvarGarantia,
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

  bool garantiaVencida(Map<String, dynamic> item) {
    final vencimento = item['vencimento'];

    if (vencimento is Timestamp) {
      return vencimento.toDate().isBefore(DateTime.now());
    }

    return false;
  }

  String formatarVencimento(Map<String, dynamic> item) {
    final vencimento = item['vencimento'];

    if (vencimento is Timestamp) {
      final data = vencimento.toDate();
      return '${data.day.toString().padLeft(2, '0')}/${data.month.toString().padLeft(2, '0')}/${data.year}';
    }

    return 'Sem vencimento';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,

      appBar: AppBar(
        backgroundColor: Colors.black,
        centerTitle: true,
        iconTheme: IconThemeData(color: dourado),
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
                  'GARANTIAS',
                  style: TextStyle(
                    color: dourado,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Controle de garantias e comprovantes',
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
                hintText: 'Pesquisar garantia...',
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
              stream: garantias.snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return Center(
                    child: CircularProgressIndicator(color: dourado),
                  );
                }

                final dados = snapshot.data!.docs.where((doc) {
                  final item = doc.data() as Map<String, dynamic>;

                  return (item['cliente'] ?? '')
                          .toString()
                          .toLowerCase()
                          .contains(busca) ||
                      (item['aparelho'] ?? '')
                          .toString()
                          .toLowerCase()
                          .contains(busca) ||
                      (item['servico'] ?? '')
                          .toString()
                          .toLowerCase()
                          .contains(busca);
                }).toList();

                if (dados.isEmpty) {
                  return Center(
                    child: Text(
                      'Nenhuma garantia encontrada',
                      style: TextStyle(color: Colors.white70),
                    ),
                  );
                }

                return ListView.builder(
                  itemCount: dados.length,
                  itemBuilder: (context, index) {
                    final doc = dados[index];
                    final item = doc.data() as Map<String, dynamic>;

                    final vencida = garantiaVencida(item);
                    final cor = vencida ? Colors.redAccent : dourado;

                    return Card(
                      elevation: 8,
                      shadowColor: cor.withOpacity(0.3),
                      color: Color(0xFF111111),
                      margin: EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 7,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                        side: BorderSide(color: cor, width: 1),
                      ),
                      child: ListTile(
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        leading: CircleAvatar(
                          backgroundColor: cor,
                          child: Icon(
                            Icons.verified,
                            color: Colors.black,
                          ),
                        ),
                        title: Text(
                          item['cliente'] ?? '',
                          style: TextStyle(
                            color: cor,
                            fontWeight: FontWeight.bold,
                            fontSize: 17,
                          ),
                        ),
                        subtitle: Text(
                          '${item['aparelho'] ?? ''} - ${item['servico'] ?? ''}\n'
                          'Garantia: ${item['garantia'] ?? ''}\n'
                          'Vencimento: ${formatarVencimento(item)}',
                          style: TextStyle(color: Colors.white70),
                        ),
                        trailing: PopupMenuButton<String>(
                          color: Color(0xFF111111),
                          icon: Icon(Icons.more_vert, color: cor),
                          onSelected: (valor) {
                            if (valor == 'pdf') {
                              gerarPDF(item);
                            }

                            if (valor == 'excluir') {
                              excluirGarantia(doc.id);
                            }
                          },
                          itemBuilder: (context) => [
                            PopupMenuItem(
                              value: 'pdf',
                              child: Text(
                                'Gerar PDF',
                                style: TextStyle(color: Colors.white),
                              ),
                            ),
                            PopupMenuItem(
                              value: 'excluir',
                              child: Text(
                                'Excluir',
                                style: TextStyle(color: Colors.redAccent),
                              ),
                            ),
                          ],
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