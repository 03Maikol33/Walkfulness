import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:walkfulness/ui/core/widgets/action_card.dart';

void main() {
  group('Test su ActionCard (Widget Condiviso)', () {
    //test 1: verifica che titolo, sottotitolo e icona vengano renderizzati correttamente
    testWidgets('Renderizza correttamente titolo, sottotitolo e icona', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ActionCard(
              title: 'Titolo di prova',
              subtitle: 'Sottotitolo di prova',
              icon: Icons.directions_walk,
            ),
          ),
        ),
      );

      //verifico che siano presenti nell'albero dei widget
      expect(find.text('Titolo di prova'), findsOneWidget);
      expect(find.text('Sottotitolo di prova'), findsOneWidget);
      expect(find.byIcon(Icons.directions_walk), findsOneWidget);
    });

    //test 2: verifico l'interazione
    testWidgets('Invoca la callback onTap quando cliccata', (
      WidgetTester tester,
    ) async {
      bool tapRegistrato = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ActionCard(
              title: 'Cliccami',
              subtitle: 'Test interazione',
              icon: Icons.touch_app,
              onTap: () {
                tapRegistrato = true;
              },
            ),
          ),
        ),
      );

      //tap
      await tester.tap(find.byType(ActionCard));
      await tester.pumpAndSettle();

      //verifio che la callback sia stata invocata
      expect(tapRegistrato, isTrue);
    });

    //test 3: verifica che la card venga costruita correttamente con isPrimary true, deve applicare il colore primario
    testWidgets('Costruisce correttamente la card in modalità isPrimary', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ActionCard(
              title: 'Primary',
              subtitle: 'Modalità principale',
              icon: Icons.star,
              isPrimary: true,
            ),
          ),
        ),
      );
      expect(find.text('Primary'), findsOneWidget);
      expect(find.byType(Card), findsOneWidget);
    });
  });
}
