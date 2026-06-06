import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:walkfulness/domain/models/percorso_model.dart';
import 'package:walkfulness/ui/features/main_wrapper/view_model/main_wrapper_view_model.dart';
import 'package:walkfulness/ui/features/percorsi_community/view/percorsi_community_view.dart';
import 'package:walkfulness/ui/features/percorsi_community/view_model/percorsi_community_view_model.dart';

// mock view models per testare i widget in isolamento

class MockPercorsiCommunityViewModel extends ChangeNotifier
    implements PercorsiCommunityViewModel {
  @override
  bool isLoading = false;

  @override
  String? errorMessage;

  @override
  List<PercorsoModel> percorsiVisibili = [];

  @override
  List<String> tagDisponibili = ["Natura", "Città", "Montagna"];

  @override
  String tagSelezionato = "Tutti";

  String? cittaCercata;
  String? tagCliccato;

  @override
  void impostaCitta(String citta) {
    cittaCercata = citta;
    notifyListeners();
  }

  @override
  void selezionaTag(String tag) {
    tagCliccato = tag;
    tagSelezionato = tag;
    notifyListeners();
  }

  @override
  Future<void> inizializza() async {}

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class MockMainWrapperViewModel extends ChangeNotifier
    implements MainWrapperViewModel {
  bool paginaAperta = false;

  @override
  void apriPaginaInterna(Widget pagina, {Object? arguments}) {
    paginaAperta = true;
    notifyListeners();
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

// inizio test

void main() {
  group('Test sui Widget di PercorsiCommunityView', () {
    // test 1: CommunitySearchBarWidget imposta la città
    testWidgets(
      'CommunitySearchBarWidget invoca impostaCitta quando si preme invio',
      (WidgetTester tester) async {
        final MockViewModel = MockPercorsiCommunityViewModel();

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: CommunitySearchBarWidget(viewModel: MockViewModel),
            ),
          ),
        );

        //cerco la barra di ricerca
        final textField = find.byType(TextField);
        expect(textField, findsOneWidget);

        // inserisco una città di test
        await tester.enterText(textField, "Milano");

        // premo invio
        await tester.testTextInput.receiveAction(TextInputAction.done);

        // verifico che la funzione del view model sia stata chiamata con il testo corretto
        expect(MockViewModel.cittaCercata, "Milano");
      },
    );

    //test 2: mostra i tag per i filtri e imposta quelli cliccati
    testWidgets(
      'CommunityTagFilterWidget mostra i tag e invoca selezionaTag al tap',
      (WidgetTester tester) async {
        final MockViewModel = MockPercorsiCommunityViewModel();

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: CommunityTagFilterWidget(viewModel: MockViewModel),
            ),
          ),
        );

        // verifico che mostri i tag disponibili
        expect(find.text("Natura"), findsOneWidget);
        expect(find.text("Città"), findsOneWidget);

        //tap su un tag
        await tester.tap(find.text("Montagna"));
        await tester.pumpAndSettle();

        // verifico che la funzione del view model sia stata chiamata con il tag cliccato
        expect(MockViewModel.tagCliccato, "Montagna");
      },
    );

    //test 3: verifica che venga mostrato il caricamento
    testWidgets(
      'CommunityRouteListWidget mostra la rotellina se isLoading è true',
      (WidgetTester tester) async {
        final MockViewModel = MockPercorsiCommunityViewModel();
        MockViewModel.isLoading = true;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: CommunityRouteListWidget(viewModel: MockViewModel),
            ),
          ),
        );

        expect(find.byType(CircularProgressIndicator), findsOneWidget);
      },
    );

    testWidgets(
      'CommunityRouteListWidget mostra messaggio vuoto se non ci sono percorsi',
      (WidgetTester tester) async {
        final MockViewModel = MockPercorsiCommunityViewModel();
        MockViewModel.isLoading = false;
        MockViewModel.percorsiVisibili = [];

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: CommunityRouteListWidget(viewModel: MockViewModel),
            ),
          ),
        );

        expect(
          find.text("Nessun percorso trovato con questi filtri."),
          findsOneWidget,
        );
      },
    );

    // test 4: verifica che vengano mostrate le card dei percorsi e che sia possibile interagire con i bottoni
    testWidgets(
      'CommunityCardActionButtons invoca MainWrapperViewModel al tap su "Vedi i Dettagli"',
      (WidgetTester tester) async {
        final MockWrapper = MockMainWrapperViewModel();

        //percorso mock da mostrare nella card
        final percorsoMock = PercorsoModel(
          id: "1",
          utenteId: "user",
          nome: "Percorso 1",
          tappe: [],
          nomeCreatore: "Mario",
          citta: "Roma",
          tags: [],
        );

        await tester.pumpWidget(
          ChangeNotifierProvider<MainWrapperViewModel>(
            create: (_) => MockWrapper,
            child: MaterialApp(
              home: Scaffold(
                body: CommunityCardActionButtons(percorso: percorsoMock),
              ),
            ),
          ),
        );

        //cerco il bottone "Vedi i Dettagli" e tap
        await tester.tap(find.text("Vedi i Dettagli"));
        await tester.pumpAndSettle();

        //verifico che abbia chiamato la funzione per aprire la pagina dei dettagli del percorso
        expect(MockWrapper.paginaAperta, isTrue);
      },
    );
  });
}
