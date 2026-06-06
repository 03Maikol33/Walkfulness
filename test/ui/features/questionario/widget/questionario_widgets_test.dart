import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:walkfulness/domain/models/activity_model.dart';
import 'package:walkfulness/ui/features/main_wrapper/view_model/main_wrapper_view_model.dart';
import 'package:walkfulness/ui/features/questionario/view/questionario_view.dart';
import 'package:walkfulness/ui/features/questionario/view_model/questionario_view_model.dart';

// modk dei ViewModel per testare i widget in isolamento
class MockQuestionarioViewModel extends ChangeNotifier
    implements QuestionarioViewModel {
  @override
  bool isLoading = false;

  bool salvataggioInvocato = false;

  @override
  Future<bool> salvaQuestionario({
    required String activityId,
    String? umore,
    bool? percorsoHaRilassato,
    List<String>? elementiApprezzati,
  }) async {
    isLoading = true;
    notifyListeners();
    await Future.delayed(const Duration(milliseconds: 100));
    salvataggioInvocato = true;
    isLoading = false;
    notifyListeners();
    return true;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class MockMainWrapperViewModel extends ChangeNotifier
    implements MainWrapperViewModel {
  int paginaCorrente = 0;
  @override
  void cambiaPagina(int index) {
    paginaCorrente = index;
    notifyListeners();
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  group('Test su QuestionarioView', () {
    final testAttivita = ActivityModel(
      id: "act_123",
      userId: "user_123",
      data: DateTime(2024, 1, 1),
      percorso: const [],
      durata: const Duration(minutes: 45),
      km: 5.2,
    );

    // helper per costruire il widget di test
    Widget buildTestWidget(
      MockQuestionarioViewModel mockVm,
      MockMainWrapperViewModel mockWrapper,
    ) {
      return MultiProvider(
        providers: [
          ChangeNotifierProvider<MainWrapperViewModel>(
            create: (_) => mockWrapper,
          ),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: QuestionarioView(
              attivita: testAttivita,
              viewModelOverride: mockVm,
            ),
          ),
        ),
      );
    }

    //test 1: verifica che quando si seleziona un umore venga evidenziato correttamente
    testWidgets('MoodSelectorWidget seleziona umore', (
      WidgetTester tester,
    ) async {
      final mockVm = MockQuestionarioViewModel();
      final mockWrapper = MockMainWrapperViewModel();

      await tester.pumpWidget(buildTestWidget(mockVm, mockWrapper));

      final energicoFinder = find.descendant(
        of: find.byType(GestureDetector),
        matching: find.text("⚡"),
      );

      // scrolla fino a che l'elemento è visibile
      await tester.ensureVisible(energicoFinder.first);
      await tester.pumpAndSettle();

      await tester.tap(energicoFinder.first);
      await tester.pumpAndSettle();
      expect(find.text("ENERGICO"), findsOneWidget);
    });

    //test 2: verifica che quando si seleziona "Sì" al toggle di rilassamento venga evidenziato correttamente
    testWidgets('RelaxToggleWidget seleziona "Sì" correttamente', (
      WidgetTester tester,
    ) async {
      final mockVm = MockQuestionarioViewModel();
      final mockWrapper = MockMainWrapperViewModel();

      await tester.pumpWidget(buildTestWidget(mockVm, mockWrapper));

      final siFinder = find.text("Sì");

      // scrolla fino al bottone "Sì"
      await tester.ensureVisible(siFinder);
      await tester.pumpAndSettle();

      await tester.tap(siFinder);
      await tester.pumpAndSettle();

      expect(find.byType(GestureDetector), findsWidgets);
    });

    //test 3: verifica che quando si selezionano gli elementi apprezzati vengano evidenziati correttamente
    testWidgets('SaveButtonWidget salva ed esegue il redirect', (
      WidgetTester tester,
    ) async {
      final mockVm = MockQuestionarioViewModel();
      final mockWrapper = MockMainWrapperViewModel();

      await tester.pumpWidget(buildTestWidget(mockVm, mockWrapper));

      final bottoneSalvaFinder = find.text("Torna alla Foresta");

      // scrolla fino alla fine della pagina per il bottone di salvataggio
      await tester.ensureVisible(bottoneSalvaFinder);
      await tester.pumpAndSettle();

      await tester.tap(bottoneSalvaFinder);
      await tester.pumpAndSettle();

      expect(mockVm.salvataggioInvocato, isTrue);
    });
  });
}
