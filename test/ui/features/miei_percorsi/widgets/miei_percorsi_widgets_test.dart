import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:walkfulness/domain/models/percorso_model.dart';
import 'package:walkfulness/ui/features/main_wrapper/view_model/main_wrapper_view_model.dart';
import 'package:walkfulness/ui/features/miei_percorsi/view/miei_percorsi_view.dart';
import 'package:walkfulness/ui/features/miei_percorsi/view_model/miei_percorsi_view_model.dart';
import 'package:walkfulness/ui/core/widgets/route_card.dart';

//Vengono creati dei finti ViewModel per testare i widget senza dipendere dalla logica reale e quindi da FireBase

class MockMieiPercorsiViewModel extends ChangeNotifier
    implements MieiPercorsiViewModel {
  @override
  bool isLoading = false;

  @override
  String? errorMessage;

  @override
  List<PercorsoModel> percorsiVisibili = [];

  @override
  bool visualizzaPubblici = false;

  bool filtroCambiato = false;

  @override
  void cambiaFiltro(bool mostraPubblici) {
    filtroCambiato = true;
    visualizzaPubblici = mostraPubblici;
    notifyListeners();
  }

  @override
  Future<void> caricaMieiPercorsi(String userId) async {}
  @override
  Future<bool> eliminaPercorso(String percorsoId) async => true;
  @override
  Future<void> toggleVisibilita(PercorsoModel percorso) async {}

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

// mock del MainWrapper per testare il bottone Vedi Dettagli
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

//inizio dei test

void main() {
  group('Test su MieiPercorsi Widgets', () {
    //test 1: lista dei percorsi
    testWidgets('RouteListWidget mostra caricamento se isLoading è true', (
      WidgetTester tester,
    ) async {
      final MockViewModel = MockMieiPercorsiViewModel();
      MockViewModel.isLoading = true; // imposta lo stato a caricamento

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: RouteListWidget(viewModel: MockViewModel)),
        ),
      );

      // verifica che ci sia un CircularProgressIndicator a schermo
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets(
      'RouteListWidget mostra messaggio vuoto se non ci sono percorsi',
      (WidgetTester tester) async {
        final MockViewModel = MockMieiPercorsiViewModel();
        MockViewModel.isLoading = false;
        MockViewModel.percorsiVisibili = []; // lista vuota

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(body: RouteListWidget(viewModel: MockViewModel)),
          ),
        );

        // verifica il testo di stato vuoto
        expect(
          find.text("Nessun percorso trovato in questa categoria."),
          findsOneWidget,
        );
      },
    );

    //test 2: sezione dei filtri
    testWidgets('FilterSectionWidget invoca cambiaFiltro al tap su Pubblici', (
      WidgetTester tester,
    ) async {
      final MockViewModel = MockMieiPercorsiViewModel();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: FilterSectionWidget(viewModel: MockViewModel)),
        ),
      );

      // cerca il bottone "Pubblici" poi fa tap
      await tester.tap(find.text('Pubblici'));
      await tester.pumpAndSettle();

      // verifica che il ViewModel abbia registrato il click
      expect(MockViewModel.filtroCambiato, isTrue);
    });

    //test 3: tasti azione delle singole card
    testWidgets(
      'CardActionButtonsWidget apre il dialog di eliminazione al tap del cestino',
      (WidgetTester tester) async {
        final MockViewModel = MockMieiPercorsiViewModel();
        final MockWrapper = MockMainWrapperViewModel();

        //finto percorso da passare al bottone
        final percorsoMock = PercorsoModel(
          id: "123",
          utenteId: "user1",
          nome: "Percorso Test",
          tappe: [],
          nomeCreatore: "Maikol",
          citta: "Roma",
          tags: [],
        );

        await tester.pumpWidget(
          //serve il provider perché il widget usa context.read<MainWrapperViewModel>
          ChangeNotifierProvider<MainWrapperViewModel>(
            create: (_) => MockWrapper,
            child: MaterialApp(
              home: Scaffold(
                body: CardActionButtonsWidget(
                  viewModel: MockViewModel,
                  percorso: percorsoMock,
                ),
              ),
            ),
          ),
        );

        // cerca l'icona del cestino ed esegue il tap
        await tester.tap(find.byIcon(Icons.delete_outline));
        await tester.pumpAndSettle(); // aspetta che sia apra il dialog

        // verifica che il dialog sia presente
        expect(find.text("Elimina percorso"), findsOneWidget);
        expect(
          find.text("Sei sicuro di voler eliminare 'Percorso Test'?"),
          findsOneWidget,
        );
      },
    );
  });
}
