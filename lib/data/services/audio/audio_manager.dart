import 'package:audioplayers/audioplayers.dart';
import 'package:walkfulness/data/services/audio/tts_service.dart';

class AudioManager {
  // Livello 2 e 3 (Voce TTS)
  final AudioGuideService _tts = AudioGuideService();
  // Livello 1 (Musica Ambientale)
  final AudioPlayer _ambientPlayer = AudioPlayer();

  bool _isSpeaking = false;

  Future<void> inizializza() async {
    await _tts.inizializza();
    await _ambientPlayer.setReleaseMode(
      ReleaseMode.loop,
    ); // La musica riparte da capo all'infinito
  }

  // Permette all'utente di spegnere/accendere la voce
  void impostaStatoVoce(bool stato) {
    _tts.impostaStato(stato);
  }

  // --- LAYER AMBIENTE ---
  Future<void> avviaSottofondoNaturale(String assetPath) async {
    // Esempio: assetPath = 'audio/foresta.mp3'
    // Decommenta quando avrai i file audio reali nel progetto
    // await _ambientPlayer.play(AssetSource(assetPath));
    // await _ambientPlayer.setVolume(0.4); // Volume di base
  }

  Future<void> fermaSottofondo() async {
    await _ambientPlayer.stop();
  }

  // --- LAYER VOCE (Con Ducking) ---
  Future<void> parla(String testo) async {
    if (_isSpeaking) return; // Evita che le frasi si sovrappongano

    _isSpeaking = true;
    //Abbassa la musica ambientale
    await _ambientPlayer.setVolume(0.1);
    //Fai parlare il TTS
    await _tts.parla(testo);
    //Rialza la musica ambientale
    await _ambientPlayer.setVolume(0.4);
    _isSpeaking = false;
  }

  Future<void> fermaTutto() async {
    await _tts.ferma();
    await _ambientPlayer.stop();
  }
}
