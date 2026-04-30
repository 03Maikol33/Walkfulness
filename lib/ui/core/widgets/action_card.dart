import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ActionCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final bool isPrimary;
  final Color? colorOverride;
  final VoidCallback? onTap;

  const ActionCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    this.isPrimary = false,
    this.colorOverride,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      clipBehavior: Clip.antiAlias, // Taglia visivamente l'eccedenza
      color:
          colorOverride ??
          (isPrimary ? theme.colorScheme.primary : theme.cardTheme.color),
      child: InkWell(
        onTap: onTap ?? () => print("Cliccato su $title"),
        child: Container(
          constraints: const BoxConstraints(minHeight: 150),
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          // Usiamo questo per evitare che Flutter segnali l'overflow in basso
          child: SingleChildScrollView(
            physics: const NeverScrollableScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  color: (isPrimary || colorOverride != null)
                      ? Colors.white
                      : theme.colorScheme.primary,
                  size: 28,
                ),
                const SizedBox(height: 12),
                Text(
                  title,
                  style: GoogleFonts.notoSerif(
                    color: (isPrimary || colorOverride != null)
                        ? Colors.white
                        : theme.colorScheme.primary,
                    fontWeight: FontWeight.normal,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: (isPrimary || colorOverride != null)
                        ? Colors.white70
                        : Colors.black54,
                    fontSize: 12,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/*/////////////////////////////////////////////////////////

//helper per costruire le cards
Widget _buildActionCard(
  BuildContext context, {
  required String title,
  required String subtitle,
  required IconData icon,
  required VoidCallback onTap,
  bool isPrimary = false,
  Color? colorOverride, // Nuovo parametro per il colore personalizzato
}) {
  final theme = Theme.of(context);

  return Card(
    clipBehavior: Clip.antiAlias,
    // Se c'è un colore forzato usa quello, altrimenti usa primary se è primary, altrimenti il default
    color:
        colorOverride ??
        (isPrimary ? theme.colorScheme.primary : theme.cardTheme.color),
    child: InkWell(
      onTap: onTap,
      child: Container(
        constraints: BoxConstraints(minHeight: 150),
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: (isPrimary || colorOverride != null)
                  ? Colors.white
                  : theme.colorScheme.primary,
              size: 28,
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: GoogleFonts.notoSerif(
                // Ho messo 'Lora' come esempio, cambialo con quello che preferisci
                color: (isPrimary || colorOverride != null)
                    ? Colors.white
                    : theme.colorScheme.primary,
                fontWeight: FontWeight.normal,
                fontSize: 18,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(
                color: (isPrimary || colorOverride != null)
                    ? Colors.white70
                    : Colors.black54,
                fontSize: 12,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    ),
  );
}*/
