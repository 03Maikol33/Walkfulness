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
    try {
      await _locationService.inizializza();
      await audioManager.inizializza();
      // await audioManager.avviaSottofondoNaturale('audio/foresta.mp3'); //  quando avrò l'MP3
      await audioManager.parla("Attività avviata. Iniziamo!");

      // Se hai il metodo inizializza nel PoiService, chiamalo, altrimenti resettalo.
      try {
        _poiService.inizializza();
      } catch (_) {}

      inCorso = true;
      _oraDiInizio = DateTime.now(); // Per il conteggio immune al background

      //await audioGuideService.parla("Attività avviata. Iniziamo!");

      _inizioCronometro();
      _ascoltaPosizione();
      notifyListeners();
    } catch (e) {
      print('Errore inizializzazione: $e');
    }
  }

  void toggleGuidaVocale(bool stato) {
    isVoceAttiva = stato;
    audioManager.impostaStatoVoce(stato);
    notifyListeners();
  }

  //gestione del player
  Future<void> toggleSuoniAmbientali() async {
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
  }

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
          kmPercorsi += distanza;
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

    int kmInteri = kmPercorsi.floor();
    if (kmInteri > _ultimoKmAnnunciato) {
      _ultimoKmAnnunciato = kmInteri;
      audioManager.parla(
        "Chilometro $kmInteri completato. Velocità media, ${velocitaAttuale.toStringAsFixed(1)} chilometri orari.",
      );
    }

    int minutiAttuali = durata.inMinutes;
    if (minutiAttuali > 0 &&
        minutiAttuali % 10 == 0 &&
        minutiAttuali > _ultimoMinutoAnnunciato) {
      _ultimoMinutoAnnunciato = minutiAttuali;
      audioManager.parla(
        "Sei in cammino da $minutiAttuali minuti. Hai percorso ${kmPercorsi.toStringAsFixed(1)} chilometri.",
      );
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
        String frase = await _mindfulness.generaFrasePerPOI(luogo);
        await audioManager.parla(frase);
        notifyListeners();
      }
    } catch (e) {
      print("Errore controllo POI: $e");
    } finally {
      _isCercandoPoi = false;
    }
  }

  Future<void> fermaESalva(UserProvider userProvider) async {
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

      await _activityRepository.salvaAttivita(nuovaAttivita);
      await userProvider.caricaUtente(forceRefresh: true);
    }
    notifyListeners();
  }
}
