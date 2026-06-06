import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:walkfulness/ui/features/tribu/view_model/tribu_view_model.dart';
import 'package:walkfulness/domain/models/iniziativa_model.dart';
import 'package:walkfulness/ui/features/main_wrapper/view_model/main_wrapper_view_model.dart';
import 'package:walkfulness/ui/features/crea_iniziativa/view/crea_iniziativa_view.dart';

class TribuView extends StatelessWidget {
  const TribuView({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ChangeNotifierProvider(
      create: (_) => TribuViewModel()..caricaIniziative(),
      child: Builder(
        builder: (context) {
          final vm = context.watch<TribuViewModel>();

          return Scaffold(
            backgroundColor: const Color(0xFFF7FBF8),
            floatingActionButton: FloatingActionButton.extended(
              onPressed: () {
                context.read<MainWrapperViewModel>().apriPaginaInterna(
                  const CreaIniziativaView(),
                );
              },
              backgroundColor: const Color(0xFF012D1C),
              icon: const Icon(Icons.add, color: Colors.white),
              label: const Text(
                "Crea iniziativa",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            body: SafeArea(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Iniziative collettive",
                          style: theme.textTheme.headlineLarge?.copyWith(
                            color: const Color(0xFF012D1C),
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text("Partecipa ad iniziative collettive"),
                        const SizedBox(height: 20),

                        //ricerca
                        TextField(
                          onChanged: vm.impostaRicerca,
                          decoration: InputDecoration(
                            hintText: "Cerca luogo o titolo...",
                            prefixIcon: const Icon(Icons.search),
                            filled: true,
                            fillColor: Colors.white,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(20),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        //filtri
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              _buildFiltro(
                                context,
                                vm,
                                "Tutte",
                                TipoFiltroTribu.tutte,
                              ),
                              const SizedBox(width: 8),
                              _buildFiltro(
                                context,
                                vm,
                                "Create da me",
                                TipoFiltroTribu.mie,
                              ),
                              const SizedBox(width: 8),
                              _buildFiltro(
                                context,
                                vm,
                                "Partecipo",
                                TipoFiltroTribu.partecipo,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  Expanded(
                    child: vm.isLoading
                        ? const Center(child: CircularProgressIndicator())
                        : vm.iniziativeFiltrate.isEmpty
                        ? const Center(
                            child: Text("Nessuna iniziativa trovata."),
                          )
                        : RefreshIndicator(
                            onRefresh: vm.caricaIniziative,
                            color: const Color(0xFF012D1C),
                            child: ListView.builder(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24,
                                vertical: 8,
                              ),
                              itemCount: vm.iniziativeFiltrate.length,
                              itemBuilder: (context, index) => IniziativaCard(
                                iniziativa: vm.iniziativeFiltrate[index],
                                viewModel: vm,
                              ),
                            ),
                          ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildFiltro(
    BuildContext context,
    TribuViewModel vm,
    String testo,
    TipoFiltroTribu tipo,
  ) {
    final isSelected = vm.filtroAttuale == tipo;
    final primary = Theme.of(context).colorScheme.primary;
    return FilterChip(
      label: Text(testo),
      selected: isSelected,
      onSelected: (_) => vm.impostaFiltro(tipo),
      selectedColor: primary,
      checkmarkColor: Colors.white,
      labelStyle: TextStyle(color: isSelected ? Colors.white : Colors.black87),
      shape: const StadiumBorder(),
    );
  }
}

class IniziativaCard extends StatelessWidget {
  final IniziativaModel iniziativa;
  final TribuViewModel viewModel;

  const IniziativaCard({
    super.key,
    required this.iniziativa,
    required this.viewModel,
  });

  //aprire Google Maps con il Pin
  Future<void> _apriGoogleMaps() async {
    final lat = iniziativa.posizione.latitude;
    final lng = iniziativa.posizione.longitude;
    final Uri url = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=$lat,$lng',
    );

    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      debugPrint("Impossibile aprire Google Maps");
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isOwner = iniziativa.creatoreId == viewModel.currentUserId;
    final isPartecipante = iniziativa.partecipantiIds.contains(
      viewModel.currentUserId,
    );
    final postiRimasti =
        iniziativa.maxPartecipanti - iniziativa.partecipantiIds.length;

    return Card(
      elevation: 4,
      shadowColor: Colors.black12,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
      clipBehavior: Clip.antiAlias,
      margin: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 200,
            width: double.infinity,
            color: Colors.grey.shade300,
            child: Image.asset(
              (iniziativa.immagineCopertina?.isNotEmpty ?? false)
                  ? iniziativa.immagineCopertina!
                  : 'assets/images/iniziativa_default.jpg',
              fit: BoxFit.cover,
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  iniziativa.luogo.toUpperCase(),
                  style: const TextStyle(
                    fontSize: 10,
                    color: Colors.grey,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  iniziativa.titolo,
                  style: GoogleFonts.notoSerif(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  "Data: ${iniziativa.dataOra.day}/${iniziativa.dataOra.month}/${iniziativa.dataOra.year} - ${iniziativa.dataOra.hour}:${iniziativa.dataOra.minute.toString().padLeft(2, '0')}",
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 8),
                //pulsante per google maps
                TextButton.icon(
                  onPressed: _apriGoogleMaps,
                  icon: const Icon(Icons.directions, size: 18),
                  label: const Text("Raggiungi il posto"),
                  style: TextButton.styleFrom(
                    foregroundColor: theme.colorScheme.primary,
                    padding: EdgeInsets.zero,
                    minimumSize: const Size(50, 30),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    alignment: Alignment.centerLeft,
                  ),
                ),
                const SizedBox(height: 20),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "${iniziativa.partecipantiIds.length} partecipanti",
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    if (postiRimasti > 0)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFC7EBEB),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          "Ancora $postiRimasti posti",
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF184D4F),
                          ),
                        ),
                      )
                    else
                      const Text(
                        "AL COMPLETO",
                        style: TextStyle(
                          color: Colors.red,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    if (isOwner) ...[
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            context
                                .read<MainWrapperViewModel>()
                                .apriPaginaInterna(
                                  CreaIniziativaView(
                                    iniziativaDaModificare: iniziativa,
                                  ),
                                );
                          },
                          child: const Text("Modifica"),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red.shade100,
                          ),
                          onPressed: () => _mostraConfermaEliminazione(context),
                          child: const Text(
                            "Elimina",
                            style: TextStyle(color: Colors.red),
                          ),
                        ),
                      ),
                    ] else if (isPartecipante) ...[
                      Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange.shade100,
                          ),
                          onPressed: () => viewModel.abbandona(iniziativa.id),
                          child: const Text(
                            "Smetti di partecipare",
                            style: TextStyle(color: Colors.deepOrange),
                          ),
                        ),
                      ),
                    ] else ...[
                      Expanded(
                        child: ElevatedButton(
                          onPressed: postiRimasti > 0
                              ? () => viewModel.partecipa(iniziativa.id)
                              : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: theme.colorScheme.primary,
                          ),
                          child: const Text(
                            "Partecipa anche tu",
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _mostraConfermaEliminazione(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Elimina Iniziativa"),
        content: const Text(
          "Sei sicuro di voler eliminare definitivamente questo evento?",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Annulla"),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              viewModel.elimina(iniziativa.id);
            },
            child: const Text("Elimina", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
