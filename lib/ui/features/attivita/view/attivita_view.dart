// lib/ui/features/attivita/view/attivita_in_corso_view.dart
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:walkfulness/ui/core/providers/user_provider.dart';
import '../view_model/attivita_view_model.dart';

class AttivitaView extends StatefulWidget {
  const AttivitaView({super.key});

  @override
  State<AttivitaView> createState() => _AttivitaViewState();
}

class _AttivitaViewState extends State<AttivitaView> {
  final _viewModel = AttivitaViewModel();

  //controller della mappa
  final _mapController = MapController();
  int _puntiTracciati = 0;

  @override
  void initState() {
    super.initState();
    _viewModel.avviaAttivita();

    //aggiunge un listener al view model
    //quando il view model riceve nuovi dati sulla posizione, centra la mappa su quella posizione
    _viewModel.addListener(_centraMappa);
  }

  void _centraMappa() {
    if (_viewModel.tracciaGps.length < _puntiTracciati) {
      _puntiTracciati = 0;
    }

    //Sposta la mappa SOLO se la lista dei punti GPS è aumentata
    if (_viewModel.tracciaGps.length > _puntiTracciati) {
      _puntiTracciati = _viewModel.tracciaGps.length;
      final ultimoPunto = _viewModel.tracciaGps.last;

      //spostare la mappa
      _mapController.move(
        LatLng(ultimoPunto.latitude, ultimoPunto.longitude),
        16.0, // Manteniamo uno zoom ravvicinato
      );
    }
  }

