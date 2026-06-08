import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:url_launcher/url_launcher.dart';

class OsDetalhesScreen extends StatefulWidget {
  final Map dados;

  const OsDetalhesScreen({
    super.key,
    required this.dados,
  });

  @override
  State<OsDetalhesScreen> createState() => _OsDetalhesScreenState();
}

class _OsDetalhesScreenState extends State<OsDetalhesScreen> {
  final Color dourado = Color(0xFFD4AF37);

  late TextEditingController clienteController;
  late TextEditingController telefoneController;
  late TextEditingController imeiController;
  late TextEditingController marcaController;
  late TextEditingController modeloController;
  late TextEditingController defeitoController;
  late TextEditingController valorController;
  late TextEditingController observacaoController;

  late String status;
  bool editando = false;

  @override
  void initState() {
    super.initState();

    clienteController =
        TextEditingController(text: widget.dados['cliente'] ?? '');
    telefoneController =
        TextEditingController(text: widget.dados['telefone'] ?? '');
    imeiController = TextEditingController(text: widget.dados['imei'] ?? '');
    marcaController = TextEditingController(text: widget.dados['marca'] ?? '');
    modeloController =
        TextEditingController(text: widget.dados['modelo'] ?? '');
    defeitoController =
        TextEditingController(text: widget.dados['defeito'] ?? '');
    valorController = TextEditingController(text: widget.dados['valor'] ?? '');
    observacaoController =
        TextEditingController(text: widget.dados['observacao'] ?? '');

    status = widget.dados['status'] ?? 'Em análise';
  }

  int converterInteiro(dynamic valor) {
    return int.tryParse(valor.toString()) ?? 0;
  }

  Map<String, dynamic> get checklist {
    final dadosChecklist = widget.dados['checklist'];

    if (dadosChecklist is Map) {
      return Map<String, dynamic>.from(dadosChecklist);
    }

    return {};
  }

  String iconeChecklist(dynamic valor) {
    return valor == true ? '✅' : '❌';
  }

  Future<void> baixarEstoqueAutomaticamente() async {
    if (status != 'Entregue') return;
    if (widget.dados['estoque_baixado'] == true) return;

    final String peca = (widget.dados['peca_usada'] ?? '').toString();
    final int quantidadeUsada =
        converterInteiro(widget.dados['quantidade_peca']);

    if (peca.isEmpty || quantidadeUsada <= 0) return;

    final estoqueBusca = await FirebaseFirestore.instance
        .collection('estoque')
        .where('nome', isEqualTo: peca)
        .limit(1)
        .get();

    if (estoqueBusca.docs.isEmpty) return;

    final docEstoque = estoqueBusca.docs.first;
    final dadosEstoque = docEstoque.data();

    final int estoqueAtual = converterInteiro(dadosEstoque['quantidade']);
    final int novoEstoque = estoqueAtual - quantidadeUsada;

    await FirebaseFirestore.instance
        .collection('estoque')
        .doc(docEstoque.id)
        .update({
      'quantidade': novoEstoque < 0 ? '0' : novoEstoque.toString(),
    });
  }

  Future<void> salvarAlteracoes() async {
    final id = widget.dados['id'];

    await baixarEstoqueAutomaticamente();

    await FirebaseFirestore.instance
        .collection('ordens_servico')
        .doc(id)
        .update({
      'cliente': clienteController.text,
      'telefone': telefoneController.text,
      'imei': imeiController.text,
      'marca': marcaController.text,
      'modelo': modeloController.text,
      'defeito': defeitoController.text,
      'valor': valorController.text,
      'observacao': observacaoController.text,
      'status': status,
      'estoque_baixado':
          status == 'Entregue' ? true : widget.dados['estoque_baixado'] ?? false,
      'atualizado_em': DateTime.now(),
    });

    widget.dados['status'] = status;

    if (status == 'Entregue') {
      widget.dados['estoque_baixado'] = true;
    }

    setState(() {
      editando = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('OS atualizada com sucesso')),
    );
  }

