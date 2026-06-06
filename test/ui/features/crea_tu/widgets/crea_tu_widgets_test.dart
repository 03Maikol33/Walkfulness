import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:walkfulness/domain/models/user_model.dart';
import 'package:walkfulness/ui/core/providers/user_provider.dart';
import 'package:walkfulness/ui/features/crea_tu/view/crea_tu_view.dart';
import 'package:walkfulness/ui/features/crea_tu/view_model/crea_tu_view_model.dart';

// view model mock per testare i widget senza dipendere dalla logica reale

class MockCreaTuViewModel extends ChangeNotifier implements CreaTuViewModel {
  @override
  bool isCalcolandoRotta = false;

  @override
  List<PinModel> pinSelezionati = [];

  @override
  MapController mapController = MapController();

  @override
  List<Polyline> lineePercorso = [];

  @override
  LatLng? posizioneUtente;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class MockUserProvider extends ChangeNotifier implements UserProvider {
  @override
  bool isLoading = false;
  @override
  UserModel? utente = UserModel(
    uid: "test_uid",
    email: "test@test.com",
    nome: "Tester",
  );
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

//inizio test

void main() {
  group('Test su tutti i Widget di CreaTuView', () {
    // test 1: verifica che l'header mostri il titolo corretto in base a isDettaglio
    testWidgets('HeaderWidget mostra il titolo in base a isDettaglio', (
      WidgetTester tester,
    ) async {
      // testo  quando isDettaglio è false
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: HeaderWidget(isDettaglio: false)),
        ),
      );
      expect(find.text("Crea percorso"), findsOneWidget);

      // testo quando isDettaglio è true
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: HeaderWidget(isDettaglio: true)),
        ),
      );
      expect(find.text("Dettagli percorso"), findsOneWidget);
    });

    // test 2: verifica che il LoadingOverlayWidget appaia solo quando isCalcolandoRotta è true
    testWidgets(
      'LoadingOverlayWidget appare solo se isCalcolandoRotta è true',
      (WidgetTester tester) async {
        final MockViewModel = MockCreaTuViewModel();

        // provo con false
        MockViewModel.isCalcolandoRotta = false;
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: LoadingOverlayWidget(viewModel: MockViewModel),
            ),
          ),
        );
        expect(find.byType(CircularProgressIndicator), findsNothing);

        //provo con true
        MockViewModel.isCalcolandoRotta = true;
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: LoadingOverlayWidget(viewModel: MockViewModel),
            ),
          ),
        );
        expect(find.byType(CircularProgressIndicator), findsOneWidget);
        expect(find.text("Calcolo del percorso..."), findsOneWidget);
      },
    );

    // test 3: verifica che il SearchBarWidget chiami onSearch quando l'utente inserisce testo e preme invio
    testWidgets('SearchBarWidget invoca onSearch quando l\'utente cerca', (
      WidgetTester tester,
    ) async {
      String testoCercato = "";

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SearchBarWidget(
              onSearch: (valore) {
                testoCercato = valore;
              },
            ),
          ),
        ),
      );

      // inserisco del testo nella TextField
      await tester.enterText(find.byType(TextField), "Roma");
      // simulo la pressione del tasto invio
      await tester.testTextInput.receiveAction(TextInputAction.done);

      // verifico che la callback onSearch sia stata invocata con il testo corretto
      expect(testoCercato, "Roma");
    });

    // test 4: verifica che HandleAreaWidget mostri il numero di pin selezionati
    testWidgets('HandleAreaWidget mostra correttamente il numero di pin', (
      WidgetTester tester,
    ) async {
      final MockViewModel = MockCreaTuViewModel();
      // imposto 3 pin selezionati per testare l'aggiornamento del testo
      MockViewModel.pinSelezionati = [
        PinModel(coordinate: const LatLng(0, 0)),
        PinModel(coordinate: const LatLng(0, 0)),
        PinModel(coordinate: const LatLng(0, 0)),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: HandleAreaWidget(
              viewModel: MockViewModel,
              isEspanso: false,
              onToggle: () {},
              onDragEnd: (details) {},
            ),
          ),
        ),
      );

      // Il testo deve essersi aggiornato ascoltando il viewModel
      expect(find.text("PUNTI INSERITI (3)"), findsOneWidget);
    });

    // test 5: verifica che ActionButtonsWidget mostri i bottoni Salva e Avvia
    testWidgets('ActionButtonsWidget mostra sempre i bottoni Salva e Avvia', (
      WidgetTester tester,
    ) async {
      final MockViewModel = MockCreaTuViewModel();

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<UserProvider>(
              create: (_) => MockUserProvider(),
            ),
          ],
          child: MaterialApp(
            home: Scaffold(body: ActionButtonsWidget(viewModel: MockViewModel)),
          ),
        ),
      );

      // verifica che i bottoni siano sempre presenti
      expect(find.text("Salva"), findsOneWidget);
      expect(find.text("Avvia"), findsOneWidget);
    });

    // --- test 6:verifica se la mappa viene renderizzata
    testWidgets('MapLayerWidget renderizza la mappa senza errori', (
      WidgetTester tester,
    ) async {
      final MockViewModel = MockCreaTuViewModel();
      // per le animazioni della mappa
      final animationController = AnimationController(
        vsync: const TestVSync(),
        duration: const Duration(seconds: 1),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MapLayerWidget(
              viewModel: MockViewModel,
              animationController: animationController,
            ),
          ),
        ),
      );

      // verifica che la mappa sia stata renderizzata
      expect(find.byType(FlutterMap), findsOneWidget);
    });
  });
}
