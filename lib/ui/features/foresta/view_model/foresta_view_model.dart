import 'package:flutter/material.dart';
import 'package:walkfulness/data/repositories/user_repository.dart';
import 'package:walkfulness/data/services/frase_service.dart';
import 'package:walkfulness/domain/models/user_model.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ForestaViewModel extends ChangeNotifier {
  //final AuthService _authService = AuthService();
  final UserRepository _userRepository = UserRepository();
  UserModel? _utente;
  bool isLoading = false;

  get livelloCalcolato => _utente?.livelloCalcolato ?? 1;
  get percentualeProgresso => _utente?.percentualeLivello ?? 0.0;
  get frase => FraseService().frase();

  Future<void> inizializza() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      isLoading = true;
      notifyListeners();
      try {
        await FraseService().inizializza();
        _utente = await _userRepository.getUserData(user.uid);
      } catch (e) {
        print("Errore Home: $e");
      } finally {
        isLoading = false;
        notifyListeners();
      }
    }
  }
}
