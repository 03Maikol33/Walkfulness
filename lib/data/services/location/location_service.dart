import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:geolocator/geolocator.dart';
import 'package:walkfulness/data/services/location/location_service_base.dart';

@pragma('vm:entry-point')
void startCallback() {
  FlutterForegroundTask.setTaskHandler(LocationTaskHandler());
}

class LocationTaskHandler extends TaskHandler {
  StreamSubscription<Position>? _positionStream;

  @override
  Future<void> onStart(DateTime timestamp, TaskStarter starter) async {
    // IMPORTANTE: Aggiungi un piccolo delay PRIMA di iniziare lo streaming
    // Questo garantisce che il main thread abbia tempo di registrare il callback
    await Future.delayed(const Duration(milliseconds: 300));

    final locationSettings = AndroidSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 3,
      forceLocationManager: true,
      timeLimit: const Duration(seconds: 10), // timeout per ogni lettura
      intervalDuration: const Duration(milliseconds: 1000),
    );

    // Prima lettura immediata
    try {
      print("[ISOLATE] Tentativo getCurrentPosition...");
      final initialPos = await Geolocator.getCurrentPosition(
        locationSettings: locationSettings,
      );

      print(
        "[ISOLATE] Posizione iniziale trovata: ${initialPos.latitude}, ${initialPos.longitude}",
      );

      // CRITICO: Verifica che il main thread sia pronto
      await Future.delayed(const Duration(milliseconds: 100));

      final dataToSend = {
        'lat': initialPos.latitude,
        'lng': initialPos.longitude,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      };

      print("[ISOLATE] Invio dati iniziali al main thread: $dataToSend");
      FlutterForegroundTask.sendDataToMain(dataToSend);
    } catch (e) {
      print("[ISOLATE] ERRORE prima lettura GPS: $e");
      // Invia un dato di errore al main thread per diagnostica
      FlutterForegroundTask.sendDataToMain({
        'error': 'getCurrentPosition failed: $e',
      });
    }

    // Avvia lo stream continuo
    print("[ISOLATE] Avvio getPositionStream...");
    _positionStream =
        Geolocator.getPositionStream(locationSettings: locationSettings).listen(
          (Position position) {
            final dataToSend = {
              'lat': position.latitude,
              'lng': position.longitude,
              'timestamp': DateTime.now().millisecondsSinceEpoch,
              'accuracy': position.accuracy,
              'altitude': position.altitude,
              'speed': position.speed,
            };

            print(
              "[ISOLATE] Nuova posizione: ${position.latitude}, ${position.longitude} (accuracy: ${position.accuracy}m)",
            );
            FlutterForegroundTask.sendDataToMain(dataToSend);
          },
          onError: (error) {
            print("[ISOLATE] ERRORE nello stream: $error");
            FlutterForegroundTask.sendDataToMain({
              'error': 'Stream error: $error',
            });
          },
          cancelOnError:
              false, // IMPORTANTE: Non killare lo stream al primo errore
        );

    print("[ISOLATE] Stream attivato correttamente");
  }

  @override
  void onRepeatEvent(DateTime timestamp) {
    // Heartbeat diagnostico ogni 5 secondi
    print("[ISOLATE] Heartbeat - Stream attivo: ${_positionStream != null}");
  }

  @override
  Future<void> onDestroy(DateTime timestamp, bool isTimeout) async {
    print("[ISOLATE] onDestroy chiamato");
    await _positionStream?.cancel();
    _positionStream = null;
  }
}

class LocationService implements LocationServiceBase {
  StreamController<GeoPoint>? _positionController;
  late final void Function(Object) _taskDataCallback;

  // NUOVO: Contatore per diagnostica
  int _dataReceivedCount = 0;

  double velocitaCorrente = 0.0;

  LocationService() {
    _taskDataCallback = _onReceiveTaskData;
  }

