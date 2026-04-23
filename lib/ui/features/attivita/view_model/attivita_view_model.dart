import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
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
  LocationServiceBase _locationService = MockLocationService(); // Inizialmente usa il mock
  final ActivityRepository _activityRepository = ActivityRepository();

  bool usaGpsSimulato = true;
  // Stato dell'attività
  bool inCorso = false;
  double kmPercorsi = 0.0;
  Duration durata = Duration.zero;
  List<GeoPoint> tracciaGps = [];

  Timer? _timer;
  StreamSubscription<GeoPoint>? _locationSubscription;

  //FUNZIONE PER IL DEBUG
  Future<void> cambiaSorgenteGps(bool usaMock) async {
    usaGpsSimulato = usaMock;

    // Ferma l'ascolto delle coordinate attuali
    await _locationSubscription?.cancel();

    // Scambia il "motore"
    if (usaMock) {
      _locationService = MockLocationService();
    } else {
      _locationService = LocationService(); // Il GPS VERO
    }

    // Se l'utente stava già camminando, riavvia l'ascolto col nuovo motore
    if (inCorso) {
      await _locationService.inizializza();
      _ascoltaPosizione();
    }

    notifyListeners();
  }
  //////////////////////////////////

  Future<void> avviaAttivita() async {
    try {
      await _locationService.inizializza();

      inCorso = true;
      _inizioCronometro();
      _ascoltaPosizione();
      notifyListeners();
    } catch (e) {
      // Gestione errori di inizializzazione (es. permessi negati)
      print('Errore inizializzazione GPS: $e');
      return;
    }
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
      notifyListeners();
    });
  }

  Future<void> fermaESalva(UserProvider userProvider) async {
    inCorso = false;
    _timer?.cancel();
    _locationSubscription?.cancel();

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
