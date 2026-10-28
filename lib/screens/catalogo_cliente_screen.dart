
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class CatalogoClienteScreen extends StatelessWidget {
  final String empresaId;

  CatalogoClienteScreen({
    super.key,
    required this.empresaId,
  });

  final Color dourado = const Color(0xFFD4AF37);

  final CollectionReference<Map<String, dynamic>> celulares =
      FirebaseFirestore.instance.collection('celulares_usados');

  Future<void> enviarWhatsApp(Map<String, dynamic> item) async {
    final texto = Uri.encodeComponent(
      'Olá! Tenho interesse no aparelho:\n\n'
      '${item['marca'] ?? ''} ${item['modelo'] ?? ''}\n'
      'Capacidade: ${item['capacidade'] ?? 'Não informada'}\n'
      'Cor: ${item['cor'] ?? 'Não informada'}\n'
      'Preço: R\$ ${item['valor_venda'] ?? 'Consulte'}',
    );

    final url = Uri.parse(
      'https://wa.me/5565993571837?text=$texto',
    );

    await launchUrl(
      url,
      mode: LaunchMode.externalApplication,
    );
  }

  Widget foto(String path) {
    if (path.isNotEmpty && File(path).existsSync()) {
      return Image.file(
        File(path),
        height: 220,
        width: double.infinity,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return _fotoPadrao();
        },
      );
    }

    return _fotoPadrao();
  }

  Widget _fotoPadrao() {
    return Container(
      height: 220,
      width: double.infinity,
      color: const Color(0xFF111111),
      child: const Center(
        child: Icon(
          Icons.phone_android,
          color: Colors.white54,
          size: 80,
        ),
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
        iconTheme: IconThemeData(color: dourado),
        title: Text(
          'Catálogo Elite Cell',
          style: TextStyle(
            color: dourado,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: celulares
            .where('empresaId', isEqualTo: empresaId)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(
              child: Text(
                'Erro ao carregar o catálogo.',
                style: TextStyle(color: Colors.redAccent),
              ),
            );
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: CircularProgressIndicator(color: dourado),
            );
          }

          final documentos = snapshot.data?.docs ?? [];

          final aparelhos = documentos.where((doc) {
            final item = doc.data();

            return item['empresaId'] == empresaId &&
                item['status'] == 'Disponível' &&
                item['publicadoCatalogo'] == true;
          }).toList();

          if (aparelhos.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'Nenhum aparelho disponível no catálogo.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 16,
                  ),
                ),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.only(bottom: 16),
            itemCount: aparelhos.length,
            itemBuilder: (context, index) {
              final item = aparelhos[index].data();

              return Card(
                color: const Color(0xFF111111),
                margin: const EdgeInsets.all(12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                  side: BorderSide(color: dourado),
                ),
                clipBehavior: Clip.antiAlias,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    foto(item['foto_path']?.toString() ?? ''),
                    Padding(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${item['marca'] ?? ''} ${item['modelo'] ?? ''}',
                            style: TextStyle(
                              color: dourado,
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 12),
                          _detalhe(
                            'Memória',
                            item['capacidade']?.toString() ?? 'Não informada',
                          ),
                          _detalhe(
                            'Cor',
                            item['cor']?.toString() ?? 'Não informada',
                          ),
                          _detalhe(
                            'Bateria',
                            item['bateria'] == null
                                ? 'Não informada'
                                : '${item['bateria']}%',
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'R\$ ${item['valor_venda'] ?? 'Consulte'}',
                            style: const TextStyle(
                              color: Colors.greenAccent,
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 14),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                ),
                              ),
                              onPressed: () => enviarWhatsApp(item),
                              icon: const Icon(Icons.chat),
                              label: const Text('Tenho interesse'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _detalhe(String titulo, String valor) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        '$titulo: $valor',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 15,
        ),
      ),
    );
  }
}
