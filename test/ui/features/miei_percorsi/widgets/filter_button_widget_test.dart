import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:walkfulness/ui/features/miei_percorsi/view/miei_percorsi_view.dart';

void main() {
  // raggrupparo più test relativi allo stesso widget
  group('FilterButtonWidget Tests', () {
    // test1: verifica che il testo appaia e che il tap funzioni
    testWidgets('Renderizza il titolo e risponde al tap', (
      WidgetTester tester,
    ) async {
      bool bottonePremuto = false;
      //monta il widget da testare
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FilterButtonWidget(
              titolo: 'Pubblici',
              isActive: false,
              onTap: () {
                bottonePremuto = true;
              },
            ),
          ),
        ),
      );

      //verifica che l'interfaccia sia disegnata bene
      // Usa find.text come suggerito dalle slide
      expect(find.text('Pubblici'), findsOneWidget);

      //simula il tap
      await tester.tap(find.text('Pubblici'));
      await tester.pumpAndSettle();

      // verifica l'effetto del tap
      expect(bottonePremuto, isTrue);
    });

    // test 2: verifica quale pulsante è attivo e quale no
    testWidgets('Cambia stile quando isActive è true', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FilterButtonWidget(
              titolo: 'Privati',
              isActive: true,
              onTap: () {},
            ),
          ),
        ),
      );

      // trova il Container del testo per ispezionarne il colore
      final containerFinder = find.descendant(
        of: find.byType(GestureDetector),
        matching: find.byType(Container),
      );

      // Estraiamo il widget reale per controllarne le proprietà
      final Container containerWidget = tester.widget(containerFinder);
      final BoxDecoration decoration =
          containerWidget.decoration as BoxDecoration;

      // verifica che lo sfondo sia Verde Scuro
      expect(decoration.color, const Color(0xFF012D1C));
    });
  });
}
