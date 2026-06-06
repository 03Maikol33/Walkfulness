// lib/ui/features/tribu/view_model/tribu_view_model.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:walkfulness/data/repositories/tribu_repository.dart';
import 'package:walkfulness/domain/models/iniziativa_model.dart';

enum TipoFiltroTribu { tutte, mie, partecipo }

class TribuViewModel extends ChangeNotifier {
  final TribuRepository _repository = TribuRepository();

  List<IniziativaModel> _tutteIniziative = [];
  List<IniziativaModel> iniziativeFiltrate = [];

  bool isLoading = true;
  String searchQuery = "";
  TipoFiltroTribu filtroAttuale = TipoFiltroTribu.tutte;

  String? get currentUserId => FirebaseAuth.instance.currentUser?.uid;

  Future<void> caricaIniziative() async {
    isLoading = true;
    notifyListeners();

    try {
      _tutteIniziative = await _repository.getIniziative();
      applicaFiltri();
    } catch (e) {
      debugPrint("Errore caricamento: $e");
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  void impostaRicerca(String query) {
    searchQuery = query;
    applicaFiltri();
  }

  void impostaFiltro(TipoFiltroTribu filtro) {
    filtroAttuale = filtro;
    applicaFiltri();
  }

  void applicaFiltri() {
    final uid = currentUserId;
    iniziativeFiltrate = _tutteIniziative.where((i) {
      // 1. Filtro Ricerca
      bool matchRicerca =
          i.luogo.toLowerCase().contains(searchQuery.toLowerCase()) ||
          i.titolo.toLowerCase().contains(searchQuery.toLowerCase());
      if (!matchRicerca) return false;

      // 2. Filtro Tab
      if (filtroAttuale == TipoFiltroTribu.mie) return i.creatoreId == uid;
      if (filtroAttuale == TipoFiltroTribu.partecipo)
        return i.partecipantiIds.contains(uid) && i.creatoreId != uid;

      return true; // TipoFiltroTribu.tutte
    }).toList();
    notifyListeners();
  }

  // --- AZIONI ---
  Future<void> partecipa(String id) async {
    if (currentUserId != null) {
      await _repository.partecipaIniziativa(id, currentUserId!);
      await caricaIniziative();
    }
  }

  Future<void> abbandona(String id) async {
    if (currentUserId != null) {
      await _repository.abbandonaIniziativa(id, currentUserId!);
      await caricaIniziative();
    }
  }

  Future<void> elimina(String id) async {
    await _repository.eliminaIniziativa(id);
    await caricaIniziative();
  }
}
