import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

class MeteoService {
  //stringa descrittiva del meteo attuale
  Future<String> ottieniCondizioniAttuali(LatLng coordinate) async {
    final url = Uri.parse(
      'https://api.open-meteo.com/v1/forecast?latitude=${coordinate.latitude}&longitude=${coordinate.longitude}&current_weather=true',
    );

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final weatherCode = data['current_weather']['weathercode'];
        final temperature = data['current_weather']['temperature'];

        String descrizione = _decodificaMeteo(weatherCode);
        return "$descrizione con ${temperature.toStringAsFixed(1)}°C";
      }
    } catch (e) {
      print("[METEO SERVICE] Errore: $e");
    }
    return "Condizioni climatiche stabili, temperatura mite.";
  }

  String _decodificaMeteo(int code) {
    if (code == 0) return "Cielo sereno";
    if (code >= 1 && code <= 3) return "Parzialmente nuvoloso";
    if (code >= 45 && code <= 48) return "Nebbia";
    if (code >= 51 && code <= 67) return "Pioggia leggera/pioviggine";
    if (code >= 71 && code <= 77) return "Neve";
    if (code >= 80 && code <= 99) return "Acquazzoni o temporali";
    return "Meteo variabile";
  }
}
