import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'package:walkfulness/data/services/location/routing_service.dart';
import 'package:walkfulness/domain/models/percorso_model.dart';
import 'package:walkfulness/ui/core/providers/user_provider.dart';

class PinModel {
  final String id;
  LatLng coordinate;
  String nome;
  TipoRouting tipoRottaVersoProssimo;

  PinModel({
    required this.coordinate,
    this.nome = "Inizializzazione...",
    this.tipoRottaVersoProssimo = TipoRouting.lineaAria,
  }) : id = const Uuid().v4();
}

class CreaTuViewModel extends ChangeNotifier {
  final MapController mapController = MapController();
  final RoutingService _routingService = RoutingService();
  final List<PinModel> pinSelezionati = [];
  final List<Polyline> lineePercorso = [];

  bool isCalcolndoRotta = false;
  bool get isCalcolandoRotta => isCalcolndoRotta;

  LatLng? posizioneUtente;
  StreamSubscription<Position>? _positionSubscription;

  //costruttore
  CreaTuViewModel() {
    //_inizializzaPosizioneUtente();
  }

  void inizializza() {
    _inizializzaPosizioneUtente();
  }

  void cambiaTipoRouting(int index) {
    if (index >= pinSelezionati.length - 1) {
      return; // L'ultimo pin non va da nessuna parte
    }

    final pin = pinSelezionati[index];
    pin.tipoRottaVersoProssimo =
        pin.tipoRottaVersoProssimo == TipoRouting.lineaAria
        ? TipoRouting.automatico
        : TipoRouting.lineaAria;

    _aggiornaInterfaccia();
  }

