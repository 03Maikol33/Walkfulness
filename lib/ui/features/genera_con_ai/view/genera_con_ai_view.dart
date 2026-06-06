import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:walkfulness/ui/features/genera_con_ai/view_model/genera_con_ai_view_model.dart';
import 'package:walkfulness/ui/features/crea_tu/view/crea_tu_view.dart';
import 'package:walkfulness/ui/features/main_wrapper/view_model/main_wrapper_view_model.dart';

class GeneraConAiView extends StatefulWidget {
  final GeneraConAiViewModel? viewModelOverride;

  const GeneraConAiView({super.key, this.viewModelOverride});

  @override
  State<GeneraConAiView> createState() => _GeneraConAiViewState();
}

class _GeneraConAiViewState extends State<GeneraConAiView> {
  final TextEditingController _noteController = TextEditingController();
  late GeneraConAiViewModel _viewModel;

  //stato locale della ui
  String? moodSelezionato;
  final List<String> tagSelezionati = [];

  final List<String> tagDisponibili = [
    "Natura",
    "Città",
    "Montagna",
    "Relax",
    "Sport",
    "Cultura",
    "Mare",
    "Bosco",
  ];

  final List<Map<String, String>> moods = [
    {"label": "Rilassato", "emoji": "😌"},
    {"label": "Stressato", "emoji": "😤"},
    {"label": "Energico", "emoji": "⚡"},
    {"label": "Triste", "emoji": "😔"},
    {"label": "Riflessivo", "emoji": "🤔"},
    {"label": "Ansioso", "emoji": "😰"},
  ];
  //********** */

  @override
  void initState() {
    super.initState();

    _viewModel =
        widget.viewModelOverride ?? GeneraConAiViewModel(); //per il testing
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;

    return ChangeNotifierProvider<GeneraConAiViewModel>.value(
      value: _viewModel,
      child: Scaffold(
        backgroundColor: const Color(0xFFF7FBF8),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Genera con AI",
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: primary,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                "Come ti senti oggi?",
                style: theme.textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: primary,
                ),
              ),
              const SizedBox(height: 8),
              const Text("Scegli un'emozione per iniziare."),
              const SizedBox(height: 20),

              //selettore mood
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 1.1,
                ),
                itemCount: moods.length,
                itemBuilder: (context, index) {
                  final mood = moods[index];
                  final isSelected = moodSelezionato == mood['label'];
                  return InkWell(
                    onTap: () => setState(() {
                      //set state locale alla ui
                      moodSelezionato = mood['label'];
                    }),
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      decoration: BoxDecoration(
                        color: isSelected ? primary : Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isSelected ? primary : Colors.grey.shade200,
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            mood['emoji']!,
                            style: const TextStyle(fontSize: 24),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            mood['label']!,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: isSelected ? Colors.white : primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 32),

              Text(
                "Preferenze ambientali",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: primary,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 12),

              //tag ambientali
              Wrap(
                spacing: 8,
                children: tagDisponibili.map((tag) {
                  final isSelected = tagSelezionati.contains(tag);
                  return FilterChip(
                    label: Text(tag),
                    selected: isSelected,
                    onSelected: (selected) => setState(() {
                      //set state locale alla ui
                      if (selected) {
                        tagSelezionati.add(tag);
                      } else {
                        tagSelezionati.remove(tag);
                      }
                    }),
                    selectedColor: primary,
                    checkmarkColor: Colors.white,
                    labelStyle: TextStyle(
                      fontSize: 12,
                      color: isSelected ? Colors.white : Colors.black87,
                    ),
                    side: BorderSide.none,
                    shape: const StadiumBorder(),
                    backgroundColor: Colors.white,
                  );
                }).toList(),
              ),
              const SizedBox(height: 32),

              Text(
                "Richieste particolari",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: primary,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _noteController,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText:
                      "Es: Evita strade asfaltate, voglio passare vicino a un ruscello...",
                  hintStyle: const TextStyle(
                    fontSize: 14,
                    color: Colors.black38,
                  ),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 40),

              //genera btn
              Consumer<GeneraConAiViewModel>(
                //lìunico componente ui che ascolta il vm per il caricamento
                builder: (context, vm, _) {
                  return SizedBox(
                    width: double.infinity,
                    height: 60,
                    child: ElevatedButton(
                      onPressed: (moodSelezionato == null || vm.isLoading)
                          ? null
                          : () async {
                              final percorso = await vm.generaItinerario(
                                moodSelezionato,
                                tagSelezionati,
                                _noteController.text,
                              );
                              if (percorso != null && context.mounted) {
                                context
                                    .read<MainWrapperViewModel>()
                                    .apriPaginaInterna(
                                      const CreaTuView(),
                                      arguments: percorso,
                                    );
                              }
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primary,
                        shape: const StadiumBorder(),
                      ),
                      child: vm.isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text(
                              "GENERA PERCORSO",
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
