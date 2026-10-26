import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';

class CelularesUsadosScreen extends StatefulWidget {
  final String empresaId;

  const CelularesUsadosScreen({
    super.key,
    required this.empresaId,
  });

  @override
  State<CelularesUsadosScreen> createState() => _CelularesUsadosScreenState();
}

class _CelularesUsadosScreenState extends State<CelularesUsadosScreen> {
  final Color dourado = Color(0xFFD4AF37);

  final marcaController = TextEditingController();
  final modeloController = TextEditingController();
  final imeiController = TextEditingController();
  final estadoController = TextEditingController();
  final corController = TextEditingController();
  final capacidadeController = TextEditingController();
  final bateriaController = TextEditingController();
  final compraController = TextEditingController();
  final vendaController = TextEditingController();
  final observacaoController = TextEditingController();

  String statusSelecionado = 'Disponível';
  bool publicadoNoCatalogo = false;
  String busca = '';

  File? fotoCelular;

  final celulares =
      FirebaseFirestore.instance.collection('celulares_usados');

  final financeiro =
      FirebaseFirestore.instance.collection('financeiro');

  void preencherFormulario(Map<String, dynamic>? item) {
    marcaController.text = item?['marca']?.toString() ?? '';
    modeloController.text = item?['modelo']?.toString() ?? '';
    imeiController.text = item?['imei']?.toString() ?? '';
    estadoController.text = item?['estado']?.toString() ?? '';
    corController.text = item?['cor']?.toString() ?? '';
    capacidadeController.text = item?['capacidade']?.toString() ?? '';
    bateriaController.text = item?['bateria']?.toString() ?? '';
    compraController.text = item?['valor_compra']?.toString() ?? '';
    vendaController.text = item?['valor_venda']?.toString() ?? '';
    observacaoController.text = item?['observacao']?.toString() ?? '';
    statusSelecionado = item?['status']?.toString() ?? 'Disponível';
    publicadoNoCatalogo = item?['publicadoCatalogo'] == true;
    fotoCelular = null;
  }

