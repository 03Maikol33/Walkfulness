import 'package:flutter/material.dart';
import 'package:walkfulness/domain/models/percorso_model.dart';
import 'package:walkfulness/data/repositories/percorso_repository.dart';

class MieiPercorsiViewModel extends ChangeNotifier {
  final PercorsoRepository _repository = PercorsoRepository();

  // Liste interne
  List<PercorsoModel> _tuttiIPercorsi = [];
  List<PercorsoModel> percorsiVisibili = [];

  bool isLoading = true;
  String? errorMessage;

  bool visualizzaPubblici = false;

  //carica dati
  Future<void> caricaMieiPercorsi(String userId) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners(); //mostra caricamenmto

    try {
      _tuttiIPercorsi = await _repository.getMieiPercorsi(userId);
      _applicaFiltro(); // Suddivide i dati in base al filtro attivo
    } catch (e) {
      errorMessage = "Si è verificato un errore durante il caricamento.";
      debugPrint("Errore ViewModel: $e");
    } finally {
      isLoading = false;
      notifyListeners(); // nasconde caricamento
    }
  }

  //Gestione filtro privati/pubblici
  void cambiaFiltro(bool mostraPubblici) {
    if (visualizzaPubblici == mostraPubblici) return;

    visualizzaPubblici = mostraPubblici;
    _applicaFiltro();
    notifyListeners(); // Aggiorna la UI
  }

  void _applicaFiltro() {
    if (visualizzaPubblici) {
      percorsiVisibili = _tuttiIPercorsi
          .where((p) => p.isPublic == true)
          .toList();
    } else {
      percorsiVisibili = _tuttiIPercorsi
          .where((p) => p.isPublic == false)
          .toList();
    }
  }

  // Elimina percorso
  Future<bool> eliminaPercorso(String percorsoId) async {
    // chiede alla repo di eliminare il percorso su Firebase
    final successo = await _repository.eliminaPercorso(percorsoId);

    if (successo) {
      // se Firebase lo ha eliminato si toglie anche dalla lista locale
      _tuttiIPercorsi.removeWhere((p) => p.id == percorsoId);
      _applicaFiltro();
      notifyListeners();
      return true;
    } else {
      return false;
    }
  }

  Future<void> toggleVisibilita(PercorsoModel percorso) async {
    final nuovoStato = !percorso.isPublic;
    final successo = await _repository.cambiaVisibilita(
      percorso.id!,
      nuovoStato,
    );

    if (successo) {
      // Aggiorniamo l'oggetto nella nostra lista locale per riflettere il cambio in UI
      final index = _tuttiIPercorsi.indexWhere((p) => p.id == percorso.id);
      if (index != -1) {
        _tuttiIPercorsi[index].isPublic = nuovoStato;
        _applicaFiltro();
        notifyListeners();
      }
    }
  }
}
