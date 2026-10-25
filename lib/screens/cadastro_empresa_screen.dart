import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class CadastroEmpresaScreen extends StatefulWidget {
  const CadastroEmpresaScreen({super.key});

  @override
  State<CadastroEmpresaScreen> createState() =>
      _CadastroEmpresaScreenState();
}

class _CadastroEmpresaScreenState extends State<CadastroEmpresaScreen> {
  final nomeController = TextEditingController();
  final emailController = TextEditingController();
  final senhaController = TextEditingController();
  final confirmarSenhaController = TextEditingController();

  final Color dourado = const Color(0xFFD4AF37);
  bool carregando = false;

  void mensagem(String texto) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(texto)),
    );
  }


  Future<void> cadastrar() async {
    if (carregando) return;

    final nome = nomeController.text.trim();
    final email = emailController.text.trim();
    final senha = senhaController.text;
    final confirmarSenha = confirmarSenhaController.text;

    if (nome.isEmpty ||
        email.isEmpty ||
        senha.isEmpty ||
        confirmarSenha.isEmpty) {
      mensagem('Preencha todos os campos.');
      return;
    }

    if (senha.length < 6) {
      mensagem('A senha precisa ter pelo menos 6 caracteres.');
      return;
    }

    if (senha != confirmarSenha) {
      mensagem('As senhas não coincidem.');
      return;
    }

    setState(() => carregando = true);

    UserCredential? credencial;
    bool dadosSalvos = false;

    try {
      credencial = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(
        email: email,
        password: senha,
      );

      final usuario = credencial.user;

      if (usuario == null) {
        throw Exception('Não foi possível criar a conta.');
      }

      await FirebaseFirestore.instance
          .collection('empresas')
          .doc(usuario.uid)
          .set({
        'nome': nome,
        'email': email,
        'usuarioId': usuario.uid,
        'uidDono': usuario.uid,
        'status': 'pendente',
        'statusAssinatura': 'pendente',
        'plano': 'mensal',
        'valorMensal': 19.90,
        'criadoEm': FieldValue.serverTimestamp(),
      });

      dadosSalvos = true;

      if (!mounted) return;

      mensagem(
        'Conta criada! A assinatura está pendente de confirmação.',
      );

      Navigator.pop(context);
    } on FirebaseAuthException catch (e) {
      if (credencial?.user != null && !dadosSalvos) {
        try {
          await credencial!.user!.delete();
        } catch (_) {}
      }

      if (e.code == 'email-already-in-use') {
        mensagem('Este e-mail já está cadastrado.');
      } else if (e.code == 'weak-password') {
        mensagem('Escolha uma senha mais forte.');
      } else if (e.code == 'invalid-email') {
        mensagem('Digite um e-mail válido.');
      } else {
        mensagem('Não foi possível criar a conta.');
      }
    } catch (e) {
      if (credencial?.user != null && !dadosSalvos) {
        try {
          await credencial!.user!.delete();
        } catch (_) {}
      }

      mensagem(
        'Não foi possível concluir o cadastro. '
        'Verifique a conexão e tente novamente.',
      );
    } finally {
      if (mounted) {
        setState(() => carregando = false);
      }
    }
  }

  InputDecoration decoracao(String texto) {
    return InputDecoration(
      labelText: texto,
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
    nomeController.dispose();
    emailController.dispose();
    senhaController.dispose();
    confirmarSenhaController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: dourado,
        title: const Text('Cadastrar assistência'),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Icon(
                Icons.storefront,
                size: 70,
                color: dourado,
              ),
              const SizedBox(height: 12),
              Text(
                'ELITE CELL',
                style: TextStyle(
                  color: dourado,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Plano mensal: R\$ 19,90',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 28),
              TextField(
                controller: nomeController,
                style: const TextStyle(color: Colors.white),
                decoration: decoracao('Nome da assistência'),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: emailController,
                keyboardType: TextInputType.emailAddress,
                style: const TextStyle(color: Colors.white),
                decoration: decoracao('E-mail'),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: senhaController,
                obscureText: true,
                style: const TextStyle(color: Colors.white),
                decoration: decoracao('Senha'),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: confirmarSenhaController,
                obscureText: true,
                style: const TextStyle(color: Colors.white),
                decoration: decoracao('Confirmar senha'),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: carregando ? null : cadastrar,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: dourado,
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: carregando
                      ? const CircularProgressIndicator(
                          color: Colors.black,
                        )
                      : const Text(
                          'CRIAR CONTA',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