  bool validarFormulario() {
    final camposObrigatorios = [
      marcaController.text,
      modeloController.text,
      imeiController.text,
      estadoController.text,
      capacidadeController.text,
    ];
    final compra = double.tryParse(compraController.text.replaceAll(',', '.'));
    final venda = double.tryParse(vendaController.text.replaceAll(',', '.'));
    final bateria = int.tryParse(bateriaController.text);

    if (camposObrigatorios.any((campo) => campo.trim().isEmpty) ||
        compra == null ||
        venda == null ||
        compra < 0 ||
        venda < 0 ||
        bateria == null ||
        bateria < 0 ||
        bateria > 100) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Preencha os campos obrigatórios e informe valores válidos.',
          ),
        ),
      );
      return false;
    }

    return true;
  }

  double converterValor(dynamic valor) {
    return double.tryParse(valor.toString().replaceAll(',', '.')) ?? 0;
  }

  Future<void> escolherFoto(ImageSource origem) async {
    final picker = ImagePicker();

    final imagem = await picker.pickImage(
      source: origem,
      imageQuality: 75,
    );

    if (imagem != null) {
      setState(() {
        fotoCelular = File(imagem.path);
      });
    }
  }

  Future<void> salvarCelular({
    String? id,
    String? fotoPathOriginal,
  }) async {
    final dados = {
      'marca': marcaController.text,
      'modelo': modeloController.text,
      'imei': imeiController.text,
      'estado': estadoController.text,
      'cor': corController.text,
      'capacidade': capacidadeController.text,
      'bateria': bateriaController.text,
      'valor_compra': compraController.text,
      'valor_venda': vendaController.text,
      'observacao': observacaoController.text,
      'status': statusSelecionado,
      'publicadoCatalogo': publicadoNoCatalogo,
      'foto_path': fotoCelular?.path ?? fotoPathOriginal ?? '',
      'empresaId': widget.empresaId,
    };

    try {
      if (id == null) {
        await celulares.add({...dados, 'data': DateTime.now()});
      } else {
        await FirebaseFirestore.instance.runTransaction((transacao) async {
          final documento = await transacao.get(celulares.doc(id));
          if (!documento.exists ||
              documento.data()?['empresaId'] != widget.empresaId) {
            throw StateError('Você não tem acesso a este aparelho.');
          }
          transacao.update(celulares.doc(id), dados);
        });
      }

      if (!mounted) return;
      preencherFormulario(null);
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(id == null ? 'Aparelho cadastrado.' : 'Aparelho atualizado.')),
      );
    } on StateError catch (erro) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(erro.message.toString())),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Não foi possível salvar o aparelho.')),
      );
    }
  }

  Future<void> marcarComoVendido(String id) async {
    final celular = celulares.doc(id);
    final lancamentoVenda = financeiro.doc();
    final agora = Timestamp.now();

    try {
      await FirebaseFirestore.instance.runTransaction((transacao) async {
        final documento = await transacao.get(celular);
        final item = documento.data();

        if (item == null) {
          throw StateError('Aparelho não encontrado.');
        }

        if (item['empresaId'] != widget.empresaId) {
          throw StateError('Você não tem acesso a este aparelho.');
        }

        if (item['status'] == 'Vendido') {
          throw StateError('Este aparelho já foi vendido.');
        }

        transacao.update(celular, {
          'status': 'Vendido',
          'vendido_em': agora,
          'financeiroVendaId': lancamentoVenda.id,
        });

        transacao.set(lancamentoVenda, {
          'empresaId': widget.empresaId,
          'descricao':
              'Venda celular usado - ${item['marca'] ?? ''} ${item['modelo'] ?? ''}',
          'valor': item['valor_venda'] ?? '0',
          'tipo': 'Entrada',
          'pagamento': 'Pix',
          'data': agora,
          'origem': 'celular_usado',
          'celularUsadoId': id,
        });
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Celular vendido e lançado no financeiro')),
      );
    } on StateError catch (erro) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(erro.message.toString())),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Não foi possível registrar a venda.')),
      );
    }
  }

  Future<void> reverterVenda(String id) async {
    final celular = celulares.doc(id);
    final lancamentoEstorno = financeiro.doc();
    final agora = Timestamp.now();

    try {
      await FirebaseFirestore.instance.runTransaction((transacao) async {
        final documento = await transacao.get(celular);
        final item = documento.data();

        if (item == null) {
          throw StateError('Aparelho não encontrado.');
        }

        if (item['empresaId'] != widget.empresaId) {
          throw StateError('Você não tem acesso a este aparelho.');
        }

        if (item['status'] != 'Vendido') {
          throw StateError('Este aparelho não possui uma venda para reverter.');
        }

        transacao.update(celular, {
          'status': 'Disponível',
          'vendido_em': FieldValue.delete(),
          'financeiroEstornoId': lancamentoEstorno.id,
        });

        transacao.set(lancamentoEstorno, {
          'empresaId': widget.empresaId,
          'descricao':
              'Estorno venda celular usado - ${item['marca'] ?? ''} ${item['modelo'] ?? ''}',
          'valor': item['valor_venda'] ?? '0',
          'tipo': 'Saída',
          'pagamento': 'Estorno',
          'data': agora,
          'origem': 'estorno_celular_usado',
          'celularUsadoId': id,
          'referenciaLancamentoId': item['financeiroVendaId'],
        });
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Venda revertida e estorno lançado no financeiro')),
      );
    } on StateError catch (erro) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(erro.message.toString())),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Não foi possível reverter a venda.')),
      );
    }
  }

  Future<void> enviarWhatsApp(Map<String, dynamic> item) async {
    final texto = Uri.encodeComponent(
      '📱 *${item['marca'] ?? ''} ${item['modelo'] ?? ''}*\n\n'
      '💾 Capacidade: ${item['capacidade'] ?? ''}\n'
      '🎨 Cor: ${item['cor'] ?? ''}\n'
      '🔋 Bateria: ${item['bateria'] ?? ''}%\n'
      '📌 Estado: ${item['estado'] ?? ''}\n\n'
      '💰 Valor: R\$ ${item['valor_venda'] ?? ''}\n\n'
      'Elite Cell Assistência Técnica',
    );

    final url = Uri.parse('https://wa.me/?text=$texto');

    await launchUrl(
      url,
      mode: LaunchMode.externalApplication,
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

  Widget campo(TextEditingController controller, String label) {
    return Padding(
      padding: EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: controller,
        style: TextStyle(color: Colors.white),
        decoration: decoracaoCampo(label),
      ),
    );
  }

  Widget dashboardCard(
    String titulo,
    String valor,
    Color cor,
    IconData icon,
  ) {
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Color(0xFF111111),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: cor),
        boxShadow: [
          BoxShadow(
            color: cor.withOpacity(0.18),
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: cor, size: 26),
          SizedBox(height: 6),
          Text(
            titulo,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white70,
              fontSize: 12,
            ),
          ),
          SizedBox(height: 4),
          Text(
            valor,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: cor,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget dashboardRevenda(List<QueryDocumentSnapshot> docs) {
    double investido = 0;
    double valorVenda = 0;
    double lucro = 0;

    int disponiveis = 0;
    int reservados = 0;
    int vendidos = 0;

    for (var doc in docs) {
      final item = doc.data() as Map<String, dynamic>;

      final compra = converterValor(item['valor_compra']);
      final venda = converterValor(item['valor_venda']);
      final status = item['status'] ?? 'Disponível';

      investido += compra;
      valorVenda += venda;
      lucro += venda - compra;

      if (status == 'Disponível') disponiveis++;
      if (status == 'Reservado') reservados++;
      if (status == 'Vendido') vendidos++;
    }

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 12),
      child: Column(
        children: [
          Text(
            'Dashboard de Revenda',
            style: TextStyle(
              color: dourado,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),

          SizedBox(height: 12),

          GridView.count(
            shrinkWrap: true,
            physics: NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 1.35,
            children: [
              dashboardCard(
                'Investido',
                'R\$ ${investido.toStringAsFixed(0)}',
                Colors.orangeAccent,
                Icons.shopping_cart,
              ),
              dashboardCard(
                'Valor Venda',
                'R\$ ${valorVenda.toStringAsFixed(0)}',
                dourado,
                Icons.attach_money,
              ),
              dashboardCard(
                'Lucro Previsto',
                'R\$ ${lucro.toStringAsFixed(0)}',
                lucro >= 0 ? Colors.greenAccent : Colors.redAccent,
                Icons.trending_up,
              ),
              dashboardCard(
                'Disponíveis',
                '$disponiveis',
                Colors.blueAccent,
                Icons.phone_android,
              ),
              dashboardCard(
                'Reservados',
                '$reservados',
                Colors.orangeAccent,
                Icons.lock,
              ),
              dashboardCard(
                'Vendidos',
                '$vendidos',
                Colors.greenAccent,
                Icons.check_circle,
              ),
            ],
          ),

          SizedBox(height: 15),
        ],
      ),
    );
  }

  void abrirFormulario({String? id, Map<String, dynamic>? item}) {
    preencherFormulario(item);
    final fotoPathOriginal = item?['foto_path']?.toString();

    showDialog(
      context: context,
      builder: (_) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return AlertDialog(
              backgroundColor: Color(0xFF111111),
              title: Text(
                id == null ? 'Cadastrar Celular' : 'Editar Celular',
                style: TextStyle(color: dourado),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    campo(marcaController, 'Marca'),
                    campo(modeloController, 'Modelo'),
                    campo(imeiController, 'IMEI'),
                    campo(estadoController, 'Estado do aparelho'),
                    campo(corController, 'Cor'),
                    campo(capacidadeController, 'Capacidade'),
                    campo(bateriaController, 'Saúde da bateria (%)'),
                    campo(compraController, 'Valor de compra'),
                    campo(vendaController, 'Valor de venda'),
                    campo(observacaoController, 'Observações'),

                    SizedBox(height: 10),

                    if (fotoCelular != null)
                      ClipRRect(
                        borderRadius: BorderRadius.circular(14),
                        child: Image.file(
                          fotoCelular!,
                          height: 150,
                          width: double.infinity,
                          fit: BoxFit.cover,
                        ),
                      )
                    else
                      Container(
                        height: 100,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.black,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: dourado),
                        ),
                        child: Center(
                          child: Text(
                            'Nenhuma foto selecionada',
                            style: TextStyle(color: Colors.white60),
                          ),
                        ),
                      ),

                    SizedBox(height: 10),

                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () async {
                              await escolherFoto(ImageSource.camera);
                              setModalState(() {});
                            },
                            icon: Icon(Icons.camera_alt),
                            label: Text('Câmera'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: dourado,
                              side: BorderSide(color: dourado),
                            ),
                          ),
                        ),
                        SizedBox(width: 8),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () async {
                              await escolherFoto(ImageSource.gallery);
                              setModalState(() {});
                            },
                            icon: Icon(Icons.photo),
                            label: Text('Galeria'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: dourado,
                              side: BorderSide(color: dourado),
                            ),
                          ),
                        ),
                      ],
                    ),

                    SizedBox(height: 12),

                    DropdownButtonFormField<String>(
                      value: statusSelecionado,
                      dropdownColor: Color(0xFF111111),
                      style: TextStyle(color: Colors.white),
                      decoration: decoracaoCampo('Status'),
                      items: [
                        'Disponível',
                        'Reservado',
                        'Vendido',
                      ].map((item) {
                        return DropdownMenuItem(
                          value: item,
                          child: Text(item),
                        );
                      }).toList(),
                      onChanged: (valor) {
                        setState(() {
                          statusSelecionado = valor!;
                        });
                      },
                    ),

                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      activeThumbColor: dourado,
                      title: Text(
                        'Divulgar no catálogo',
                        style: TextStyle(color: Colors.white),
                      ),
                      subtitle: Text(
                        'Exibe o aparelho disponível no catálogo do cliente.',
                        style: TextStyle(color: Colors.white60),
                      ),
                      value: publicadoNoCatalogo,
                      onChanged: (valor) {
                        setModalState(() {
                          publicadoNoCatalogo = valor;
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
                  onPressed: () {
                    if (!validarFormulario()) return;
                    salvarCelular(
                      id: id,
                      fotoPathOriginal: fotoPathOriginal,
                    );
                  },
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
      },
    );
  }

  Future<void> excluirCelular(String id) async {
    try {
      await FirebaseFirestore.instance.runTransaction((transacao) async {
        final documento = await transacao.get(celulares.doc(id));
        final item = documento.data();

        if (item == null || item['empresaId'] != widget.empresaId) {
          throw StateError('Você não tem acesso a este aparelho.');
        }

        if (item['status'] == 'Vendido') {
          throw StateError('Reverta a venda antes de excluir o aparelho.');
        }

        transacao.delete(celulares.doc(id));
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Aparelho excluído.')),
      );
    } on StateError catch (erro) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(erro.message.toString())),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Não foi possível excluir o aparelho.')),
      );
    }
  }

  Future<void> confirmarExclusao(String id) async {
    final confirmou = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Color(0xFF111111),
        title: Text('Excluir aparelho', style: TextStyle(color: dourado)),
        content: Text(
          'Esta ação não poderá ser desfeita.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            child: Text('Excluir'),
          ),
        ],
      ),
    );

    if (confirmou == true) {
      await excluirCelular(id);
    }
  }

  Color corStatus(String status) {
    if (status == 'Vendido') return Colors.greenAccent;
    if (status == 'Reservado') return Colors.orangeAccent;
    return dourado;
  }

  Widget imagemCelular(String fotoPath, Color cor) {
    if (fotoPath.isNotEmpty && File(fotoPath).existsSync()) {
      return ClipRRect(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(18),
        ),
        child: Image.file(
          File(fotoPath),
          height: 180,
          width: double.infinity,
          fit: BoxFit.cover,
        ),
      );
    }

    return Container(
      height: 120,
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(18),
        ),
      ),
      child: Icon(
        Icons.phone_iphone,
        color: cor,
        size: 60,
      ),
    );
  }

  Widget cardCelular(
    String id,
    Map<String, dynamic> item,
  ) {
    final compra = converterValor(item['valor_compra']);
    final venda = converterValor(item['valor_venda']);
    final lucro = venda - compra;
    final status = item['status'] ?? 'Disponível';
    final cor = corStatus(status);
    final fotoPath = (item['foto_path'] ?? '').toString();

    return Card(
      color: Color(0xFF111111),
      elevation: 8,
      shadowColor: cor.withOpacity(0.25),
      margin: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: cor, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          imagemCelular(fotoPath, cor),

          Padding(
            padding: EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${item['marca'] ?? ''} ${item['modelo'] ?? ''}',
                  style: TextStyle(
                    color: cor,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                SizedBox(height: 8),

                Text(
                  'IMEI: ${item['imei'] ?? ''}\n'
                  'Estado: ${item['estado'] ?? ''}\n'
                  'Cor: ${item['cor'] ?? ''}\n'
                  'Capacidade: ${item['capacidade'] ?? ''}\n'
                  'Bateria: ${item['bateria'] ?? ''}%',
                  style: TextStyle(color: Colors.white70),
                ),

                SizedBox(height: 10),

                Text(
                  'Compra: R\$ ${item['valor_compra'] ?? ''}',
                  style: TextStyle(color: Colors.white60),
                ),

                Text(
                  'Venda: R\$ ${item['valor_venda'] ?? ''}',
                  style: TextStyle(
                    color: dourado,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                Text(
                  'Lucro: R\$ ${lucro.toStringAsFixed(2)}',
                  style: TextStyle(
                    color: lucro >= 0 ? Colors.greenAccent : Colors.redAccent,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),

                SizedBox(height: 10),

                Row(
                  children: [
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: cor.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: cor),
                      ),
                      child: Text(
                        status,
                        style: TextStyle(
                          color: cor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),

                    Spacer(),

                    IconButton(
                      icon: Icon(Icons.share, color: dourado),
                      onPressed: () => enviarWhatsApp(item),
                    ),

                    IconButton(
                      icon: Icon(Icons.edit, color: Colors.blueAccent),
                      onPressed: () => abrirFormulario(id: id, item: item),
                    ),

                    if (status != 'Vendido')
                      IconButton(
                        icon: Icon(Icons.delete, color: Colors.redAccent),
                        onPressed: () => confirmarExclusao(id),
                      ),

                    if (status != 'Vendido')
                      IconButton(
                        icon: Icon(Icons.check_circle, color: Colors.greenAccent),
                        onPressed: () => marcarComoVendido(id),
                      ),

                    if (status == 'Vendido')
                      IconButton(
                        icon: Icon(Icons.undo, color: Colors.redAccent),
                        onPressed: () => reverterVenda(id),
                      ),
                  ],
                ),
              ],
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
        title: Text(
          'Celulares Usados',
          style: TextStyle(color: dourado),
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
          Padding(
            padding: EdgeInsets.all(12),
            child: TextField(
              style: TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Pesquisar celular...',
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
              stream: celulares
                  .where('empresaId', isEqualTo: widget.empresaId)
                  .orderBy('data', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return Center(
                    child: CircularProgressIndicator(color: dourado),
                  );
                }

                final todos = snapshot.data!.docs;

                final dados = todos.where((doc) {
                  final item = doc.data() as Map<String, dynamic>;

                  return (item['marca'] ?? '')
                          .toString()
                          .toLowerCase()
                          .contains(busca) ||
                      (item['modelo'] ?? '')
                          .toString()
                          .toLowerCase()
                          .contains(busca) ||
                      (item['imei'] ?? '')
                          .toString()
                          .toLowerCase()
                          .contains(busca) ||
                      (item['status'] ?? '')
                          .toString()
                          .toLowerCase()
                          .contains(busca) ||
                      (item['capacidade'] ?? '')
                          .toString()
                          .toLowerCase()
                          .contains(busca) ||
                      (item['cor'] ?? '')
                          .toString()
                          .toLowerCase()
                          .contains(busca);
                }).toList();

                return ListView(
                  children: [
                    dashboardRevenda(todos),

                    if (dados.isEmpty)
                      Padding(
                        padding: EdgeInsets.all(30),
                        child: Center(
                          child: Text(
                            'Nenhum celular cadastrado',
                            style: TextStyle(color: Colors.white70),
                          ),
                        ),
                      )
                    else
                      ...dados.map((doc) {
                        final item = doc.data() as Map<String, dynamic>;
                        return cardCelular(doc.id, item);
                      }).toList(),
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