  void _onReceiveTaskData(Object data) {
    print(
      "[MAIN THREAD] ✅ Ricevuti dati dal task (#${++_dataReceivedCount}): $data",
    );

    if (data is Map) {
      // Gestisci errori
      if (data.containsKey('error')) {
        print(
          "[MAIN THREAD] ⚠️ Errore ricevuto dall'isolate: ${data['error']}",
        );
        return;
      }

      // Verifica che il controller sia valido
      if (_positionController == null) {
        print("[MAIN THREAD] ERRORE: Controller è null!");
        return;
      }

      if (_positionController!.isClosed) {
        print("[MAIN THREAD] ERRORE: Controller è chiuso!");
        return;
      }

      // Estrai la velocità
      final speedMs = (data['speed'] as num?)?.toDouble() ?? 0.0;
      print("[MAIN THREAD] Velocità ricevuta: $speedMs m/s");
      velocitaCorrente = speedMs * 3.6; // km/h

      // Estrai coordinate
      final lat = (data['lat'] as num?)?.toDouble();
      final lng = (data['lng'] as num?)?.toDouble();

      if (lat == null || lng == null) {
        print("[MAIN THREAD] Coordinate mancanti: lat=$lat, lng=$lng");
        return;
      }

      print("[MAIN THREAD] Aggiungo GeoPoint($lat, $lng) allo stream");
      _positionController!.add(GeoPoint(lat, lng));
    } else {
      print("[MAIN THREAD] Dato ricevuto non è una Map: ${data.runtimeType}");
    }
  }

  @override
  Future<void> inizializza() async {
    print("[MAIN THREAD] Inizializzazione LocationService...");

    // 1. Cleanup del vecchio controller
    await _positionController?.close();
    _positionController = StreamController<GeoPoint>.broadcast();
    _dataReceivedCount = 0;
    print("[MAIN THREAD]  StreamController creato");

    // 2. Permessi GPS
    LocationPermission permission = await Geolocator.checkPermission();
    print("[MAIN THREAD] Permesso GPS attuale: $permission");

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      print("[MAIN THREAD] Permesso GPS dopo richiesta: $permission");
    }

    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      throw Exception("Permessi GPS negati: $permission");
    }

    // 3. Permessi Notifica
    final notificationPermission =
        await FlutterForegroundTask.checkNotificationPermission();
    print("[MAIN THREAD] Permesso notifiche: $notificationPermission");

    if (notificationPermission != NotificationPermission.granted) {
      await FlutterForegroundTask.requestNotificationPermission();
    }

    // 4. Init ForegroundTask
    FlutterForegroundTask.init(
      androidNotificationOptions: AndroidNotificationOptions(
        channelId: 'walkfulness_tracker',
        channelName: 'Tracciamento Attività',
        channelDescription: 'Traccia la tua posizione durante la camminata',
        channelImportance: NotificationChannelImportance.LOW,
        priority: NotificationPriority.LOW,
      ),
      iosNotificationOptions: const IOSNotificationOptions(
        showNotification: true,
        playSound: false,
      ),
      foregroundTaskOptions: ForegroundTaskOptions(
        eventAction: ForegroundTaskEventAction.repeat(5000),
        autoRunOnBoot: false,
        allowWakeLock: true,
        allowWifiLock: true,
      ),
    );
    print("[MAIN THREAD] ForegroundTask configurato");

    // 5. CRITICO: Registra il callback PRIMA di avviare il servizio
    FlutterForegroundTask.removeTaskDataCallback(_taskDataCallback);
    FlutterForegroundTask.addTaskDataCallback(_taskDataCallback);
    print("[MAIN THREAD] Callback registrato");

    // 6. NUOVO: Aspetta un momento per garantire la registrazione
    await Future.delayed(const Duration(milliseconds: 100));

    // 7. Avvia/Riavvia il servizio
    final isRunning = await FlutterForegroundTask.isRunningService;
    print("[MAIN THREAD] Servizio già in esecuzione: $isRunning");

    if (isRunning) {
      print("[MAIN THREAD] Riavvio servizio...");
      await FlutterForegroundTask.restartService();
    } else {
      print("[MAIN THREAD] Avvio nuovo servizio...");
      final started = await FlutterForegroundTask.startService(
        notificationTitle: 'Sessione Walkfulness Attiva',
        notificationText: 'Stiamo tracciando i tuoi passi nella natura...',
        callback: startCallback,
      );
      print("[MAIN THREAD] Servizio avviato: $started");
    }

    print("[MAIN THREAD] Inizializzazione completata");
  }

  @override
  Stream<GeoPoint> get positionStream {
    if (_positionController == null || _positionController!.isClosed) {
      throw StateError(
        'LocationService non inizializzato. Chiama inizializza() prima.',
      );
    }
    return _positionController!.stream;
  }

  @override
  Future<void> ferma() async {
    print("[MAIN THREAD] Fermata del LocationService...");
    FlutterForegroundTask.removeTaskDataCallback(_taskDataCallback);
    await FlutterForegroundTask.stopService();
    await _positionController?.close();
    _positionController = null;
    print("[MAIN THREAD] LocationService fermato");
  }
}
