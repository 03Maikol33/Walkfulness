import 'dart:ffi';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:walkfulness/ui/core/widgets/action_card.dart';
import 'package:walkfulness/ui/features/attivita/view/attivita_view.dart';

class CreaView extends StatelessWidget {
  const CreaView({super.key});

  @override
  Widget build(BuildContext context) {
    //recupero il tema
    final theme = Theme.of(context);

    return Scaffold(
      body: SingleChildScrollView(
        //corpo scrollabile
        padding: const EdgeInsets.all(16), //padding intorno al contenuto
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start, //allineamento a sinisgtra,
          children: [
            Text(
              "Inizia Attività",
              style: theme.textTheme.headlineLarge, //stile del testo
            ),
            const SizedBox(height: 8), //spazio verticale
            Text("Scegli come connetterti con la natura oggi."),
            const SizedBox(height: 24),

            //Inizio Cards
            ActionCard(
              title: "Avvia Subito",
              subtitle: "Cammina senza limiti",
              icon: Icons.bolt,
              isPrimary: true,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const AttivitaView()),
                );
              },
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: ActionCard(
                    title: "Genera con AI",
                    subtitle: "Creato sul tuo stato d'animo",
                    icon: Icons.auto_awesome,
                    onTap: () {}, // Funzione vuota corretta
                    colorOverride: theme.colorScheme.secondary,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ActionCard(
                    title: "Crea Tu",
                    subtitle: "Disegna il tuo nuovo cammino",
                    icon: Icons.brush,
                    onTap: () {},
                  ),
                ),
              ],
            ),
            Row(
              children: [
                Expanded(
                  child: ActionCard(
                    title: "Cerca Percorsi",
                    subtitle: "Esplora i percorsi della community",
                    icon: Icons.search,
                    onTap: () {},
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ActionCard(
                    title: "I miei percorsi",
                    subtitle: "Cerca tra quelli creati da te",
                    icon: Icons.map,
                    onTap: () {},
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
