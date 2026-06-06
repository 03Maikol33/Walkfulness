import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:walkfulness/domain/models/iniziativa_model.dart';
import 'package:walkfulness/ui/features/crea_iniziativa/view_model/crea_iniziativa_view_model.dart';
import 'package:walkfulness/ui/features/main_wrapper/view_model/main_wrapper_view_model.dart';
import 'package:google_fonts/google_fonts.dart';

class CreaIniziativaView extends StatefulWidget {
  final IniziativaModel? iniziativaDaModificare;
  const CreaIniziativaView({super.key, this.iniziativaDaModificare});

  @override
  State<CreaIniziativaView> createState() => _CreaIniziativaViewState();
}

class _CreaIniziativaViewState extends State<CreaIniziativaView> {
  final _titoloController = TextEditingController();
  final _descController = TextEditingController();
  final _obiettivoController = TextEditingController();
  final _maxPartecipantiController = TextEditingController();
  final _luogoController = TextEditingController();

  DateTime _dataSelezionata = DateTime.now().add(const Duration(days: 1));
  TimeOfDay _oraSelezionata = const TimeOfDay(hour: 9, minute: 0);

  final List<String> _immaginiDisponibili = [
    'assets/images/iniziativa_default.jpg',
    'assets/images/foresta1.jpg',
    'assets/images/foresta2.jpg',
    'assets/images/lago1.jpg',
    'assets/images/lago2.jpg',
    'assets/images/montagna1.jpg',
    'assets/images/montagna2.jpg',
    'assets/images/parco.jpg',
    'assets/images/spiaggia.jpg',
  ];
  String _immagineSelezionata = 'assets/images/iniziativa_default.jpg';

  final MapController _mapController = MapController();
  LatLng _posizioneSelezionata = const LatLng(42.3582, 13.3862);

  @override
  void initState() {
    super.initState();
    if (widget.iniziativaDaModificare != null) {
      final old = widget.iniziativaDaModificare!;
      _titoloController.text = old.titolo;
      _descController.text = old.descrizione;
      _obiettivoController.text = old.obiettivo;
      _maxPartecipantiController.text = old.maxPartecipanti.toString();
      _luogoController.text = old.luogo;
      _dataSelezionata = old.dataOra;
      _oraSelezionata = TimeOfDay.fromDateTime(old.dataOra);
      _posizioneSelezionata = LatLng(
        old.posizione.latitude,
        old.posizione.longitude,
      );
      if (old.immagineCopertina != null && old.immagineCopertina!.isNotEmpty) {
        _immagineSelezionata = old.immagineCopertina!;
      }
    }
  }

  @override
  void dispose() {
    _titoloController.dispose();
    _descController.dispose();
    _obiettivoController.dispose();
    _maxPartecipantiController.dispose();
    _luogoController.dispose();
    _mapController.dispose();
    super.dispose();
  }

  DateTime get _dataOraCombinata {
    return DateTime(
      _dataSelezionata.year,
      _dataSelezionata.month,
      _dataSelezionata.day,
      _oraSelezionata.hour,
      _oraSelezionata.minute,
    );
  }

  Future<void> _cercaLuogo(String query) async {
    if (query.trim().isEmpty) return;
    try {
      final url = Uri.parse(
        'https://nominatim.openstreetmap.org/search?q=$query&format=json&limit=1',
      );
      final response = await http.get(
        url,
        headers: {'User-Agent': 'WalkfulnessApp/1.0'},
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body) as List;
        if (data.isNotEmpty) {
          final lat = double.parse(data[0]['lat']);
          final lon = double.parse(data[0]['lon']);
          setState(() {
            _posizioneSelezionata = LatLng(lat, lon);
            _luogoController.text = data[0]['display_name']
                .toString()
                .split(',')
                .first;
          });
          _mapController.move(_posizioneSelezionata, 15.0);
        }
      }
    } catch (e) {
      debugPrint("Errore geocoding: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;
    final isEditing = widget.iniziativaDaModificare != null;

    return ChangeNotifierProvider(
      create: (_) => CreaIniziativaViewModel(),
      child: Consumer<CreaIniziativaViewModel>(
        builder: (context, vm, _) {
          return Scaffold(
            backgroundColor: const Color(0xFFF7FBF8),
            body: SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.arrow_back),
                          onPressed: () => context
                              .read<MainWrapperViewModel>()
                              .chiudiPaginaInterna(),
                          padding: EdgeInsets.zero,
                          alignment: Alignment.centerLeft,
                        ),
                      ],
                    ),
                    Text(
                      isEditing ? "Modifica Iniziativa" : "Crea Iniziativa",
                      style: theme.textTheme.headlineLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF012D1C),
                      ),
                    ),
                    const SizedBox(height: 32),

