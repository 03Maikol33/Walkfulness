import 'package:flutter/material.dart';
import '../../../../data/services/auth_service.dart';

class LoginViewModel extends ChangeNotifier {
  final AuthService _authService = AuthService();
  
  bool isLoading = false;
  String? errorMessage;

  Future<bool> accedi(String email, String password) async {
    isLoading = true;
    errorMessage = null; // Resetta l'errore precedente
    notifyListeners();

    final user = await _authService.login(email, password);

    isLoading = false;
    if (user == null) {
      errorMessage = "Email o password errati.";
    }
    
    notifyListeners();
    return user != null;
  }
}