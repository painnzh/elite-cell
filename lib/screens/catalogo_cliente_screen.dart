import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class CatalogoClienteScreen extends StatelessWidget {
  CatalogoClienteScreen({super.key});

  final Color dourado = const Color(0xFFD4AF37);

  final celulares =
      FirebaseFirestore.instance.collection('celulares_usados');

  Future<void> enviarWhatsApp(
    Map<String, dynamic> item,
  ) async {
    final texto = Uri.encodeComponent(
      'Olá! Tenho interesse no aparelho:\n\n'
      '${item['marca']} ${item['modelo']}\n'
      'Capacidade: ${item['capacidade']}\n'
      'Cor: ${item['cor']}\n'
      'Preço: R\$ ${item['valor_venda']}',
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
      );
    }

    return Container(
      height: 220,
      color: Colors.black,
      child: Center(
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
        title: Text(
          'Catálogo Elite Cell',
          style: TextStyle(color: dourado),
        ),
      ),

      body: StreamBuilder<QuerySnapshot>(
        stream: celulares.snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return Center(
              child: CircularProgressIndicator(
                color: dourado,
              ),
            );
          }

          final aparelhos = snapshot.data!.docs.where((doc) {
            final item = doc.data() as Map<String, dynamic>;
            return item['status'] == 'Disponível';
          }).toList();

          if (aparelhos.isEmpty) {
            return Center(
              child: Text(
                'Nenhum aparelho disponível',
                style: TextStyle(color: Colors.white),
              ),
            );
          }

          return ListView.builder(
            itemCount: aparelhos.length,
            itemBuilder: (context, index) {
              final doc = aparelhos[index];
              final item =
                  doc.data() as Map<String, dynamic>;

              return Card(
                color: const Color(0xFF111111),
                margin: const EdgeInsets.all(12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                  side: BorderSide(color: dourado),
                ),
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    ClipRRect(
                      borderRadius:
                          const BorderRadius.vertical(
                        top: Radius.circular(20),
                      ),
                      child: foto(
                        item['foto_path'] ?? '',
                      ),
                    ),

                    Padding(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${item['marca']} ${item['modelo']}',
                            style: TextStyle(
                              color: dourado,
                              fontSize: 22,
                              fontWeight:
                                  FontWeight.bold,
                            ),
                          ),

                          const SizedBox(height: 10),

                          Text(
                            '💾 ${item['capacidade']}',
                            style: const TextStyle(
                              color: Colors.white,
                            ),
                          ),

                          Text(
                            '🎨 ${item['cor']}',
                            style: const TextStyle(
                              color: Colors.white,
                            ),
                          ),

                          Text(
                            '🔋 ${item['bateria']}%',
                            style: const TextStyle(
                              color: Colors.white,
                            ),
                          ),

                          const SizedBox(height: 12),

                          Text(
                            'R\$ ${item['valor_venda']}',
                            style: TextStyle(
                              color: Colors.greenAccent,
                              fontSize: 28,
                              fontWeight:
                                  FontWeight.bold,
                            ),
                          ),

                          const SizedBox(height: 12),

                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              style:
                                  ElevatedButton.styleFrom(
                                backgroundColor:
                                    Colors.green,
                              ),
                              onPressed: () =>
                                  enviarWhatsApp(item),
                              icon: const Icon(
                                Icons.chat,
                                color: Colors.white,
                              ),
                              label: const Text(
                                'Tenho Interesse',
                                style: TextStyle(
                                  color: Colors.white,
                                ),
                              ),
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
}