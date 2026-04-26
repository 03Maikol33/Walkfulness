import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:walkfulness/data/services/POI/poi_service.dart';
import 'package:walkfulness/data/services/TTS/tts_service.dart';
import 'package:walkfulness/data/services/location/location_service.dart';
import 'package:walkfulness/data/services/location/location_service_base.dart';
import 'package:walkfulness/data/services/location/location_utils.dart';
import 'package:walkfulness/ui/core/providers/user_provider.dart';
import '../../../../data/services/location/mock_location_service.dart';
import '../../../../data/repositories/activity_repository.dart';
import '../../../../domain/models/activity_model.dart';

class AttivitaViewModel extends ChangeNotifier {
  //final LocationService _locationService = LocationService();
  //final MockLocationService _locationService = MockLocationService();
  LocationServiceBase _locationService =
      MockLocationService(); // Inizialmente usa il mock
  final PoiService _poiService =
      PoiService(); // Per trovare luoghi di interesse
  final AudioGuideService audioGuideService =
      AudioGuideService(); // Per la guida audio
  final ActivityRepository _activityRepository = ActivityRepository();

  bool usaGpsSimulato = true;
  // Stato dell'attività
  bool inCorso = false;
  double kmPercorsi = 0.0;
  Duration durata = Duration.zero;
  List<GeoPoint> tracciaGps = [];

  //POI
  //List<String> luoghiAnnunciati = [];
  DateTime? _ultimoControlloPoi;
  bool _isCercandoPoi = false;

  String? luogoVicinoAttuale; // Nome del luogo di interesse più vicino
  int _ultimoKmAnnunciato = 0; // Per evitare annunci ripetuti

  Timer? _timer;
  StreamSubscription<GeoPoint>? _locationSubscription;

  //FUNZIONE PER IL DEBUG
  Future<void> cambiaSorgenteGps(bool usaMock) async {
    if (usaGpsSimulato == usaMock) return; // nessun cambio reale
    usaGpsSimulato = usaMock;

    //Ferma
    await _locationSubscription?.cancel();
    _locationSubscription = null;
    await _locationService.ferma();

    tracciaGps.clear();
    kmPercorsi = 0.0;

    // INIEZIONE DEL PERCORSO DI TEST
    if (usaMock) {
      final mock = MockLocationService();
      mock.impostaPercorsoAlbaAdriatica(); // Carichiamo il percorso forzato!
      _locationService = mock;
    } else {
      _locationService = LocationService();
    }

    // 4. Se l'attività è in corso, riavvia con il nuovo motore
    if (inCorso) {
      await _locationService.inizializza(); // il controller è già pronto
      _ascoltaPosizione(); // ora il listener c'è prima dei dati
    }

    notifyListeners();
  }
  //////////////////////////////////

  Future<void> avviaAttivita() async {
    try {
      await _locationService.inizializza();
      await audioGuideService.inizializza();
      _poiService.inizializza();
      inCorso = true;

      await audioGuideService.parla("Attività avviata. Iniziamo!");

      _inizioCronometro();
      _ascoltaPosizione();
      notifyListeners();
    } catch (e) {
      // Gestione errori di inizializzazione (es. permessi negati)
      print('Errore inizializzazione GPS: $e');
      return;
    }
  }

  void toggleGuidaVocale(bool stato) {
    audioGuideService.impostaStato(stato);
    notifyListeners();
  }

  void _inizioCronometro() {
    _timer = Timer.periodic(const Duration(milliseconds: 250), (timer) {
      durata += const Duration(milliseconds: 250);
      notifyListeners();
    });
  }

  void _ascoltaPosizione() {
    _locationSubscription = _locationService.positionStream.listen((punto) {
      if (tracciaGps.isNotEmpty) {
        //calcola la distanza tra l'ultimo punto e il nuovo punto
        final ultimoPunto = tracciaGps.last;
        final distanza = LocationUtils.calcolaDistanza(ultimoPunto, punto);
        kmPercorsi += distanza;
      }
      tracciaGps.add(punto);

      _controllaPOI(punto);

      notifyListeners();
    });
  }

  Future<void> _controllaPOI(GeoPoint posizione) async {
    if (_isCercandoPoi) return;

    if (_ultimoControlloPoi != null) {
      final secondiTrascorsi = DateTime.now()
          .difference(_ultimoControlloPoi!)
          .inSeconds;
      if (secondiTrascorsi < 10) {
        //90
        //1 minuto e mezzo di cooldown
        return; // Troppo presto.
      }
    }

    // MUTUA ESCLUSIONE: lucchetto chiuso
    _isCercandoPoi = true;

    try {
      final luogo = await _poiService.trovaLuogoNaturaleVicino(posizione);

      // Aggiorniamo l'ora dell'ultima chiamata riuscita
      _ultimoControlloPoi = DateTime.now();

      String messaggio = "";
      if (luogo != null) {
        luogoVicinoAttuale = luogo;
        messaggio = " Sei nei pressi di $luogo.";
        await audioGuideService.parla(messaggio);
        notifyListeners(); // Aggiorna l'interfaccia
      }
    } catch (e) {
      print("Errore durante il controllo POI: $e");
    } finally {
      // MUTUA ESCLUSIONE: lucchetto aperto
      _isCercandoPoi = false;
    }
  }

  Future<void> fermaESalva(UserProvider userProvider) async {
    inCorso = false;
    _timer?.cancel();
    _locationSubscription?.cancel();

    await _locationService.ferma();
    await audioGuideService.ferma();

    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final nuovaAttivita = ActivityModel(
        userId: user.uid,
        km: kmPercorsi,
        data: DateTime.now(),
        durata: durata,
        percorso: tracciaGps,
      );

      await _activityRepository.salvaAttivita(nuovaAttivita);
      await userProvider.caricaUtente(
        forceRefresh: true,
      ); // Ricarica i dati dell'utente per aggiornare km percorsi e livello
    }
    notifyListeners();
  }
}
