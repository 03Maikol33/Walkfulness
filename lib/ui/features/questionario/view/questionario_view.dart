import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:walkfulness/domain/models/activity_model.dart';
import 'package:walkfulness/ui/core/widgets/condivisione_dialog.dart';
import 'package:walkfulness/ui/features/main_wrapper/view_model/main_wrapper_view_model.dart';
import '../view_model/questionario_view_model.dart';

class QuestionarioView extends StatefulWidget {
  final ActivityModel attivita;

  const QuestionarioView({super.key, required this.attivita});

  @override
  State<QuestionarioView> createState() => _QuestionarioViewState();
}

class _QuestionarioViewState extends State<QuestionarioView> {
  final QuestionarioViewModel _viewModel = QuestionarioViewModel();

  // Stato locale del form
  String? _moodSelezionato;
  bool? _percorsoHaRilassato;
  final List<String> _apprezzamentiSelezionati = [];

  final List<Map<String, String>> _moods = [
    {"label": "Rilassato", "emoji": "😌"},
    {"label": "Stressato", "emoji": "😤"},
    {"label": "Energico", "emoji": "⚡"},
    {"label": "Triste", "emoji": "😔"},
    {"label": "Riflessivo", "emoji": "🤔"},
    {"label": "Ansioso", "emoji": "😰"},
  ];

