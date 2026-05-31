import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class TecnicosScreen extends StatefulWidget {
  @override
  State<TecnicosScreen> createState() => _TecnicosScreenState();
}

class _TecnicosScreenState extends State<TecnicosScreen> {
  final Color dourado = Color(0xFFD4AF37);

  final nomeController = TextEditingController();
  final metaController = TextEditingController();

  final tecnicos = FirebaseFirestore.instance.collection('tecnicos');

  Future<void> salvarTecnico() async {
    await tecnicos.add({
      'nome': nomeController.text,
      'meta_mensal': metaController.text,
      'data': DateTime.now(),
    });

    nomeController.clear();
    metaController.clear();

    Navigator.pop(context);
  }

  Future<void> excluirTecnico(String id) async {
    await tecnicos.doc(id).delete();
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

  void abrirFormulario() {
    showDialog(
      context: context,
      builder: (_) {
        return AlertDialog(
          backgroundColor: Color(0xFF111111),
          title: Text(
            'Novo Técnico',
            style: TextStyle(color: dourado),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nomeController,
                style: TextStyle(color: Colors.white),
                decoration: decoracaoCampo('Nome do técnico'),
              ),
              SizedBox(height: 12),
              TextField(
                controller: metaController,
                style: TextStyle(color: Colors.white),
                keyboardType: TextInputType.number,
                decoration: decoracaoCampo('Meta mensal R\$'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancelar', style: TextStyle(color: Colors.white70)),
            ),
            ElevatedButton(
              onPressed: salvarTecnico,
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

  double converterValor(dynamic valor) {
    return double.tryParse(valor.toString().replaceAll(',', '.')) ?? 0;
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
          'Técnicos',
          style: TextStyle(color: dourado),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: dourado,
        foregroundColor: Colors.black,
        onPressed: abrirFormulario,
        child: Icon(Icons.add),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: tecnicos.orderBy('nome').snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return Center(child: CircularProgressIndicator(color: dourado));
          }

          final dados = snapshot.data!.docs;

          if (dados.isEmpty) {
            return Center(
              child: Text(
                'Nenhum técnico cadastrado',
                style: TextStyle(color: Colors.white70),
              ),
            );
          }

          return ListView.builder(
            itemCount: dados.length,
            itemBuilder: (context, index) {
              final doc = dados[index];
              final item = doc.data() as Map<String, dynamic>;

              final meta = converterValor(item['meta_mensal']);

              return Card(
                color: Color(0xFF111111),
                margin: EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                  side: BorderSide(color: dourado),
                ),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: dourado,
                    child: Icon(Icons.engineering, color: Colors.black),
                  ),
                  title: Text(
                    item['nome'] ?? '',
                    style: TextStyle(
                      color: dourado,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  subtitle: Text(
                    'Meta mensal: R\$ ${meta.toStringAsFixed(2)}',
                    style: TextStyle(color: Colors.white70),
                  ),
                  trailing: IconButton(
                    icon: Icon(Icons.delete, color: Colors.redAccent),
                    onPressed: () => excluirTecnico(doc.id),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}