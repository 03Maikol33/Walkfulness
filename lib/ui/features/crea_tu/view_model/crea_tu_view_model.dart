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

  bool _isDisposed = false;
  bool get isDisposed => _isDisposed;

  LatLng? posizioneUtente;
  StreamSubscription<Position>? _positionSubscription;

  //costruttore
  CreaTuViewModel() {}

  void inizializza() {
    _inizializzaPosizioneUtente();
  }

  void cambiaTipoRouting(int index) {
    if (index >= pinSelezionati.length - 1) {
      return;
    }

    final pin = pinSelezionati[index];
    pin.tipoRottaVersoProssimo =
        pin.tipoRottaVersoProssimo == TipoRouting.lineaAria
        ? TipoRouting.automatico
        : TipoRouting.lineaAria;

    _aggiornaInterfaccia();
  }

  void caricaPercorsoGenerato(List<PinModel> pinsGenerati) {
    pinSelezionati.clear();
    pinSelezionati.addAll(pinsGenerati);
    _aggiornaInterfaccia();

    if (pinSelezionati.isNotEmpty && !_isDisposed) {
      mapController.move(pinSelezionati.first.coordinate, 14.0);
    }
  }

  Future<void> _inizializzaPosizioneUtente() async {
    if (isDisposed) return;
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

  // cercha i luoghi con API Nominatim
  Future<void> cercaEAggiungiLuogo(String query) async {
    if (query.trim().isEmpty) return;

    print("Ricerca in corso per: $query...");
    final url = Uri.parse(
      'https://nominatim.openstreetmap.org/search?q=$query&format=json&limit=1',
    );

    try {
      final response = await http.get(
        url,
        headers: {
          'User-Agent':
              'WalkfulnessApp/1.0',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as List;
        if (data.isNotEmpty) {
          final result = data[0];
          final lat = double.parse(result['lat']);
          final lon = double.parse(result['lon']);
          final nomeLuogo = result['display_name'].toString().split(',').first;

          final puntoTrovato = LatLng(lat, lon);
          mapController.move(puntoTrovato, 16.0);
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
      // mappa i pin nel formato corretto per Firebase
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
      ];

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
        isPublic: isPublic,
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
      //analizza il percorso segmento per segmento
      for (int i = 0; i < pinSelezionati.length - 1; i++) {
        final startPin = pinSelezionati[i];
        final endPin = pinSelezionati[i + 1];

        if (startPin.tipoRottaVersoProssimo == TipoRouting.automatico) {
          // routing automatico con OSRM
          final punti = await _routingService.calcolaOSRM(
            startPin.coordinate,
            endPin.coordinate,
          );

          // effetto alone trasparente
          lineePercorso.add(
            Polyline(
              points: punti,
              color: Colors.white, // colore catturato da ShaderMask
              strokeWidth: 10.0,
            ),
          );
          // centro linea
          lineePercorso.add(
            Polyline(
              points: punti,
              color: Colors.white,
              strokeWidth: 1.0,
            ),
          );
        } else {
          // Routing in line d'aria
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
    _isDisposed = true;
    super.dispose();
  }
}
