import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class ClientesScreen extends StatefulWidget {
  @override
  State<ClientesScreen> createState() => _ClientesScreenState();
}

class _ClientesScreenState extends State<ClientesScreen> {
  final Color dourado = Color(0xFFD4AF37);

  final nomeController = TextEditingController();
  final telefoneController = TextEditingController();
  final emailController = TextEditingController();
  final observacaoController = TextEditingController();

  String busca = '';

  final clientes = FirebaseFirestore.instance.collection('clientes');

  Future<void> salvarCliente() async {
    await clientes.add({
      'nome': nomeController.text,
      'telefone': telefoneController.text,
      'email': emailController.text,
      'observacao': observacaoController.text,
      'data': DateTime.now(),
    });

    nomeController.clear();
    telefoneController.clear();
    emailController.clear();
    observacaoController.clear();

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
            'Novo Cliente',
            style: TextStyle(color: dourado),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                campoFormulario(nomeController, 'Nome'),
                campoFormulario(telefoneController, 'Telefone'),
                campoFormulario(emailController, 'E-mail'),
                campoFormulario(observacaoController, 'Observações'),
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
              onPressed: salvarCliente,
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

  void abrirDetalhes(Map<String, dynamic> cliente, String id) {
    final nomeEdit = TextEditingController(text: cliente['nome'] ?? '');
    final telefoneEdit = TextEditingController(text: cliente['telefone'] ?? '');
    final emailEdit = TextEditingController(text: cliente['email'] ?? '');
    final obsEdit = TextEditingController(text: cliente['observacao'] ?? '');

    showDialog(
      context: context,
      builder: (_) {
        return AlertDialog(
          backgroundColor: Color(0xFF111111),
          title: Text(
            'Detalhes do Cliente',
            style: TextStyle(color: dourado),
          ),
          content: SingleChildScrollView(
            child: Column(
              children: [
                CircleAvatar(
                  radius: 34,
                  backgroundColor: dourado,
                  child: Icon(
                    Icons.person,
                    color: Colors.black,
                    size: 38,
                  ),
                ),

                SizedBox(height: 18),

                campoFormulario(nomeEdit, 'Nome'),
                campoFormulario(telefoneEdit, 'Telefone'),
                campoFormulario(emailEdit, 'E-mail'),
                campoFormulario(obsEdit, 'Observações'),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () async {
                await clientes.doc(id).delete();
                Navigator.pop(context);
              },
              child: Text(
                'Excluir',
                style: TextStyle(color: Colors.redAccent),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                await clientes.doc(id).update({
                  'nome': nomeEdit.text,
                  'telefone': telefoneEdit.text,
                  'email': emailEdit.text,
                  'observacao': obsEdit.text,
                  'atualizado_em': DateTime.now(),
                });

                Navigator.pop(context);
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
                  'CLIENTES',
                  style: TextStyle(
                    color: dourado,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2,
                  ),
                ),

                SizedBox(height: 4),

                Text(
                  'Cadastro e gerenciamento',
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
                hintText: 'Pesquisar cliente...',
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
              stream: clientes.snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return Center(
                    child: CircularProgressIndicator(color: dourado),
                  );
                }

                final dados = snapshot.data!.docs.where((doc) {
                  final cliente = doc.data() as Map<String, dynamic>;

                  return (cliente['nome'] ?? '')
                          .toString()
                          .toLowerCase()
                          .contains(busca) ||
                      (cliente['telefone'] ?? '')
                          .toString()
                          .toLowerCase()
                          .contains(busca) ||
                      (cliente['email'] ?? '')
                          .toString()
                          .toLowerCase()
                          .contains(busca);
                }).toList();

                if (dados.isEmpty) {
                  return Center(
                    child: Text(
                      'Nenhum cliente encontrado',
                      style: TextStyle(color: Colors.white70),
                    ),
                  );
                }

                return ListView.builder(
                  itemCount: dados.length,
                  itemBuilder: (context, index) {
                    final doc = dados[index];
                    final cliente = doc.data() as Map<String, dynamic>;

                    return GestureDetector(
                      onTap: () => abrirDetalhes(cliente, doc.id),
                      child: Card(
                        elevation: 8,
                        shadowColor: dourado.withOpacity(0.3),
                        color: Color(0xFF111111),
                        margin: EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 7,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                          side: BorderSide(color: dourado, width: 1),
                        ),
                        child: ListTile(
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          leading: CircleAvatar(
                            backgroundColor: dourado,
                            child: Icon(
                              Icons.person,
                              color: Colors.black,
                            ),
                          ),
                          title: Text(
                            cliente['nome'] ?? '',
                            style: TextStyle(
                              color: dourado,
                              fontWeight: FontWeight.bold,
                              fontSize: 17,
                            ),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SizedBox(height: 4),
                              Text(
                                cliente['telefone'] ?? '',
                                style: TextStyle(color: Colors.white70),
                              ),
                              if ((cliente['email'] ?? '').toString().isNotEmpty)
                                Text(
                                  cliente['email'] ?? '',
                                  style: TextStyle(
                                    color: Colors.white54,
                                    fontSize: 12,
                                  ),
                                ),
                            ],
                          ),
                          trailing: Icon(
                            Icons.edit,
                            color: dourado,
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