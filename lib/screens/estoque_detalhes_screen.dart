import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class EstoqueDetalhesScreen extends StatefulWidget {
  final Map dados;

  const EstoqueDetalhesScreen({
    super.key,
    required this.dados,
  });

  @override
  State<EstoqueDetalhesScreen> createState() => _EstoqueDetalhesScreenState();
}

class _EstoqueDetalhesScreenState extends State<EstoqueDetalhesScreen> {
  final Color dourado = Color(0xFFD4AF37);

  late TextEditingController nomeController;
  late TextEditingController modeloController;
  late TextEditingController quantidadeController;
  late TextEditingController custoController;
  late TextEditingController vendaController;
  late TextEditingController fornecedorController;

  bool editando = false;

  @override
  void initState() {
    super.initState();

    nomeController = TextEditingController(text: widget.dados['nome'] ?? '');
    modeloController = TextEditingController(text: widget.dados['modelo'] ?? '');
    quantidadeController = TextEditingController(text: widget.dados['quantidade'] ?? '');
    custoController = TextEditingController(text: widget.dados['custo'] ?? '');
    vendaController = TextEditingController(text: widget.dados['venda'] ?? '');
    fornecedorController = TextEditingController(text: widget.dados['fornecedor'] ?? '');
  }

  double converterValor(String valor) {
    return double.tryParse(valor.replaceAll(',', '.')) ?? 0;
  }

  int converterQuantidade(String valor) {
    return int.tryParse(valor) ?? 0;
  }

  double calcularLucro() {
    final custo = converterValor(custoController.text);
    final venda = converterValor(vendaController.text);

    return venda - custo;
  }

  Future<void> salvarAlteracoes() async {
    final id = widget.dados['id'];

    await FirebaseFirestore.instance.collection('estoque').doc(id).update({
      'nome': nomeController.text,
      'modelo': modeloController.text,
      'quantidade': quantidadeController.text,
      'custo': custoController.text,
      'venda': vendaController.text,
      'fornecedor': fornecedorController.text,
      'atualizado_em': DateTime.now(),
    });

    setState(() {
      editando = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Peça atualizada com sucesso'),
      ),
    );
  }

  Future<void> excluirPeca() async {
    final id = widget.dados['id'];

    await FirebaseFirestore.instance.collection('estoque').doc(id).delete();

    Navigator.pop(context);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Peça excluída com sucesso'),
      ),
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
      margin: EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: dourado, width: 1),
      ),
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

  Widget resumoCard(
    IconData icon,
    String titulo,
    String valor,
    Color cor,
  ) {
    return Card(
      color: Color(0xFF111111),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: cor, width: 1),
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: cor,
          child: Icon(
            icon,
            color: Colors.black,
          ),
        ),
        title: Text(
          titulo,
          style: TextStyle(
            color: Colors.white70,
          ),
        ),
        subtitle: Text(
          valor,
          style: TextStyle(
            color: cor,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final lucro = calcularLucro();
    final quantidade = converterQuantidade(quantidadeController.text);
    final estoqueBaixo = quantidade <= 1;
    final corPrincipal = estoqueBaixo ? Colors.redAccent : dourado;

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
        actions: [
          IconButton(
            icon: Icon(Icons.delete, color: Colors.redAccent),
            onPressed: excluirPeca,
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
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: corPrincipal,
                  width: 1.4,
                ),
                boxShadow: [
                  BoxShadow(
                    color: corPrincipal.withOpacity(0.25),
                    blurRadius: 10,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.inventory,
                    size: 52,
                    color: corPrincipal,
                  ),

                  SizedBox(height: 10),

                  Text(
                    nomeController.text,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: corPrincipal,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  SizedBox(height: 6),

                  Text(
                    estoqueBaixo ? 'ESTOQUE BAIXO' : 'EM ESTOQUE',
                    style: TextStyle(
                      color: estoqueBaixo ? Colors.redAccent : Colors.white70,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: 16),

            resumoCard(
              Icons.inventory_2,
              'Quantidade',
              quantidadeController.text,
              corPrincipal,
            ),

            resumoCard(
              Icons.attach_money,
              'Lucro por peça',
              'R\$ ${lucro.toStringAsFixed(2)}',
              lucro >= 0 ? dourado : Colors.redAccent,
            ),

            SizedBox(height: 10),

            campo('Nome da peça', nomeController),
            campo('Modelo compatível', modeloController),
            campo('Quantidade', quantidadeController),
            campo('Valor de custo', custoController),
            campo('Valor de venda', vendaController),
            campo('Fornecedor', fornecedorController),

            SizedBox(height: 20),

            if (editando)
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: salvarAlteracoes,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: dourado,
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: Text(
                    'Salvar alterações',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}