import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:walkfulness/ui/core/providers/user_provider.dart';
import 'package:walkfulness/ui/features/attivita/view/attivita_view.dart';
import 'package:walkfulness/ui/features/foresta_immersiva/view/foresta_immersiva_view.dart';
import 'package:walkfulness/ui/features/main_wrapper/view_model/main_wrapper_view_model.dart';
import 'package:walkfulness/ui/features/storico_attivita/view/storico_attivita_view.dart';
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
    // La pagina principale ora è totalmente STATICA!
    // Nessun Provider.of in ascolto globale, nessun ListenableBuilder gigante.
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. INTENTO GIORNALIERO (Ascolta il ForestaViewModel)
          QuoteWidget(viewModel: _viewModel),

          const SizedBox(height: 32),

          // 2. AZIONI (Totalmente statiche, non ascoltano nulla)
          const ActionCardsWidget(),

          const SizedBox(height: 24),

          // 3. SEZIONE FORESTA (Ascolta il UserProvider tramite Consumer)
          const UserForestWidget(),
        ],
      ),
    );
  }
}

// ============================================================================
// WIDGET ESTRATTI E OTTIMIZZATI CON ASCOLTO GRANULARE
// ============================================================================

class QuoteWidget extends StatelessWidget {
  final ForestaViewModel viewModel;

  const QuoteWidget({super.key, required this.viewModel});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Questo ListenableBuilder ascolta SOLO il caricamento della frase
    return ListenableBuilder(
      listenable: viewModel,
      builder: (context, _) {
        if (viewModel.isLoading) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 20.0),
            child: Center(
              child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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
            SizedBox(
              width: MediaQuery.of(context).size.width * 0.80,
              child: Text(
                "“${viewModel.frase}”",
                style: GoogleFonts.aBeeZee(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.primary,
                  height: 1.3,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class ActionCardsWidget extends StatelessWidget {
  const ActionCardsWidget({super.key});

  @override
  Widget build(BuildContext context) {
    // Essendo stateless pura, questa riga di bottoni non verrà MAI ricalcolata
    // a meno che non si cambi schermata nel Wrapper.
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: ActionCard(
              title: "Avvia Subito",
              subtitle: "Cammina libero senza limiti",
              icon: Icons.bolt,
              isPrimary: true,
              onTap: () {
                // context.read non mette in ascolto la UI, serve solo a lanciare comandi!
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const AttivitaView()),
                );
              },
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: ActionCard(
              title: "Storico attività",
              subtitle: "Visualizza le tue attività passate",
              icon: Icons.history,
              onTap: () {
                context.read<MainWrapperViewModel>().apriPaginaInterna(
                  const StoricoAttivitaView(),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class UserForestWidget extends StatelessWidget {
  const UserForestWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Il Consumer fa da "ListenableBuilder" specifico per il UserProvider.
    // Si aggiornerà solo questa Card quando l'utente sale di livello!
    return Consumer<UserProvider>(
      builder: (context, userProvider, child) {
        if (userProvider.isLoading) {
          return Center(
            child: CircularProgressIndicator(color: theme.colorScheme.primary),
          );
        }

        final utente = userProvider.utente;
        if (utente == null) {
          return const Center(child: Text("Errore nel caricamento dei dati"));
        }

        return ForestCard(
          livello: utente.livelloCalcolato,
          percentuale: utente.percentualeLivello.toInt(),
          onTap: () {
            context.read<MainWrapperViewModel>().apriPaginaInterna(
              const ForestaImmersivaView(),
            );
          },
        );
      },
    );
  }
}
