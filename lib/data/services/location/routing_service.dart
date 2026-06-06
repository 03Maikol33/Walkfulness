import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

enum TipoRouting { lineaAria, automatico }

class RoutingService {
  //Routing Automatico tra due punti
  Future<List<LatLng>> calcolaOSRM(LatLng start, LatLng end) async {
    final url = Uri.parse(
      'http://router.project-osrm.org/route/v1/foot/${start.longitude},${start.latitude};${end.longitude},${end.latitude}?overview=full&geometries=geojson',
    );

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final routes = data['routes'] as List;
        if (routes.isNotEmpty) {
          final coordinates = routes[0]['geometry']['coordinates'] as List;
          return coordinates
              .map((c) => LatLng(c[1] as double, c[0] as double))
              .toList();
        }
      }
    } catch (e) {
      print('[ROUTING] Errore OSRM: $e');
    }
    // In caso di errore OSRM fallback su linea retta
    return calcolaLineaAria(start, end);
  }

  //Routing Linea d'Aria tra due punti
  List<LatLng> calcolaLineaAria(LatLng start, LatLng end) {
    return [start, end];
  }

  //da Coordinate a Città
  Future<String> rilevaCitta(LatLng coordinate) async {
    final url = Uri.parse(
      'https://nominatim.openstreetmap.org/reverse?format=json&lat=${coordinate.latitude}&lon=${coordinate.longitude}&zoom=10&addressdetails=1',
    );

    try {
      final response = await http.get(
        url,
        headers: {'User-Agent': 'WalkfulnessApp/1.0'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data != null && data['address'] != null) {
          final address = data['address'];
          return address['city'] ??
              address['town'] ??
              address['village'] ??
              address['county'] ??
              "";
        }
      }
    } catch (e) {
      print('[ROUTING] Errore Reverse Geocoding: $e');
    }
    return "";
  }
}
