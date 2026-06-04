import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class RouteCard extends StatelessWidget {
  final String luogo;
  final String km;
  final String durata;
  final String? sottotitolo;
  final String? imageAsset;
  final Widget actionButtons;

  const RouteCard({
    super.key,
    required this.luogo,
    required this.km,
    required this.durata,
    this.sottotitolo,
    this.imageAsset,
    required this.actionButtons,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // --- PARTE SUPERIORE: Immagine e Testo ---
          ClipRRect(
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(32),
              topRight: Radius.circular(32),
              bottomLeft: Radius.circular(12),
              bottomRight: Radius.circular(12),
            ),
            child: SizedBox(
              height: 180,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // Sfondo (Immagine o Colore)
                  if (imageAsset != null)
                    Image.asset(imageAsset!, fit: BoxFit.cover)
                  else
                    Container(color: theme.colorScheme.primary),

                  // Gradiente per rendere il testo leggibile
                  DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withValues(alpha: 0.7),
                        ],
                      ),
                    ),
                  ),

                  // Testo in basso a sinistra
                  Positioned(
                    bottom: 16,
                    left: 20,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.location_on_outlined,
                              color: Colors.white70,
                              size: 14,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              luogo.toUpperCase(),
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.2,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        RichText(
                          text: TextSpan(
                            style: GoogleFonts.notoSerif(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                            children: [
                              TextSpan(text: "$km "),
                              TextSpan(
                                text: "| ",
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.5),
                                ),
                              ),
                              TextSpan(text: durata),
                            ],
                          ),
                        ),
                        if (sottotitolo != null) ...[
                          const SizedBox(height: 2),
                          Text(
                            sottotitolo!,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.7),
                              fontSize: 12,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ]
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Bottoni Dinamici
          Padding(padding: const EdgeInsets.all(16.0), child: actionButtons),
        ],
      ),
    );
  }
}
