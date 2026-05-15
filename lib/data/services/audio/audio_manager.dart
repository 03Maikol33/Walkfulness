import 'package:audioplayers/audioplayers.dart';
import 'package:walkfulness/data/services/audio/tts_service.dart';

class AudioManager {
  // Livello 2 e 3 (Voce TTS)
  final AudioGuideService _tts = AudioGuideService();
  // Livello 1 (Musica Ambientale)
  final AudioPlayer _ambientPlayer = AudioPlayer();

  double _volumeBase = 0.4;

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
  Future<void> avviaSottofondoNaturale(String nomeFile) async {
    await _ambientPlayer.setVolume(_volumeBase); // Volume di base morbido
    await _ambientPlayer.play(AssetSource('audio/$nomeFile'));
  }

  void impostaVolumeBase(double volume) {
    _volumeBase = volume;
    if (!_isSpeaking) {
      _ambientPlayer.setVolume(_volumeBase);
    }
  }

  Future<void> fermaSottofondo() async {
    await _ambientPlayer.stop();
  }

  // --- LAYER VOCE (Con Ducking) ---
  Future<void> parla(String testo) async {
    if (_isSpeaking) return; // Evita che le frasi si sovrappongano

    _isSpeaking = true;
    //Abbassa la musica ambientale
    await _ambientPlayer.setVolume(_volumeBase * 0.2);
    //Fai parlare il TTS
    await _tts.parla(testo);
    //Rialza la musica ambientale
    await _ambientPlayer.setVolume(_volumeBase);
    _isSpeaking = false;
  }

  Future<void> fermaTutto() async {
    await _tts.ferma();
    await _ambientPlayer.stop();
  }
}
