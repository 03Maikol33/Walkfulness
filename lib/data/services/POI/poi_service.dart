import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';

class PoiService {
  List<String> giaAnnunciati = [];
  DateTime? _ultimoAnnuncio;

  void inizializza() {
    giaAnnunciati.clear();
    _ultimoAnnuncio = null;
    print('[POI SERVICE]: Lista dei POI annunciati resettata');
  }

  // Cerca parchi, boschi o siti storici in un raggio di 500 metri
  Future<String?> trovaLuogoNaturaleVicino(GeoPoint posizione) async {
    if (_ultimoAnnuncio != null &&
        DateTime.now().difference(_ultimoAnnuncio!) < Duration(minutes: 3)) {
      print(
        '[POI SERVICE]: Ultimo annuncio troppo recente, salto controllo POI',
      );
      return null; // Evita di cercare troppo spesso
    }
    final lat = posizione.latitude;
    final lng = posizione.longitude;
    final raggio = 10;

    print(
      '[POI SERVICE]: Controllo POI vicino a ($lat, $lng) con raggio $raggio metri',
    );

    // Query nel linguaggio Overpass QL
    final query =
        '''
      [out:json];
      (
        nwr["leisure"="park"](around:$raggio, $lat, $lng);
        nwr["natural"~"wood|beach|water"](around:$raggio, $lat, $lng);
        nwr["historic"](around:$raggio, $lat, $lng);
        nwr["amenity"~"fountain|place_of_worship"](around:$raggio, $lat, $lng);
        nwr["tourism"~"museum|viewpoint|artwork|attraction"](around:$raggio, $lat, $lng);
      );
      out tags; 
    '''; // Prende solo il più vicino

    final url = Uri.parse('https://overpass-api.de/api/interpreter');

    try {
      // Aggiungiamo gli HEADERS per farci accettare dal server
      final response = await http.post(
        url,
        headers: {
          'Accept': 'application/json', // Risolve l'errore 406!
          'User-Agent': 'WalkfulnessApp/1.0', // Buona norma per API gratuite
        },
        body: {'data': query},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final elements = data['elements'] as List;

        print(
          '[POI SERVICE]: Risposta Overpass: ${elements.length} elementi trovati',
        );
        if (elements.isNotEmpty) {
          // Cerchiamo il primo che ha un nome
          for (var el in elements) {
            if (el['tags'] != null && el['tags']['name'] != null) {
              if (giaAnnunciati.contains(el['tags']['name'])) continue;
              final nome = el['tags']['name'];
              print('[POI] TROVATO : $nome');
              giaAnnunciati.add(nome);
              _ultimoAnnuncio = DateTime.now();
              return nome;
            }
          }
        }
      } else {
        print(
          '[POI SERVICE]: Errore Overpass: ${response.statusCode} - ${response.reasonPhrase}',
        );
      }
    } catch (e) {
      print('[POI SERVICE]: Errore API Overpass: $e');
    }
    return null; // Nessun poi trovato
  }
}
