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

  Future<String?> trovaLuogoNaturaleVicino(GeoPoint posizione) async {
    if (_ultimoAnnuncio != null &&
        DateTime.now().difference(_ultimoAnnuncio!) <
            const Duration(minutes: 3)) {
      return null;
    }
    final lat = posizione.latitude;
    final lng = posizione.longitude;
    final raggio = 20;

    print(
      '[POI SERVICE]: Controllo POI vicino a ($lat, $lng) con raggio $raggio metri',
    );

    final query =
        '''
      [out:json];
      (
        nwr["historic"](around:$raggio, $lat, $lng);
        nwr["tourism"~"museum|viewpoint|artwork|attraction"](around:$raggio, $lat, $lng);
        nwr["amenity"~"fountain|place_of_worship"](around:$raggio, $lat, $lng);
        nwr["natural"~"wood|beach|water|peak"](around:$raggio, $lat, $lng);
        nwr["leisure"="park"](around:$raggio, $lat, $lng);
      );
      out tags; 
    ''';

    final url = Uri.parse('https://overpass-api.de/api/interpreter');

    try {
      final response = await http.post(
        url,
        headers: {
          'Accept': 'application/json',
          'User-Agent': 'WalkfulnessApp/1.0',
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
          for (var el in elements) {
            if (el['tags'] != null) {
              String? nome = el['tags']['name'];
              if (nome != null && !giaAnnunciati.contains(nome)) {
                print('[POI] TROVATO CON NOME : $nome');
                giaAnnunciati.add(nome);
                _ultimoAnnuncio = DateTime.now();
                return nome;
              }
            }
          }

          //fallback nomi generici
          //gli elementi trovati prima nessuno aveva un nome proprio.
          for (var el in elements) {
            if (el['tags'] != null) {
              String? nomeGenerico;

              final historic = el['tags']['historic'];
              final tourism = el['tags']['tourism'];
              final natural = el['tags']['natural'];
              final leisure = el['tags']['leisure'];
              final amenity = el['tags']['amenity'];

              if (historic == 'monument' ||
                  historic == 'castle' ||
                  historic == 'ruins') {
                nomeGenerico = "un monumento storico";
              } else if (tourism == 'artwork') {
                nomeGenerico = "un'opera d'arte";
              } else if (natural == 'beach') {
                nomeGenerico = "la spiaggia";
              } else if (leisure == 'park') {
                nomeGenerico = "un'area verde";
              } else if (natural == 'water') {
                nomeGenerico = "uno specchio d'acqua";
              } else if (amenity == 'fountain') {
                nomeGenerico = "una fontana";
              }

              if (nomeGenerico != null &&
                  !giaAnnunciati.contains(nomeGenerico)) {
                print('[POI] TROVATO GENERICO : $nomeGenerico');
                giaAnnunciati.add(nomeGenerico);
                _ultimoAnnuncio = DateTime.now();
                return nomeGenerico;
              }
            }
          }
        }
      }
    } catch (e) {
      print('[POI SERVICE]: Errore API Overpass: $e');
    }
    return null;
  }
}
