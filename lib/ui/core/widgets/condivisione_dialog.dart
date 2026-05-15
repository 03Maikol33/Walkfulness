import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../../../domain/models/activity_model.dart';

class CondivisioneDialog extends StatefulWidget {
  final ActivityModel attivita;
  final String? umore;

  const CondivisioneDialog({super.key, required this.attivita, this.umore});

  @override
  State<CondivisioneDialog> createState() => _CondivisioneDialogState();
}

class _CondivisioneDialogState extends State<CondivisioneDialog> {
  final GlobalKey _globalKey = GlobalKey();
  bool _isCondividendo = false;

  Future<void> _generaECondividiImmagine() async {
    setState(() => _isCondividendo = true);

    try {
      RenderRepaintBoundary boundary =
          _globalKey.currentContext!.findRenderObject()
              as RenderRepaintBoundary;

      ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      ByteData? byteData = await image.toByteData(
        format: ui.ImageByteFormat.png,
      );
      Uint8List pngBytes = byteData!.buffer.asUint8List();

      final directory = await getTemporaryDirectory();
      final imagePath = await File(
        '${directory.path}/walkfulness_share.png',
      ).create();
      await imagePath.writeAsBytes(pngBytes);

      // Testo di condivisione pulito, senza emoji
      await Share.shareXFiles(
        [XFile(imagePath.path)],
        text:
            'Oggi ho dedicato ${widget.attivita.durata.inMinutes} minuti a me stesso con Walkfulness.',
      );

      if (mounted) Navigator.pop(context);
    } catch (e) {
      debugPrint('Errore durante la condivisione: $e');
    } finally {
      if (mounted) setState(() => _isCondividendo = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          RepaintBoundary(
            key: _globalKey,
            child: _buildCartolinaSocial(context, primaryColor),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton.icon(
              onPressed: _isCondividendo ? null : _generaECondividiImmagine,
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              icon: _isCondividendo
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Icon(Icons.ios_share, color: Colors.white),
              label: Text(
                _isCondividendo ? "Generazione in corso..." : "Condividi",
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              "Chiudi",
              style: TextStyle(color: Colors.white70),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCartolinaSocial(BuildContext context, Color primaryColor) {
    final theme = Theme.of(context);

    return Container(
      width: 350,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: theme
            .colorScheme
            .surface, // Usa il colore di sfondo di sistema (es. bianco)
        borderRadius: BorderRadius.circular(32),
        boxShadow: const [
          BoxShadow(
            color: Colors.black26, // Ombra più morbida
            blurRadius: 20,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset("assets/images/logo_decorated.png", height: 50),
            ],
          ),
          const SizedBox(height: 40),
          Text(
            widget.umore != null
                ? "Oggi mi sento\n${widget.umore!.toUpperCase()}"
                : "Il mio cammino oggi.", // Testo più neutro se l'umore non è disponibile
            textAlign: TextAlign.left,
            style: GoogleFonts.notoSerif(
              fontSize: 28,
              fontWeight: FontWeight.w600,
              color: primaryColor, // Testo visibile sullo sfondo chiaro
              height: 1.2,
            ),
          ),
          const SizedBox(height: 40),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildStat(
                context,
                "${widget.attivita.km.toStringAsFixed(1)}",
                "KM",
                primaryColor,
              ),
              Container(
                width: 1,
                height: 40,
                color: theme
                    .colorScheme
                    .outlineVariant, // Divisore grigio neutro di sistema
              ),
              _buildStat(
                context,
                "${widget.attivita.durata.inMinutes}",
                "MINUTI",
                primaryColor,
              ),
            ],
          ),
          const SizedBox(height: 40),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: primaryColor.withOpacity(
                0.1,
              ), // Sfondo leggerissimo per il badge
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              "Unisciti a me,\nScarica Walkfulness!",
              style: TextStyle(
                color: primaryColor,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStat(
    BuildContext context,
    String valore,
    String etichetta,
    Color primaryColor,
  ) {
    final theme = Theme.of(context);

    return Column(
      children: [
        Text(
          valore,
          style: GoogleFonts.inter(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color:
                primaryColor, // Niente più colori fluo, usa il primario dell'app
          ),
        ),
        Text(
          etichetta,
          style: TextStyle(
            fontSize: 10,
            color: theme
                .colorScheme
                .onSurfaceVariant, // Grigio scuro per ottima leggibilità
            letterSpacing: 1.5,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
