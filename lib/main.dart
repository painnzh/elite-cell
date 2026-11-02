import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';

import 'screens/login_screen.dart';
import 'theme/tema_empresa_controller.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp();

  runApp(const EliteCellApp());
}

class EliteCellApp extends StatelessWidget {
  const EliteCellApp({super.key});

  @override
  Widget build(BuildContext context) {
    const dourado = Color(0xFFD4AF37);
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: temaEmpresaController,
      builder: (_, tema, _) => MaterialApp(
        debugShowCheckedModeBanner: false,
        themeMode: tema,
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(
            seedColor: dourado,
            brightness: Brightness.light,
          ),
          appBarTheme: const AppBarTheme(centerTitle: true),
          inputDecorationTheme: const InputDecorationTheme(
            border: OutlineInputBorder(),
          ),
        ),
        darkTheme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(
            seedColor: dourado,
            brightness: Brightness.dark,
            surface: const Color(0xFF111111),
          ),
          scaffoldBackgroundColor: Colors.black,
          appBarTheme: const AppBarTheme(
            backgroundColor: Colors.black,
            foregroundColor: dourado,
            centerTitle: true,
          ),
        ),
        home: const LoginScreen(),
      ),
    );
  }
}
