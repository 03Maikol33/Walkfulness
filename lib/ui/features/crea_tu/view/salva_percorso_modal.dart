import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:walkfulness/ui/features/crea_tu/view_model/crea_tu_view_model.dart';
import 'package:walkfulness/ui/core/providers/user_provider.dart';
import 'package:walkfulness/ui/features/main_wrapper/view_model/main_wrapper_view_model.dart';

class SalvaPercorsoModal extends StatefulWidget {
  final CreaTuViewModel viewModel;

  const SalvaPercorsoModal({super.key, required this.viewModel});

  @override
  State<SalvaPercorsoModal> createState() => _SalvaPercorsoModalState();
}

class _SalvaPercorsoModalState extends State<SalvaPercorsoModal> {
  final _nomeController = TextEditingController();
  bool _isPublic = false;
  final List<String> _tagSelezionati = [];

  final List<String> _tagDisponibili = [
    "Natura",
    "Città",
    "Montagna",
    "Relax",
    "Sport",
    "Cultura",
    "Mare",
    "Bosco",
  ];

  @override
  void dispose() {
    _nomeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final userProvider = context.read<UserProvider>();

    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      decoration: const BoxDecoration(
        color: Color(0xFFF7FBF8),
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize:
              MainAxisSize.min, // Occupa solo lo spazio necessario in verticale
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 5,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            Text(
              "Dai un nome alla tua\navventura",
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: const Color(0xFF012D1C),
              ),
            ),
            const SizedBox(height: 24),

            // NOME PERCORSO
            TextField(
              controller: _nomeController,
              decoration: InputDecoration(
                labelText: "Nome del percorso",
                hintText: "es. Camminata nel bosco",
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 24),

            // SEZIONE TAG
            const Text(
              "TAG TEMATICI",
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              children: _tagDisponibili.map((tag) {
                final isSelected = _tagSelezionati.contains(tag);
                return FilterChip(
                  label: Text(tag),
                  selected: isSelected,
                  onSelected: (selected) {
                    setState(() {
                      selected
                          ? _tagSelezionati.add(tag)
                          : _tagSelezionati.remove(tag);
                    });
                  },
                  selectedColor: const Color(0xFF012D1C),
                  checkmarkColor: Colors.white,
                  labelStyle: TextStyle(
                    color: isSelected ? Colors.white : Colors.black87,
                  ),
                  side: BorderSide.none,
                  shape: const StadiumBorder(),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),

            // VISIBILITÀ
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
              child: SwitchListTile(
                title: const Text(
                  "Rendi pubblico",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: const Text(
                  "Permetti agli altri di vedere e percorrere questo itinerario",
                  style: TextStyle(fontSize: 11),
                ),
                value: _isPublic,
                activeColor: const Color(0xFF012D1C),
                onChanged: (val) => setState(() => _isPublic = val),
              ),
            ),

            const SizedBox(height: 32),

            // BOTTONE SALVA
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: () async {
                  if (_nomeController.text.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("Inserisci un nome per il percorso"),
                      ),
                    );
                    return;
                  }

                  // Usiamo widget.viewModel che abbiamo passato nel costruttore
                  final successo = await widget.viewModel
                      .salvaPercorsoConDettagli(
                        context: context,
                        utenteId: userProvider.utente!.uid,
                        nome: _nomeController.text,
                        isPublic: _isPublic,
                        tags: _tagSelezionati,
                      );

                  if (successo && mounted) {
                    //chiude il BottomSheet
                    Navigator.pop(context);
                    // chiede al Wrapper di chiudere la mappa e tornare alla lista
                    context.read<MainWrapperViewModel>().chiudiPaginaInterna();
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF012D1C),
                  shape: const StadiumBorder(),
                ),
                child: const Text(
                  "CONFERMA E SALVA",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
