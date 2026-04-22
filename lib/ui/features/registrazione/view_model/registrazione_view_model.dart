import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../data/services/auth_service.dart';
import '../../../../data/repositories/user_repository.dart';
import '../../../../domain/models/user_model.dart';

class RegistrazioneViewModel extends ChangeNotifier {
  final AuthService _authService = AuthService();
  final UserRepository _userRepository = UserRepository();
  bool isLoading = false;
  String? errorMessage;

  Future<bool> registra({
    required String email,
    required String password,
    required String confermaPassword,
    required String nome,
  }) async {
    // 1. Validazione delle password
    if (password != confermaPassword) {
      errorMessage = "Le password non coincidono.";
      notifyListeners();
      return false;
    }

    if (nome.isEmpty || email.isEmpty || password.isEmpty) {
      errorMessage = "Compila tutti i campi.";
      notifyListeners();
      return false;
    }

    isLoading = true;
    errorMessage = null;
    notifyListeners(); 

    try {
      // 2. Registrazione su Firebase Auth
      final user = await _authService.register(email, password);

      if (user != null) {
        final nuovoUtente = UserModel(
          uid: user.uid,
          nome: nome,
          email: email,
          // 'kmPercorsi': 0, Valori di default
          // 'livelloForesta': 1, Valori di default
          //'oreInNatura': 0, Valori di default
        );

        await _userRepository.createUser(nuovoUtente);

        isLoading = false;
        notifyListeners();
        return true;
      }
    } on FirebaseAuthException catch (e) {
      // 2. GESTIONE CODICI ERRORE SPECIFICI
      //non arriva mai a questo punto, sembra che FirebaseAuthException non venga catturata, forse è un problema di import o di versione del pacchetto
      if (e.code == 'email-already-in-use') {
        errorMessage = "L'indirizzo email è già in uso.";
      } else if (e.code == 'weak-password') {
        errorMessage = "La password fornita è troppo debole.";
      } else if (e.code == 'invalid-email') {
        errorMessage = "L'indirizzo email non è valido.";
      } else {
        errorMessage = "Si è verificato un errore durante la registrazione.";
      }
    } catch (e) {
      errorMessage = "Errore imprevisto.";
    }

    isLoading = false;
    notifyListeners();
    return false;
  }
}
