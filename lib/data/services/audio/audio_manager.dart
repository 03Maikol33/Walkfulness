import 'package:audioplayers/audioplayers.dart';
import 'package:walkfulness/data/services/audio/tts_service.dart';

class AudioManager {
  //Voce TTS
  final AudioGuideService _tts = AudioGuideService();
  //musica ambientale
  final AudioPlayer _ambientPlayer = AudioPlayer();

  double _volumeBase = 0.4;

  bool _isSpeaking = false;

  Future<void> inizializza() async {
    await _tts.inizializza();
    await _ambientPlayer.setReleaseMode(
      ReleaseMode.loop,
    ); // loop per la musica
  }

  void impostaStatoVoce(bool stato) {
    _tts.impostaStato(stato);
  }


  Future<void> avviaSottofondoNaturale(String nomeFile) async {
    await _ambientPlayer.setVolume(_volumeBase);
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

  Future<void> parla(String testo) async {
    if (_isSpeaking) return;

    _isSpeaking = true;
    //abbassa musica ambientale
    await _ambientPlayer.setVolume(_volumeBase * 0.2);
    await _tts.parla(testo);
    await _ambientPlayer.setVolume(_volumeBase);
    _isSpeaking = false;
  }

  Future<void> fermaTutto() async {
    await _tts.ferma();
    await _ambientPlayer.stop();
  }
}
