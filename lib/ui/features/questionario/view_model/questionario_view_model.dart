import 'package:flutter/material.dart';
import '../../../../data/repositories/activity_repository.dart';

class QuestionarioViewModel extends ChangeNotifier {
  final ActivityRepository _repository = ActivityRepository();
  bool isLoading = false;

  Future<bool> salvaQuestionario({
    required String activityId,
    String? umore,
    bool? percorsoHaRilassato,
    List<String>? elementiApprezzati,
  }) async {
    isLoading = true;
    notifyListeners();

    try {
      final Map<String, dynamic> dati = {};
      if (umore != null) dati['umoreFineAttivita'] = umore;
      if (percorsoHaRilassato != null)
        dati['percorsoHaRilassato'] = percorsoHaRilassato;
      if (elementiApprezzati != null && elementiApprezzati.isNotEmpty) {
        dati['elementiApprezzati'] = elementiApprezzati;
      }

      // aggiorna l'attività solo se l'utente ha inserito almeno un feedback
      if (dati.isNotEmpty) {
        await _repository.aggiornaQuestionario(activityId, dati);
      }
      return true;
    } catch (e) {
      debugPrint("Errore salvataggio questionario: $e");
      return false;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }
}
