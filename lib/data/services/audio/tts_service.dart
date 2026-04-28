import 'package:flutter_tts/flutter_tts.dart';

class AudioGuideService {
  final FlutterTts _flutterTts = FlutterTts();
  bool _isAttiva = true;

  Future<void> inizializza() async {
    await _flutterTts.setLanguage("it-IT");
    await _flutterTts.setSpeechRate(0.5); // Velocità moderata e rilassante
    await _flutterTts.setPitch(1.0);
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
