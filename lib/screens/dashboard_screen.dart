import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'catalogo_cliente_screen.dart';

import 'garantia_screen.dart';
import 'consulta_cliente_screen.dart';
import 'clientes_screen.dart';
import 'estoque_screen.dart';
import 'financeiro_screen.dart';
import 'os_screen.dart';
import 'celulares_usados_screen.dart';

class DashboardScreen extends StatelessWidget {
  final Color dourado = Color(0xFFD4AF37);

  final clientes = FirebaseFirestore.instance.collection('clientes');
  final os = FirebaseFirestore.instance.collection('ordens_servico');
  final estoque = FirebaseFirestore.instance.collection('estoque');
  final financeiro = FirebaseFirestore.instance.collection('financeiro');
  final garantias = FirebaseFirestore.instance.collection('garantias');

  double converterValor(dynamic valor) {
    return double.tryParse(valor.toString().replaceAll(',', '.')) ?? 0;
  }

  int converterQuantidade(dynamic valor) {
    return int.tryParse(valor.toString()) ?? 0;
  }

  bool garantiaVencida(Map<String, dynamic> item) {
    final vencimento = item['vencimento'];

    if (vencimento is Timestamp) {
      return vencimento.toDate().isBefore(DateTime.now());
    }

    return false;
  }

