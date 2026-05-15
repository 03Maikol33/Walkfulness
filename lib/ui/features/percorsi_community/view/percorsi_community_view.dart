import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
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
    // Inizializza il caricamento, il GPS e la ricerca iniziale
    _viewModel.inizializza();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ListenableBuilder(
      listenable: _viewModel,
      builder: (context, _) {
        return Scaffold(
          backgroundColor: const Color(0xFFF7FBF8),
          body: _buildContent(theme),
        );
      },
    );
  }

  Widget _buildContent(ThemeData theme) {
    if (_viewModel.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_viewModel.errorMessage != null) {
      return Center(child: Text(_viewModel.errorMessage!));
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      // Titolo (0) + Ricerca (1) + Tag (2) + Lista Percorsi
      itemCount: _viewModel.percorsiVisibili.length + 3,
      itemBuilder: (context, index) {
        //TITOLO
        if (index == 0) {
          return Padding(
            padding: const EdgeInsets.fromLTRB(4, 10, 4, 10),
            child: Text(
              "Esplora la\nCommunity",
              style: theme.textTheme.headlineLarge?.copyWith(
                color: const Color(0xFF012D1C),
              ),
            ),
          );
        }

        //BARRA DI RICERCA PER CITTA'
        if (index == 1) {
          return Container(
            margin: const EdgeInsets.fromLTRB(0, 0, 0, 16),
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
              onSubmitted: (valore) => _viewModel.impostaCitta(valore),
              decoration: const InputDecoration(
                hintText: "Cerca una città (es. Roma)...",
                prefixIcon: Icon(Icons.location_city, color: Color(0xFF012D1C)),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 15,
                ),
              ),
            ),
          );
        }

        //FILTRI TAG ORIZZONTALI
        if (index == 2) {
          return SizedBox(
            height: 50,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _viewModel.tagDisponibili.length,
              itemBuilder: (context, tIndex) {
                final tag = _viewModel.tagDisponibili[tIndex];
                final isSelected = _viewModel.tagSelezionato == tag;
                return Padding(
                  padding: const EdgeInsets.only(right: 8, bottom: 10),
                  child: FilterChip(
                    label: Text(tag),
                    selected: isSelected,
                    onSelected: (_) => _viewModel.selezionaTag(tag),
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
        }

        // GESTIONE LISTA VUOTA
        if (_viewModel.percorsiVisibili.isEmpty) {
          return const Padding(
            padding: EdgeInsets.only(top: 40),
            child: Center(
              child: Text("Nessun percorso trovato con questi filtri."),
            ),
          );
        }

        // LE CARD DEI PERCORSI
        final percorso = _viewModel.percorsiVisibili[index - 3];
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
          actionButtons: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Align(
                alignment: Alignment.centerRight,
                child: ElevatedButton.icon(
                  onPressed: () => Navigator.pushNamed(
                    context,
                    '/attivita',
                    arguments: percorso,
                  ),
                  icon: const Icon(
                    Icons.play_arrow,
                    color: Colors.white,
                    size: 20,
                  ),
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
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
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
                      arguments:
                          percorso, // Passiamo il percorso come argomento
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
          ),
        );
      },
    );
  }
}
