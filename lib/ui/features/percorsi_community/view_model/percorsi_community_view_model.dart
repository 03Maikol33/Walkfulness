import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:walkfulness/domain/models/percorso_model.dart';
import 'package:walkfulness/data/repositories/percorso_repository.dart';
import 'package:walkfulness/data/services/location/location_utils.dart';

class PercorsiCommunityViewModel extends ChangeNotifier {
  final PercorsoRepository _repository = PercorsoRepository();

  List<PercorsoModel> percorsiVisibili = [];
  bool isLoading = true;
  String? errorMessage;
  Position? _posizioneAttuale;

  // Stato dei filtri inseriti dall'utente
  String cittaRicercata = "";
  String tagSelezionato = "";

  // Tag disponibili per l'interfaccia
  final List<String> tagDisponibili = [
    "Natura",
    "Città",
    "Montagna",
    "Relax",
    "Sport",
    "Cultura",
    "Mare",
    "Lago",
    "Fiume",
    "Bosco",
  ];

  Future<void> inizializza() async {
    await _ottieniPosizioneUtente();
    await eseguiRicerca();
  }

  // Chiamata esplicita quando l'utente preme invio o clicca un tag
  Future<void> eseguiRicerca() async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      //SCARICA DAL SERVER GIA' FILTRATI (Città + Tag)
      List<PercorsoModel> scaricati = await _repository.getPercorsiCommunity(
        citta: cittaRicercata,
        tag: tagSelezionato,
      );

      //ORDINA LOCALMENTE PER DISTANZA
      if (_posizioneAttuale != null && scaricati.isNotEmpty) {
        final posUtente = GeoPoint(
          _posizioneAttuale!.latitude,
          _posizioneAttuale!.longitude,
        );

        scaricati.sort((a, b) {
          if (a.tappe.isEmpty && b.tappe.isEmpty) return 0;
          if (a.tappe.isEmpty) return 1;
          if (b.tappe.isEmpty) return -1;

          final pA = GeoPoint(a.tappe.first['lat'], a.tappe.first['lon']);
          final pB = GeoPoint(b.tappe.first['lat'], b.tappe.first['lon']);

          final distA = LocationUtils.calcolaDistanza(posUtente, pA);
          final distB = LocationUtils.calcolaDistanza(posUtente, pB);

          return distA.compareTo(distB);
        });
      }

      percorsiVisibili = scaricati;
    } catch (e) {
      errorMessage = "Errore nel caricamento.";
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _ottieniPosizioneUtente() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return;

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) return;
      }
      if (permission == LocationPermission.deniedForever) return;

      _posizioneAttuale = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
    } catch (e) {
      debugPrint("Errore geolocalizzazione: $e");
    }
  }

  // Azioni UI
  void impostaCitta(String citta) {
    cittaRicercata = citta;
    eseguiRicerca();
  }

  void selezionaTag(String tag) {
    // Se premo lo stesso tag lo deseleziono
    if (tagSelezionato == tag) {
      tagSelezionato = "";
    } else {
      tagSelezionato = tag;
    }
    eseguiRicerca();
  }
}
