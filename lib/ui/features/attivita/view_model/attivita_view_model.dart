import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:latlong2/latlong.dart';
import 'package:walkfulness/data/services/POI/poi_service.dart';
import 'package:walkfulness/data/services/audio/audio_manager.dart';
import 'package:walkfulness/data/services/audio/mindfulness_service.dart';
import 'package:walkfulness/data/services/location/location_service.dart';
import 'package:walkfulness/data/services/location/location_service_base.dart';
import 'package:walkfulness/data/services/location/location_utils.dart';
import 'package:walkfulness/ui/core/providers/user_provider.dart';
import 'package:walkfulness/ui/features/main_wrapper/view_model/main_wrapper_view_model.dart';
import 'package:walkfulness/ui/features/questionario/view/questionario_view.dart';
import '../../../../data/services/location/mock_location_service.dart';
import '../../../../data/repositories/activity_repository.dart';
import '../../../../domain/models/activity_model.dart';
import 'package:walkfulness/data/services/location/routing_service.dart';
import 'package:walkfulness/ui/features/crea_tu/view_model/crea_tu_view_model.dart';

class AttivitaViewModel extends ChangeNotifier {
  LocationServiceBase _locationService =
      LocationService(); // o MockLocationService()
  final PoiService _poiService = PoiService();
  final AudioManager audioManager = AudioManager();
  final MindfulnessService _mindfulness = MindfulnessService();
  //final AudioGuideService audioGuideService = AudioGuideService();
  final ActivityRepository _activityRepository = ActivityRepository();
  final RoutingService _routingService = RoutingService();
  List<PinModel> tappePianificate = [];
  List<LatLng> percorsoPianificatoCompleto =
      []; //comprende anche i punti intermedi calcolati dal routing

  bool usaGpsSimulato = false;
  bool inCorso = false;
  double kmPercorsi = 0.0;
  Duration durata = Duration.zero;
  List<GeoPoint> tracciaGps = [];
  String? luogoVicinoAttuale;

  List<LatLng> percorsoPianificato = [];
  String? percorsoOrigineId;

  bool isVoceAttiva = true; // Per il toggle della guida vocale
  bool isAmbienteAttivo = false; // Per il toggle della musica ambientale
  String? tracciaAttiva;
  double volumeAmbientale = 0.4;

  final List<Map<String, String>> tracceDisponibili = [
    {'nome': 'Foresta', 'file': 'foresta.mp3'},
    {'nome': 'Pioggia', 'file': 'pioggia.mp3'},
    {'nome': 'Onde', 'file': 'mare.mp3'},
  ];

  void cambiaTraccia(String nomeFile) {
    if (tracciaAttiva == nomeFile) {
      // Se clicca sulla traccia già attiva, la spegne (Pausa)
      audioManager.fermaSottofondo();
      tracciaAttiva = null;
    } else {
      // Avvia la nuova traccia
      audioManager.avviaSottofondoNaturale(nomeFile);
      tracciaAttiva = nomeFile;
    }
    notifyListeners(); // Avvisa l'UI per accendere il pulsante
  }

  void toggleSuoniAmbientali() {
    if (tracciaAttiva != null) {
      audioManager.fermaSottofondo();
      tracciaAttiva = null;
    } else {
      cambiaTraccia(
        tracceDisponibili[0]['file']!,
      ); // Avvia la prima traccia (Bosco)
    }
    notifyListeners();
  }

  // Tasto Avanti
  void tracciaSuccessiva() {
    if (tracciaAttiva == null) {
      cambiaTraccia(tracceDisponibili[0]['file']!);
      return;
    }
    int index = tracceDisponibili.indexWhere((t) => t['file'] == tracciaAttiva);
    int nextIndex =
        (index + 1) %
        tracceDisponibili.length; // Passa alla successiva o riparte da zero
    cambiaTraccia(tracceDisponibili[nextIndex]['file']!);
  }

  // Tasto Indietro
  void tracciaPrecedente() {
    if (tracciaAttiva == null) {
      cambiaTraccia(tracceDisponibili.last['file']!);
      return;
    }
    int index = tracceDisponibili.indexWhere((t) => t['file'] == tracciaAttiva);
    int prevIndex =
        (index - 1 + tracceDisponibili.length) % tracceDisponibili.length;
    cambiaTraccia(tracceDisponibili[prevIndex]['file']!);
  }

