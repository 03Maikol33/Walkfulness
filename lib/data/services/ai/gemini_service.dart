import 'dart:convert';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_ai/firebase_ai.dart' hide LatLng;
import 'package:latlong2/latlong.dart';

class GeminiService {
  late final GenerativeModel _model;

  GeminiService() {
    // Si aggancia automaticamente a Firebase tramite il provider Gemini Developer API
    _model = FirebaseAI.googleAI().generativeModel(
      model: 'gemini-3.1-flash-lite',
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

  Future<String?> generaFraseMindful(String nomePoi, LatLng posizione) async {
    final prompt =
        '''
    Sei una guida spirituale e di cammino consapevole. L'utente si trova presso: "$nomePoi" (Coordinate: ${posizione.latitude}, ${posizione.longitude}).
    Scrivi un pensiero profondo di circa 30-40 parole. 
    Non limitarti a descrivere il luogo: invita l'utente a connettere ciò che vede con il proprio stato interiore.
    Usa le coordinate per descrivere l'ambiente circostante a la visione che si ha del punto di interesse $nomePoi.
    Usa un tono calmo, poetico e filosofico. Esplora la percezione del corpo nel luogo.
    Mensiona sempre il nome del punto di interesse per creare un legame tra ambiente e mente.
    IMPORTANTE: Scrivi solo il testo puro per il sintetizzatore vocale, senza formattazioni o emoji.
    REGOLA FONDAMENTALE: Usa le coordinate SOLO per capire l'area geografica in cui si trova l'utente. ASSOLUTAMENTE NON scrivere, pronunciare o menzionare mai i numeri delle coordinate nel testo finale.
    ''';

    try {
      final response = await _model.generateContent([Content.text(prompt)]);
      return response.text?.replaceAll(RegExp(r'[*_~`]'), '')?.trim();
    } catch (e) {
      print("[GEMINI SERVICE] Errore generazione frase mindful: $e");
    }
    return null;
  }

  Future<String?> generaEsercizioRespirazione(
    String statoPasso,
    LatLng posizione,
    String nomePoi,
  ) async {
    final contestoLuogo = nomePoi != null
        ? "vicino al punto di interesse $nomePoi"
        : "in questo ambiente";
    final prompt =
        '''
    Sei una guida di mindfulness. L'utente sta camminando con un passo $statoPasso $contestoLuogo (Posizione: ${posizione.latitude}, ${posizione.longitude}).
    Genera un esercizio di respirazione e consapevolezza di circa 30 parole.
    Collega l'atto del respirare con l'ambiente circostante e la sensazione del movimento nelle gambe. 
    Aiuta l'utente a sentirsi presente nel qui ed ora.
     Usa le coordinate per descrivere l'ambiente circostante a la visione che si ha del punto di interesse $nomePoi.
    Usa un tono calmo, poetico e filosofico. Esplora la percezione del corpo nel luogo.
    Mensiona sempre il nome del punto di interesse per creare un legame tra ambiente e mente.
    IMPORTANTE: Scrivi solo il testo puro, niente markdown.
    REGOLA FONDAMENTALE: Usa le coordinate SOLO per capire l'area geografica in cui si trova l'utente. ASSOLUTAMENTE NON scrivere, pronunciare o menzionare mai i numeri delle coordinate nel testo finale.
    ''';

    try {
      final response = await _model.generateContent([Content.text(prompt)]);
      return response.text?.replaceAll(RegExp(r'[*_~`]'), '')?.trim();
    } catch (e) {
      print("[GEMINI SERVICE] Errore generazione esercizio respirazione: $e");
    }
    return null;
  }

  Future<String?> generaFraseMotivazionale(
    int kmPercorsi,
    LatLng posizione,
    String nomePoi,
  ) async {
    final contestoLuogo = nomePoi != null
        ? "vicino al punto di interesse $nomePoi"
        : "in questo ambiente";
    final prompt =
        '''
   'L' utente ha completato il chilometro numero $kmPercorsi $contestoLuogo (Posizione attuale: ${posizione.latitude}, ${posizione.longitude}).
    Scrivi una riflessione di circa 35 parole sulla costanza e sulla trasformazione che avviene nel corpo e nella mente dopo questa distanza.
    Parla del paesaggio come di uno specchio dell'anima. Rendi il traguardo fisico un'esperienza sensoriale e introspettiva.
    IMPORTANTE: Scrivi solo il testo puro.
    REGOLA FONDAMENTALE: Usa le coordinate SOLO per capire l'area geografica in cui si trova l'utente. ASSOLUTAMENTE NON scrivere, pronunciare o menzionare mai i numeri delle coordinate nel testo finale.
    ''';

    try {
      final response = await _model.generateContent([Content.text(prompt)]);
      return response.text?.replaceAll(RegExp(r'[*_~`]'), '')?.trim();
    } catch (e) {
      print("[GEMINI SERVICE] Errore generazione frase motivazionale: $e");
    }
    return null;
  }
}