  Future<void> excluirOS() async {
    final id = widget.dados['id'];

    await FirebaseFirestore.instance
        .collection('ordens_servico')
        .doc(id)
        .delete();

    Navigator.pop(context);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('OS excluída com sucesso')),
    );
  }

  Future<void> gerarPDF() async {
    final pdf = pw.Document();

    pw.Widget linha(String titulo, String valor) {
      return pw.Padding(
        padding: pw.EdgeInsets.only(bottom: 6),
        child: pw.Row(
          children: [
            pw.Text(
              '$titulo: ',
              style: pw.TextStyle(
                fontSize: 10,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
            pw.Expanded(
              child: pw.Container(
                padding: pw.EdgeInsets.only(bottom: 2),
                decoration: pw.BoxDecoration(
                  border: pw.Border(
                    bottom: pw.BorderSide(width: 0.5),
                  ),
                ),
                child: pw.Text(
                  valor,
                  style: pw.TextStyle(fontSize: 10),
                ),
              ),
            ),
          ],
        ),
      );
    }

    pw.Widget check(String texto) {
      return pw.Container(
        width: 230,
        margin: pw.EdgeInsets.only(bottom: 5),
        child: pw.Row(
          children: [
            pw.Container(
              width: 10,
              height: 10,
              decoration: pw.BoxDecoration(
                border: pw.Border.all(width: 0.8),
              ),
            ),
            pw.SizedBox(width: 6),
            pw.Text(
              texto,
              style: pw.TextStyle(fontSize: 9),
            ),
          ],
        ),
      );
    }

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: pw.EdgeInsets.all(22),
        build: (context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Container(
                width: double.infinity,
                padding: pw.EdgeInsets.all(10),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(width: 1),
                ),
                child: pw.Column(
                  children: [
                    pw.Text(
                      'ELITE CELL',
                      style: pw.TextStyle(
                        fontSize: 24,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.Text(
                      'ASSISTÊNCIA TÉCNICA',
                      style: pw.TextStyle(
                        fontSize: 11,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.SizedBox(height: 6),
                    pw.Text(
                      'ORDEM DE SERVIÇO',
                      style: pw.TextStyle(
                        fontSize: 18,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),

              pw.SizedBox(height: 12),

              pw.Row(
                children: [
                  pw.Text(
                    'OS Nº: ${widget.dados['numero_os'] ?? ''}',
                    style: pw.TextStyle(
                      fontSize: 11,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.Spacer(),
                  pw.Text(
                    'DATA: ____/____/______',
                    style: pw.TextStyle(fontSize: 10),
                  ),
                ],
              ),

              pw.SizedBox(height: 12),

              linha('CLIENTE', clienteController.text),
              linha('TELEFONE', telefoneController.text),
              linha(
                'MARCA / MODELO',
                '${marcaController.text} ${modeloController.text}',
              ),
              linha('IMEI / SÉRIE', imeiController.text),

              pw.SizedBox(height: 8),

              pw.Text(
                'DEFEITO RELATADO',
                style: pw.TextStyle(
                  fontSize: 10,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.Container(
                height: 42,
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(width: 0.5),
                ),
              ),

              pw.SizedBox(height: 10),

              pw.Container(
                width: double.infinity,
                padding: pw.EdgeInsets.all(8),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(width: 0.8),
                ),
                child: pw.Column(
                  children: [
                    pw.Text(
                      'CHECKLIST DE ENTRADA',
                      style: pw.TextStyle(
                        fontSize: 12,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.SizedBox(height: 8),
                    pw.Wrap(
                      spacing: 20,
                      runSpacing: 2,
                      children: [
                        check('Liga'),
                        check('Face ID'),
                        check('Touch funcionando'),
                        check('Biometria'),
                        check('Tela sem manchas'),
                        check('Câmera frontal'),
                        check('Wi-Fi'),
                        check('Câmera traseira'),
                        check('Bluetooth'),
                        check('Microfone'),
                        check('Alto-falante'),
                        check('Conector de carga'),
                        check('Oxidado'),
                        check('Aparelho aberto'),
                      ],
                    ),
                  ],
                ),
              ),

              pw.SizedBox(height: 8),

              pw.Text(
                'OBSERVAÇÕES',
                style: pw.TextStyle(
                  fontSize: 10,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.Container(
                height: 36,
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(width: 0.5),
                ),
              ),

              pw.SizedBox(height: 8),

              pw.Row(
                children: [
                  pw.Expanded(
                    child: pw.Container(
                      padding: pw.EdgeInsets.all(7),
                      decoration: pw.BoxDecoration(
                        border: pw.Border.all(width: 0.7),
                      ),
                      child: pw.Text(
                        'VALOR DO SERVIÇO: R\$ ${valorController.text}',
                        style: pw.TextStyle(
                          fontSize: 10,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  pw.SizedBox(width: 8),
                  pw.Expanded(
                    child: pw.Container(
                      padding: pw.EdgeInsets.all(7),
                      decoration: pw.BoxDecoration(
                        border: pw.Border.all(width: 0.7),
                      ),
                      child: pw.Text(
                        'PREVISÃO: ____/____/______',
                        style: pw.TextStyle(
                          fontSize: 10,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              pw.SizedBox(height: 8),

              pw.Text(
                'TERMO DE GARANTIA: A garantia cobre apenas o serviço executado e/ou peça substituída. Não cobrimos garantia por tela quebrada, trincada, riscada ou arranhada após a entrega, aparelhos com contato com água, umidade ou oxidação, quedas, impactos, mau uso, violação por terceiros ou defeitos não relacionados ao reparo realizado.',
                style: pw.TextStyle(fontSize: 7),
                textAlign: pw.TextAlign.justify,
              ),

              pw.SizedBox(height: 14),

              pw.Row(
                children: [
                  pw.Expanded(
                    child: pw.Column(
                      children: [
                        pw.Text(
                          'ASSINATURA DO CLIENTE',
                          style: pw.TextStyle(fontSize: 8),
                        ),
                        pw.SizedBox(height: 24),
                        pw.Divider(),
                      ],
                    ),
                  ),
                  pw.SizedBox(width: 24),
                  pw.Expanded(
                    child: pw.Column(
                      children: [
                        pw.Text(
                          'ASSINATURA ELITE CELL',
                          style: pw.TextStyle(fontSize: 8),
                        ),
                        pw.SizedBox(height: 24),
                        pw.Divider(),
                      ],
                    ),
                  ),
                ],
              ),

              pw.Spacer(),

              pw.Center(
                child: pw.Text(
                  'OBRIGADO PELA PREFERÊNCIA!',
                  style: pw.TextStyle(
                    fontSize: 10,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (format) async => pdf.save(),
    );
  }

  Future<void> enviarWhatsApp() async {
    final telefone =
        telefoneController.text.replaceAll(RegExp(r'[^0-9]'), '');

    final mensagem = Uri.encodeComponent(
      'Olá ${clienteController.text}, sua OS ${widget.dados['numero_os'] ?? ''} da Elite Cell está com status: $status.\n\n'
      'Aparelho: ${marcaController.text} ${modeloController.text}\n'
      'Defeito: ${defeitoController.text}\n'
      'Valor: R\$ ${valorController.text}\n\n'
      'Obrigado pela preferência!',
    );

    final url = Uri.parse('https://wa.me/55$telefone?text=$mensagem');

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
        borderRadius: BorderRadius.circular(12),
      ),
      focusedBorder: OutlineInputBorder(
        borderSide: BorderSide(color: dourado, width: 2),
        borderRadius: BorderRadius.circular(12),
      ),
    );
  }

  Widget campo(String titulo, TextEditingController controller) {
    if (editando) {
      return Padding(
        padding: EdgeInsets.only(bottom: 12),
        child: TextField(
          controller: controller,
          style: TextStyle(color: Colors.white),
          decoration: decoracaoCampo(titulo),
        ),
      );
    }

    return Card(
      color: Color(0xFF111111),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: dourado, width: 1),
      ),
      margin: EdgeInsets.only(bottom: 12),
      child: ListTile(
        title: Text(
          titulo,
          style: TextStyle(
            color: dourado,
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Text(
          controller.text,
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
          ),
        ),
      ),
    );
  }

  Widget infoCard(String titulo, String valor) {
    if (valor.isEmpty) return SizedBox();

    return Card(
      color: Color(0xFF111111),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: dourado, width: 1),
      ),
      margin: EdgeInsets.only(bottom: 12),
      child: ListTile(
        title: Text(
          titulo,
          style: TextStyle(
            color: dourado,
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Text(
          valor,
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
          ),
        ),
      ),
    );
  }

  Widget itemChecklistTela(String titulo, String chave) {
    final valor = checklist[chave] == true;

    return ListTile(
      dense: true,
      leading: Text(
        iconeChecklist(valor),
        style: TextStyle(fontSize: 18),
      ),
      title: Text(
        titulo,
        style: TextStyle(color: Colors.white),
      ),
      trailing: Text(
        valor ? 'OK' : 'NÃO',
        style: TextStyle(
          color: valor ? Colors.greenAccent : Colors.redAccent,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget checklistTela() {
    if (checklist.isEmpty) {
      return SizedBox();
    }

    return Container(
      width: double.infinity,
      margin: EdgeInsets.only(bottom: 16),
      padding: EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Color(0xFF111111),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: dourado, width: 1.2),
      ),
      child: Column(
        children: [
          Text(
            'CHECKLIST DE ENTRADA',
            style: TextStyle(
              color: dourado,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 8),
          itemChecklistTela('Liga', 'liga'),
          itemChecklistTela('Touch funcionando', 'touch'),
          itemChecklistTela('Tela sem manchas', 'tela'),
          itemChecklistTela('Face ID', 'faceId'),
          itemChecklistTela('Biometria', 'biometria'),
          itemChecklistTela('Câmera frontal', 'cameraFrontal'),
          itemChecklistTela('Câmera traseira', 'cameraTraseira'),
          itemChecklistTela('Wi-Fi', 'wifi'),
          itemChecklistTela('Bluetooth', 'bluetooth'),
          itemChecklistTela('Microfone', 'microfone'),
          itemChecklistTela('Alto-falante', 'altoFalante'),
          itemChecklistTela('Conector de carga', 'conector'),
          itemChecklistTela('Aparelho oxidado', 'oxidado'),
        ],
      ),
    );
  }

  void abrirFoto(String fotoUrl) {
    showDialog(
      context: context,
      builder: (_) {
        return Dialog(
          backgroundColor: Colors.black,
          child: InteractiveViewer(
            child: Image.network(
              fotoUrl,
              fit: BoxFit.contain,
            ),
          ),
        );
      },
    );
  }

  Widget fotoItem(String titulo, String fotoUrl) {
    if (fotoUrl.isEmpty) {
      return SizedBox();
    }

    return GestureDetector(
      onTap: () => abrirFoto(fotoUrl),
      child: Container(
        width: double.infinity,
        margin: EdgeInsets.only(bottom: 16),
        padding: EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Color(0xFF111111),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: dourado, width: 1.2),
        ),
        child: Column(
          children: [
            Text(
              titulo,
              style: TextStyle(
                color: dourado,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: Image.network(
                fotoUrl,
                height: 240,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget galeriaFotos() {
    final fotoFrente =
        (widget.dados['foto_frente_url'] ?? widget.dados['foto_url'] ?? '')
            .toString();

    final fotoTras = (widget.dados['foto_tras_url'] ?? '').toString();
    final fotoImei = (widget.dados['foto_imei_url'] ?? '').toString();
    final fotoAntesDepois =
        (widget.dados['foto_antes_depois_url'] ?? '').toString();

    final existeAlgumaFoto = fotoFrente.isNotEmpty ||
        fotoTras.isNotEmpty ||
        fotoImei.isNotEmpty ||
        fotoAntesDepois.isNotEmpty;

    if (!existeAlgumaFoto) {
      return SizedBox();
    }

    return Column(
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: Text(
            'Fotos do aparelho',
            style: TextStyle(
              color: dourado,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        SizedBox(height: 12),
        fotoItem('Foto frontal', fotoFrente),
        fotoItem('Foto traseira', fotoTras),
        fotoItem('Foto do IMEI', fotoImei),
        fotoItem('Foto antes/depois', fotoAntesDepois),
      ],
    );
  }

  Widget botaoAcao(IconData icon, String texto, VoidCallback acao) {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: ElevatedButton.icon(
        onPressed: acao,
        icon: Icon(icon),
        label: Text(texto),
        style: ElevatedButton.styleFrom(
          backgroundColor: dourado,
          foregroundColor: Colors.black,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final numeroOS = widget.dados['numero_os'] ?? 'Sem número';
    final pecaUsada = (widget.dados['peca_usada'] ?? '').toString();
    final quantidadePeca =
        (widget.dados['quantidade_peca'] ?? '').toString();

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: IconThemeData(color: dourado),
        centerTitle: true,
        title: Text(
          'Detalhes da OS',
          style: TextStyle(color: dourado),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.chat, color: dourado),
            onPressed: enviarWhatsApp,
          ),
          IconButton(
            icon: Icon(Icons.picture_as_pdf, color: dourado),
            onPressed: gerarPDF,
          ),
          IconButton(
            icon: Icon(Icons.delete, color: dourado),
            onPressed: excluirOS,
          ),
          IconButton(
            icon: Icon(
              editando ? Icons.save : Icons.edit,
              color: dourado,
            ),
            onPressed: () {
              if (editando) {
                salvarAlteracoes();
              } else {
                setState(() {
                  editando = true;
                });
              }
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Color(0xFF111111),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: dourado, width: 1.4),
              ),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 35,
                    backgroundColor: dourado,
                    child: Icon(
                      Icons.phone_android,
                      color: Colors.black,
                      size: 40,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    numeroOS,
                    style: TextStyle(
                      color: dourado,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 6),
                  Text(
                    status,
                    style: TextStyle(color: Colors.white70),
                  ),
                ],
              ),
            ),
            SizedBox(height: 16),
            galeriaFotos(),
            checklistTela(),
            infoCard('Peça utilizada', pecaUsada),
            infoCard('Quantidade da peça', quantidadePeca),
            campo('Cliente', clienteController),
            campo('Telefone', telefoneController),
            campo('IMEI', imeiController),
            campo('Marca', marcaController),
            campo('Modelo', modeloController),
            campo('Defeito', defeitoController),
            campo('Valor', valorController),
            campo('Observações', observacaoController),
            SizedBox(height: 10),
            DropdownButtonFormField<String>(
              value: status,
              dropdownColor: Color(0xFF111111),
              style: TextStyle(color: Colors.white),
              decoration: decoracaoCampo('Status'),
              items: [
                'Em análise',
                'Aprovado',
                'Aguardando peça',
                'Em reparo',
                'Pronto',
                'Entregue',
                'Cancelado',
              ].map((item) {
                return DropdownMenuItem(
                  value: item,
                  child: Text(item),
                );
              }).toList(),
              onChanged: editando
                  ? (valor) {
                      if (valor != null) {
                        setState(() {
                          status = valor;
                        });
                      }
                    }
                  : null,
            ),
            SizedBox(height: 20),
            if (editando)
              botaoAcao(
                Icons.save,
                'Salvar alterações',
                salvarAlteracoes,
              ),
          ],
        ),
      ),
    );
  }
}