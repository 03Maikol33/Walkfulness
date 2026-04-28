import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:uuid/uuid.dart';
import 'package:geolocator/geolocator.dart';
import 'package:walkfulness/data/services/location/routing_service.dart';

class PinModel {
  final String id;
  LatLng coordinate;
  String indirizzoMock;
  TipoRouting tipoRottaVersoProssimo;

  PinModel({
    required this.coordinate,
    this.indirizzoMock = "Inizializzazione...",
    this.tipoRottaVersoProssimo = TipoRouting.lineaAria,
  }) : id = const Uuid().v4();
}

class CreaTuViewModel extends ChangeNotifier {
  final MapController mapController = MapController();
  final RoutingService _routingService = RoutingService();
  final List<PinModel> pinSelezionati = [];
  final List<Polyline> lineePercorso = [];

  LatLng? posizioneUtente;
  StreamSubscription<Position>? _positionSubscription;

  //costruttore
  CreaTuViewModel() {
    _inizializzaPosizioneUtente();
  }

  void cambiaTipoRouting(int index) {
    if (index >= pinSelezionati.length - 1)
      return; // L'ultimo pin non va da nessuna parte

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
        desiredAccuracy: LocationAccuracy.high,
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

  void aggiungiPin(LatLng punto) {
    final nuovoPin = PinModel(
      coordinate: punto,
      indirizzoMock:
          "Punto GPS: ${punto.latitude.toStringAsFixed(4)}, ${punto.longitude.toStringAsFixed(4)}",
    );
    pinSelezionati.add(nuovoPin);
    _aggiornaInterfaccia();
    notifyListeners();
  }

  Future<void> _aggiornaInterfaccia() async {
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
    if (index == pinSelezionati.length - 1 && pinSelezionati.length > 1)
      return "Arrivo";
    return "Tappa ${index + 1}";
  }

  void salvaPercorso() {
    if (pinSelezionati.length < 2) return;
    print("Percorso Salvato");
  }

  void avviaSubito() {
    if (pinSelezionati.length < 2) return;
    print("Avvio immediato attività...");
    // Qui andrà la logica per passare i dati alla vista attività
  }

  @override
  void dispose() {
    _positionSubscription?.cancel();
    mapController.dispose();
    super.dispose();
  }
}