  final List<String> _opzioniApprezzamento = [
    "Silenzio",
    "Panorama",
    "Audio Guida",
    "Passo Libero",
    "Profumi",
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary; // Verde scuro (0xFF012D1C)
    final bgColor = const Color(0xFFF7FBF8); // Sfondo chiaro

    // Formattazione dati passati dall'attività
    final minuti = widget.attivita.durata.inMinutes;
    final km = widget.attivita.km.toStringAsFixed(1);

    return ListenableBuilder(
      listenable: _viewModel,
      builder: (context, _) {
        return Scaffold(
          backgroundColor: bgColor,
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(
                horizontal: 24.0,
                vertical: 20.0,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 24),
                  Text(
                    "Sessione\nCompletata",
                    textAlign: TextAlign.center,
                    style: theme.textTheme.headlineLarge?.copyWith(
                      color: const Color(0xFF012D1C),
                      fontWeight: FontWeight.bold,
                      fontSize: 32,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    "Ecco il tuo progresso di oggi.",
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.black54, fontSize: 14),
                  ),
                  const SizedBox(height: 32),

                  // STATISTICHE (Tempo e Distanza)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(32),
                    ),
                    child: Column(
                      children: [
                        const Icon(Icons.access_time, color: Colors.grey),
                        const SizedBox(height: 8),
                        RichText(
                          text: TextSpan(
                            style: TextStyle(color: primaryColor),
                            children: [
                              TextSpan(
                                text: "$minuti ",
                                style: GoogleFonts.notoSerif(
                                  fontSize: 40,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              TextSpan(
                                text: "min",
                                style: GoogleFonts.inter(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Text(
                          "TEMPO TOTALE",
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(40),
                    ),
                    child: Column(
                      children: [
                        RichText(
                          text: TextSpan(
                            style: TextStyle(color: primaryColor),
                            children: [
                              TextSpan(
                                text: "$km ",
                                style: GoogleFonts.notoSerif(
                                  fontSize: 28,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              TextSpan(
                                text: "km",
                                style: GoogleFonts.inter(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Text(
                          "DISTANZA",
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 40),

                  // QUESTIONARIO
                  Text(
                    "Come ti senti ora?",
                    style: GoogleFonts.notoSerif(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: primaryColor,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // EMOJI SCROLLABILI
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: _moods.map((mood) {
                        final isSelected = _moodSelezionato == mood['label'];
                        return GestureDetector(
                          onTap: () =>
                              setState(() => _moodSelezionato = mood['label']),
                          child: Container(
                            margin: const EdgeInsets.symmetric(horizontal: 8),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: isSelected ? primaryColor : Colors.white,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: isSelected
                                    ? primaryColor
                                    : Colors.grey.shade300,
                              ),
                            ),
                            child: Text(
                              mood['emoji']!,
                              style: const TextStyle(fontSize: 28),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  if (_moodSelezionato != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      _moodSelezionato!.toUpperCase(),
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ],

                  const SizedBox(height: 40),

                  Text(
                    "Il percorso ti ha aiutato a\nrilassarti?",
                    textAlign: TextAlign.center,
                    style: GoogleFonts.notoSerif(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: primaryColor,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: _buildChoiceButton(
                          "Sì",
                          _percorsoHaRilassato == true,
                          () => setState(() => _percorsoHaRilassato = true),
                          primaryColor,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildChoiceButton(
                          "No",
                          _percorsoHaRilassato == false,
                          () => setState(() => _percorsoHaRilassato = false),
                          primaryColor,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 40),

                  Text(
                    "Cosa hai apprezzato di più?",
                    style: GoogleFonts.notoSerif(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: primaryColor,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Wrap(
                    spacing: 8,
                    runSpacing: 12,
                    alignment: WrapAlignment.center,
                    children: _opzioniApprezzamento.map((tag) {
                      final isSelected = _apprezzamentiSelezionati.contains(
                        tag,
                      );
                      return FilterChip(
                        label: Text(tag),
                        selected: isSelected,
                        onSelected: (selected) {
                          setState(() {
                            selected
                                ? _apprezzamentiSelezionati.add(tag)
                                : _apprezzamentiSelezionati.remove(tag);
                          });
                        },
                        selectedColor: primaryColor,
                        checkmarkColor: Colors.white,
                        backgroundColor: Colors.grey.shade200,
                        labelStyle: TextStyle(
                          fontSize: 13,
                          color: isSelected ? Colors.white : Colors.black87,
                          fontWeight: isSelected
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                        side: BorderSide.none,
                        shape: const StadiumBorder(),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 12,
                        ),
                      );
                    }).toList(),
                  ),

                  const SizedBox(height: 50),

                  // BOTTONE FINALE
                  SizedBox(
                    width: double.infinity,
                    height: 60,
                    child: ElevatedButton(
                      onPressed: _viewModel.isLoading
                          ? null
                          : () async {
                              // 1. Salviamo i dati (l'Activity ha l'ID che gli abbiamo passato da fermaESalva!)
                              if (widget.attivita.id != null) {
                                await _viewModel.salvaQuestionario(
                                  activityId: widget.attivita.id!,
                                  umore: _moodSelezionato,
                                  percorsoHaRilassato: _percorsoHaRilassato,
                                  elementiApprezzati: _apprezzamentiSelezionati,
                                );
                              }

                              // 2. Chiudiamo la pagina interna e torniamo alla Foresta
                              if (context.mounted) {
                                Navigator.of(
                                  context,
                                ).popUntil((route) => route.isFirst);
                                context
                                    .read<MainWrapperViewModel>()
                                    .cambiaPagina(0);
                              }
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        shape: const StadiumBorder(),
                      ),
                      child: const Text(
                        "Torna alla Foresta",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (context) => CondivisioneDialog(
                          attivita: widget.attivita,
                          umore: _moodSelezionato,
                        ),
                      );
                    }, // Logica per generare l'immagine social
                    child: const Text(
                      "CONDIVIDI IL TUO CAMMINO",
                      style: TextStyle(
                        color: Colors.black54,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // Helper per i bottoni Si/No
  Widget _buildChoiceButton(
    String text,
    bool isSelected,
    VoidCallback onTap,
    Color primary,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 55,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isSelected ? primary : Colors.grey.shade200,
          borderRadius: BorderRadius.circular(30),
        ),
        child: Text(
          text,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: isSelected ? Colors.white : Colors.black87,
          ),
        ),
      ),
    );
  }
}
