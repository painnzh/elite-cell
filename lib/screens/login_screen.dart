import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'dashboard_screen.dart';
import 'cadastro_empresa_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final emailController = TextEditingController();
  final senhaController = TextEditingController();

  bool carregando = false;
  final Color dourado = const Color(0xFFD4AF37);

  Future<void> entrar() async {
    if (carregando) return;

    setState(() => carregando = true);

    try {
      final credencial =
          await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: emailController.text.trim(),
        password: senhaController.text,
      );

      final usuario = credencial.user;

      if (usuario == null) {
        throw Exception('Usuário não encontrado.');
      }

      final consulta = await FirebaseFirestore.instance
          .collection('empresas')
          .where('uidDono', isEqualTo: usuario.uid)
          .limit(1)
          .get();

      if (!mounted) return;

      if (consulta.docs.isEmpty) {
        await FirebaseAuth.instance.signOut();
        mostrarMensagem(
          'Empresa não encontrada. Entre em contato com o suporte.',
        );
        return;
      }

      final empresa = consulta.docs.first.data();
      final status = empresa['status']?.toString().toLowerCase();

      if (status != 'ativo') {
        await FirebaseAuth.instance.signOut();
        mostrarMensagem(
          'Assinatura pendente ou inativa. Regularize seu pagamento.',
        );
        return;
      }

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => DashboardScreen()),
      );
    } on FirebaseAuthException catch (e) {
      mostrarMensagem(
        e.code == 'invalid-credential' ||
                e.code == 'wrong-password' ||
                e.code == 'user-not-found'
            ? 'E-mail ou senha incorretos.'
            : 'Não foi possível entrar. Verifique sua conexão.',
      );
    } catch (e) {
      mostrarMensagem(
        'Não foi possível verificar a assinatura. Tente novamente.',
      );
    } finally {
      if (mounted) setState(() => carregando = false);
    }
  }

  void mostrarMensagem(String mensagem) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(mensagem)),
    );
  }

  void abrirCadastroEmpresa() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const CadastroEmpresaScreen(),
      ),
    );
  }

  InputDecoration campoDecoracao(String label) {
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

  @override
  void dispose() {
    emailController.dispose();
    senhaController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Image.asset(
                'assets/images/elite_cell_logo.png',
                height: 150,
              ),
              const SizedBox(height: 10),
              Text(
                'ELITE CELL',
                style: TextStyle(
                  color: dourado,
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Assistência Técnica',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 16,
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(height: 35),
              TextField(
                controller: emailController,
                keyboardType: TextInputType.emailAddress,
                style: const TextStyle(color: Colors.white),
                decoration: campoDecoracao('E-mail'),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: senhaController,
                obscureText: true,
                style: const TextStyle(color: Colors.white),
                decoration: campoDecoracao('Senha'),
                onSubmitted: (_) => entrar(),
              ),
              const SizedBox(height: 24),
              if (carregando)
                CircularProgressIndicator(color: dourado)
              else
                Column(
                  children: [
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: entrar,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: dourado,
                          foregroundColor: Colors.black,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: const Text(
                          'ENTRAR',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextButton(
                      onPressed: abrirCadastroEmpresa,
                      child: Text(
                        'Cadastrar minha empresa',
                        style: TextStyle(color: dourado),
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}