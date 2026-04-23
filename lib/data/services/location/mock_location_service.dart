import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:walkfulness/data/services/location/location_service_base.dart';

class MockLocationService implements LocationServiceBase {
  List<GeoPoint>? _percorsoDaSeguire;
  double _currentLat = 42.358246; // Latitudine di partenza (es. Milano)
  double _currentLng = 13.386197; // Longitudine di partenza

  // Metodo per caricare un percorso (es. quello generato dall'AI)
  void setPercorso(List<GeoPoint> percorso) => _percorsoDaSeguire = percorso;

  @override
  Future<void> inizializza() async {
    return;
  }

  @override
  Stream<GeoPoint> get positionStream async* {
    if (_percorsoDaSeguire != null) {
      // Segue il percorso predefinito punto per punto
      for (var punto in _percorsoDaSeguire!) {
        await Future.delayed(const Duration(seconds: 2));
        yield punto;
      }
    } else {
      while (true) {
        await Future.delayed(const Duration(seconds: 2));
        // Simuliamo un piccolo spostamento verso nord-est
        if (Random().nextInt(10) <= 5) {
          // ogni tanto facciamo un salto più grande per simulare deviazioni
          _currentLat += 0.0001;
        } else {
          _currentLat -= 0.0001;
        }
        if (Random().nextInt(10) <= 5) {
          _currentLng += 0.0001;
        } else {
          _currentLng -= 0.0001;
        }
        yield GeoPoint(_currentLat, _currentLng);
      }
    }
  }
}
