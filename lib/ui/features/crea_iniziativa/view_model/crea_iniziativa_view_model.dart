import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:walkfulness/data/repositories/tribu_repository.dart';
import 'package:walkfulness/domain/models/iniziativa_model.dart';

class CreaIniziativaViewModel extends ChangeNotifier {
  final TribuRepository _repository = TribuRepository();
  bool isLoading = false;

  Future<void> salvaIniziativa({
    String? idEsistente,
    required String titolo,
    required String descrizione,
    required String obiettivo,
    required int maxPartecipanti,
    required DateTime dataOra,
    required String luogo,
    required GeoPoint posizione,
    required String immagineCopertina,
  }) async {
    isLoading = true;
    notifyListeners();

    try {
      final user = FirebaseAuth.instance.currentUser;
      final modello = IniziativaModel(
        id: idEsistente ?? '',
        creatoreId: user?.uid ?? '',
        nomeCreatore: "${user?.displayName ?? 'Utente'}",
        titolo: titolo,
        descrizione: descrizione,
        obiettivo: obiettivo,
        maxPartecipanti: maxPartecipanti,
        dataOra: dataOra,
        luogo: luogo,
        posizione: posizione,
        immagineCopertina: immagineCopertina,
        // mantiene i partecipanti se stai aggiornando Se è nuova la lista parte vuota.
        partecipantiIds: idEsistente == null ? [user?.uid ?? ''] : [],
      );

      if (idEsistente != null) {
        await _repository.aggiornaIniziativa(idEsistente, modello);
      } else {
        await _repository.creaIniziativa(modello);
      }
    } catch (e) {
      debugPrint("Errore salvataggio: $e");
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }
}
