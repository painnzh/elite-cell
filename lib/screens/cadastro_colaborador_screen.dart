import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../services/acesso_empresa_service.dart';
import 'dashboard_screen.dart';

class CadastroColaboradorScreen extends StatefulWidget {
  const CadastroColaboradorScreen({super.key});

  @override
  State<CadastroColaboradorScreen> createState() => _CadastroColaboradorScreenState();
}

class _CadastroColaboradorScreenState extends State<CadastroColaboradorScreen> {
  final _email = TextEditingController();
  final _senha = TextEditingController();
  bool _salvando = false;

  Future<void> _criarAcesso() async {
    if (_salvando) return;
    setState(() => _salvando = true);
    try {
      await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _email.text.trim(),
        password: _senha.text,
      );
      final acesso = await AcessoEmpresaService().acessoAtual();
      if (acesso == null) {
        await FirebaseAuth.instance.signOut();
        throw StateError('Não há convite ativo para este e-mail. Peça ao responsável da assistência para convidá-lo primeiro.');
      }
      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => DashboardScreen(empresaId: acesso.empresaId, papel: acesso.papel)),
        (_) => false,
      );
    } on FirebaseAuthException catch (erro) {
      _mensagem(erro.code == 'email-already-in-use'
          ? 'Este e-mail já possui uma conta. Use a tela de login.'
          : 'Não foi possível criar o acesso. Confira o e-mail e use uma senha com ao menos 6 caracteres.');
    } catch (erro) {
      _mensagem(erro.toString().replaceFirst('Bad state: ', ''));
    } finally {
      if (mounted) setState(() => _salvando = false);
    }
  }

  void _mensagem(String texto) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(texto)));

  @override
  void dispose() { _email.dispose(); _senha.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Ativar acesso de colaborador')),
        body: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(children: [
            const Text('Use exatamente o e-mail que recebeu o convite da assistência.'),
            const SizedBox(height: 20),
            TextField(controller: _email, keyboardType: TextInputType.emailAddress, decoration: const InputDecoration(labelText: 'E-mail convidado')),
            const SizedBox(height: 12),
            TextField(controller: _senha, obscureText: true, decoration: const InputDecoration(labelText: 'Crie sua senha')),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _salvando ? null : _criarAcesso,
              icon: const Icon(Icons.verified_user_outlined),
              label: Text(_salvando ? 'Ativando...' : 'Ativar meu acesso'),
            ),
          ]),
        ),
      );
}
