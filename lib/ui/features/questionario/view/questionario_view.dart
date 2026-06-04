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

  // Stato locale del form (Va benissimo tenerlo qui per un form semplice)
  String? _moodSelezionato;
  bool? _percorsoHaRilassato;
  final List<String> _apprezzamentiSelezionati = [];

  @override
  Widget build(BuildContext context) {
    // Formattazione dati
    final minuti = widget.attivita.durata.inMinutes;
    final km = widget.attivita.km.toStringAsFixed(1);

    // IL BUILD PRINCIPALE È STATO RIPULITO DAL LISTENABLE BUILDER GLOBALE
    return Scaffold(
      backgroundColor: const Color(0xFFF7FBF8),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 24),
              const QuestionarioHeaderWidget(), // Costante e immutabile
              const SizedBox(height: 32),

              QuestionarioStatsWidget(minuti: minuti, km: km),
              const SizedBox(height: 40),

              MoodSelectorWidget(
                moodSelezionato: _moodSelezionato,
                onMoodChanged: (mood) =>
                    setState(() => _moodSelezionato = mood),
              ),
              const SizedBox(height: 40),

              RelaxToggleWidget(
                isRilassato: _percorsoHaRilassato,
                onChanged: (val) => setState(() => _percorsoHaRilassato = val),
              ),
              const SizedBox(height: 40),

              TagsSelectorWidget(
                tagsSelezionati: _apprezzamentiSelezionati,
                onTagToggled: (tag, isSelected) {
                  setState(() {
                    isSelected
                        ? _apprezzamentiSelezionati.add(tag)
                        : _apprezzamentiSelezionati.remove(tag);
                  });
                },
              ),
              const SizedBox(height: 50),

              // Questo è L'UNICO pezzo che ascolta il ViewModel
              SaveButtonWidget(
                viewModel: _viewModel,
                attivita: widget.attivita,
                moodSelezionato: _moodSelezionato,
                percorsoHaRilassato: _percorsoHaRilassato,
                apprezzamentiSelezionati: _apprezzamentiSelezionati,
              ),

              const SizedBox(height: 16),
              ShareButtonWidget(
                attivita: widget.attivita,
                moodSelezionato: _moodSelezionato,
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// WIDGET ESTRATTI E OTTIMIZZATI CON ASCOLTO GRANULARE E CONSTANTS
// ============================================================================

class QuestionarioHeaderWidget extends StatelessWidget {
  const QuestionarioHeaderWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
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
      ],
    );
  }
}

class QuestionarioStatsWidget extends StatelessWidget {
  final int minuti;
  final String km;

  const QuestionarioStatsWidget({
    super.key,
    required this.minuti,
    required this.km,
  });

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).colorScheme.primary;

    return Column(
      children: [
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
      ],
    );
  }
}

class MoodSelectorWidget extends StatelessWidget {
  final String? moodSelezionato;
  final Function(String) onMoodChanged;

  static const List<Map<String, String>> _moods = [
    {"label": "Rilassato", "emoji": "😌"},
    {"label": "Stressato", "emoji": "😤"},
    {"label": "Energico", "emoji": "⚡"},
    {"label": "Triste", "emoji": "😔"},
    {"label": "Riflessivo", "emoji": "🤔"},
    {"label": "Ansioso", "emoji": "😰"},
  ];

  const MoodSelectorWidget({
    super.key,
    required this.moodSelezionato,
    required this.onMoodChanged,
  });

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).colorScheme.primary;

    return Column(
      children: [
        Text(
          "Come ti senti ora?",
          style: GoogleFonts.notoSerif(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: primaryColor,
          ),
        ),
        const SizedBox(height: 20),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: _moods.map((mood) {
              final isSelected = moodSelezionato == mood['label'];
              return GestureDetector(
                onTap: () => onMoodChanged(mood['label']!),
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isSelected ? primaryColor : Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSelected ? primaryColor : Colors.grey.shade300,
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
        if (moodSelezionato != null) ...[
          const SizedBox(height: 8),
          Text(
            moodSelezionato!.toUpperCase(),
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.5,
            ),
          ),
        ],
      ],
    );
  }
}