  // Slider Volume
  void cambiaVolume(double nuovoVolume) {
    volumeAmbientale = nuovoVolume;
    audioManager.impostaVolumeBase(
      nuovoVolume,
    ); // Comunica il nuovo volume al manager
    notifyListeners();
  }

  // Variabili per Background e Audio
  DateTime? _oraDiInizio;
  DateTime? _ultimoControlloPoi;
  bool _isCercandoPoi = false;
  int _ultimoKmAnnunciato = 0;
  int _ultimoMinutoAnnunciato = 0;

  Timer? _timer;
  StreamSubscription<GeoPoint>? _locationSubscription;

  Future<void> impostaPercorsoPianificato(
    List<PinModel> tappe, {
    String? id,
  }) async {
    // Evitiamo ricalcoli se il percorso è già stato caricato
    if (tappePianificate.isNotEmpty || tappe.isEmpty) return;

    tappePianificate = tappe;
    percorsoOrigineId = id;
    notifyListeners(); // Notifica subito per far apparire almeno i pallini sulla mappa

    List<LatLng> tracciaRicalcolata = [];

    // Ricostruiamo segmento per segmento esattamente come nella schermata Crea Tu
    for (int i = 0; i < tappe.length - 1; i++) {
      final startPin = tappe[i];
      final endPin = tappe[i + 1];

      if (startPin.tipoRottaVersoProssimo == TipoRouting.automatico) {
        final punti = await _routingService.calcolaOSRM(
          startPin.coordinate,
          endPin.coordinate,
        );
        tracciaRicalcolata.addAll(punti);
      } else {
        final punti = _routingService.calcolaLineaAria(
          startPin.coordinate,
          endPin.coordinate,
        );
        tracciaRicalcolata.addAll(punti);
      }
    }

    percorsoPianificatoCompleto = tracciaRicalcolata;
    notifyListeners(); // Notifica finale per far apparire la linea azzurra unita
  }

  Future<void> cambiaSorgenteGps(bool usaMock) async {
    if (usaGpsSimulato == usaMock) return;
    usaGpsSimulato = usaMock;

    await _locationSubscription?.cancel();
    _locationSubscription = null;
    await _locationService.ferma();

    tracciaGps.clear();
    kmPercorsi = 0.0;
    if (_oraDiInizio != null) _oraDiInizio = DateTime.now();

    if (usaMock) {
      final mock = MockLocationService();
      mock.impostaPercorsoAlbaAdriatica();
      _locationService = mock;
    } else {
      _locationService = LocationService();
    }

    if (inCorso) {
      await _locationService.inizializza();
      _ascoltaPosizione();
    }
    notifyListeners();
  }

  Future<void> avviaAttivita() async {
    inCorso = true;
    notifyListeners();
    try {
      await _locationService.inizializza();
      await audioManager.inizializza();
      // await audioManager.avviaSottofondoNaturale('audio/foresta.mp3'); //  quando avrò l'MP3
      await audioManager.parla("Attività avviata. Iniziamo!");

      // Se hai il metodo inizializza nel PoiService, chiamalo, altrimenti resettalo.
      try {
        _poiService.inizializza();
      } catch (_) {}

      _oraDiInizio = DateTime.now(); // Per il conteggio immune al background

      _inizioCronometro();
      _ascoltaPosizione();
      notifyListeners();
    } catch (e) {
      print('Errore inizializzazione: $e');
      inCorso = false;
      notifyListeners();
    }
  }

  void toggleGuidaVocale(bool stato) {
    isVoceAttiva = stato;
    audioManager.impostaStatoVoce(stato);
    notifyListeners();
  }

  //gestione del player
  /*Future<void> toggleSuoniAmbientali() async {
    isAmbienteAttivo = !isAmbienteAttivo;
    if (isAmbienteAttivo) {
      // Quando avrai il file .mp3, lo farai partire qui
      // await audioManager.avviaSottofondoNaturale('audio/foresta.mp3');
      print("[AUDIO] Play Sottofondo Naturale");
    } else {
      await audioManager.fermaSottofondo();
      print("[AUDIO] Pausa Sottofondo Naturale");
    }
    notifyListeners();
  }*/

