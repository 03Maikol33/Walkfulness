import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:walkfulness/data/services/location/routing_service.dart';
import 'package:walkfulness/domain/models/percorso_model.dart';
import 'package:walkfulness/ui/core/providers/user_provider.dart';
import 'package:walkfulness/ui/features/crea_tu/view/salva_percorso_modal.dart';
import 'package:walkfulness/ui/features/crea_tu/view_model/crea_tu_view_model.dart';
import 'package:walkfulness/ui/features/main_wrapper/view_model/main_wrapper_view_model.dart';

class CreaTuView extends StatefulWidget {
  const CreaTuView({super.key});

  @override
  State<CreaTuView> createState() => _CreaTuViewState();
}

class _CreaTuViewState extends State<CreaTuView>
    with SingleTickerProviderStateMixin {
  //per l'animazione
  final CreaTuViewModel _viewModel = CreaTuViewModel();

  //stato ui
  bool _isEspanso = false;
  bool _isReady = false;
  late AnimationController _animationController;

  //variabili d'appoggio per leggere gli argomenti passati dopo la creazione della mappa
  Object? argsPendenti;
  bool _argomentiLetti = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();

    Future.delayed(const Duration(milliseconds: 350), () {
      if (mounted) {
        setState(() => _isReady = true);

        // aspetta la fine del frame per assicurarci che la mappa sia già renderizzata
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _viewModel.inizializza();
          if (argsPendenti != null) {
            if (argsPendenti is PercorsoModel) {
              _viewModel.caricaPercorsoEsistente(argsPendenti as PercorsoModel);
            } else if (argsPendenti is List<PinModel>) {
              _viewModel.caricaPercorsoGenerato(argsPendenti as List<PinModel>);
            }
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _viewModel.dispose();
    _animationController.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // legge gli argomenti
    if (!_argomentiLetti) {
      _argomentiLetti = true;
      argsPendenti =
          ModalRoute.of(context)?.settings.arguments ??
          Provider.of<MainWrapperViewModel>(context, listen: false).arguments;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isReady) {
      return const Scaffold(
        backgroundColor: Color(0xFFF7FBF8),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    bool isDettaglio = argsPendenti != null;

    final altezzaSchermo = MediaQuery.of(context).size.height;
    final altezzaContratta = 250.0;
    final altezzaEspansa = altezzaSchermo - 330.0;
    final altezzaAttuale = _isEspanso ? altezzaEspansa : altezzaContratta;

    return Scaffold(
      backgroundColor: const Color(0xFFF7FBF8),
      body: SafeArea(
        child: Column(
          children: [
            HeaderWidget(isDettaglio: isDettaglio),

            Expanded(
              child: Stack(
                children: [
                  MapLayerWidget(
                    viewModel: _viewModel,
                    animationController: _animationController,
                  ),
                  LoadingOverlayWidget(viewModel: _viewModel),

                  //menu inferiore espandibile
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeOutCubic,
                      height: altezzaAttuale,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.vertical(
                          top: Radius.circular(40),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black12,
                            blurRadius: 10,
                            offset: Offset(0, -3),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          HandleAreaWidget(
                            viewModel: _viewModel,
                            isEspanso: _isEspanso,
                            onToggle: () =>
                                setState(() => _isEspanso = !_isEspanso),
                            onDragEnd: (details) {
                              if (details.primaryVelocity! < -100)
                                setState(() => _isEspanso = true);
                              else if (details.primaryVelocity! > 100)
                                setState(() => _isEspanso = false);
                            },
                          ),
                          SearchBarWidget(
                            onSearch: _viewModel.cercaEAggiungiLuogo,
                          ),
                          Expanded(child: PinListWidget(viewModel: _viewModel)),
                          ActionButtonsWidget(viewModel: _viewModel),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

//widget componenti dell'ui

class HeaderWidget extends StatelessWidget {
  final bool isDettaglio;
  const HeaderWidget({super.key, required this.isDettaglio});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Text(
            isDettaglio ? "Dettagli percorso" : "Crea percorso",
            style: theme.textTheme.headlineLarge?.copyWith(
              color: const Color(0xFF012D1C),
            ),
          ),
        ],
      ),
    );
  }
}

class MapLayerWidget extends StatelessWidget {
  final CreaTuViewModel viewModel;
  final AnimationController animationController;

  const MapLayerWidget({
    super.key,
    required this.viewModel,
    required this.animationController,
  });

  @override
  Widget build(BuildContext context) {
    final cyanPrimary = Theme.of(context).colorScheme.primary;

    return ListenableBuilder(
      listenable: viewModel,
      builder: (context, _) {
        return FlutterMap(
          mapController: viewModel.mapController,
          options: MapOptions(
            initialCenter: const LatLng(42.358246, 13.386197),
            initialZoom: 15.0,
            onLongPress: (tap, point) => viewModel.aggiungiPin(point),
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.walkfulness.app',
            ),
            PolylineLayer(
              polylines: viewModel.lineePercorso
                  .where((p) => p.color != Colors.white)
                  .toList(),
            ),
            AnimatedBuilder(
              animation: animationController,
              builder: (context, child) {
                return ShaderMask(
                  shaderCallback: (rect) {
                    return LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      transform: GradientRotation(
                        animationController.value * 2 * 3.14,
                      ),
                      colors: const [
                        Color(0xFF001F12),
                        Color(0xFF00695C),
                        Color(0xFF00E5FF),
                        Color(0xFF7C4DFF),
                        Color(0xFFFF4081),
                        Color(0xFFFFD740),
                      ],
                      stops: const [0.0, 0.2, 0.4, 0.6, 0.8, 1.0],
                    ).createShader(rect);
                  },
                  child: PolylineLayer(
                    polylines: viewModel.lineePercorso
                        .where((p) => p.color == Colors.white)
                        .map(
                          (p) => Polyline(
                            points: p.points,
                            strokeWidth: p.strokeWidth,
                            color: Colors.white,
                          ),
                        )
                        .toList(),
                  ),
                );
              },
            ),
            MarkerLayer(
              markers: [
                if (viewModel.posizioneUtente != null)
                  Marker(
                    point: viewModel.posizioneUtente!,
                    width: 24,
                    height: 24,
                    child: _buildUserLocationMarker(cyanPrimary),
                  ),
                ...viewModel.pinSelezionati.asMap().entries.map((entry) {
                  return Marker(
                    point: entry.value.coordinate,
                    width: 35,
                    height: 35,
                    child: _buildMapMarker(cyanPrimary, entry.key + 1),
                  );
                }),
              ],
            ),
          ],
        );
      },
    );
  }

  Widget _buildUserLocationMarker(Color color) {
    return Container(
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 3),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
    );
  }

  Widget _buildMapMarker(Color primary, int numero) {
    return Container(
      decoration: BoxDecoration(
        color: primary,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 3),
        boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 4)],
      ),
      child: Center(
        child: Text(
          "$numero",
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
        ),
      ),
    );
  }
}

class LoadingOverlayWidget extends StatelessWidget {
  final CreaTuViewModel viewModel;
  const LoadingOverlayWidget({super.key, required this.viewModel});

  @override
  Widget build(BuildContext context) {
    final cyanPrimary = Theme.of(context).colorScheme.primary;

    return ListenableBuilder(
      listenable: viewModel,
      builder: (context, _) {
        if (!viewModel.isCalcolandoRotta) return const SizedBox.shrink();

        return Container(
          color: Colors.white.withValues(alpha: 0.7),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(color: cyanPrimary),
                const SizedBox(height: 16),
                Text(
                  "Calcolo del percorso...",
                  style: TextStyle(
                    color: cyanPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class HandleAreaWidget extends StatelessWidget {
  final CreaTuViewModel viewModel;
  final bool isEspanso;
  final VoidCallback onToggle;
  final Function(DragEndDetails) onDragEnd;

  const HandleAreaWidget({
    super.key,
    required this.viewModel,
    required this.isEspanso,
    required this.onToggle,
    required this.onDragEnd,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onVerticalDragEnd: onDragEnd,
      onTap: onToggle,
      child: Container(
        color: Colors.transparent,
        width: double.infinity,
        child: Column(
          children: [
            const SizedBox(height: 12),
            Container(
              width: 50,
              height: 5,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(5),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // il testo ascolta il viewmodel per aggiornare il numero di pin inseriti
                  ListenableBuilder(
                    listenable: viewModel,
                    builder: (context, _) {
                      return Text(
                        "PUNTI INSERITI (${viewModel.pinSelezionati.length})",
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                          color: Colors.black54,
                        ),
                      );
                    },
                  ),
                  Icon(
                    isEspanso ? Icons.expand_more : Icons.expand_less,
                    color: Colors.black38,
                    size: 24,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class SearchBarWidget extends StatefulWidget {
  final Function(String) onSearch;
  const SearchBarWidget({super.key, required this.onSearch});

  @override
  State<SearchBarWidget> createState() => _SearchBarWidgetState();
}

class _SearchBarWidgetState extends State<SearchBarWidget> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _submitSearch(String value) {
    if (value.trim().isEmpty) return;

    widget.onSearch(value); // Invia la query al ViewModel
    setState(() {
      _searchController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final cyanPrimary = Theme.of(context).colorScheme.primary;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFFF0F3F6),
          borderRadius: BorderRadius.circular(20),
        ),
        child: TextField(
          controller: _searchController,
          onSubmitted: _submitSearch,
          decoration: InputDecoration(
            hintText: "Cerca un luogo da aggiungere...",
            hintStyle: const TextStyle(fontSize: 14, color: Colors.black38),
            prefixIcon: Icon(Icons.search, color: cyanPrimary),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(vertical: 15),
          ),
        ),
      ),
    );
  }
}

class PinListWidget extends StatelessWidget {
  final CreaTuViewModel viewModel;
  const PinListWidget({super.key, required this.viewModel});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cyanPrimary = theme.colorScheme.primary;

    return ListenableBuilder(
      listenable: viewModel,
      builder: (context, _) {
        if (viewModel.pinSelezionati.isEmpty) {
          return Center(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.add_location_alt_outlined,
                    size: 50,
                    color: cyanPrimary.withValues(alpha: 0.3),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    "Nessun punto inserito.",
                    style: TextStyle(color: Colors.black38),
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20),
                    child: Text(
                      "Tieni premuto sulla mappa per aggiungere un punto.",
                      style: TextStyle(fontSize: 12, color: Colors.black54),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        return ReorderableListView.builder(
          buildDefaultDragHandles: false,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: viewModel.pinSelezionati.length,
          onReorder: viewModel.riordinaPin,
          itemBuilder: (context, index) {
            final pin = viewModel.pinSelezionati[index];
            final isUltimo = index == viewModel.pinSelezionati.length - 1;

            return Card(
              key: ValueKey(pin.id),
              elevation: 0,
              color: Colors.transparent,
              margin: const EdgeInsets.symmetric(vertical: 4),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 10),
                leading: CircleAvatar(
                  backgroundColor: const Color(0xFFC7EBEB),
                  child: Text(
                    "${index + 1}",
                    style: TextStyle(
                      color: cyanPrimary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                title: Text(
                  viewModel.getTitoloPin(index),
                  style: GoogleFonts.notoSerif(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: cyanPrimary,
                  ),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      pin.nome,
                      style: const TextStyle(fontSize: 11),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (!isUltimo) ...[
                      const SizedBox(height: 8),
                      InkWell(
                        onTap: () => viewModel.cambiaTipoRouting(index),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color:
                                pin.tipoRottaVersoProssimo ==
                                    TipoRouting.automatico
                                ? cyanPrimary.withValues(alpha: 0.1)
                                : Colors.grey.shade200,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color:
                                  pin.tipoRottaVersoProssimo ==
                                      TipoRouting.automatico
                                  ? cyanPrimary
                                  : Colors.grey.shade400,
                              width: 1,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                pin.tipoRottaVersoProssimo ==
                                        TipoRouting.automatico
                                    ? Icons.auto_awesome
                                    : Icons.straighten,
                                size: 14,
                                color:
                                    pin.tipoRottaVersoProssimo ==
                                        TipoRouting.automatico
                                    ? cyanPrimary
                                    : Colors.grey.shade700,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                pin.tipoRottaVersoProssimo ==
                                        TipoRouting.automatico
                                    ? "AI Routing"
                                    : "Linea d'aria",
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color:
                                      pin.tipoRottaVersoProssimo ==
                                          TipoRouting.automatico
                                      ? cyanPrimary
                                      : Colors.grey.shade700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(
                        Icons.delete_outline,
                        color: Colors.redAccent,
                        size: 20,
                      ),
                      onPressed: () => viewModel.rimuoviPin(index),
                    ),
                    ReorderableDragStartListener(
                      index: index,
                      child: const Icon(
                        Icons.drag_handle,
                        color: Colors.black26,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class ActionButtonsWidget extends StatelessWidget {
  final CreaTuViewModel viewModel;
  const ActionButtonsWidget({super.key, required this.viewModel});

  @override
  Widget build(BuildContext context) {
    final cyanPrimary = Theme.of(context).colorScheme.primary;

    return ListenableBuilder(
      listenable: viewModel,
      builder: (context, _) {
        bool canAction = viewModel.pinSelezionati.length >= 2;

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 30),
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(top: BorderSide(color: Color(0xFFEEEEEE))),
          ),
          child: Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 55,
                  child: ElevatedButton.icon(
                    onPressed: canAction
                        ? () {
                            showModalBottomSheet(
                              context: context,
                              isScrollControlled: true,
                              backgroundColor: Colors.transparent,
                              builder: (ctx) =>
                                  SalvaPercorsoModal(viewModel: viewModel),
                            );
                          }
                        : null,
                    icon: Icon(
                      Icons.save_outlined,
                      color: canAction ? Colors.black87 : Colors.black38,
                    ),
                    label: const Text(
                      "Salva",
                      style: TextStyle(
                        color: Colors.black87,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFE5E9D6),
                      disabledBackgroundColor: const Color(0xFFEEEEEE),
                      shape: const StadiumBorder(),
                      elevation: 0,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: SizedBox(
                  height: 55,
                  child: ElevatedButton.icon(
                    onPressed: canAction
                        ? () {
                            final userProvider = Provider.of<UserProvider>(
                              context,
                              listen: false,
                            );
                            viewModel.avviaSubito(
                              context,
                              userProvider.utente!.uid,
                            );
                          }
                        : null,
                    icon: Icon(
                      Icons.play_arrow,
                      color: canAction ? Colors.white : Colors.black38,
                    ),
                    label: const Text(
                      "Avvia",
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: cyanPrimary,
                      disabledBackgroundColor: const Color(0xFFEEEEEE),
                      shape: const StadiumBorder(),
                      elevation: 0,
                    ),
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
