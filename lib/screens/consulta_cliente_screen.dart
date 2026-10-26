import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class ConsultaClienteScreen extends StatefulWidget {
  final String empresaId;

  const ConsultaClienteScreen({super.key, required this.empresaId});

  @override
  State<ConsultaClienteScreen> createState() => _ConsultaClienteScreenState();
}

class _ConsultaClienteScreenState extends State<ConsultaClienteScreen> {
  final Color dourado = Color(0xFFD4AF37);

  final buscaController = TextEditingController();
  String busca = '';

  final os = FirebaseFirestore.instance.collection('ordens_servico');

  double converterValor(dynamic valor) {
    return double.tryParse(valor.toString().replaceAll(',', '.')) ?? 0;
  }

  Future<void> enviarWhatsApp(Map<String, dynamic> item) async {
    final telefone = (item['telefone'] ?? '').toString().replaceAll(
      RegExp(r'[^0-9]'),
      '',
    );

    final mensagem = Uri.encodeComponent(
      'Olá ${item['cliente'] ?? ''}, sua OS ${item['numero_os'] ?? ''} está com status: ${item['status'] ?? ''}.\n\n'
      'Aparelho: ${item['marca'] ?? ''} ${item['modelo'] ?? ''}\n'
      'Defeito: ${item['defeito'] ?? ''}\n'
      'Valor: R\$ ${item['valor'] ?? ''}\n\n'
      'Elite Cell Assistência Técnica',
    );

    final url = Uri.parse('https://wa.me/55$telefone?text=$mensagem');

    await launchUrl(url, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,

      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: IconThemeData(color: dourado),
        centerTitle: true,
        title: Image.asset('assets/images/elite_cell_logo.png', height: 45),
      ),

      body: Column(
        children: [
          Container(
            padding: EdgeInsets.only(left: 16, right: 16, top: 18, bottom: 8),
            child: Column(
              children: [
                Text(
                  'CONSULTA CLIENTE',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: dourado,
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Busque por nome, telefone, IMEI ou OS',
                  style: TextStyle(color: Colors.white60, fontSize: 14),
                ),
              ],
            ),
          ),

          Padding(
            padding: EdgeInsets.all(12),
            child: TextField(
              controller: buscaController,
              style: TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Digite telefone, IMEI, nome ou OS',
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
              stream: os
                  .where('empresaId', isEqualTo: widget.empresaId)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return Center(
                    child: CircularProgressIndicator(color: dourado),
                  );
                }

                if (busca.isEmpty) {
                  return Center(
                    child: Text(
                      'Digite algo para consultar',
                      style: TextStyle(color: Colors.white70),
                    ),
                  );
                }

                final dados = snapshot.data!.docs.where((doc) {
                  final item = doc.data() as Map<String, dynamic>;

                  return (item['cliente'] ?? '')
                          .toString()
                          .toLowerCase()
                          .contains(busca) ||
                      (item['telefone'] ?? '')
                          .toString()
                          .toLowerCase()
                          .contains(busca) ||
                      (item['imei'] ?? '').toString().toLowerCase().contains(
                        busca,
                      ) ||
                      (item['numero_os'] ?? '')
                          .toString()
                          .toLowerCase()
                          .contains(busca);
                }).toList();

                if (dados.isEmpty) {
                  return Center(
                    child: Text(
                      'Nenhuma OS encontrada',
                      style: TextStyle(color: Colors.white70),
                    ),
                  );
                }

                double totalGasto = 0;

                for (var doc in dados) {
                  final item = doc.data() as Map<String, dynamic>;
                  totalGasto += converterValor(item['valor']);
                }

                return Column(
                  children: [
                    Card(
                      color: Color(0xFF111111),
                      margin: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                        side: BorderSide(color: dourado),
                      ),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: dourado,
                          child: Icon(Icons.analytics, color: Colors.black),
                        ),
                        title: Text(
                          'Resumo encontrado',
                          style: TextStyle(
                            color: dourado,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        subtitle: Text(
                          '${dados.length} OS encontrada(s)\nTotal: R\$ ${totalGasto.toStringAsFixed(2)}',
                          style: TextStyle(color: Colors.white70),
                        ),
                      ),
                    ),

                    Expanded(
                      child: ListView.builder(
                        itemCount: dados.length,
                        itemBuilder: (context, index) {
                          final item =
                              dados[index].data() as Map<String, dynamic>;

                          final status = item['status'] ?? '';
                          final entregue = status == 'Entregue';

                          return Card(
                            elevation: 8,
                            shadowColor: dourado.withOpacity(0.3),
                            color: Color(0xFF111111),
                            margin: EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 7,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(18),
                              side: BorderSide(
                                color: entregue ? Colors.greenAccent : dourado,
                                width: 1,
                              ),
                            ),
                            child: ListTile(
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 10,
                              ),
                              leading: CircleAvatar(
                                backgroundColor: entregue
                                    ? Colors.greenAccent
                                    : dourado,
                                child: Icon(
                                  Icons.phone_android,
                                  color: Colors.black,
                                ),
                              ),
                              title: Text(
                                '${item['numero_os'] ?? 'Sem número'} - ${item['cliente'] ?? ''}',
                                style: TextStyle(
                                  color: entregue
                                      ? Colors.greenAccent
                                      : dourado,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              subtitle: Text(
                                '${item['marca'] ?? ''} ${item['modelo'] ?? ''}\n'
                                'Defeito: ${item['defeito'] ?? ''}\n'
                                'Valor: R\$ ${item['valor'] ?? ''}\n'
                                'Status: ${item['status'] ?? ''}',
                                style: TextStyle(color: Colors.white70),
                              ),
                              trailing: IconButton(
                                icon: Icon(Icons.chat, color: dourado),
                                onPressed: () => enviarWhatsApp(item),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