  Widget cabecalhoPremium() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF111111),
            Color(0xFF1A1A1A),
          ],
        ),
        border: Border.all(color: dourado, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: dourado.withOpacity(0.22),
            blurRadius: 14,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          Image.asset(
            'assets/images/elite_cell_logo.png',
            height: 80,
          ),
          SizedBox(height: 10),
          Text(
            'ELITE CELL',
            style: TextStyle(
              color: dourado,
              fontSize: 30,
              fontWeight: FontWeight.bold,
              letterSpacing: 3,
            ),
          ),
          SizedBox(height: 5),
          Text(
            'Sistema Premium de Assistência Técnica',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white70,
              fontSize: 14,
            ),
          ),
        ],
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
      height: 260,
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF111111),
            Color(0xFF1B1B1B),
          ],
        ),
        border: Border.all(color: dourado),
        boxShadow: [
          BoxShadow(
            color: dourado.withOpacity(0.20),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            'Resumo Financeiro',
            style: TextStyle(
              color: dourado,
              fontSize: 20,
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
                        color: saldo >= 0
                            ? Colors.greenAccent
                            : Colors.redAccent,
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
        centerTitle: true,
        title: Image.asset(
          'assets/images/elite_cell_logo.png',
          height: 55,
        ),
      ),

      body: StreamBuilder<QuerySnapshot>(
        stream: os.snapshots(),
        builder: (context, osSnapshot) {
          return StreamBuilder<QuerySnapshot>(
            stream: clientes.snapshots(),
            builder: (context, clientesSnapshot) {
              return StreamBuilder<QuerySnapshot>(
                stream: estoque.snapshots(),
                builder: (context, estoqueSnapshot) {
                  return StreamBuilder<QuerySnapshot>(
                    stream: financeiro.snapshots(),
                    builder: (context, financeiroSnapshot) {
                      return StreamBuilder<QuerySnapshot>(
                        stream: garantias.snapshots(),
                        builder: (context, garantiasSnapshot) {
                          if (!osSnapshot.hasData ||
                              !clientesSnapshot.hasData ||
                              !estoqueSnapshot.hasData ||
                              !financeiroSnapshot.hasData ||
                              !garantiasSnapshot.hasData) {
                            return Center(
                              child: CircularProgressIndicator(
                                color: dourado,
                              ),
                            );
                          }

                          final totalOS = osSnapshot.data!.docs.length;
                          final totalClientes =
                              clientesSnapshot.data!.docs.length;
                          final totalPecas =
                              estoqueSnapshot.data!.docs.length;

                          int osAbertas = 0;
                          int osEntregues = 0;
                          int osProntas = 0;
                          int osMes = 0;

                          final agora = DateTime.now();

                          for (var item in osSnapshot.data!.docs) {
                            final dados =
                                item.data() as Map<String, dynamic>;
                            final status = dados['status'] ?? '';

                            if (status == 'Entregue') {
                              osEntregues++;
                            } else {
                              osAbertas++;
                            }

                            if (status == 'Pronto') {
                              osProntas++;
                            }

                            if (dados['data'] is Timestamp) {
                              final data =
                                  (dados['data'] as Timestamp).toDate();

                              if (data.month == agora.month &&
                                  data.year == agora.year) {
                                osMes++;
                              }
                            }
                          }

                          int estoqueBaixo = 0;

                          for (var item in estoqueSnapshot.data!.docs) {
                            final dados =
                                item.data() as Map<String, dynamic>;

                            final qtd = converterQuantidade(
                              dados['quantidade'] ?? '0',
                            );

                            if (qtd <= 1) {
                              estoqueBaixo++;
                            }
                          }

                          double entradas = 0;
                          double saidas = 0;
                          double faturamentoMes = 0;

                          for (var item in financeiroSnapshot.data!.docs) {
                            final dados =
                                item.data() as Map<String, dynamic>;
                            final valor = converterValor(dados['valor']);

                            if (dados['tipo'] == 'Entrada') {
                              entradas += valor;
                            } else {
                              saidas += valor;
                            }

                            if (dados['data'] is Timestamp) {
                              final data =
                                  (dados['data'] as Timestamp).toDate();

                              if (data.month == agora.month &&
                                  data.year == agora.year &&
                                  dados['tipo'] == 'Entrada') {
                                faturamentoMes += valor;
                              }
                            }
                          }

                          final saldo = entradas - saidas;

                          int garantiasAtivas = 0;
                          int garantiasVencidas = 0;

                          for (var item in garantiasSnapshot.data!.docs) {
                            final dados =
                                item.data() as Map<String, dynamic>;

                            if (garantiaVencida(dados)) {
                              garantiasVencidas++;
                            } else {
                              garantiasAtivas++;
                            }
                          }

                          return SingleChildScrollView(
                            padding: EdgeInsets.all(16),
                            child: Column(
                              children: [
                                cabecalhoPremium(),

                                SizedBox(height: 22),

                                Align(
                                  alignment: Alignment.centerLeft,
                                  child: Text(
                                    'Indicadores',
                                    style: TextStyle(
                                      color: dourado,
                                      fontSize: 22,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),

                                SizedBox(height: 12),

                                GridView.count(
                                  shrinkWrap: true,
                                  physics: NeverScrollableScrollPhysics(),
                                  crossAxisCount: 2,
                                  crossAxisSpacing: 12,
                                  mainAxisSpacing: 12,
                                  childAspectRatio: 1.18,
                                  children: [
                                    indicador(
                                      Icons.calendar_month,
                                      'OS do mês',
                                      '$osMes',
                                      Colors.blueAccent,
                                    ),
                                    indicador(
                                      Icons.trending_up,
                                      'Faturamento mês',
                                      'R\$ ${faturamentoMes.toStringAsFixed(0)}',
                                      Colors.greenAccent,
                                    ),
                                    indicador(
                                      Icons.build,
                                      'OS abertas',
                                      '$osAbertas',
                                      dourado,
                                    ),
                                    indicador(
                                      Icons.check_circle,
                                      'OS prontas',
                                      '$osProntas',
                                      Colors.greenAccent,
                                    ),
                                    indicador(
                                      Icons.people,
                                      'Clientes',
                                      '$totalClientes',
                                      dourado,
                                    ),
                                    indicador(
                                      Icons.inventory,
                                      'Peças',
                                      '$totalPecas',
                                      dourado,
                                    ),
                                    indicador(
                                      Icons.warning_amber,
                                      'Estoque baixo',
                                      '$estoqueBaixo',
                                      estoqueBaixo > 0
                                          ? Colors.redAccent
                                          : dourado,
                                    ),
                                    indicador(
                                      Icons.attach_money,
                                      'Saldo',
                                      'R\$ ${saldo.toStringAsFixed(2)}',
                                      saldo >= 0
                                          ? dourado
                                          : Colors.redAccent,
                                    ),
                                    indicador(
                                      Icons.verified,
                                      'Garantias ativas',
                                      '$garantiasAtivas',
                                      Colors.greenAccent,
                                    ),
                                    indicador(
                                      Icons.cancel,
                                      'Garantias vencidas',
                                      '$garantiasVencidas',
                                      garantiasVencidas > 0
                                          ? Colors.redAccent
                                          : dourado,
                                    ),
                                    indicador(
                                      Icons.description,
                                      'Total OS',
                                      '$totalOS',
                                      dourado,
                                    ),
                                    indicador(
                                      Icons.checklist,
                                      'OS entregues',
                                      '$osEntregues',
                                      Colors.greenAccent,
                                    ),
                                  ],
                                ),

                                SizedBox(height: 24),

                                graficoFinanceiro(
                                  entradas,
                                  saidas,
                                  saldo,
                                ),

                                SizedBox(height: 24),

                                Align(
                                  alignment: Alignment.centerLeft,
                                  child: Text(
                                    'Atalhos',
                                    style: TextStyle(
                                      color: dourado,
                                      fontSize: 22,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),

                                SizedBox(height: 12),

                                GridView.count(
                                  shrinkWrap: true,
                                  physics: NeverScrollableScrollPhysics(),
                                  crossAxisCount: 2,
                                  crossAxisSpacing: 12,
                                  mainAxisSpacing: 12,
                                  childAspectRatio: 1.25,
                                  children: [
                                    menuCard(
                                      context,
                                      Icons.build,
                                      'Ordens de Serviço',
                                      OsScreen(),
                                      ),
                                      menuCard(
                                        context,
                                        Icons.storefront,
                                        'Catálogo Cliente',
                                        CatalogoClienteScreen(),
                                      ),
                                    menuCard(
                                      context,
                                      Icons.people,
                                      'Clientes',
                                      ClientesScreen(),
                                    ),
                                    menuCard(
                                      context,
                                      Icons.inventory,
                                      'Estoque',
                                      EstoqueScreen(),
                                    ),
                                    menuCard(
                                      context,
                                      Icons.phone_android,
                                      'Celulares Usados',
                                      CelularesUsadosScreen(),
                                    ),
                                    menuCard(
                                      context,
                                      Icons.attach_money,
                                      'Financeiro',
                                      FinanceiroScreen(),
                                    ),
                                    menuCard(
                                      context,
                                      Icons.verified,
                                      'Garantias',
                                      GarantiaScreen(),
                                    ),
                                    menuCard(
                                      context,
                                      Icons.search,
                                      'Consulta Cliente',
                                      ConsultaClienteScreen(),
                                    ),
                                  ],
                                ),

                                SizedBox(height: 30),

                                Text(
                                  'Elite Cell Assistência Técnica',
                                  style: TextStyle(
                                    color: dourado,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),

                                SizedBox(height: 5),

                                Text(
                                  'Versão V2 Premium',
                                  style: TextStyle(
                                    color: Colors.white54,
                                  ),
                                ),

                                SizedBox(height: 30),
                              ],
                            ),
                          );
                        },
                      );
                    },
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  Widget indicador(
    IconData icon,
    String titulo,
    String valor,
    Color cor,
  ) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF111111),
            Color(0xFF1B1B1B),
          ],
        ),
        border: Border.all(color: cor, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: cor.withOpacity(0.22),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      padding: EdgeInsets.all(12),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 34,
            color: cor,
          ),
          SizedBox(height: 8),
          Text(
            titulo,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white70,
              fontSize: 14,
            ),
          ),
          SizedBox(height: 6),
          Text(
            valor,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: cor,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget menuCard(
    BuildContext context,
    IconData icon,
    String title,
    Widget screen,
  ) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => screen,
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF111111),
              Color(0xFF1A1A1A),
            ],
          ),
          border: Border.all(color: dourado, width: 1.4),
          boxShadow: [
            BoxShadow(
              color: dourado.withOpacity(0.20),
              blurRadius: 12,
              offset: Offset(0, 4),
            ),
          ],
        ),
        padding: EdgeInsets.all(8),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 42,
              color: dourado,
            ),
            SizedBox(height: 10),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}