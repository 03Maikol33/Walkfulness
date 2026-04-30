import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:walkfulness/ui/core/providers/user_provider.dart';
import '../../../core/widgets/action_card.dart';
import '../../../core/widgets/forest_card.dart';
import '../view_model/foresta_view_model.dart';

class ForestaView extends StatefulWidget {
  const ForestaView({super.key});

  @override
  State<ForestaView> createState() => _ForestaViewState();
}

class _ForestaViewState extends State<ForestaView> {
  final _viewModel = ForestaViewModel();

  @override
  void initState() {
    super.initState();
    _viewModel.inizializza();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Recupero l'utente loggato grazie al provider
    final userProvider = Provider.of<UserProvider>(context);
    final utente = userProvider.utente;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. INTENTO GIORNALIERO
          Text(
            "PENSIERO DEL GIORNO",
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.2,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 12),

          // 2. CITAZIONE (Vincolata al 55%)
          SizedBox(
            width: MediaQuery.of(context).size.width * 0.80,
            child: Text(
              "“${_viewModel.frase}”",
              style: GoogleFonts.aBeeZee(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.primary,
                height: 1.3,
              ),
            ),
          ),

          const SizedBox(height: 32),

          // 3. AZIONI (Row con IntrinsicHeight)
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: ActionCard(
                    title: "Avvia Subito",
                    subtitle: "Cammina libero senza limiti",
                    icon: Icons.bolt,
                    isPrimary: true,
                    onTap: () {},
                  ),
                ),
                const SizedBox(width: 8),
                const Expanded(
                  child: ActionCard(
                    title: "Storico attività",
                    subtitle: "Visualizza le tue attività passate",
                    icon: Icons.history,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // 3. SEZIONE FORESTA (Card replicata per coerenza)
          ForestCard(
            livello: utente?.livelloCalcolato ?? 1, // Usa utente dal provider
            percentuale:
                utente?.percentualeLivello.toInt() ??
                0, // Usa utente dal provider
          ),
        ],
      ),
    );
  }

  /*
  Widget _buildBar(double height, {bool isMain = false}) {
    return Container(
      width: 12,
      height: height,
      decoration: BoxDecoration(
        color: isMain ? const Color(0xFF012D1C) : Colors.grey.shade300,
        borderRadius: BorderRadius.circular(10),
      ),
    );
  }*/
}
