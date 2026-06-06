import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:walkfulness/domain/models/user_model.dart';
import 'package:walkfulness/ui/core/providers/user_provider.dart';
import 'package:walkfulness/ui/core/widgets/action_card.dart';
import 'package:walkfulness/ui/core/widgets/forest_card.dart';
import 'package:walkfulness/ui/features/foresta/view/foresta_view.dart';
import 'package:walkfulness/ui/features/foresta/view_model/foresta_view_model.dart';
import 'package:walkfulness/ui/features/main_wrapper/view_model/main_wrapper_view_model.dart';

// mock view models e provider per testare i widget in isolamento

class MockForestaViewModel extends ChangeNotifier implements ForestaViewModel {
  @override
  bool isLoading = false;

  @override
  String frase = "Frase motivazionale di test";

  @override
  Future<void> inizializza() async {}

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class MockUserProvider extends ChangeNotifier implements UserProvider {
  @override
  bool isLoading = false;

  @override
  UserModel? utente;

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
  group('Test sui Widget di ForestaView', () {
    // test 1: widget della frase del giorno mostra caricamento e poi frase
    testWidgets('QuoteWidget mostra il caricamento se isLoading è true', (
      WidgetTester tester,
    ) async {
      final MockViewModel = MockForestaViewModel();
      MockViewModel.isLoading = true; // forza stato caricamento

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: QuoteWidget(viewModel: MockViewModel)),
        ),
      );

      // verifico mostri il CircularProgressIndicator e non la frase
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text("PENSIERO DEL GIORNO"), findsNothing);
    });

    //test 2: widget della frase del giorno mostra la frase quando il caricamento finisce
    testWidgets('QuoteWidget mostra la frase quando il caricamento finisce', (
      WidgetTester tester,
    ) async {
      final MockViewModel = MockForestaViewModel();
      MockViewModel.isLoading = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: QuoteWidget(viewModel: MockViewModel)),
        ),
      );

      // verifico mostri la frase e non il caricamento
      expect(find.text("PENSIERO DEL GIORNO"), findsOneWidget);
      expect(find.text("“Frase motivazionale di test”"), findsOneWidget);
    });

    // test 3: ActionCardsWidget mostra le card e risponde al tap su Storico
    testWidgets(
      'ActionCardsWidget renderizza le card e risponde al tap su Storico',
      (WidgetTester tester) async {
        final MockWrapper = MockMainWrapperViewModel();

        await tester.pumpWidget(
          ChangeNotifierProvider<MainWrapperViewModel>(
            create: (_) => MockWrapper,
            child: const MaterialApp(home: Scaffold(body: ActionCardsWidget())),
          ),
        );

        // verifico che ci siano 2 ActionCard e i testi corretti
        expect(find.byType(ActionCard), findsNWidgets(2));
        expect(find.text("Avvia Subito"), findsOneWidget);
        expect(find.text("Storico attività"), findsOneWidget);

        // tap sulla card "Storico attività"
        await tester.tap(find.text("Storico attività"));
        await tester.pumpAndSettle();

        // verifico che la pagina sia stata aperta
        expect(MockWrapper.paginaAperta, isTrue);
      },
    );

    // test 4: UserForestWidget mostra caricamento se il provider sta caricando
    testWidgets(
      'UserForestWidget mostra caricamento se il provider sta caricando',
      (WidgetTester tester) async {
        final MockProvider = MockUserProvider();
        MockProvider.isLoading = true; // forza stato caricamento

        await tester.pumpWidget(
          ChangeNotifierProvider<UserProvider>(
            create: (_) => MockProvider,
            child: const MaterialApp(home: Scaffold(body: UserForestWidget())),
          ),
        );

        expect(find.byType(CircularProgressIndicator), findsOneWidget);
      },
    );

    // test 5: UserForestWidget mostra errore se l'utente è nullo
    testWidgets('UserForestWidget mostra errore se l\'utente è nullo', (
      WidgetTester tester,
    ) async {
      final MockProvider = MockUserProvider();
      MockProvider.isLoading = false;
      MockProvider.utente = null;

      await tester.pumpWidget(
        ChangeNotifierProvider<UserProvider>(
          create: (_) => MockProvider,
          child: const MaterialApp(home: Scaffold(body: UserForestWidget())),
        ),
      );

      expect(find.text("Errore nel caricamento dei dati"), findsOneWidget);
    });

    // test 6: UserForestWidget mostra ForestCard e naviga al tap
    testWidgets('UserForestWidget mostra ForestCard e naviga al tap', (
      WidgetTester tester,
    ) async {
      final MockProvider = MockUserProvider();
      final MockWrapper = MockMainWrapperViewModel();

      //utente mock
      MockProvider.isLoading = false;
      MockProvider.utente = UserModel(
        uid: "123",
        email: "test@mail.com",
        nome: "Tester",
        kmPercorsi: 10.0,
      );

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<UserProvider>(create: (_) => MockProvider),
            ChangeNotifierProvider<MainWrapperViewModel>(
              create: (_) => MockWrapper,
            ),
          ],
          child: const MaterialApp(home: Scaffold(body: UserForestWidget())),
        ),
      );

      //verifico che mostri la ForestCard
      expect(find.byType(ForestCard), findsOneWidget);

      // tap sulla ForestCard
      await tester.tap(find.byType(ForestCard));
      await tester.pumpAndSettle();

      // verifico abbia aperto la pagina foresta immersiva
      expect(MockWrapper.paginaAperta, isTrue);
    });
  });
}
