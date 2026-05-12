import 'package:flutter_tts/flutter_tts.dart';

class AudioGuideService {
  final FlutterTts _flutterTts = FlutterTts();
  bool _isAttiva = true;

  Future<void> inizializza() async {
    await _flutterTts.setLanguage("it-IT");
    await _flutterTts.setSpeechRate(0.4); // Velocità lenta e rilassante
    await _flutterTts.setPitch(0.8);

    await _flutterTts.awaitSpeakCompletion(
      true,
    ); //blocca il codice finché non ha finito di parlare
    await _impostaVoceMigliore();
  }

  Future<void> _impostaVoceMigliore() async {
    try {
      List<dynamic> voices = await _flutterTts.getVoices;

      //solo le voci in italiano
      List<dynamic> vociItaliane = voices
          .where((v) => v["locale"] == "it-IT")
          .toList();

      if (vociItaliane.isNotEmpty) {
        var voceMigliore = vociItaliane.firstWhere(
          (v) => v["name"].toString().contains("network"),
          orElse: () => vociItaliane.first, // Fallback alla prima disponibile
        );

        await _flutterTts.setVoice({
          "name": voceMigliore["name"],
          "locale": voceMigliore["locale"],
        });
      }
    } catch (e) {
      print("Impossibile impostare la voce migliore: $e");
    }
  }

  void impostaStato(bool attiva) {
    _isAttiva = attiva;
  }

  bool get isAttiva => _isAttiva;

  Future<void> parla(String testo) async {
    if (!_isAttiva) return; // Se l'utente l'ha disattivata, tace.
    await _flutterTts.speak(testo);
  }

  Future<void> ferma() async {
    await _flutterTts.stop();
  }
}
