import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:walkfulness/domain/models/percorso_model.dart';
import 'package:walkfulness/ui/core/widgets/route_card.dart';
import 'package:walkfulness/ui/features/main_wrapper/view_model/main_wrapper_view_model.dart';
import 'package:walkfulness/ui/features/percorsi_community/view_model/percorsi_community_view_model.dart';
import 'package:walkfulness/ui/features/crea_tu/view/crea_tu_view.dart';

class PercorsiCommunityView extends StatefulWidget {
  const PercorsiCommunityView({super.key});

  @override
  State<PercorsiCommunityView> createState() => _PercorsiCommunityViewState();
}

class _PercorsiCommunityViewState extends State<PercorsiCommunityView> {
  final PercorsiCommunityViewModel _viewModel = PercorsiCommunityViewModel();

  @override
  void initState() {
    super.initState();
    _viewModel.inizializza();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7FBF8),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const CommunityTitleWidget(),
            CommunitySearchBarWidget(viewModel: _viewModel),
            CommunityTagFilterWidget(viewModel: _viewModel),
            Expanded(child: CommunityRouteListWidget(viewModel: _viewModel)),
          ],
        ),
      ),
    );
  }
}

// widget componenti UI

class CommunityTitleWidget extends StatelessWidget {
  const CommunityTitleWidget({super.key});

  @override
  Widget build(BuildContext context) {
    //statico
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 10),
      child: Text(
        "Percorsi della\nCommunity",
        style: theme.textTheme.headlineLarge?.copyWith(
          color: const Color(0xFF012D1C),
        ),
      ),
    );
  }
}

class CommunitySearchBarWidget extends StatelessWidget {
  final PercorsiCommunityViewModel viewModel;

  const CommunitySearchBarWidget({super.key, required this.viewModel});

  @override
  Widget build(BuildContext context) {
    // La barra comunica col ViewModel onSubmitted ma non ascolta
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TextField(
        onSubmitted: (valore) => viewModel.impostaCitta(valore),
        decoration: const InputDecoration(
          hintText: "Cerca una città (es. Roma)...",
          prefixIcon: Icon(Icons.location_city, color: Color(0xFF012D1C)),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 15),
        ),
      ),
    );
  }
}

class CommunityTagFilterWidget extends StatelessWidget {
  final PercorsiCommunityViewModel viewModel;

  const CommunityTagFilterWidget({super.key, required this.viewModel});

  @override
  Widget build(BuildContext context) {
    // Ascolta il ViewModel per capire quale tag evidenziare
    return ListenableBuilder(
      listenable: viewModel,
      builder: (context, _) {
        return SizedBox(
          height: 50,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: viewModel.tagDisponibili.length,
            itemBuilder: (context, index) {
              final tag = viewModel.tagDisponibili[index];
              final isSelected = viewModel.tagSelezionato == tag;

              return Padding(
                padding: const EdgeInsets.only(right: 8, bottom: 10),
                child: FilterChip(
                  label: Text(tag),
                  selected: isSelected,
                  onSelected: (_) => viewModel.selezionaTag(tag),
                  selectedColor: const Color(0xFF012D1C),
                  checkmarkColor: Colors.white,
                  labelStyle: TextStyle(
                    color: isSelected ? Colors.white : Colors.black87,
                    fontWeight: isSelected
                        ? FontWeight.bold
                        : FontWeight.normal,
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}

class CommunityRouteListWidget extends StatelessWidget {
  final PercorsiCommunityViewModel viewModel;

  const CommunityRouteListWidget({super.key, required this.viewModel});

  @override
  Widget build(BuildContext context) {
    // Ascolta il ViewModel per mostrare la rotellina gli errori o le Card
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
          return const Padding(
            padding: EdgeInsets.only(top: 40),
            child: Center(
              child: Text("Nessun percorso trovato con questi filtri."),
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          itemCount: viewModel.percorsiVisibili.length,
          itemBuilder: (context, index) {
            final percorso = viewModel.percorsiVisibili[index];
            final puntoPartenza = percorso.tappe.isNotEmpty
                ? percorso.tappe.first['nome'] ?? "Partenza Ignota"
                : "Punto di Partenza";
            final stimaKm = (percorso.tappe.length * 1.5).toStringAsFixed(1);
            final dataStr = percorso.dataCreazione != null
                ? percorso.dataCreazione!.split(' ').first
                : "Recente";

            return RouteCard(
              luogo: puntoPartenza,
              km: "${stimaKm}km",
              durata: dataStr,
              sottotitolo: "Creato da ${percorso.nomeCreatore}",
              imageAsset: "assets/images/forest_bg.png",
              actionButtons: CommunityCardActionButtons(percorso: percorso),
            );
          },
        );
      },
    );
  }
}

class CommunityCardActionButtons extends StatelessWidget {
  final PercorsoModel percorso;

  const CommunityCardActionButtons({super.key, required this.percorso});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Align(
          alignment: Alignment.centerRight,
          child: ElevatedButton.icon(
            onPressed: () =>
                Navigator.pushNamed(context, '/attivita', arguments: percorso),
            icon: const Icon(Icons.play_arrow, color: Colors.white, size: 20),
            label: const Text(
              "AVVIA PERCORSO",
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF012D1C),
              shape: const StadiumBorder(),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          height: 50,
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
        ),
      ],
    );
  }
}
