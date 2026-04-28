import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:latlong2/latlong.dart';
import 'package:walkfulness/data/services/location/routing_service.dart';
import 'package:walkfulness/ui/features/crea_tu/view_model/crea_tu_view_model.dart';

class CreaTuView extends StatefulWidget {
  const CreaTuView({super.key});

  @override
  State<CreaTuView> createState() => _CreaTuViewState();
}

class _CreaTuViewState extends State<CreaTuView>
    with SingleTickerProviderStateMixin {
  //per l'animazione
  final CreaTuViewModel _viewModel = CreaTuViewModel();
  bool _isEspanso = false;

  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    // Inizializzazione del controller: 'vsync: this' ora funzionerà correttamente
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(); // Fa scorrere il gradiente all'infinito
  }

  @override
  void dispose() {
    _viewModel.dispose();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cyanPrimary = theme.colorScheme.primary;

    final altezzaSchermo = MediaQuery.of(context).size.height;
    final altezzaContratta = altezzaSchermo * 0.35;
    final altezzaEspansa = altezzaSchermo * 0.90;
    final altezzaAttuale = _isEspanso ? altezzaEspansa : altezzaContratta;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: ListenableBuilder(
        listenable: _viewModel,
        builder: (context, _) {
          return Stack(
            children: [
              Positioned.fill(
                child: FlutterMap(
                  mapController: _viewModel.mapController,
                  options: MapOptions(
                    initialCenter: const LatLng(42.358246, 13.386197),
                    initialZoom: 15.0,
                    onLongPress: (tap, point) => _viewModel.aggiungiPin(point),
                  ),
                  children: [
                    TileLayer(
                      urlTemplate:
                          'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.walkfulness.app',
                    ),
                    PolylineLayer(
                      polylines: _viewModel.lineePercorso
                          .where((p) => p.color != Colors.white)
                          .toList(),
                    ),
                    AnimatedBuilder(
                      animation: _animationController,
                      builder: (context, child) {
                        return ShaderMask(
                          // Qui creiamo il gradiente che "scorre"
                          shaderCallback: (rect) {
                            return LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              // Spostiamo i colori in base al valore dell'animazione
                              transform: GradientRotation(
                                _animationController.value * 2 * 3.14,
                              ),
                              colors: [
                                const Color(0xFF001F12),
                                const Color(0xFF00695C),
                                const Color(0xFF00E5FF),
                                const Color(0xFF7C4DFF),
                                const Color(0xFFFF4081),
                                const Color(0xFFFFD740),
                              ],
                              stops: const [0.0, 0.2, 0.4, 0.6, 0.8, 1.0],
                            ).createShader(rect);
                          },
                          child: PolylineLayer(
                            polylines: _viewModel.lineePercorso
                                .where(
                                  (p) => p.color == Colors.white,
                                ) // Prendiamo solo le linee AI
                                .map(
                                  (p) => Polyline(
                                    points: p.points,
                                    strokeWidth: p.strokeWidth,
                                    color: Colors
                                        .white, // Il bianco "assorbe" il gradiente dello ShaderMask
                                  ),
                                )
                                .toList(),
                          ),
                        );
                      },
                    ),
                    MarkerLayer(
                      markers: [
                        if (_viewModel.posizioneUtente != null)
                          Marker(
                            point: _viewModel.posizioneUtente!,
                            width: 24,
                            height: 24,
                            child: _buildUserLocationMarker(cyanPrimary),
                          ),
                        ..._viewModel.pinSelezionati.asMap().entries.map((
                          entry,
                        ) {
                          return Marker(
                            point: entry.value.coordinate,
                            width: 35,
                            height: 35,
                            child: _buildMapMarker(theme, entry.key + 1),
                          );
                        }).toList(),
                      ],
                    ),
                  ],
                ),
              ),

              _buildFloatingHeader(context, theme, cyanPrimary),

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
                      _buildHandleArea(),
                      Expanded(
                        child: _viewModel.pinSelezionati.isEmpty
                            ? _buildEmptyState(cyanPrimary)
                            : ReorderableListView.builder(
                                // Rende il riordinamento possibile trascinando l'icona specifica
                                buildDefaultDragHandles: false,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                ),
                                itemCount: _viewModel.pinSelezionati.length,
                                onReorder: _viewModel.riordinaPin,
                                itemBuilder: (context, index) {
                                  final pin = _viewModel.pinSelezionati[index];
                                  return _buildPinListItem(
                                    context,
                                    index,
                                    pin,
                                    cyanPrimary,
                                    theme,
                                  );
                                },
                              ),
                      ),
                      _buildActionButtons(theme, cyanPrimary),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  // --- COMPONENTI UI ---

  Widget _buildUserLocationMarker(Color color) {
    return Container(
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 3),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
    );
  }

  Widget _buildHandleArea() {
    return GestureDetector(
      onVerticalDragEnd: (details) {
        if (details.primaryVelocity! < -100)
          setState(() => _isEspanso = true);
        else if (details.primaryVelocity! > 100)
          setState(() => _isEspanso = false);
      },
      onTap: () => setState(() => _isEspanso = !_isEspanso),
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
                  Text(
                    "PUNTI INSERITI (${_viewModel.pinSelezionati.length})",
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                      color: Colors.black54,
                    ),
                  ),
                  Icon(
                    _isEspanso ? Icons.expand_more : Icons.expand_less,
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

  Widget _buildPinListItem(
    BuildContext context,
    int index,
    PinModel pin,
    Color cyan,
    ThemeData theme,
  ) {
    final isUltimo = index == _viewModel.pinSelezionati.length - 1;

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
            style: TextStyle(color: cyan, fontWeight: FontWeight.bold),
          ),
        ),
        title: Text(
          _viewModel.getTitoloPin(index),
          style: GoogleFonts.notoSerif(
            fontWeight: FontWeight.bold,
            fontSize: 14,
            color: cyan,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              pin.indirizzoMock,
              style: const TextStyle(fontSize: 11),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),

            if (!isUltimo) ...[
              const SizedBox(height: 8),
              InkWell(
                onTap: () {
                  _viewModel.cambiaTipoRouting(index);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: pin.tipoRottaVersoProssimo == TipoRouting.automatico
                        ? cyan.withOpacity(0.1)
                        : Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color:
                          pin.tipoRottaVersoProssimo == TipoRouting.automatico
                          ? cyan
                          : Colors.grey.shade400,
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        pin.tipoRottaVersoProssimo == TipoRouting.automatico
                            ? Icons.auto_awesome
                            : Icons.straighten,
                        size: 14,
                        color:
                            pin.tipoRottaVersoProssimo == TipoRouting.automatico
                            ? cyan
                            : Colors.grey.shade700,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        pin.tipoRottaVersoProssimo == TipoRouting.automatico
                            ? "AI Routing"
                            : "Linea d'aria",
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color:
                              pin.tipoRottaVersoProssimo ==
                                  TipoRouting.automatico
                              ? cyan
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
              onPressed: () => _viewModel.rimuoviPin(index),
            ),
            ReorderableDragStartListener(
              index: index,
              child: const Icon(Icons.drag_handle, color: Colors.black26),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons(ThemeData theme, Color cyan) {
    bool canAction = _viewModel.pinSelezionati.length >= 2;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 30),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFEEEEEE))),
      ),
      child: Row(
        children: [
          // Tasto SALVA (Verde chiaro foto)
          Expanded(
            child: SizedBox(
              height: 55,
              child: ElevatedButton.icon(
                onPressed: canAction ? () => _viewModel.salvaPercorso() : null,
                icon: Icon(
                  Icons.save_outlined,
                  color: canAction ? Colors.black87 : Colors.black38,
                ),
                label: const Text(
                  "SALVA",
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
          // Tasto AVVIA (Ciano primario)
          Expanded(
            child: SizedBox(
              height: 55,
              child: ElevatedButton.icon(
                onPressed: canAction ? () => _viewModel.avviaSubito() : null,
                icon: Icon(
                  Icons.play_arrow,
                  color: canAction ? Colors.white : Colors.black38,
                ),
                label: const Text(
                  "AVVIA",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: cyan,
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
  }

  // --- ALTRI COMPONENTI (Mappa Marker, Header, Empty State rimasti uguali) ---
  Widget _buildMapMarker(ThemeData theme, int numero) {
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.primary,
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

  Widget _buildFloatingHeader(
    BuildContext context,
    ThemeData theme,
    Color cyan,
  ) {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: Container(
        margin: const EdgeInsets.fromLTRB(24, 60, 24, 0),
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.95),
          borderRadius: BorderRadius.circular(32),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              "CREA PERCORSO",
              style: GoogleFonts.notoSerif(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: cyan,
              ),
            ),
            const SizedBox(height: 15),
            Container(
              height: 55,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: const Color(0xFFF0F3F6),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  Icon(Icons.search, color: cyan),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      "Cerca...",
                      style: TextStyle(color: Colors.black38, fontSize: 16),
                    ),
                  ),
                  const Icon(Icons.tune, color: Colors.black38),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(Color cyan) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.add_location_alt_outlined,
            size: 50,
            color: cyan.withOpacity(0.3),
          ),
          const SizedBox(height: 16),
          const Text(
            "Nessun punto inserito.",
            style: TextStyle(color: Colors.black38),
          ),
          const Text(
            "Tieni premuto sulla mappa per aggiungere un punto.",
            style: TextStyle(fontSize: 12, color: Colors.black54),
          ),
        ],
      ),
    );
  }
}