  Future<void> _inizializzaPosizioneUtente() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return;

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return;
    }

    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          //const crea LocationSettings una sola votla
          accuracy: LocationAccuracy.high,
          distanceFilter: 3,
        ),
        //desiredAccuracy: LocationAccuracy.high,
      );
      posizioneUtente = LatLng(position.latitude, position.longitude);
      mapController.move(posizioneUtente!, 15.0);
      notifyListeners();

      _positionSubscription =
          Geolocator.getPositionStream(
            locationSettings: const LocationSettings(
              accuracy: LocationAccuracy.high,
              distanceFilter: 3,
            ),
          ).listen((Position pos) {
            posizioneUtente = LatLng(pos.latitude, pos.longitude);
            notifyListeners();
          });
    } catch (e) {
      print("Errore GPS: $e");
    }
  }

  // RICERCA LUOGHI (API Nominatim)
  Future<void> cercaEAggiungiLuogo(String query) async {
    if (query.trim().isEmpty) return;

    print("Ricerca in corso per: $query...");
    // Chiamata all'API gratuita di OpenStreetMap
    final url = Uri.parse(
      'https://nominatim.openstreetmap.org/search?q=$query&format=json&limit=1',
    );

    try {
      final response = await http.get(
        url,
        headers: {
          'User-Agent':
              'WalkfulnessApp/1.0', // Nominatim richiede un User-Agent
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as List;
        if (data.isNotEmpty) {
          final result = data[0];
          final lat = double.parse(result['lat']);
          final lon = double.parse(result['lon']);
          // Estrapoliamo un nome pulito (prima della virgola)
          final nomeLuogo = result['display_name'].toString().split(',').first;

          // Creiamo il punto e spostiamo la mappa
          final puntoTrovato = LatLng(lat, lon);
          mapController.move(puntoTrovato, 16.0);

          // Aggiungiamo il pin col nome reale appena trovato!
          final nuovoPin = PinModel(coordinate: puntoTrovato, nome: nomeLuogo);
          pinSelezionati.add(nuovoPin);
          _aggiornaInterfaccia();
        } else {
          print("Nessun luogo trovato.");
        }
      }
    } catch (e) {
      print("Errore geocoding: $e");
    }
  }

  Future<bool> salvaPercorso(
    BuildContext context,
    String utenteId,
    String nomePercorso,
  ) async {
    if (pinSelezionati.length < 2) return false;

    try {
      // Mappiamo i Pin nel formato corretto per Firebase
      final tappeFirebase = pinSelezionati
          .map(
            (pin) => {
              'lat': pin.coordinate.latitude,
              'lon': pin.coordinate.longitude,
              'nome': pin.nome,
              'routingAutomatico':
                  pin.tipoRottaVersoProssimo == TipoRouting.automatico,
            },
          )
          .toList();

      String cittaRilevata = "";
      if (pinSelezionati.isNotEmpty) {
        cittaRilevata = await _routingService.rilevaCitta(
          pinSelezionati[0].coordinate,
        );
      }

      List<String> tags = [
        "Natura",
        "Relax",
      ]; // TODO: Aggiungere selezione tag da UI

      final nuovoPercorso = PercorsoModel(
        utenteId: utenteId,
        nome: nomePercorso,
        tappe: tappeFirebase,
        nomeCreatore:
            context.read<UserProvider>().utente?.nome ?? "Sconosciuto",
        citta: cittaRilevata,
        tags: tags,
      );

      await FirebaseFirestore.instance
          .collection('percorsi')
          .add(nuovoPercorso.toMap());
      print("Percorso '$nomePercorso' salvato nel DB per l'utente $utenteId!");
      if (context.mounted) {
        Navigator.pushReplacementNamed(
          context,
          '/main',
          arguments: pinSelezionati,
        );
      }
      return true;
    } catch (e) {
      print("Errore nel salvataggio del percorso: $e");
      return false;
    }
  }

  Future<bool> salvaPercorsoConDettagli({
    required BuildContext context,
    required String utenteId,
    required String nome,
    required bool isPublic,
    required List<String> tags,
  }) async {
    if (pinSelezionati.length < 2) return false;

    try {
      final tappeFirebase = pinSelezionati
          .map(
            (pin) => {
              'lat': pin.coordinate.latitude,
              'lon': pin.coordinate.longitude,
              'nome': pin.nome,
              'routingAutomatico':
                  pin.tipoRottaVersoProssimo == TipoRouting.automatico,
            },
          )
          .toList();

      // Rilevamento città dal primo punto
      String cittaRilevata = await _routingService.rilevaCitta(
        pinSelezionati[0].coordinate,
      );

      final nuovoPercorso = PercorsoModel(
        utenteId: utenteId,
        nome: nome,
        tappe: tappeFirebase,
        nomeCreatore:
            context.read<UserProvider>().utente?.nome ?? "Sconosciuto",
        citta: cittaRilevata,
        tags: tags,
        isPublic: isPublic, // Passiamo il valore scelto dall'utente
      );

      await FirebaseFirestore.instance
          .collection('percorsi')
          .add(nuovoPercorso.toMap());
      return true;
    } catch (e) {
      debugPrint("Errore salvataggio: $e");
      return false;
    }
  }

  void caricaPercorsoEsistente(PercorsoModel percorso) {
    pinSelezionati.clear();
    for (var tappa in percorso.tappe) {
      pinSelezionati.add(
        PinModel(
          coordinate: LatLng(tappa['lat'], tappa['lon']),
          nome: tappa['nome'] ?? "",
          tipoRottaVersoProssimo: tappa['routingAutomatico'] == true
              ? TipoRouting.automatico
              : TipoRouting.lineaAria,
        ),
      );
    }
    _aggiornaInterfaccia();
  }

  Future<void> avviaSubito(BuildContext context, String utenteId) async {
    if (pinSelezionati.length < 2) return;

    //Salvia il percorso
    if (await salvaPercorso(context, utenteId, "Percorso Rapido")) {
      if (context.mounted) {
        print("Percorso salvato, avvio attività...");
        Navigator.pushReplacementNamed(
          context,
          '/attivita',
          arguments: pinSelezionati,
        );
      }
    } else {
      print(
        "Errore nel salvataggio del percorso, impossibile avviare l'attività.",
      );
    }
  }

  void aggiungiPin(LatLng punto) {
    final nuovoPin = PinModel(
      coordinate: punto,
      nome:
          "Punto GPS: ${punto.latitude.toStringAsFixed(4)}, ${punto.longitude.toStringAsFixed(4)}",
    );
    pinSelezionati.add(nuovoPin);
    _aggiornaInterfaccia();
    notifyListeners();
  }

  Future<void> _aggiornaInterfaccia() async {
    isCalcolndoRotta = true;
    notifyListeners();

    lineePercorso.clear();

    if (pinSelezionati.length >= 2) {
      // Analizziamo il percorso a segmenti (Pin 0 -> Pin 1, Pin 1 -> Pin 2, ecc.)
      for (int i = 0; i < pinSelezionati.length - 1; i++) {
        final startPin = pinSelezionati[i];
        final endPin = pinSelezionati[i + 1];

        if (startPin.tipoRottaVersoProssimo == TipoRouting.automatico) {
          // --- ROUTING OSRM CON EFFETTO GLOWING AI ---
          final punti = await _routingService.calcolaOSRM(
            startPin.coordinate,
            endPin.coordinate,
          );

          // 1. L'Alone (Spesso e semitrasparente)
          lineePercorso.add(
            Polyline(
              points: punti,
              color: Colors.white, // Segnale per ShaderMask
              strokeWidth: 10.0,
            ),
          );
          // 2. Il Nucleo (Sottile e brillante)
          lineePercorso.add(
            Polyline(
              points: punti,
              color: Colors.white, // Segnale per ShaderMask
              strokeWidth: 1.0,
            ),
          );
        } else {
          // --- ROUTING LINEA D'ARIA (TRATTEGGIATA) ---
          final punti = _routingService.calcolaLineaAria(
            startPin.coordinate,
            endPin.coordinate,
          );
          lineePercorso.add(
            Polyline(
              points: punti,
              color: const Color(0xFF012D1C),
              strokeWidth: 10.0,
            ),
          );
        }
      }
    }
    isCalcolndoRotta = false;
    notifyListeners();
  }

  void rimuoviPin(int index) {
    pinSelezionati.removeAt(index);
    _aggiornaInterfaccia();
    notifyListeners();
  }

  // Corretta gestione degli indici per il riordinamento
  void riordinaPin(int oldIndex, int newIndex) {
    if (oldIndex < newIndex) {
      newIndex -= 1;
    }
    final PinModel item = pinSelezionati.removeAt(oldIndex);
    pinSelezionati.insert(newIndex, item);
    _aggiornaInterfaccia();
    notifyListeners();
  }

  String getTitoloPin(int index) {
    if (pinSelezionati.isEmpty) return "";
    if (index == 0) return "Partenza";
    if (index == pinSelezionati.length - 1 && pinSelezionati.length > 1) {
      return "Arrivo";
    }
    return "Tappa ${index + 1}";
  }

  @override
  void dispose() {
    _positionSubscription?.cancel();
    mapController.dispose();
    super.dispose();
  }
}
