import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../../../data/services/auth_service.dart';

class LoginViewModel extends ChangeNotifier {
  final AuthService _authService = AuthService();

  bool isLoading = false;
  String? errorMessage;

  Future<bool> accedi(String email, String password) async {
    isLoading = true;
    errorMessage = null; // resetta l'errore precedente
    notifyListeners();

    try {
      final user = await _authService.login(email, password);

      isLoading = false;
      if (user == null) {
        errorMessage = "Email o password errati.";
      }

      notifyListeners();
      return user != null;
    } on FirebaseAuthException catch (e) {
      isLoading = false;

      if (e.code == 'invalid-credential' ||
          e.code == 'wrong-password' ||
          e.code == 'user-not-found') {
        errorMessage = "Email o password errati.";
      } else if (e.code == 'invalid-email') {
        errorMessage = "Il formato dell'email non è valido.";
      } else if (e.code == 'user-disabled') {
        errorMessage = "Questo account è stato disabilitato.";
      } else {
        errorMessage = "Si è verificato un problema (${e.code}).";
      }
      notifyListeners();
      return false;
    }
  }
}
