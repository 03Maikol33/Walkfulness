import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../domain/models/activity_model.dart';
import '../../../core/widgets/route_card.dart';
import '../../../core/providers/user_provider.dart';
import '../../../core/widgets/condivisione_dialog.dart';
import '../view_model/storico_attivita_view_model.dart';

class StoricoAttivitaView extends StatefulWidget {
  const StoricoAttivitaView({super.key});

  @override
  State<StoricoAttivitaView> createState() => _StoricoAttivitaViewState();
}

class _StoricoAttivitaViewState extends State<StoricoAttivitaView> {
  final StoricoAttivitaViewModel _viewModel = StoricoAttivitaViewModel();

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      final userId = context.read<UserProvider>().utente?.uid;
      if (userId != null) {
        _viewModel.caricaStorico(userId);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // IL BUILD PRINCIPALE ORA È STATICO E PULITO
    return Scaffold(
      backgroundColor: const Color(0xFFF7FBF8),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                "Storico Attività",
                style: theme.textTheme.headlineLarge?.copyWith(
                  color: const Color(0xFF012D1C),
                ),
              ),
            ),
            // Solo la lista ascolta i cambiamenti del ViewModel
            Expanded(child: StoricoListWidget(viewModel: _viewModel)),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// WIDGET ESTRATTI E OTTIMIZZATI CON ASCOLTO GRANULARE
// ============================================================================

class StoricoListWidget extends StatelessWidget {
  final StoricoAttivitaViewModel viewModel;

  const StoricoListWidget({super.key, required this.viewModel});

  @override
  Widget build(BuildContext context) {
    // Questo è l'unico ListenableBuilder della schermata
    return ListenableBuilder(
      listenable: viewModel,
      builder: (context, _) {
        if (viewModel.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (viewModel.errorMessage != null) {
          return Center(child: Text(viewModel.errorMessage!));
        }

        if (viewModel.attivitaList.isEmpty) {
          return const Center(
            child: Text(
              "Nessuna attività completata finora.",
              style: TextStyle(color: Colors.grey, fontSize: 16),
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          itemCount: viewModel.attivitaList.length,
          itemBuilder: (context, index) {
            final attivita = viewModel.attivitaList[index];
            final data = attivita.data;

            // Formattazione manuale della data
            final dataStr =
                "${data.day.toString().padLeft(2, '0')}/${data.month.toString().padLeft(2, '0')}/${data.year} - ${data.hour.toString().padLeft(2, '0')}:${data.minute.toString().padLeft(2, '0')}";

            String sottotitolo = "Camminata libera";
            // Se in futuro re-integrerai l'umore post-attività nel modello, scommentalo qui:
            /*if (attivita.umorePost != null) {
              sottotitolo = "Umore: ${attivita.umorePost!.toUpperCase()}";
            }*/

            return RouteCard(
              luogo: "Sessione del $dataStr",
              km: "${attivita.km.toStringAsFixed(1)} Km",
              durata: "${attivita.durata.inMinutes} min",
              sottotitolo: sottotitolo,
              imageAsset: "assets/images/forest_bg.png",
              actionButtons: StoricoCardButtonsWidget(attivita: attivita),
            );
          },
        );
      },
    );
  }
}

class StoricoCardButtonsWidget extends StatelessWidget {
  final ActivityModel attivita;

  const StoricoCardButtonsWidget({super.key, required this.attivita});

  @override
  Widget build(BuildContext context) {
    // Bottone totalmente statico che si limita ad aprire il Dialog
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: OutlinedButton.icon(
        onPressed: () {
          showDialog(
            context: context,
            builder: (context) => CondivisioneDialog(
              attivita: attivita,
              /*umore: attivita.umorePost,*/
            ),
          );
        },
        icon: const Icon(Icons.share_outlined, color: Color(0xFF012D1C)),
        label: const Text(
          "Condividi Cammino",
          style: TextStyle(
            color: Color(0xFF012D1C),
            fontWeight: FontWeight.bold,
          ),
        ),
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: Color(0xFF012D1C)),
          shape: const StadiumBorder(),
        ),
      ),
    );
  }
}
