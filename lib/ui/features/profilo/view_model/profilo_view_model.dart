import 'package:flutter/material.dart';
import '../../../../data/services/auth_service.dart';

class ProfiloViewModel extends ChangeNotifier {
  final AuthService _authService = AuthService();
  //final UserRepository _userRepository = UserRepository();

  //UserModel? _utente;
  bool isLoading = false;

  //String nomeUtente = 'Nome Utente';
  //String emailUtente = 'email@example.com';

  //getters per la view
  //I getter ora leggono direttamente dall'oggetto _utente
  // Se _utente è null (es. durante il caricamento), mostrano un valore di default
  /*String get nome => _utente?.nome ?? "Nome Utente";
  String get email => _utente?.email ?? "email@example.com";
  String get kmPercorsi => _utente?.kmPercorsi.toString() ?? '0';
  String get livelloForesta => _utente?.livelloForesta.toString() ?? '1';
  int get livelloCalcolato => _utente?.livelloCalcolato ?? 1;
  double get percentualeProgresso => _utente?.percentualeLivello ?? 0.0;
  String get oreInNatura => _utente?.oreInNatura.toString() ?? '0';*/
  // _utente != null ? _utente!.kmPercorsi.toString() : '0';

  //funzione per caricare i dati dell'utente loggato, da chiamare all'interno del ProfiloView
  /*Future<void> caricaDatiUtente() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      isLoading = true;
      notifyListeners(); //così la view sa che deve mostrare un indicatore di caricamento
      try {
        //recupera i dati dell'utente dall nostra repository, che a sua volta li recupera da Firestore
        print("Recupero dati utente per UID: ${user.uid}");
        _utente = await _userRepository.getUserData(user.uid);
        print("Dati utente recuperati: ${_utente?.nome}, ${_utente?.email}");
      } catch (e) {
        print("Errore durante il recupero dei dati utente: $e");
      } finally {
        isLoading = false;
        notifyListeners(); //così la view sa che può mostrare i dati
      }
    }
  }*/

  Future<void> disconnetti() async {
    await _authService.logout();
  }
}
