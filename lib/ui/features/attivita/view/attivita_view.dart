import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:walkfulness/data/services/location/routing_service.dart';
import 'package:walkfulness/domain/models/percorso_model.dart';
import 'package:walkfulness/ui/core/providers/user_provider.dart';
import 'package:walkfulness/ui/features/main_wrapper/view_model/main_wrapper_view_model.dart';
import 'package:walkfulness/ui/features/questionario/view/questionario_view.dart';
import '../view_model/attivita_view_model.dart';
import 'package:walkfulness/ui/features/crea_tu/view_model/crea_tu_view_model.dart';

class AttivitaView extends StatefulWidget {
  const AttivitaView({super.key});

  @override
  State<AttivitaView> createState() => _AttivitaViewState();
}

class _AttivitaViewState extends State<AttivitaView> {
  final _viewModel = AttivitaViewModel();
  final _mapController = MapController();
  int _puntiTracciati = 0;
  bool _isReady = false;

  @override
  void initState() {
    super.initState();
    _viewModel.addListener(_centraMappa);
    Future.delayed(const Duration(milliseconds: 350), () {
      if (mounted) {
        setState(() => _isReady = true);
        _viewModel.avviaAttivita();
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)?.settings.arguments;

    if (args != null && args is PercorsoModel) {
      final tappeConvertite = args.tappe.map((mappa) {
        return PinModel(
          coordinate: LatLng(mappa['lat'], mappa['lon']),
          nome: mappa['nome'] ?? "",
          tipoRottaVersoProssimo: mappa['routingAutomatico'] == true
              ? TipoRouting.automatico
              : TipoRouting.lineaAria,
        );
      }).toList();
      _viewModel.impostaPercorsoPianificato(tappeConvertite, id: args.id);
    }

    if (args != null && args is List<PinModel>) {
      _viewModel.impostaPercorsoPianificato(args);
    }
  }

  void _centraMappa() {
    if (_viewModel.tracciaGps.length < _puntiTracciati) {
      _puntiTracciati = 0;
    }

    if (_viewModel.tracciaGps.length > _puntiTracciati) {
      _puntiTracciati = _viewModel.tracciaGps.length;
      final ultimoPunto = _viewModel.tracciaGps.last;

      _mapController.move(
        LatLng(ultimoPunto.latitude, ultimoPunto.longitude),
        16.0,
      );
    }
  }

  @override
  void dispose() {
    _viewModel.removeListener(_centraMappa);
    _mapController.dispose();
    super.dispose();
  }

  void _mostraConfirmTermina(BuildContext context) {
    bool isSalvando = false;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text("Terminare l'attività?"),
              content: const Text(
                "Sei sicuro di voler terminare l'attività corrente?",
              ),
              actions: [
                TextButton(
                  onPressed: isSalvando
                      ? null
                      : () => Navigator.pop(dialogContext),
                  child: const Text("Annulla"),
                ),
                TextButton(
                  onPressed: isSalvando
                      ? null
                      : () async {
                          setDialogState(() => isSalvando = true);
                          final userProvider = Provider.of<UserProvider>(
                            context,
                            listen: false,
                          );
                          final attivita = await _viewModel.fermaESalva(
                            userProvider,
                          );

                          if (context.mounted && attivita != null) {
                            Navigator.pop(dialogContext);
                            Navigator.pop(context);
                            context
                                .read<MainWrapperViewModel>()
                                .apriPaginaInterna(
                                  QuestionarioView(attivita: attivita),
                                );
                          } else if (context.mounted) {
                            setDialogState(() => isSalvando = false);
                          }
                        },
                  child: isSalvando
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text(
                          "Termina",
                          style: TextStyle(color: Colors.red),
                        ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        if (_viewModel.inCorso) {
          _mostraConfirmTermina(context);
        } else {
          Navigator.pop(context);
        }
      },
      child: Scaffold(
        body: Stack(
          children: [
            SafeArea(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    const SizedBox(height: 50),
                    MainStatsWidget(viewModel: _viewModel),
                    AudioTogglesWidget(viewModel: _viewModel),
                    const SizedBox(height: 10),
                    MapCardWidget(
                      viewModel: _viewModel,
                      mapController: _mapController,
                    ),
                    const SizedBox(height: 10),
                    LandmarkCardWidget(viewModel: _viewModel),
                    const SizedBox(height: 10),
                    PlayerCardWidget(viewModel: _viewModel),
                    const SizedBox(height: 10),
                    TerminateButtonWidget(
                      onTerminate: () => _mostraConfirmTermina(context),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

//Widget ui
class MainStatsWidget extends StatelessWidget {
  final AttivitaViewModel viewModel;
  const MainStatsWidget({super.key, required this.viewModel});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

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
                ActivityTimerWidget(viewModel: viewModel),
                const SizedBox(width: 24),
                Text(
                  viewModel.kmPercorsi.toStringAsFixed(1),
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
}

class ActivityTimerWidget extends StatefulWidget {
  final AttivitaViewModel viewModel;
  const ActivityTimerWidget({super.key, required this.viewModel});

  @override
  State<ActivityTimerWidget> createState() => _ActivityTimerWidgetState();
}

class _ActivityTimerWidgetState extends State<ActivityTimerWidget> {
  Timer? _uiTimer;

  @override
  void initState() {
    super.initState();
    _uiTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted && widget.viewModel.inCorso) {
        setState(() {}); // agg ogni secondo
      }
    });
  }

  @override
  void dispose() {
    _uiTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final durata = widget.viewModel.durata;

    final minuti = durata.inMinutes.remainder(60).toString().padLeft(2, '0');
    final secondi = durata.inSeconds.remainder(60).toString().padLeft(2, '0');

    return Row(
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        Text(
          "$minuti:$secondi",
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
      ],
    );
  }
}

class AudioTogglesWidget extends StatelessWidget {
  final AttivitaViewModel viewModel;
  const AudioTogglesWidget({super.key, required this.viewModel});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListenableBuilder(
      listenable: viewModel,
      builder: (context, _) {
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 24),
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.8),
            borderRadius: BorderRadius.circular(40),
          ),
          child: FittedBox(
            child: Row(
              children: [
                TextButton(
                  onPressed: () =>
                      viewModel.toggleGuidaVocale(!viewModel.isVoceAttiva),
                  child: Row(
                    children: [
                      Icon(
                        viewModel.isVoceAttiva
                            ? Icons.volume_up
                            : Icons.volume_off,
                        color: viewModel.isVoceAttiva
                            ? theme.colorScheme.primary
                            : Colors.grey,
                      ),
                      const SizedBox(width: 8),
                      const Text("Guida Vocale"),
                    ],
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

class MapCardWidget extends StatelessWidget {
  final AttivitaViewModel viewModel;
  final MapController mapController;
  const MapCardWidget({
    super.key,
    required this.viewModel,
    required this.mapController,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ListenableBuilder(
      listenable: viewModel,
      builder: (context, _) {
        LatLng centroIniziale = const LatLng(42.358246, 13.386197);
        if (viewModel.tracciaGps.isNotEmpty) {
          centroIniziale = LatLng(
            viewModel.tracciaGps.last.latitude,
            viewModel.tracciaGps.last.longitude,
          );
        } else if (viewModel.percorsoPianificato.isNotEmpty) {
          centroIniziale = viewModel.percorsoPianificato.first;
        }

        return Container(
          height: 200,
          margin: const EdgeInsets.symmetric(horizontal: 24),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(32),
            color: Colors.white.withValues(alpha: 0.9),
          ),
          clipBehavior: Clip.antiAlias,
          child: FlutterMap(
            mapController: mapController,
            options: MapOptions(
              initialCenter: centroIniziale,
              initialZoom: 16.0,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.walkfulness',
              ),
              PolylineLayer(
                polylines: [
                  if (viewModel.percorsoPianificatoCompleto.isNotEmpty)
                    Polyline(
                      points: viewModel.percorsoPianificatoCompleto,
                      color: Colors.cyan.withValues(alpha: 0.6),
                      strokeWidth: 8,
                    ),
                  Polyline(
                    points: viewModel.tracciaGps
                        .map((p) => LatLng(p.latitude, p.longitude))
                        .toList(),
                    color: theme.colorScheme.primary,
                    strokeWidth: 8,
                  ),
                ],
              ),
              MarkerLayer(
                markers: [
                  ...viewModel.tappePianificate.map(
                    (pin) => Marker(
                      point: pin.coordinate,
                      width: 16,
                      height: 16,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.cyan,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                          boxShadow: const [
                            BoxShadow(color: Colors.black26, blurRadius: 4),
                          ],
                        ),
                      ),
                    ),
                  ),
                  if (viewModel.tracciaGps.isNotEmpty)
                    Marker(
                      point: LatLng(
                        viewModel.tracciaGps.last.latitude,
                        viewModel.tracciaGps.last.longitude,
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
                              color: Colors.black.withValues(alpha: 0.3),
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
      },
    );
  }
}

class LandmarkCardWidget extends StatelessWidget {
  final AttivitaViewModel viewModel;
  const LandmarkCardWidget({super.key, required this.viewModel});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ListenableBuilder(
      listenable: viewModel,
      builder: (context, _) {
        if (viewModel.luogoVicinoAttuale == null)
          return const SizedBox.shrink();

        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 24),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.8),
            borderRadius: BorderRadius.circular(40),
          ),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: const Color(0xFFC7EBEB),
                child: Icon(Icons.place, color: theme.colorScheme.primary),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "SEI NEI PRESSI DI",
                      style: TextStyle(fontSize: 10, color: Colors.black54),
                    ),
                    Text(
                      viewModel.luogoVicinoAttuale!,
                      style: GoogleFonts.notoSerif(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.primary,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class PlayerCardWidget extends StatelessWidget {
  final AttivitaViewModel viewModel;
  const PlayerCardWidget({super.key, required this.viewModel});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ListenableBuilder(
      listenable: viewModel,
      builder: (context, _) {
        String nomeTraccia = "Silenzio";
        if (viewModel.tracciaAttiva != null) {
          final traccia = viewModel.tracceDisponibili.firstWhere(
            (t) => t['file'] == viewModel.tracciaAttiva,
            orElse: () => {"nome": "Sconosciuto"},
          );
          nomeTraccia = traccia['nome']!;
        }
        final isPlaying = viewModel.tracciaAttiva != null;

        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 24),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.9),
            borderRadius: BorderRadius.circular(40),
          ),
          child: Column(
            children: [
              const Text(
                "AUDIO AMBIENTALE",
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.black54,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                nomeTraccia,
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
                  IconButton(
                    icon: const Icon(Icons.skip_previous, size: 32),
                    color: Colors.grey,
                    onPressed: () => viewModel.tracciaPrecedente(),
                  ),
                  GestureDetector(
                    onTap: () => viewModel.toggleSuoniAmbientali(),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        isPlaying ? Icons.pause : Icons.play_arrow,
                        color: Colors.white,
                        size: 36,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.skip_next, size: 32),
                    color: Colors.grey,
                    onPressed: () => viewModel.tracciaSuccessiva(),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Slider(
                value: viewModel.volumeAmbientale,
                onChanged: (v) => viewModel.cambiaVolume(v),
                activeColor: theme.colorScheme.primary,
                inactiveColor: Colors.grey.shade300,
              ),
            ],
          ),
        );
      },
    );
  }
}

class TerminateButtonWidget extends StatelessWidget {
  final VoidCallback onTerminate;
  const TerminateButtonWidget({super.key, required this.onTerminate});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 250,
      height: 60,
      child: ElevatedButton.icon(
        onPressed: onTerminate,
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

class DebugGpsToggle extends StatelessWidget {
  final AttivitaViewModel viewModel;

  const DebugGpsToggle({super.key, required this.viewModel});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: viewModel,
      builder: (context, _) {
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 24),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.amber.shade100.withValues(alpha: 0.8),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.amber, width: 2),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "DEBUG: GPS Simulato",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.brown,
                ),
              ),
              Switch(
                value: viewModel.usaGpsSimulato,
                onChanged: (val) {
                  viewModel.cambiaSorgenteGps(val);
                },
                activeColor: Colors.amber.shade800,
              ),
            ],
          ),
        );
      },
    );
  }
}
