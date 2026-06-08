import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:walkfulness/domain/models/activity_model.dart';
import 'package:walkfulness/ui/core/widgets/condivisione_dialog.dart';
import 'package:walkfulness/ui/core/widgets/route_card.dart';
import 'package:walkfulness/ui/features/storico_attivita/view/storico_attivita_view.dart';
import 'package:walkfulness/ui/features/storico_attivita/view_model/storico_attivita_view_model.dart';

//mock del ViewModel per testare i widget in isolamento

class FakeStoricoAttivitaViewModel extends ChangeNotifier
    implements StoricoAttivitaViewModel {
  @override
  bool isLoading = false;

  @override
  String? errorMessage;

  @override
  List<ActivityModel> attivitaList = [];

  //metodo di caricamento vuoto
  @override
  Future<void> caricaStorico(String userId) async {}

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

//inizio test

void main() {
  group('Test sui Widget di StoricoAttivitaView', () {
    //test 1: caricamento
    testWidgets('StoricoListWidget mostra la rotellina se isLoading è true', (
      WidgetTester tester,
    ) async {
      final fakeViewModel = FakeStoricoAttivitaViewModel();
      fakeViewModel.isLoading = true;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: StoricoListWidget(viewModel: fakeViewModel)),
        ),
      );

      // verifico che venga mostrato il CircularProgressIndicator
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    // test 2: messaggio di errore
    testWidgets('StoricoListWidget mostra messaggio di errore', (
      WidgetTester tester,
    ) async {
      final fakeViewModel = FakeStoricoAttivitaViewModel();
      fakeViewModel.isLoading = false;
      fakeViewModel.errorMessage = "Impossibile caricare lo storico.";

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: StoricoListWidget(viewModel: fakeViewModel)),
        ),
      );

      // verifico che venga mostrato il messaggio di errore
      expect(find.text("Impossibile caricare lo storico."), findsOneWidget);
    });

    //test 3: la lista è vuota
    testWidgets('StoricoListWidget mostra messaggio se non ci sono attività', (
      WidgetTester tester,
    ) async {
      final fakeViewModel = FakeStoricoAttivitaViewModel();
      fakeViewModel.isLoading = false;
      fakeViewModel.errorMessage = null;
      fakeViewModel.attivitaList = []; //vuota

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: StoricoListWidget(viewModel: fakeViewModel)),
        ),
      );

      expect(find.text("Nessuna attività completata finora."), findsOneWidget);
    });

    //test 4: bottone condivisione
    testWidgets('StoricoCardButtonsWidget apre il dialog di condivisione', (
      WidgetTester tester,
    ) async {
      final attivitaMock = ActivityModel(
        id: "act_1",
        userId: "user_1",
        data: DateTime.now(),
        percorso: const [],
        durata: const Duration(minutes: 30),
        km: 3.0,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StoricoCardButtonsWidget(attivita: attivitaMock),
          ),
        ),
      );

      //cerco il bottone di condivisione e tap
      final condividiBtn = find.text("Condividi Cammino");
      expect(condividiBtn, findsOneWidget);

      await tester.tap(condividiBtn);
      await tester.pumpAndSettle();

      //verifico che il widget di condivisione appaia nell'albero
      expect(find.byType(CondivisioneDialog), findsOneWidget);
    });

    //test 4
    testWidgets(
      'StoricoListWidget formatta la data e renderizza gli elementi della lista',
      (WidgetTester tester) async {
        final fakeViewModel = FakeStoricoAttivitaViewModel();
        fakeViewModel.isLoading = false;
        fakeViewModel.errorMessage = null;

        // 1. Creiamo una data precisa per testare lo "zero" iniziale
        final dataTest = DateTime(2024, 6, 5, 9, 5);

        fakeViewModel.attivitaList = [
          ActivityModel(
            id: "test_1",
            userId: "user_test",
            data: dataTest,
            percorso: const [],
            durata: const Duration(minutes: 120),
            km: 12.5,
          ),
        ];

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SizedBox(
                height: 800, // Diamogli spazio vitale per disegnare la lista
                child: StoricoListWidget(viewModel: fakeViewModel),
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // 2. ASSERTS BLINDATI

        // Verifichiamo che la card esista! Questo ci garantisce che
        // il ListView.builder abbia funzionato e copre tutte le righe.
        expect(find.byType(RouteCard), findsOneWidget);

        // Verifichiamo il testo del luogo (Ricordandoci che RouteCard fa .toUpperCase()!)
        expect(find.text("SESSIONE DEL 05/06/2024 - 09:05"), findsOneWidget);

        // Verifichiamo il sottotitolo (che è un normale widget Text)
        expect(find.text("Camminata libera"), findsOneWidget);

        // Verifichiamo la presenza dei bottoni custom passati alla card
        expect(find.byType(StoricoCardButtonsWidget), findsOneWidget);
      },
    );
  });
}
