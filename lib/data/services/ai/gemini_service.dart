import 'dart:convert';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_ai/firebase_ai.dart' hide LatLng;
import 'package:latlong2/latlong.dart';

class GeminiService {
  late final GenerativeModel _model;

  GeminiService() {
    // Si aggancia automaticamente a Firebase tramite il provider Gemini Developer API
    _model = FirebaseAI.googleAI().generativeModel(
      model: 'gemini-3-flash-preview',
    );
  }

  Future<Map<String, dynamic>?> generaPercorso({
    required LatLng partenza,
    required String umore,
    required String meteo,
    required List<String> poiVicini,
    required List<String> tagAmbiente,
    required String noteAggiuntive,
  }) async {
    final prompt =
        '''
    Sei una guida esperta di camminate e mindfulness. 
    L'utente si trova a queste coordinate di partenza: Lat ${partenza.latitude}, Lon ${partenza.longitude}.
    Il suo stato d'animo è: "$umore".
    Il meteo attuale è: "$meteo".
    Punti di interesse nei dintorni: ${poiVicini.isEmpty ? "Nessuno in particolare" : poiVicini.join(", ")}.
    Preferenze ambientali scelte dall'utente: ${tagAmbiente.isEmpty ? "Nessuna" : tagAmbiente.join(", ")}.
    Richieste specifiche dell'utente: "${noteAggiuntive.isEmpty ? "Nessuna nota aggiuntiva" : noteAggiuntive}".

    Crea un PERCORSO SU MISURA composto da 3 a 5 tappe (waypoints) basato strettamente sulle sue richieste, sull'umore e sul meteo. 
    Il percorso deve essere coerente e percorribile a piedi. 
    La prima tappa deve essere molto vicina al punto di partenza. Le tappe successive devono formare un itinerario logico verso una destinazione. 
    Tieni in altissima considerazione le "Richieste specifiche dell'utente" per decidere i luoghi delle tappe.

    DEVI ASSOLUTAMENTE RISPONDERE SOLO CON UN OGGETTO JSON CON QUESTA STRUTTURA ESATTA:
    {
      "titolo_percorso": "Un titolo accattivante per l'itinerario",
      "messaggio_motivazionale": "Una frase che spiega perché questo percorso rispetta le sue richieste",
      "tappe": [
        {
          "nome": "Nome specifico del luogo o della via (es. Ingresso Parco)",
          "latitudine": 42.1234,
          "longitudine": 13.1234
        },
        {
          "nome": "Seconda tappa",
          "latitudine": 42.1245,
          "longitudine": 13.1250
        }
      ]
    }
    ''';

    try {
      final response = await _model.generateContent([Content.text(prompt)]);
      final testoRisposta = response.text;

      if (testoRisposta != null) {
        final cleanText = testoRisposta
            .replaceAll('```json', '')
            .replaceAll('```', '')
            .trim();
        final dati = json.decode(cleanText);
        return dati;
      }
    } catch (e) {
      print("[GEMINI SERVICE] Errore Generazione AI: $e");
    }
    return null;
  }
}
