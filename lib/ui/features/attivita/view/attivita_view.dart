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

  @override
  void initState() {
    super.initState();
    _viewModel.avviaAttivita(); //
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
              //SFONDO foresta sfocata)
              Positioned.fill(
                child: Image.asset(
                  'assets/images/forest_bg.png',
                  fit: BoxFit.cover,
                ),
              ),
              Positioned.fill(
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                  child: Container(color: Colors.white.withOpacity(0.2)),
                ),
              ),

              // 2. CONTENUTO
              SafeArea(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      const SizedBox(height: 50),
                      _buildMainStats(theme),
                      const SizedBox(height: 30),
                      _buildMapCard(theme),
                      const SizedBox(height: 30),
                      _buildLandmarkCard(theme),
                      const SizedBox(height: 12),
                      _buildPlayerCard(theme),
                      const SizedBox(height: 30),
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
        options: MapOptions(
          initialCenter: _viewModel.tracciaGps.isNotEmpty
              ? LatLng(
                  _viewModel.tracciaGps.last.latitude,
                  _viewModel.tracciaGps.last.longitude,
                )
              : const LatLng(42.358246, 13.386197),
          initialZoom: 15.0,
        ),
        children: [
          TileLayer(
            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
            userAgentPackageName: 'com.example.walkfulness',
          ),
          PolylineLayer(
            polylines: [
              Polyline(
                points: _viewModel.tracciaGps
                    .map((p) => LatLng(p.latitude, p.longitude))
                    .toList(),
                color: theme.colorScheme.primary,
                strokeWidth: 4,
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
          const Text(
            "SESSIONE IN CORSO",
            style: TextStyle(
              letterSpacing: 1.5,
              fontSize: 12,
              color: Color.fromARGB(255, 255, 255, 255),
            ),
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                "${_viewModel.durata.inMinutes}", //
                style: GoogleFonts.notoSerif(
                  fontSize: 64,
                  fontWeight: FontWeight.bold,
                  color: Color.fromARGB(255, 255, 255, 255),
                ),
              ),
              const SizedBox(width: 4),
              Text(
                "min",
                style: GoogleFonts.notoSerif(
                  fontSize: 24,
                  color: Color.fromARGB(255, 255, 255, 255),
                ),
              ),
            ],
          ),
          Row(
            children: [
              const Icon(
                Icons.location_on,
                size: 16,
                color: Color.fromARGB(255, 255, 255, 255),
              ),
              const SizedBox(width: 4),
              Text(
                "${_viewModel.kmPercorsi.toStringAsFixed(1)} km", //
                style: const TextStyle(
                  fontSize: 16,
                  color: Color.fromARGB(255, 255, 255, 255),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLandmarkCard(ThemeData theme) {
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
            child: Icon(Icons.eco, color: theme.colorScheme.primary),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "TI STAI AVVICINANDO A",
                style: TextStyle(fontSize: 10, color: Colors.black54),
              ),
              Text(
                "La Radura delle Campanule",
                style: GoogleFonts.notoSerif(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.primary,
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
            "GUIDA ATTUALE",
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
        onPressed: () async {
          final userProvider = Provider.of<UserProvider>(
            context,
            listen: false,
          );

          await _viewModel.fermaESalva(userProvider);
          if (mounted) Navigator.pop(context);
        },
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
}