  void _inizioCronometro() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_oraDiInizio != null) {
        durata = DateTime.now().difference(_oraDiInizio!);
        notifyListeners();
      }
    });
  }

  void _ascoltaPosizione() {
    _locationSubscription = _locationService.positionStream.listen((punto) {
      try {
        if (tracciaGps.isNotEmpty) {
          final ultimoPunto = tracciaGps.last;
          final distanza = LocationUtils.calcolaDistanza(ultimoPunto, punto);
          if (distanza < 50) {
            kmPercorsi += distanza;
          } else {
            print("[VIEWMODEL] Distanza anomala ignorata: $distanza metri");
          }
        }
        tracciaGps.add(punto);

        _controllaTraguardiAudio(); // Controllo velocità e km
        _controllaPOI(punto); // Controllo Luoghi

        notifyListeners();
      } catch (e) {
        print("[VIEWMODEL] Eccezione bloccata nel listener GPS: $e");
      }
    });
  }

  void _controllaTraguardiAudio() {
    double velocitaAttuale = 0.0;
    if (durata.inSeconds > 0) {
      velocitaAttuale = kmPercorsi / (durata.inSeconds / 3600.0);
    }

    // Annuncio ogni KM completato
    int kmInteri = kmPercorsi.floor();
    if (kmInteri > _ultimoKmAnnunciato) {
      _ultimoKmAnnunciato = kmInteri;
      if (tracciaGps.isNotEmpty) {
        LatLng puntoAttuale = LatLng(
          tracciaGps.last.latitude,
          tracciaGps.last.longitude,
        );
        _mindfulness
            .generaFraseMotivazionale(
              kmInteri,
              puntoAttuale,
              luogoVicinoAttuale ?? "in questo ambiente",
            )
            .then((frase) {
              audioManager.parla(frase);
            });
      }
    }

    int minutiAttuali = durata.inMinutes;

    // esercizio di respirazione ogni 5 minuti, molto più discreto e rilassante
    if (minutiAttuali > 0 &&
        minutiAttuali % 5 == 0 &&
        minutiAttuali != _ultimoMinutoAnnunciato) {
      _ultimoMinutoAnnunciato = minutiAttuali;
      if (tracciaGps.isNotEmpty) {
        LatLng puntoAttuale = LatLng(
          tracciaGps.last.latitude,
          tracciaGps.last.longitude,
        );
        if (tracciaGps.isNotEmpty) {
          LatLng puntoAttuale = LatLng(
            tracciaGps.last.latitude,
            tracciaGps.last.longitude,
          );

          _mindfulness
              .generaEsercizioRespirazione(
                velocitaAttuale,
                puntoAttuale,
                luogoVicinoAttuale ?? "in questo ambiente",
              )
              .then((frase) {
                audioManager.parla(frase);
              });
        }
      }
    }
  }

  Future<void> _controllaPOI(GeoPoint posizione) async {
    if (_isCercandoPoi) return;

    if (_ultimoControlloPoi != null) {
      final secondiTrascorsi = DateTime.now()
          .difference(_ultimoControlloPoi!)
          .inSeconds;
      if (secondiTrascorsi < 10) return;
    }

    _isCercandoPoi = true;

    try {
      final luogo = await _poiService.trovaLuogoNaturaleVicino(posizione);
      _ultimoControlloPoi = DateTime.now();

      if (luogo != null) {
        luogoVicinoAttuale = luogo;
        LatLng posizioneLatLng = LatLng(
          posizione.latitude,
          posizione.longitude,
        );
        String frase = await _mindfulness.generaFrasePerPOI(
          luogo,
          posizioneLatLng,
        );
        await audioManager.parla(frase);
        notifyListeners();
      }
    } catch (e) {
      print("Errore controllo POI: $e");
    } finally {
      _isCercandoPoi = false;
    }
  }

  Future<ActivityModel?> fermaESalva(UserProvider userProvider) async {
    inCorso = false;
    _timer?.cancel();
    await _locationSubscription?.cancel();

    await _locationService.ferma();
    await audioManager.fermaTutto();

    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final nuovaAttivita = ActivityModel(
        userId: user.uid,
        km: kmPercorsi,
        data: DateTime.now(),
        durata: durata,
        percorso: tracciaGps,
        percorsoOrigineId: percorsoOrigineId,
      );

      final String activityId = await _activityRepository.salvaAttivita(
        nuovaAttivita,
      );

      await userProvider.caricaUtente(forceRefresh: true);
      return ActivityModel(
        id: activityId, // ORA POSSIAMO PASSARLO AL QUESTIONARIO
        userId: user.uid,
        km: kmPercorsi,
        data: DateTime.now(),
        durata: durata,
        percorso: tracciaGps,
        percorsoOrigineId: percorsoOrigineId,
      );
    }
    notifyListeners();
    return null;
  }
}
