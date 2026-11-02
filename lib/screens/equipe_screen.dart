import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../services/acesso_empresa_service.dart';

class EquipeScreen extends StatefulWidget {
  const EquipeScreen({super.key, required this.empresaId});
  final String empresaId;

  @override
  State<EquipeScreen> createState() => _EquipeScreenState();
}

class _EquipeScreenState extends State<EquipeScreen> {
  final _service = AcessoEmpresaService();

  Future<void> _convidar() async {
    final email = TextEditingController();
    var papel = 'tecnico';
    final resultado = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, atualizar) => AlertDialog(
          title: const Text('Convidar colaborador'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: email,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(labelText: 'E-mail'),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: papel,
                decoration: const InputDecoration(labelText: 'Perfil'),
                items: AcessoEmpresaService.papeis
                    .map((item) => DropdownMenuItem(
                          value: item,
                          child: Text(item[0].toUpperCase() + item.substring(1)),
                        ))
                    .toList(),
                onChanged: (valor) => atualizar(() => papel = valor!),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
            FilledButton(
              onPressed: () async {
                try {
                  await _service.convidar(
                    empresaId: widget.empresaId,
                    email: email.text,
                    papel: papel,
                  );
                  if (context.mounted) Navigator.pop(context, true);
                } catch (erro) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(erro.toString().replaceFirst('ArgumentError: ', ''))),
                    );
                  }
                }
              },
              child: const Text('Convidar'),
            ),
          ],
        ),
      ),
    );
    email.dispose();
    if (resultado == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Convite salvo. O colaborador poderá criar a conta com este e-mail.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Equipe e acessos')),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: _convidar,
          icon: const Icon(Icons.person_add_alt_1),
          label: const Text('Convidar'),
        ),
        body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: _service.membros(widget.empresaId),
          builder: (context, snapshot) {
            if (snapshot.hasError) return const Center(child: Text('Não foi possível carregar a equipe.'));
            if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
            final membros = snapshot.data!.docs;
            if (membros.isEmpty) {
              return const Center(child: Padding(
                padding: EdgeInsets.all(24),
                child: Text('Nenhum colaborador convidado. Convide pelo e-mail para liberar um perfil de acesso.'),
              ));
            }
            return ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: membros.length,
              separatorBuilder: (_, __) => const Divider(),
              itemBuilder: (_, index) {
                final dados = membros[index].data();
                return ListTile(
                  leading: const CircleAvatar(child: Icon(Icons.person_outline)),
                  title: Text(dados['email']?.toString() ?? ''),
                  subtitle: Text('${dados['papel']} • ${dados['status']}'),
                  trailing: Icon(
                    dados['status'] == 'ativo' ? Icons.verified_outlined : Icons.mail_outline,
                  ),
                );
              },
            );
          },
        ),
      );
}