  @override
  void dispose() {
    _viewModel.removeListener(_centraMappa);
    _mapController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: ListenableBuilder(
        listenable: _viewModel,
        builder: (context, _) {
          return Stack(
            children: [
              SafeArea(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      const SizedBox(height: 50),
                      _buildMainStats(theme),
                      _buildDebugToggle(),
                      _buildAudioTogglesCard(theme),
                      const SizedBox(height: 10),
                      _buildMapCard(theme),
                      const SizedBox(height: 10),
                      _buildLandmarkCard(theme),
                      const SizedBox(height: 10),
                      _buildPlayerCard(theme),
                      const SizedBox(height: 10),
                      _buildTerminateButton(context, theme),
                      const SizedBox(height: 20),
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

  Widget _buildMapCard(ThemeData theme) {
    return Container(
      height: 200,
      margin: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(32),
        color: Colors.white.withOpacity(0.9),
      ),
      clipBehavior: Clip.antiAlias,
      child: FlutterMap(
        mapController: _mapController,
        options: MapOptions(
          initialCenter: _viewModel.tracciaGps.isNotEmpty
              ? LatLng(
                  _viewModel.tracciaGps.last.latitude,
                  _viewModel.tracciaGps.last.longitude,
                )
              : const LatLng(42.358246, 13.386197),
          initialZoom: 16.0,
        ),
        children: [
          TileLayer(
            //urlTemplate: 'https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}',
            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
            userAgentPackageName: 'com.example.walkfulness',
          ),
          //crea la traccia che si aggiorna in tempo reale con i punti raccolti
          PolylineLayer(
            polylines: [
              Polyline(
                points: _viewModel.tracciaGps
                    .map((p) => LatLng(p.latitude, p.longitude))
                    .toList(),
                color: theme.colorScheme.primary,
                strokeWidth: 8,
              ),
            ],
          ),

          MarkerLayer(
            markers: [
              // Mostriamo il pallino solo se abbiamo almeno una coordinata
              if (_viewModel.tracciaGps.isNotEmpty)
                Marker(
                  point: LatLng(
                    _viewModel.tracciaGps.last.latitude,
                    _viewModel.tracciaGps.last.longitude,
                  ),
                  width: 24,
                  height: 24,
                  child: Container(
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary,
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
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMainStats(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "SESSIONE IN CORSO",
            style: TextStyle(
              letterSpacing: 1.5,
              fontSize: 12,
              color: theme.colorScheme.primary,
            ),
          ),
          FittedBox(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  "${_viewModel.durata.inMinutes.remainder(60).toString().padLeft(2, '0')}:${_viewModel.durata.inSeconds.remainder(60).toString().padLeft(2, '0')}",
                  style: GoogleFonts.notoSerif(
                    fontSize: 64,
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  "min",
                  style: GoogleFonts.notoSerif(
                    fontSize: 24,
                    color: theme.colorScheme.primary,
                  ),
                ),
                const SizedBox(width: 24),
                Text(
                  "${_viewModel.kmPercorsi.toStringAsFixed(1)}",
                  style: GoogleFonts.notoSerif(
                    fontSize: 64,
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  "km",
                  style: GoogleFonts.notoSerif(
                    fontSize: 24,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAudioTogglesCard(ThemeData theme) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.8),
        borderRadius: BorderRadius.circular(40),
      ),
      child: FittedBox(
        child: Row(
          children: [
            TextButton(
              onPressed: () {
                _viewModel.toggleGuidaVocale(
                  !_viewModel.audioGuideService.isAttiva,
                );
              },
              child: Row(
                children: [
                  Icon(
                    _viewModel.audioGuideService.isAttiva
                        ? Icons.volume_up
                        : Icons.volume_off,
                    color: _viewModel.audioGuideService.isAttiva
                        ? theme.colorScheme.primary
                        : Colors.grey,
                  ),
                  const SizedBox(width: 8),
                  const Text("Guida Vocale"),
                ],
              ),
            ),
            TextButton(
              onPressed: () {
                //_viewModel.toggleSuoniAmbientali(
                //  !_viewModel.suoniAmbientaliService.isAttiva,
                //);
              },
              child: Row(
                children: [
                  Icon(
                    _viewModel.audioGuideService.isAttiva
                        ? Icons.spatial_audio
                        : Icons.spatial_audio_off,
                    color: _viewModel.audioGuideService.isAttiva
                        ? theme.colorScheme.primary
                        : Colors.grey,
                  ),
                  const SizedBox(width: 8),
                  const Text("Suoni Ambientali"),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLandmarkCard(ThemeData theme) {
    //se non c'è ancora nessun POI non viene mostrata la cart
    if (_viewModel.luogoVicinoAttuale == null) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.8),
        borderRadius: BorderRadius.circular(40),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: const Color(0xFFC7EBEB),
            child: Icon(Icons.place, color: theme.colorScheme.primary),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "SEI NEI PRESSI DI",
                style: TextStyle(fontSize: 10, color: Colors.black54),
              ),
              FittedBox(
                child: Text(
                  _viewModel.luogoVicinoAttuale!,
                  style: GoogleFonts.notoSerif(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPlayerCard(ThemeData theme) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(40),
      ),
      child: Column(
        children: [
          const Text(
            "AUDIO ATTUALE",
            style: TextStyle(fontSize: 10, color: Colors.black54),
          ),
          const SizedBox(height: 8),
          Text(
            "Sussurri della Foresta: Resilienza",
            textAlign: TextAlign.center,
            style: GoogleFonts.notoSerif(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              const Icon(Icons.skip_previous),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.pause, color: Colors.white, size: 32),
              ),
              const Icon(Icons.replay),
            ],
          ),
          const SizedBox(height: 20),
          Slider(
            value: 0.4,
            onChanged: (v) {},
            activeColor: theme.colorScheme.primary,
            inactiveColor: Colors.grey.shade300,
          ),
        ],
      ),
    );
  }

  Widget _buildTerminateButton(BuildContext context, ThemeData theme) {
    return SizedBox(
      width: 250,
      height: 60,
      child: ElevatedButton.icon(
        onPressed: () => _mostraConfirmTermina(context),
        icon: const Icon(Icons.stop_circle_outlined, color: Colors.black87),
        label: const Text(
          "Termina Sessione",
          style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFE5E9D6),
          shape: const StadiumBorder(),
          elevation: 0,
        ),
      ),
    );
  }

  void _mostraConfirmTermina(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text("Terminare l'attività?"),
          content: const Text(
            "Sei sicuro di voler terminare l'attività corrente?",
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text("Annulla"),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(dialogContext);
                final userProvider = Provider.of<UserProvider>(
                  context,
                  listen: false,
                );
                //salva i dati
                await _viewModel.fermaESalva(userProvider);
                if (mounted) {
                  Navigator.pop(context);
                }
              },
              child: const Text("Termina", style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  Widget _buildDebugToggle() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.amber.shade100,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.amber, width: 2),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            "DEBUG: GPS Simulato",
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.brown),
          ),
          Switch(
            value: _viewModel.usaGpsSimulato,
            onChanged: (val) {
              // Cambia il motore GPS al volo
              _viewModel.cambiaSorgenteGps(val);
            },
            activeColor: Colors.amber.shade800,
          ),
        ],
      ),
    );
  }
}
