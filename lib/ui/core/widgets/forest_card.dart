import 'package:flutter/material.dart';

class ForestCard extends StatelessWidget {
  final int livello;
  final int percentuale;

  const ForestCard({
    super.key,
    required this.livello,
    required this.percentuale,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      elevation: 0,
      color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.2),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("La Mia", style: theme.textTheme.titleMedium),
                      Text(
                        "Foresta",
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                Chip(
                  label: Text("LIVELLO $livello"),
                  labelStyle: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 10,
                  ),
                  backgroundColor: Colors.grey.shade300,
                  side: BorderSide.none,
                ),
              ],
            ),
            const SizedBox(height: 30),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                _bar(percentuale.toDouble() / 2, Colors.grey.shade300),
                const SizedBox(width: 8),
                _bar(percentuale.toDouble(), theme.colorScheme.primary),
                const SizedBox(width: 8),
                _bar(
                  (percentuale / 2 + percentuale / 4).toDouble(),
                  Colors.grey.shade300,
                ),
                const SizedBox(width: 15),
                Text(
                  "${percentuale.toInt()}%",
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w300,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Center(
              child: Text(
                "PROGRESSO VERSO IL PROSSIMO ALBERO",
                style: TextStyle(
                  fontSize: 10,
                  letterSpacing: 1.5,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _bar(double height, Color color) {
    return Container(
      width: 10,
      height: height,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(10),
      ),
    );
  }
}
