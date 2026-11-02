import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class SuporteScreen extends StatelessWidget {
  const SuporteScreen({super.key});

  Future<void> _abrirWhatsApp() async {
    await launchUrl(
      Uri.parse('https://wa.me/5565993571837'),
      mode: LaunchMode.externalApplication,
    );
  }

  @override
  Widget build(BuildContext context) {
    final dourado = const Color(0xFFD4AF37);
    return Scaffold(
      appBar: AppBar(title: const Text('Suporte')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Icon(Icons.support_agent, size: 68, color: dourado),
          const SizedBox(height: 16),
          Text(
            'Como podemos ajudar?',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 24),
          const ListTile(
            leading: Icon(Icons.menu_book_outlined),
            title: Text('Uso básico'),
            subtitle: Text(
              'Cadastre clientes, OS e estoque pelos módulos da tela inicial.',
            ),
          ),
          const ListTile(
            leading: Icon(Icons.security_outlined),
            title: Text('Segurança'),
            subtitle: Text(
              'Nunca compartilhe sua senha ou dados sensíveis de clientes.',
            ),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: _abrirWhatsApp,
            icon: const Icon(Icons.chat),
            label: const Text('Falar com o suporte'),
          ),
        ],
      ),
    );
  }
}
