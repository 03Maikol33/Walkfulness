import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:walkfulness/ui/features/attivita/view/attivita_view.dart';
import 'package:walkfulness/ui/features/attivita/view_model/attivita_view_model.dart';
import 'package:walkfulness/ui/features/crea_tu/view_model/crea_tu_view_model.dart';

// view model mock per testare i widget senza dipendere dai sensori e dalla logica reale

class MockAttivitaViewModel extends ChangeNotifier
    implements AttivitaViewModel {
  @override
  Duration durata = const Duration(minutes: 0, seconds: 0);

  @override
  double kmPercorsi = 0.0;

  @override
  bool isVoceAttiva = true;

  @override
  String? luogoVicinoAttuale;

  bool toggleVoceChiamato = false;

  @override
  void toggleGuidaVocale(bool stato) {
    toggleVoceChiamato = true;
    isVoceAttiva = stato;
    notifyListeners();
  }

  // stato per la mappa
  @override
  List<GeoPoint> tracciaGps = [];
  @override
  List<LatLng> percorsoPianificato = [];
  @override
  List<LatLng> percorsoPianificatoCompleto = [];
  @override
  List<PinModel> tappePianificate = [];

  //stato per il player
  @override
  String? tracciaAttiva; // null = Silenzio
  @override
  double volumeAmbientale = 0.4;
  @override
  final List<Map<String, String>> tracceDisponibili = [
    {'nome': 'Foresta', 'file': 'foresta.mp3'},
    {'nome': 'Pioggia', 'file': 'pioggia.mp3'},
  ];
  bool toggleAudioChiamato = false;
  bool nextChiamato = false;
  bool prevChiamato = false;
  double? volumeImpostato;

  @override
  void toggleSuoniAmbientali() {
    toggleAudioChiamato = true;
    tracciaAttiva = tracciaAttiva == null ? 'foresta.mp3' : null;
    notifyListeners();
  }

  @override
  void tracciaSuccessiva() {
    nextChiamato = true;
  }

  @override
  void tracciaPrecedente() {
    prevChiamato = true;
  }

  @override
  void cambiaVolume(double nuovoVolume) {
    volumeImpostato = nuovoVolume;
    volumeAmbientale = nuovoVolume;
    notifyListeners();
  }

  //helper per i test per simulare il passaggio del tempo
  void avanzaTempo(int minuti, int secondi, double km) {
    durata = Duration(minutes: minuti, seconds: secondi);
    kmPercorsi = km;
    notifyListeners();
  }

  // ignora tutto il resto
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

//inizio dei test

void main() {
  group('Test su Attivita Widgets', () {
    //test 1: verifica dell'aggiornamento del tempo e dei km nel main stats
    testWidgets('MainStatsWidget aggiorna i testi quando il timer avanza', (
      WidgetTester tester,
    ) async {
      final MockViewModel = MockAttivitaViewModel();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: MainStatsWidget(viewModel: MockViewModel)),
        ),
      );

      //inizialmente il tempo deve essere 00:00 e i km 0.0
      expect(find.text("00:00"), findsOneWidget);
      expect(find.text("0.0"), findsOneWidget);

      //dopo 5 minuti e 30 secondi, e 1.5 km
      MockViewModel.avanzaTempo(5, 30, 1.5);
      await tester.pump();

      //la ui deve essersi aggiornata con i nuovi numeri
      expect(find.text("05:30"), findsOneWidget);
      expect(find.text("1.5"), findsOneWidget);
    });

    //test 2: interazioni con il toggle per la guida vocale
    testWidgets('AudioTogglesWidget invoca il toggle della voce al tap', (
      WidgetTester tester,
    ) async {
      final MockViewModel = MockAttivitaViewModel();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: AudioTogglesWidget(viewModel: MockViewModel)),
        ),
      );

      //cerca e preme il bottone "Guida Vocale"
      final textButton = find.text("Guida Vocale");
      await tester.tap(textButton);
      await tester.pumpAndSettle();

      // verifica che il metodo toggleGuidaVocale sia stato chiamato e che lo stato sia cambiato
      expect(MockViewModel.toggleVoceChiamato, isTrue);
    });

    //test3: widget del poi vicino
    testWidgets('LandmarkCardWidget appare solo se c\'è un luogo vicino', (
      WidgetTester tester,
    ) async {
      final MockViewModel = MockAttivitaViewModel();
      MockViewModel.luogoVicinoAttuale = null;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: LandmarkCardWidget(viewModel: MockViewModel)),
        ),
      );

      //non c'è nessun luogo quindi non deve esserci
      expect(find.byIcon(Icons.place), findsNothing);
      expect(find.text("SEI NEI PRESSI DI"), findsNothing);

      //simulzione di rilevamento poi
      MockViewModel.luogoVicinoAttuale = "Quercia Secolare";
      MockViewModel.notifyListeners();
      await tester.pump();

      //la card deve essere visibile con il nome del luogo
      expect(find.text("SEI NEI PRESSI DI"), findsOneWidget);
      expect(find.text("Quercia Secolare"), findsOneWidget);
    });

    //test 4: termina attività
    testWidgets('TerminateButtonWidget chiama la funzione onTerminate', (
      WidgetTester tester,
    ) async {
      bool bottonePremuto = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TerminateButtonWidget(
              onTerminate: () {
                bottonePremuto = true;
              },
            ),
          ),
        ),
      );

      //tap sul bottone "Termina Sessione"
      await tester.tap(find.text("Termina Sessione"));
      await tester.pumpAndSettle();

      //verifica che la funzione sia stata chiamata
      expect(bottonePremuto, isTrue);
    });

    //test 5: test della mappa
    testWidgets(
      'MapCardWidget renderizza la mappa e i suoi layer (Smoke Test)',
      (WidgetTester tester) async {
        final MockViewModel = MockAttivitaViewModel();

        // simula l'esistenza di un punto gps
        MockViewModel.tracciaGps = [const GeoPoint(42.358246, 13.386197)];

        //creo controller per la mappa
        final mapController = MapController();

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: MapCardWidget(
                viewModel: MockViewModel,
                mapController: mapController,
              ),
            ),
          ),
        );

        //verifica che la  mappa sia stata renderizzata
        expect(find.byType(FlutterMap), findsOneWidget);
        //verica che i layer della mappa siano stati renderizzati
        expect(find.byType(TileLayer), findsOneWidget);
        expect(find.byType(PolylineLayer), findsOneWidget);
        expect(find.byType(MarkerLayer), findsOneWidget);
      },
    );

    //test 6: test del player audio
    testWidgets(
      'PlayerCardWidget mostra Silenzio di default e cambia testo se in play',
      (WidgetTester tester) async {
        final MockViewModel = MockAttivitaViewModel();

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(body: PlayerCardWidget(viewModel: MockViewModel)),
          ),
        );

        //verifica che sia inizialmente "Silenzio"
        expect(find.text("Silenzio"), findsOneWidget);
        expect(find.byIcon(Icons.play_arrow), findsOneWidget);

        //inserisco una traccia attiva
        MockViewModel.tracciaAttiva = 'foresta.mp3';
        MockViewModel.notifyListeners();
        await tester.pumpAndSettle();

        //verifico che ora mostri il nome della traccia
        expect(find.text("Foresta"), findsOneWidget);
        expect(find.byIcon(Icons.pause), findsOneWidget);
      },
    );

    testWidgets('PlayerCardWidget invoca i metodi di riproduzione al tap', (
      WidgetTester tester,
    ) async {
      final MockViewModel = MockAttivitaViewModel();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: PlayerCardWidget(viewModel: MockViewModel)),
        ),
      );

      //cerco i bottoni di controllo del player
      final prevBtn = find.byIcon(Icons.skip_previous);
      final nextBtn = find.byIcon(Icons.skip_next);
      final playBtn = find.byIcon(Icons.play_arrow);

      //tap su tutti i bottoni
      await tester.tap(prevBtn);
      await tester.tap(nextBtn);
      await tester.tap(playBtn);
      await tester.pumpAndSettle();

      //verifico se i metodi del ViewModel sono stati chiamati
      expect(MockViewModel.prevChiamato, isTrue);
      expect(MockViewModel.nextChiamato, isTrue);
      expect(MockViewModel.toggleAudioChiamato, isTrue);
    });

    testWidgets('PlayerCardWidget inoltra il cambio di volume dello Slider', (
      WidgetTester tester,
    ) async {
      final MockViewModel = MockAttivitaViewModel();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: PlayerCardWidget(viewModel: MockViewModel)),
        ),
      );

      //cerco lo slider del volume
      final slider = find.byType(Slider);
      expect(slider, findsOneWidget);

      //modifico il valore dllo slider
      await tester.drag(slider, const Offset(50.0, 0.0));
      await tester.pumpAndSettle();

      //verifico che il ViewModel abbia ricevuto il nuovo valore del volume
      expect(MockViewModel.volumeImpostato, isNotNull);
      expect(MockViewModel.volumeImpostato, isNot(equals(0.4)));
    });
  });
}
