import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../screens/configuracoes_empresa_screen.dart';
import '../screens/login_screen.dart';
import '../screens/suporte_screen.dart';

class MenuLateralPremium extends StatelessWidget {
  const MenuLateralPremium({super.key, required this.empresaId});

  final String empresaId;

  Future<void> _abrirImei() async {
    await launchUrl(
      Uri.parse('https://www.imei.info/'),
      mode: LaunchMode.externalApplication,
    );
  }

  Future<void> _sair(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
    if (!context.mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (_) => false,
    );
  }

  void _abrir(BuildContext context, Widget tela) {
    Navigator.pop(context);
    Navigator.push(context, MaterialPageRoute(builder: (_) => tela));
  }

  @override
  Widget build(BuildContext context) {
    const dourado = Color(0xFFD4AF37);
    final configuracao = FirebaseFirestore.instance
        .collection('empresas')
        .doc(empresaId)
        .collection('configuracoes')
        .doc('geral');
    return Drawer(
      child: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: configuracao.snapshots(),
        builder: (context, snapshot) {
          final dados = snapshot.data?.data() ?? {};
          final nome = dados['nomeEmpresa']?.toString().trim();
          final logoUrl = dados['logoUrl']?.toString() ?? '';
          return ListView(
            padding: EdgeInsets.zero,
            children: [
              DrawerHeader(
                decoration: const BoxDecoration(color: Color(0xFF111111)),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 30,
                      backgroundColor: dourado,
                      backgroundImage: logoUrl.isNotEmpty
                          ? NetworkImage(logoUrl)
                          : null,
                      child: logoUrl.isEmpty
                          ? const Icon(
                              Icons.storefront,
                              color: Colors.black,
                              size: 32,
                            )
                          : null,
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            nome?.isNotEmpty == true ? nome! : 'Elite Cell',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: dourado,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            dados['telefone']?.toString() ??
                                'Configurações da empresa',
                            style: const TextStyle(color: Colors.white70),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              _item(
                context,
                Icons.business,
                'Perfil da empresa',
                ConfiguracoesEmpresaScreen(empresaId: empresaId),
              ),
              _item(
                context,
                Icons.settings_outlined,
                'Configurações',
                ConfiguracoesEmpresaScreen(
                  empresaId: empresaId,
                  secaoInicial: SecaoConfiguracao.geral,
                ),
              ),
              _item(
                context,
                Icons.palette_outlined,
                'Personalização',
                ConfiguracoesEmpresaScreen(
                  empresaId: empresaId,
                  secaoInicial: SecaoConfiguracao.personalizacao,
                ),
              ),
              _item(
                context,
                Icons.flag_outlined,
                'Meta e valores',
                ConfiguracoesEmpresaScreen(
                  empresaId: empresaId,
                  secaoInicial: SecaoConfiguracao.meta,
                ),
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.support_agent_outlined),
                title: const Text('Suporte'),
                onTap: () => _abrir(context, const SuporteScreen()),
              ),
              ListTile(
                leading: const Icon(Icons.qr_code_scanner_outlined),
                title: const Text('Consulta IMEI'),
                onTap: _abrirImei,
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.logout, color: Colors.redAccent),
                title: const Text('Sair da conta'),
                onTap: () => _sair(context),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _item(
    BuildContext context,
    IconData icone,
    String titulo,
    Widget tela,
  ) {
    return ListTile(
      leading: Icon(icone),
      title: Text(titulo),
      onTap: () => _abrir(context, tela),
    );
  }
}
