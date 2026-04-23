import 'dart:math';
import 'package:location/location.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:walkfulness/data/services/location/location_service_base.dart';

class LocationService implements LocationServiceBase {
  final Location _location = Location();

  @override
  Future<void> inizializza() async {
    bool serviceEnabled;
    PermissionStatus permissionGranted;

    //controllo se gps attivo su device
    serviceEnabled = await _location.serviceEnabled();
    if (!serviceEnabled) {
      serviceEnabled = await _location.requestService();
      if (!serviceEnabled) {
        throw Exception('Servizio GPS non attivo');
      }
    }

    //l'app ha i permessi per accedere alla posizione?
    permissionGranted = await _location.hasPermission();
    if (permissionGranted == PermissionStatus.denied) {
      permissionGranted = await _location.requestPermission();
      if (permissionGranted != PermissionStatus.granted) {
        throw Exception('Permessi GPS negati');
      }
    }
    //prova ad attivare la pos in background (per continuare a tracciare anche se l'app è in background)
    try {
      await _location.enableBackgroundMode(enable: true);
    } catch (e) {
      print(
        'Avviso: Impossibile abilitare il background mode. L\'app tracciarà solo a schermo acceso.',
      );
    }

    // Imposta la precisione e la frequenza di aggiornamento
    await _location.changeSettings(
      accuracy: LocationAccuracy.high,
      interval: 2000,
      distanceFilter: 2,
    );
  }

  @override
  Stream<GeoPoint> get positionStream {
    return _location.onLocationChanged.map((LocationData currentLocation) {
      return GeoPoint(currentLocation.latitude!, currentLocation.longitude!);
    });
  }
}
