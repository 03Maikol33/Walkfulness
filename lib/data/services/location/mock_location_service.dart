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
    impostaPercorsoAlbaAdriatica(); // Carichiamo un percorso di test di defaul
    return;
  }

  @override
  Future<void> ferma() async {
    return;
  }

  @override
  Stream<GeoPoint> get positionStream async* {
    if (_percorsoDaSeguire != null) {
      // Segue il percorso predefinito punto per punto
      for (var punto in _percorsoDaSeguire!) {
        await Future.delayed(const Duration(seconds: 10));
        yield punto;
      }
    } else {
      while (true) {
        await Future.delayed(const Duration(seconds: 10));
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

  //percorso di test per arrivare al monumento Ivan Palazzese ad Alba Adriatica
  void impostaPercorsoAlbaAdriatica() {
    _percorsoDaSeguire = [
      // Partenza da Sud
      const GeoPoint(42.832000, 13.933500),
      const GeoPoint(42.832500, 13.933300),
      const GeoPoint(42.833000, 13.933100), // 100 metri dal monumento
      const GeoPoint(42.833500, 13.932900),
      //davanti al Monumento
      const GeoPoint(42.833724, 13.932856),
      //oltre
      const GeoPoint(42.834000, 13.932700),
      const GeoPoint(42.834500, 13.932500),
    ];
  }
}
