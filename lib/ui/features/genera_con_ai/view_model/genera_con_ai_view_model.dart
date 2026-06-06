import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:walkfulness/data/services/POI/poi_service.dart';
import 'package:walkfulness/data/services/ai/gemini_service.dart';
import 'package:walkfulness/data/services/location/routing_service.dart';
import 'package:walkfulness/data/services/meteo_service.dart';
import 'package:walkfulness/ui/features/crea_tu/view_model/crea_tu_view_model.dart';

class GeneraConAiViewModel extends ChangeNotifier {
  final GeminiService _geminiService = GeminiService();
  final MeteoService _meteoService = MeteoService();

  bool isLoading = false;
  Future<List<PinModel>?> generaItinerario(
      String? moodSelezionato,
      List<String> tagSelezionati,
      String noteAggiuntive
    ) async {

    isLoading = true;
    notifyListeners();

    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) throw Exception("Servizio GPS disabilitato.");

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw Exception("Permessi GPS negati.");
        }
      }
      if (permission == LocationPermission.deniedForever) {
        throw Exception("Permessi GPS negati permanentemente.");
      }

      Position pos = await Geolocator.getCurrentPosition();
      LatLng partenza = LatLng(pos.latitude, pos.longitude);

      String meteo = await _meteoService.ottieniCondizioniAttuali(partenza);

      final rispostaAI = await _geminiService.generaPercorso(
        partenza: partenza,
        umore: moodSelezionato!,
        meteo: meteo,
        poiVicini: [],
        tagAmbiente: tagSelezionati,
        noteAggiuntive: noteAggiuntive,
      );

      if (rispostaAI != null && rispostaAI['tappe'] != null) {
        List<dynamic> tappeJson = rispostaAI['tappe'];
        return tappeJson
            .map(
              (t) => PinModel(
                coordinate: LatLng(t['latitudine'], t['longitudine']),
                nome: t['nome'],
                tipoRottaVersoProssimo: TipoRouting.automatico,
              ),
            )
            .toList();
      }
    } catch (e) {
      debugPrint("Errore generazione AI: $e");
    } finally {
      isLoading = false;
      notifyListeners();
    }
    return null;
  }
}