class RelaxToggleWidget extends StatelessWidget {
  final bool? isRilassato;
  final Function(bool) onChanged;

  const RelaxToggleWidget({
    super.key,
    required this.isRilassato,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).colorScheme.primary;

    return Column(
      children: [
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
                isRilassato == true,
                () => onChanged(true),
                primaryColor,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildChoiceButton(
                "No",
                isRilassato == false,
                () => onChanged(false),
                primaryColor,
              ),
            ),
          ],
        ),
      ],
    );
  }

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

class TagsSelectorWidget extends StatelessWidget {
  final List<String> tagsSelezionati;
  final Function(String, bool) onTagToggled;

  static const List<String> _opzioniApprezzamento = [
    "Silenzio",
    "Panorama",
    "Audio Guida",
    "Passo Libero",
    "Profumi",
  ];

  const TagsSelectorWidget({
    super.key,
    required this.tagsSelezionati,
    required this.onTagToggled,
  });

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).colorScheme.primary;

    return Column(
      children: [
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
            final isSelected = tagsSelezionati.contains(tag);
            return FilterChip(
              label: Text(tag),
              selected: isSelected,
              onSelected: (selected) => onTagToggled(tag, selected),
              selectedColor: primaryColor,
              checkmarkColor: Colors.white,
              backgroundColor: Colors.grey.shade200,
              labelStyle: TextStyle(
                fontSize: 13,
                color: isSelected ? Colors.white : Colors.black87,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
              side: BorderSide.none,
              shape: const StadiumBorder(),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            );
          }).toList(),
        ),
      ],
    );
  }
}

class SaveButtonWidget extends StatelessWidget {
  final QuestionarioViewModel viewModel;
  final ActivityModel attivita;
  final String? moodSelezionato;
  final bool? percorsoHaRilassato;
  final List<String> apprezzamentiSelezionati;

  const SaveButtonWidget({
    super.key,
    required this.viewModel,
    required this.attivita,
    required this.moodSelezionato,
    required this.percorsoHaRilassato,
    required this.apprezzamentiSelezionati,
  });

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).colorScheme.primary;

    // L'UNICO ListenableBuilder della pagina: in ascolto del viewModel.isLoading
    return ListenableBuilder(
      listenable: viewModel,
      builder: (context, _) {
        return SizedBox(
          width: double.infinity,
          height: 60,
          child: ElevatedButton(
            onPressed: viewModel.isLoading
                ? null
                : () async {
                    if (attivita.id != null) {
                      await viewModel.salvaQuestionario(
                        activityId: attivita.id!,
                        umore: moodSelezionato,
                        percorsoHaRilassato: percorsoHaRilassato,
                        elementiApprezzati: apprezzamentiSelezionati,
                      );
                    }
                    if (context.mounted) {
                      Navigator.of(context).popUntil((route) => route.isFirst);
                      context.read<MainWrapperViewModel>().cambiaPagina(0);
                    }
                  },
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryColor,
              shape: const StadiumBorder(),
            ),
            child: viewModel.isLoading
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(color: Colors.white),
                  )
                : const Text(
                    "Torna alla Foresta",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
          ),
        );
      },
    );
  }
}

class ShareButtonWidget extends StatelessWidget {
  final ActivityModel attivita;
  final String? moodSelezionato;

  const ShareButtonWidget({
    super.key,
    required this.attivita,
    required this.moodSelezionato,
  });

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: () {
        showDialog(
          context: context,
          builder: (context) =>
              CondivisioneDialog(attivita: attivita, umore: moodSelezionato),
        );
      },
      child: const Text(
        "CONDIVIDI IL TUO CAMMINO",
        style: TextStyle(
          color: Colors.black54,
          fontSize: 11,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}
