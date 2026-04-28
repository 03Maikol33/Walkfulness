import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

enum TipoRouting { lineaAria, automatico }

class RoutingService {
  // Metodo 1: Routing Automatico (OSRM) tra due punti
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
    // In caso di errore OSRM, fallback su linea retta
    return calcolaLineaAria(start, end);
  }

  // Metodo 2: Routing Manuale (Linea Retta)
  List<LatLng> calcolaLineaAria(LatLng start, LatLng end) {
    return [start, end];
  }
}
