import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../data/repositories/user_repository.dart';
import '../../../domain/models/user_model.dart';

class UserProvider extends ChangeNotifier {
  final UserRepository _userRepository = UserRepository();
  UserModel? _utente;
  bool _isLoading = false;

  UserModel? get utente => _utente;
  bool get isLoading => _isLoading;

  // Carica i dati una sola volta al login o all'avvio
  Future<void> caricaUtente({bool forceRefresh = false}) async {
    if (!forceRefresh && _utente != null) return;

    final firebaseUser = FirebaseAuth.instance.currentUser;

    if (firebaseUser == null) {
      _utente = null;
      _isLoading = false;
      notifyListeners();
      return;
    }
    //inizio la procedura per ottenere l'utente da firestore
    _isLoading = true;
    notifyListeners();
    try {
      _utente = await _userRepository.getUserData(firebaseUser.uid);
    } catch (e) {
      print("Errore nel caricamento dei dati utente: $e");
      _utente = null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> aggiornaProgressi(double nuoviKm) async {
    final firebaseUser = FirebaseAuth.instance.currentUser;
    if (firebaseUser == null) return;

    try {
      await _userRepository.updateProgress(firebaseUser.uid, nuoviKm);
      // Ricarica i dati aggiornati da Firestore
      await caricaUtente(forceRefresh: true);
    } catch (e) {
      print("Errore nell'aggiornamento progressi: $e");
      rethrow;
    }
  }

  // Pulisce i dati al logout
  void reset() {
    _utente = null;
    _isLoading = false;
    notifyListeners();
  }
}
