import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:walkfulness/domain/models/percorso_model.dart';
import 'package:walkfulness/ui/core/widgets/route_card.dart';
import 'package:walkfulness/ui/features/crea_tu/view/crea_tu_view.dart';
import 'package:walkfulness/ui/features/main_wrapper/view_model/main_wrapper_view_model.dart';
import 'package:walkfulness/ui/features/miei_percorsi/view_model/miei_percorsi_view_model.dart';
import 'package:walkfulness/ui/core/providers/user_provider.dart';

class MieiPercorsiView extends StatefulWidget {
  const MieiPercorsiView({super.key});

  @override
  State<MieiPercorsiView> createState() => _MieiPercorsiViewState();
}

class _MieiPercorsiViewState extends State<MieiPercorsiView> {
  final MieiPercorsiViewModel _viewModel = MieiPercorsiViewModel();

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      final userId = context.read<UserProvider>().utente?.uid;
      if (userId != null) {
        _viewModel.caricaMieiPercorsi(userId);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // BUILD PRINCIPALE STATICO (Nessun ListenableBuilder globale!)
    return Scaffold(
      backgroundColor: const Color(0xFFF7FBF8),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              "I Miei Percorsi",
              style: theme.textTheme.headlineLarge?.copyWith(
                color: const Color(0xFF012D1C),
              ),
            ),
          ),

          // LA LISTA (Ascolta il caricamento e i dati)
          Expanded(child: RouteListWidget(viewModel: _viewModel)),

          // I FILTRI (Ascoltano lo stato Pubblico/Privato)
          FilterSectionWidget(viewModel: _viewModel),
        ],
      ),
    );
  }
}

// ============================================================================
// WIDGET ESTRATTI E OTTIMIZZATI CON ASCOLTO GRANULARE
// ============================================================================

class RouteListWidget extends StatelessWidget {
  final MieiPercorsiViewModel viewModel;

  const RouteListWidget({super.key, required this.viewModel});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: viewModel,
      builder: (context, _) {
        if (viewModel.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (viewModel.errorMessage != null) {
          return Center(child: Text(viewModel.errorMessage!));
        }

        if (viewModel.percorsiVisibili.isEmpty) {
          return const Center(
            child: Text(
              "Nessun percorso trovato in questa categoria.",
              style: TextStyle(color: Colors.grey, fontSize: 16),
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          itemCount: viewModel.percorsiVisibili.length,
          itemBuilder: (context, index) {
            final percorso = viewModel.percorsiVisibili[index];
            final stimaKm = (percorso.tappe.length * 1.5).toStringAsFixed(1);

            return RouteCard(
              luogo: percorso.nome,
              km: "${stimaKm}Km",
              durata: "Stimata",
              imageAsset: "assets/images/forest_bg.png",
              actionButtons: CardActionButtonsWidget(
                viewModel: viewModel,
                percorso: percorso,
              ),
            );
          },
        );
      },
    );
  }
}

class FilterSectionWidget extends StatelessWidget {
  final MieiPercorsiViewModel viewModel;

  const FilterSectionWidget({super.key, required this.viewModel});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: viewModel,
      builder: (context, _) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          child: Row(
            children: [
              Expanded(
                child: FilterButtonWidget(
                  titolo: "Pubblici",
                  isActive: viewModel.visualizzaPubblici == true,
                  onTap: () => viewModel.cambiaFiltro(true),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilterButtonWidget(
                  titolo: "Privati",
                  isActive: viewModel.visualizzaPubblici == false,
                  onTap: () => viewModel.cambiaFiltro(false),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class FilterButtonWidget extends StatelessWidget {
  final String titolo;
  final bool isActive;
  final VoidCallback onTap;

  const FilterButtonWidget({
    super.key,
    required this.titolo,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFF012D1C) : Colors.white,
          borderRadius: BorderRadius.circular(25),
          border: isActive ? null : Border.all(color: Colors.grey.shade300),
        ),
        alignment: Alignment.center,
        child: Text(
          titolo,
          style: TextStyle(
            color: isActive ? Colors.white : Colors.black87,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}

class CardActionButtonsWidget extends StatelessWidget {
  final MieiPercorsiViewModel viewModel;
  final PercorsoModel percorso;

  const CardActionButtonsWidget({
    super.key,
    required this.viewModel,
    required this.percorso,
  });

  void _mostraDialogConfermaEliminazione(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Elimina percorso"),
        content: Text("Sei sicuro di voler eliminare '${percorso.nome}'?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Annulla"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              Navigator.pop(ctx);
              final successo = await viewModel.eliminaPercorso(percorso.id!);
              if (successo && context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Percorso eliminato")),
                );
              }
            },
            child: const Text("Elimina", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _mostraDialogConfermaVisibilita(BuildContext context) {
    final azione = percorso.isPublic ? "rendere PRIVATO" : "rendere PUBBLICO";
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Cambia visibilità"),
        content: Text("Vuoi davvero $azione il percorso '${percorso.nome}'?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Annulla"),
          ),
          TextButton(
            onPressed: () {
              viewModel.toggleVisibilita(percorso);
              Navigator.pop(ctx);
            },
            child: const Text("Conferma"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Badge Pubblicato/Privato
            GestureDetector(
              onTap: () => _mostraDialogConfermaVisibilita(context),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: percorso.isPublic
                      ? Colors.cyan.shade100
                      : Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    Icon(
                      percorso.isPublic ? Icons.public : Icons.lock_outline,
                      size: 14,
                      color: Colors.black87,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      percorso.isPublic ? "PUBBLICATO" : "PRIVATO",
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Bottone Riavvia
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pushNamed(context, '/attivita', arguments: percorso);
              },
              icon: const Icon(Icons.undo, size: 16, color: Colors.white),
              label: const Text(
                "RIAVVIA",
                style: TextStyle(color: Colors.white, fontSize: 12),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF012D1C),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 0,
                ),
              ),
            ),

            // Bottone Elimina
            IconButton(
              onPressed: () => _mostraDialogConfermaEliminazione(context),
              icon: const Icon(Icons.delete_outline, color: Colors.red),
              style: IconButton.styleFrom(backgroundColor: Colors.red.shade50),
            ),
          ],
        ),
        const SizedBox(height: 12),
        // Bottone Vedi Dettagli
        SizedBox(
          width: double.infinity,
          height: 48,
          child: OutlinedButton.icon(
            onPressed: () {
              context.read<MainWrapperViewModel>().apriPaginaInterna(
                const CreaTuView(),
                arguments: percorso,
              );
            },
            icon: const Icon(Icons.search, color: Color(0xFF012D1C)),
            label: const Text(
              "Vedi i Dettagli",
              style: TextStyle(color: Color(0xFF012D1C)),
            ),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Color(0xFF012D1C)),
            ),
          ),
        ),
      ],
    );
  }
}
