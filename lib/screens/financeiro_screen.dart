import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class FinanceiroScreen extends StatefulWidget {
  @override
  State<FinanceiroScreen> createState() => _FinanceiroScreenState();
}

class _FinanceiroScreenState extends State<FinanceiroScreen> {
  final Color dourado = Color(0xFFD4AF37);

  final descricaoController = TextEditingController();
  final valorController = TextEditingController();

  String tipoSelecionado = 'Entrada';
  String pagamentoSelecionado = 'Pix';
  String busca = '';

  final financeiro = FirebaseFirestore.instance.collection('financeiro');

  Future<void> salvarLancamento() async {
    await financeiro.add({
      'descricao': descricaoController.text,
      'valor': valorController.text,
      'tipo': tipoSelecionado,
      'pagamento': pagamentoSelecionado,
      'data': DateTime.now(),
    });

    descricaoController.clear();
    valorController.clear();

    Navigator.pop(context);
  }

  double converterValor(dynamic valor) {
    return double.tryParse(valor.toString().replaceAll(',', '.')) ?? 0;
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
        keyboardType:
            label == 'Valor' ? TextInputType.number : TextInputType.text,
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
            'Novo Lançamento',
            style: TextStyle(color: dourado),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                campoFormulario(descricaoController, 'Descrição'),
                campoFormulario(valorController, 'Valor'),

                DropdownButtonFormField<String>(
                  value: tipoSelecionado,
                  dropdownColor: Color(0xFF111111),
                  style: TextStyle(color: Colors.white),
                  decoration: decoracaoCampo('Tipo'),
                  items: ['Entrada', 'Saída'].map((item) {
                    return DropdownMenuItem(
                      value: item,
                      child: Text(item),
                    );
                  }).toList(),
                  onChanged: (valor) {
                    setState(() {
                      tipoSelecionado = valor!;
                    });
                  },
                ),

                SizedBox(height: 12),

                DropdownButtonFormField<String>(
                  value: pagamentoSelecionado,
                  dropdownColor: Color(0xFF111111),
                  style: TextStyle(color: Colors.white),
                  decoration: decoracaoCampo('Pagamento'),
                  items: [
                    'Pix',
                    'Dinheiro',
                    'Cartão Débito',
                    'Cartão Crédito',
                  ].map((item) {
                    return DropdownMenuItem(
                      value: item,
                      child: Text(item),
                    );
                  }).toList(),
                  onChanged: (valor) {
                    setState(() {
                      pagamentoSelecionado = valor!;
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
              onPressed: salvarLancamento,
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

  Widget resumoCard(IconData icon, String titulo, String valor, Color cor) {
    return Container(
      decoration: BoxDecoration(
        color: Color(0xFF111111),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: cor, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: cor.withOpacity(0.22),
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
      ),
      padding: EdgeInsets.all(10),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: cor, size: 22),
          SizedBox(height: 6),
          Text(
            titulo,
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white70, fontSize: 12),
          ),
          SizedBox(height: 5),
          Text(
            valor,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: cor,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget secaoTitulo(String titulo) {
    return Padding(
      padding: EdgeInsets.only(left: 14, right: 14, top: 8, bottom: 4),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          titulo,
          style: TextStyle(
            color: dourado,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget graficoFinanceiro(double entradas, double saidas, double saldo) {
    final maiorValor = [
      entradas,
      saidas,
      saldo < 0 ? 0 : saldo,
    ].reduce((a, b) => a > b ? a : b);

    return Container(
      height: 230,
      margin: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      padding: EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Color(0xFF111111),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: dourado, width: 1),
      ),
      child: Column(
        children: [
          Text(
            'Resumo Visual',
            style: TextStyle(
              color: dourado,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),

          SizedBox(height: 14),

          Expanded(
            child: BarChart(
              BarChartData(
                maxY: maiorValor == 0 ? 100 : maiorValor * 1.2,
                borderData: FlBorderData(show: false),
                gridData: FlGridData(show: false),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        String texto = '';

                        if (value == 0) texto = 'Entradas';
                        if (value == 1) texto = 'Saídas';
                        if (value == 2) texto = 'Saldo';

                        return Text(
                          texto,
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 10,
                          ),
                        );
                      },
                    ),
                  ),
                ),
                barGroups: [
                  BarChartGroupData(
                    x: 0,
                    barRods: [
                      BarChartRodData(
                        toY: entradas,
                        color: dourado,
                        width: 24,
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ],
                  ),
                  BarChartGroupData(
                    x: 1,
                    barRods: [
                      BarChartRodData(
                        toY: saidas,
                        color: Colors.redAccent,
                        width: 24,
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ],
                  ),
                  BarChartGroupData(
                    x: 2,
                    barRods: [
                      BarChartRodData(
                        toY: saldo < 0 ? 0 : saldo,
                        color: saldo >= 0 ? Colors.greenAccent : Colors.redAccent,
                        width: 24,
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
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

      body: StreamBuilder<QuerySnapshot>(
        stream: financeiro.orderBy('data', descending: true).snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return Center(
              child: CircularProgressIndicator(color: dourado),
            );
          }

          final todos = snapshot.data!.docs;

          final dados = todos.where((doc) {
            final lanc = doc.data() as Map<String, dynamic>;

            return (lanc['descricao'] ?? '')
                    .toString()
                    .toLowerCase()
                    .contains(busca) ||
                (lanc['tipo'] ?? '')
                    .toString()
                    .toLowerCase()
                    .contains(busca) ||
                (lanc['pagamento'] ?? '')
                    .toString()
                    .toLowerCase()
                    .contains(busca);
          }).toList();

          double entradas = 0;
          double saidas = 0;

          for (var item in todos) {
            final lanc = item.data() as Map<String, dynamic>;
            final valor = converterValor(lanc['valor']);

            if (lanc['tipo'] == 'Entrada') {
              entradas += valor;
            } else {
              saidas += valor;
            }
          }

          final saldo = entradas - saidas;
          final totalLancamentos = todos.length;
          final ticketMedio =
              totalLancamentos == 0 ? 0 : entradas / totalLancamentos;
          final corSaldo = saldo >= 0 ? dourado : Colors.redAccent;

          return Column(
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
                      'FINANCEIRO PRO+',
                      style: TextStyle(
                        color: dourado,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Controle financeiro avançado',
                      style: TextStyle(
                        color: Colors.white60,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),

              Expanded(
                child: ListView(
                  children: [
                    Padding(
                      padding: EdgeInsets.all(12),
                      child: GridView.count(
                        shrinkWrap: true,
                        physics: NeverScrollableScrollPhysics(),
                        crossAxisCount: 2,
                        crossAxisSpacing: 10,
                        mainAxisSpacing: 10,
                        childAspectRatio: 1.15,
                        children: [
                          resumoCard(
                            Icons.arrow_downward,
                            'Entradas',
                            'R\$ ${entradas.toStringAsFixed(2)}',
                            dourado,
                          ),
                          resumoCard(
                            Icons.arrow_upward,
                            'Saídas',
                            'R\$ ${saidas.toStringAsFixed(2)}',
                            Colors.redAccent,
                          ),
                          resumoCard(
                            Icons.account_balance_wallet,
                            'Saldo',
                            'R\$ ${saldo.toStringAsFixed(2)}',
                            corSaldo,
                          ),
                          resumoCard(
                            Icons.receipt_long,
                            'Ticket médio',
                            'R\$ ${ticketMedio.toStringAsFixed(2)}',
                            Colors.greenAccent,
                          ),
                          resumoCard(
                            Icons.list_alt,
                            'Lançamentos',
                            '$totalLancamentos',
                            Colors.blueAccent,
                          ),
                          resumoCard(
                            Icons.trending_up,
                            'Lucro',
                            'R\$ ${saldo.toStringAsFixed(2)}',
                            saldo >= 0 ? Colors.greenAccent : Colors.redAccent,
                          ),
                        ],
                      ),
                    ),

                    graficoFinanceiro(entradas, saidas, saldo),

                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 12),
                      child: TextField(
                        style: TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          hintText: 'Pesquisar lançamento...',
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

                    secaoTitulo('Lançamentos'),

                    if (dados.isEmpty)
                      Padding(
                        padding: EdgeInsets.all(30),
                        child: Center(
                          child: Text(
                            'Nenhum lançamento encontrado',
                            style: TextStyle(color: Colors.white70),
                          ),
                        ),
                      )
                    else
                      ListView.builder(
                        shrinkWrap: true,
                        physics: NeverScrollableScrollPhysics(),
                        itemCount: dados.length,
                        itemBuilder: (context, index) {
                          final item = dados[index];
                          final lanc = item.data() as Map<String, dynamic>;

                          final isEntrada = lanc['tipo'] == 'Entrada';
                          final cor =
                              isEntrada ? dourado : Colors.redAccent;

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
                                  isEntrada
                                      ? Icons.arrow_downward
                                      : Icons.arrow_upward,
                                  color: Colors.black,
                                ),
                              ),
                              title: Text(
                                lanc['descricao'] ?? '',
                                style: TextStyle(
                                  color: cor,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              subtitle: Text(
                                '${lanc['tipo'] ?? ''} | ${lanc['pagamento'] ?? ''}',
                                style: TextStyle(color: Colors.white70),
                              ),
                              trailing: Text(
                                'R\$ ${lanc['valor'] ?? ''}',
                                style: TextStyle(
                                  color: cor,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}