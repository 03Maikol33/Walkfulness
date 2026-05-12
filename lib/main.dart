// lib/main.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:walkfulness/ui/features/attivita/view/attivita_view.dart';
import 'package:walkfulness/ui/features/crea_tu/view/crea_tu_view.dart';
import 'package:walkfulness/ui/features/main_wrapper/view_model/main_wrapper_view_model.dart';
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
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => UserProvider()),
        ChangeNotifierProvider(
          create: (_) => MainWrapperViewModel(),
        ), // Ora è globale!
      ],
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
        // mostra la schermata giusta in base allo stato di autenticazione
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }

          if (snapshot.hasData) {
            //se c'è un utente loggato, mostro la schermata principale
            // L'utente è loggato. Diciamo al provider di caricare i dati una volta sola.
            // Usiamo Future.microtask per evitare errori di build
            Future.microtask(() {
              if (context.mounted) {
                //devo anche controllare se il contesto è ancora montato prima di chiamare il provider
                //perché potrebbe capitare che l'utente durante l'attesa chiuda la schermata ...
                context.read<UserProvider>().caricaUtente();
              }
            });
            return const MainWrapperView();
          }

          return const LoginView();
        },
      ),
      routes: {
        "/login": (context) => const LoginView(),
        "/main": (context) => const MainWrapperView(),
        "/attivita": (context) => const AttivitaView(),
        "/crea_tu": (context) => const CreaTuView(),
      },
    );
  }
}