                    Text(
                      "Copertina Iniziativa",
                      style: GoogleFonts.notoSerif(
                        fontWeight: FontWeight.bold,
                        color: primaryColor,
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 100,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: _immaginiDisponibili.length,
                        itemBuilder: (context, index) {
                          final imgPath = _immaginiDisponibili[index];
                          final isSelected = _immagineSelezionata == imgPath;
                          return GestureDetector(
                            onTap: () =>
                                setState(() => _immagineSelezionata = imgPath),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              margin: const EdgeInsets.only(right: 12),
                              width: 140,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: isSelected
                                      ? primaryColor
                                      : Colors.transparent,
                                  width: 3,
                                ),
                                image: DecorationImage(
                                  image: AssetImage(imgPath),
                                  fit: BoxFit.cover,
                                ),
                              ),
                              child: isSelected
                                  ? Container(
                                      decoration: BoxDecoration(
                                        color: Colors.black26,
                                        borderRadius: BorderRadius.circular(13),
                                      ),
                                      child: const Icon(
                                        Icons.check_circle,
                                        color: Colors.white,
                                        size: 32,
                                      ),
                                    )
                                  : null,
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 32),

                    _buildTextField(
                      _titoloController,
                      "Nome dell'iniziativa",
                      "Es. Respiro del Bosco",
                    ),
                    _buildTextField(
                      _descController,
                      "Descrizione",
                      "Racconta lo spirito di questa attività...",
                      maxLines: 3,
                    ),
                    _buildTextField(
                      _obiettivoController,
                      "Obiettivo Eco-Impatto",
                      "Es. Pulizia sentiero",
                    ),
                    _buildTextField(
                      _maxPartecipantiController,
                      "Numero massimo partecipanti",
                      "Es. 20",
                      isNumber: true,
                    ),

                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: () async {
                              final date = await showDatePicker(
                                context: context,
                                initialDate: _dataSelezionata,
                                firstDate: DateTime.now(),
                                lastDate: DateTime(2027),
                              );
                              if (date != null)
                                setState(() => _dataSelezionata = date);
                            },
                            child: _buildPickerContainer(
                              Icons.calendar_today,
                              "${_dataSelezionata.day}/${_dataSelezionata.month}/${_dataSelezionata.year}",
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: InkWell(
                            onTap: () async {
                              final time = await showTimePicker(
                                context: context,
                                initialTime: _oraSelezionata,
                              );
                              if (time != null)
                                setState(() => _oraSelezionata = time);
                            },
                            child: _buildPickerContainer(
                              Icons.access_time,
                              _oraSelezionata.format(context),
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 32),
                    Text(
                      "Luogo di ritrovo",
                      style: GoogleFonts.notoSerif(
                        fontWeight: FontWeight.bold,
                        color: primaryColor,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _luogoController,
                      onSubmitted: _cercaLuogo,
                      decoration: InputDecoration(
                        hintText: "Cerca luogo o premi sulla mappa...",
                        prefixIcon: const Icon(Icons.search),
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      height: 200,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: const [
                          BoxShadow(color: Colors.black12, blurRadius: 10),
                        ],
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: FlutterMap(
                        mapController: _mapController,
                        options: MapOptions(
                          initialCenter: _posizioneSelezionata,
                          initialZoom: 14.0,
                          onLongPress: (tapPosition, point) {
                            setState(() {
                              _posizioneSelezionata = point;
                              _luogoController.text = "Punto GPS Selezionato";
                            });
                          },
                        ),
                        children: [
                          TileLayer(
                            urlTemplate:
                                'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                            userAgentPackageName: 'com.walkfulness.app',
                          ),
                          MarkerLayer(
                            markers: [
                              Marker(
                                point: _posizioneSelezionata,
                                width: 40,
                                height: 40,
                                child: const Icon(
                                  Icons.location_on,
                                  color: Colors.red,
                                  size: 40,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 40),
                    SizedBox(
                      width: double.infinity,
                      height: 60,
                      child: ElevatedButton(
                        onPressed: vm.isLoading
                            ? null
                            : () async {
                                if (_titoloController.text.isEmpty ||
                                    _luogoController.text.isEmpty) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        "Inserisci almeno titolo e luogo!",
                                      ),
                                    ),
                                  );
                                  return;
                                }

                                await vm.salvaIniziativa(
                                  idEsistente: isEditing
                                      ? widget.iniziativaDaModificare!.id
                                      : null, // Discriminante!
                                  titolo: _titoloController.text,
                                  descrizione: _descController.text,
                                  obiettivo: _obiettivoController.text,
                                  maxPartecipanti:
                                      int.tryParse(
                                        _maxPartecipantiController.text,
                                      ) ??
                                      10,
                                  dataOra: _dataOraCombinata,
                                  luogo: _luogoController.text,
                                  posizione: GeoPoint(
                                    _posizioneSelezionata.latitude,
                                    _posizioneSelezionata.longitude,
                                  ),
                                  immagineCopertina: _immagineSelezionata,
                                );

                                if (context.mounted) {
                                  context
                                      .read<MainWrapperViewModel>()
                                      .chiudiPaginaInterna();
                                }
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF012D1C),
                          shape: const StadiumBorder(),
                        ),
                        child: vm.isLoading
                            ? const CircularProgressIndicator(
                                color: Colors.white,
                              )
                            : Text(
                                isEditing
                                    ? "SALVA MODIFICHE"
                                    : "PUBBLICA INIZIATIVA",
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String label,
    String hint, {
    bool isNumber = false,
    int maxLines = 1,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: controller,
            maxLines: maxLines,
            keyboardType: isNumber ? TextInputType.number : TextInputType.text,
            decoration: InputDecoration(
              hintText: hint,
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPickerContainer(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.grey, size: 20),
          const SizedBox(width: 8),
          Text(
            text,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
}
