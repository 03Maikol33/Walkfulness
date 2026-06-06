import 'package:flutter/material.dart';
import '../../../../domain/models/activity_model.dart';
import '../../../../data/repositories/activity_repository.dart';

class StoricoAttivitaViewModel extends ChangeNotifier {
  final ActivityRepository _repository = ActivityRepository();

  List<ActivityModel> attivitaList = [];
  bool isLoading = true;
  String? errorMessage;

  Future<void> caricaStorico(String userId) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      attivitaList = await _repository.getStoricoUtente(userId);
    } catch (e) {
      errorMessage = "Errore durante il caricamento dello storico.";
      debugPrint("Errore Storico: $e");
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }
}
