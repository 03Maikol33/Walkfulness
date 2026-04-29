// lib/main.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:walkfulness/ui/features/attivita/view/attivita_view.dart';
import 'ui/core/providers/user_provider.dart';
import 'ui/core/theme/app_theme.dart';
import 'ui/features/main_wrapper/view/main_wrapper_view.dart';
import 'ui/features/login/view/login_view.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  FlutterForegroundTask.initCommunicationPort();
  await Firebase.initializeApp();

  runApp(
    ChangeNotifierProvider(
      create: (_) => UserProvider(), // Non chiamare caricaUtente qui
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Walkfulness',
      theme: WalkfulnessTheme.lightTheme,
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }

          if (snapshot.hasData) {
            // L'utente è loggato. Diciamo al provider di caricare i dati una volta sola.
            // Usiamo Future.microtask per evitare errori di build
            Future.microtask(() => context.read<UserProvider>().caricaUtente());
            return const MainWrapperView();
          }

          return const LoginView();
        },
      ),
      routes: {
        "/login": (context) => const LoginView(),
        "/main": (context) => const MainWrapperView(),
        "/attivita": (context) => const AttivitaView(),
      },
    );
  }
}
