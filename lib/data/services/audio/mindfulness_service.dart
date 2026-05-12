import 'package:latlong2/latlong.dart';
import 'package:walkfulness/data/services/ai/gemini_service.dart';

class MindfulnessService {
  final GeminiService _geminiService = GeminiService();

  Future<String> generaFrasePerPOI(String nomePoi, LatLng posizione) async {
    final fraseAi = await _geminiService.generaFraseMindful(nomePoi, posizione);

    return fraseAi ??
        "Fermati un istante. Sei vicino a $nomePoi. Fai un respiro profondo e ascolta il suono dell'ambiente che ti circonda.";
  }

  Future<String> generaEsercizioRespirazione(
    double velocitaMedia,
    LatLng posizione,
    String nomePoi,
  ) async {
    await Future.delayed(const Duration(seconds: 1));

    final fraseAi = await _geminiService.generaEsercizioRespirazione(
      velocitaMedia > 6.0 ? "veloce" : "lento",
      posizione,
      nomePoi,
    );
    if (fraseAi != null) {
      return fraseAi;
    }
    if (velocitaMedia > 6.0) {
      return "Il tuo passo è molto energico. Sincronizza il respiro: inspira per tre passi, espira per tre passi.";
    } else {
      return "Stai camminando con calma. Porta la tua attenzione sulla pianta del piede che tocca il terreno.";
    }
  }

  Future<String> generaFraseMotivazionale(
    int kmPercorsi,
    LatLng posizione,
    String nomePoi,
  ) async {
    await Future.delayed(const Duration(seconds: 1));

    final fraseAi = await _geminiService.generaFraseMotivazionale(
      kmPercorsi,
      posizione,
      nomePoi,
    );
    if (fraseAi != null) {
      return fraseAi;
    }
    return "Hai percorso ${kmPercorsi.toStringAsFixed(1)} chilometri. Continua così, ogni passo è un piccolo traguardo!";
  }
}
