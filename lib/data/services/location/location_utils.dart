import 'dart:math' as math;
import 'package:cloud_firestore/cloud_firestore.dart';

class LocationUtils {
  // Calcola la distanza in KM tra due punti geografici
  static double calcolaDistanza(GeoPoint p1, GeoPoint p2) {
    const double raggioTerra = 6371.0; // In KM

    double dLat = _gradiInRadianti(p2.latitude - p1.latitude);
    double dLon = _gradiInRadianti(p2.longitude - p1.longitude);

    double a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_gradiInRadianti(p1.latitude)) *
            math.cos(_gradiInRadianti(p2.latitude)) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);

    double c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return raggioTerra * c;
  }

  static double _gradiInRadianti(double gradi) => gradi * (math.pi / 180);
}