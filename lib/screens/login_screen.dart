import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'dashboard_screen.dart';

class LoginScreen extends StatefulWidget {
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final emailController = TextEditingController();
  final senhaController = TextEditingController();

  bool carregando = false;

  final Color dourado = Color(0xFFD4AF37);

  Future<void> entrar() async {
    setState(() {
      carregando = true;
    });

    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: emailController.text.trim(),
        password: senhaController.text.trim(),
      );

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => DashboardScreen(),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao entrar. Verifique e-mail e senha.'),
        ),
      );
    }

    setState(() {
      carregando = false;
    });
  }

  Future<void> cadastrarFuncionario() async {
    setState(() {
      carregando = true;
    });

    try {
      await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: emailController.text.trim(),
        password: senhaController.text.trim(),
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Usuário cadastrado com sucesso'),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao cadastrar usuário'),
        ),
      );
    }

    setState(() {
      carregando = false;
    });
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
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,

      body: Center(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(24),

          child: Column(
            children: [
              Image.asset(
                'assets/images/elite_cell_logo.png',
                height: 150,
              ),

              SizedBox(height: 10),

              Text(
                'ELITE CELL',
                style: TextStyle(
                  color: dourado,
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                ),
              ),

              SizedBox(height: 4),

              Text(
                'Assistência Técnica',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 16,
                  letterSpacing: 1,
                ),
              ),

              SizedBox(height: 35),

              TextField(
                controller: emailController,
                style: TextStyle(color: Colors.white),
                decoration: campoDecoracao('E-mail'),
              ),

              SizedBox(height: 14),

              TextField(
                controller: senhaController,
                obscureText: true,
                style: TextStyle(color: Colors.white),
                decoration: campoDecoracao('Senha'),
              ),

              SizedBox(height: 24),

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
                        child: Text(
                          'ENTRAR',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),

                    SizedBox(height: 12),

                    TextButton(
                      onPressed: cadastrarFuncionario,
                      child: Text(
                        'Cadastrar usuário',
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