// lib/ui/features/profilo/view/profilo_view.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:walkfulness/ui/core/providers/user_provider.dart';
import 'package:walkfulness/ui/core/widgets/forest_card.dart';
import 'package:walkfulness/ui/features/foresta_immersiva/view/foresta_immersiva_view.dart';
import 'package:walkfulness/ui/features/main_wrapper/view_model/main_wrapper_view_model.dart';
import 'package:walkfulness/ui/features/miei_percorsi/view/miei_percorsi_view.dart';
import 'package:walkfulness/ui/features/profilo/view_model/profilo_view_model.dart';
import 'package:walkfulness/ui/features/storico_attivita/view/storico_attivita_view.dart';

class ProfiloView extends StatefulWidget {
  const ProfiloView({super.key});

  @override
  State<ProfiloView> createState() => _ProfiloViewState();
}

class _ProfiloViewState extends State<ProfiloView> {
  // Il ViewModel per gestire le azioni (es. disconnetti)
  final ProfiloViewModel _viewModel = ProfiloViewModel();

  @override
  void initState() {
    super.initState();
    //appena il widget si monta vengono caricati i dati
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Carica i dati dell'utente loggato tramite il provider
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      userProvider.caricaUtente();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Recupero l'utente loggato grazie al provider
    final userProvider = Provider.of<UserProvider>(context);
    final utente = userProvider.utente;

    // Se il provider sta ancora caricando i dati da Firestore, mostriamo la rotellina
    if (userProvider.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    //caso utente nullo
    if (utente == null) {
      return const Center(
        child: Text("Errore nel caricamento dei dati utente"),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 30.0),
      child: Column(
        children: [
          Center(
            // Mantiene tutto perfettamente centrato nella colonna
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              // Il ClipOval qui taglia TUTTO quello che c'è dentro in un cerchio
              child: ClipOval(
                child: SizedBox(
                  width: 120, // Imposta la grandezza fissa per entrambi
                  height: 120,
                  child: Stack(
                    children: [
                      // 1. FOTO PROFILO (layer base)
                      Positioned.fill(
                        child: Image.asset(
                          'assets/images/default_profile_pic.png',
                          fit: BoxFit.cover,
                        ),
                      ),

                      // 2. MEDAGLIA (layer superiore)
                      Positioned.fill(
                        child: Image.asset(
                          'assets/images/silver_medal.png',
                          fit: BoxFit.cover,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // NOME UTENTE (Preso direttamente dal provider)
          Text(
            utente.nome ?? "Non disponibile",
            style: GoogleFonts.notoSerif(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.primary,
            ),
          ),

          const SizedBox(height: 40),

          // 2. STATS RAPIDE (KM e ORE)
          IntrinsicHeight(
            child: Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    context,
                    "KM PERCORSI",
                    "${utente.kmPercorsi.toStringAsFixed(1)} km",
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildStatCard(
                    context,
                    "ORE IN NATURA",
                    "${utente.oreInNatura.toStringAsFixed(1)} h",
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // 3. SEZIONE FORESTA (Dati calcolati nel modello)
          ForestCard(
            livello: utente.livelloCalcolato,
            percentuale: utente.percentualeLivello.toInt(),
            onTap: () {
              context.read<MainWrapperViewModel>().apriPaginaInterna(
                const ForestaImmersivaView(),
              );
            },
          ),

          const SizedBox(height: 32),

          // 4. VOCI DI MENU
          _buildMenuItem(
            context,
            Icons.history,
            "Storico Attività",
            onTap: () {
              context.read<MainWrapperViewModel>().apriPaginaInterna(
                const StoricoAttivitaView(),
              );
            },
          ),
          _buildMenuItem(
            context,
            Icons.map_outlined,
            "I Miei Percorsi",
            onTap: () {
              context.read<MainWrapperViewModel>().apriPaginaInterna(
                const MieiPercorsiView(),
              );
            },
          ),
          _buildMenuItem(context, Icons.info_outline, "Informazioni"),

          const SizedBox(height: 40),

          // 5. LINK GESTIONE & LOGOUT
          TextButton(
            onPressed: () {},
            child: Text(
              "Impostazioni Account",
              style: TextStyle(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          TextButton(
            onPressed: () => _mostraConfirmLogout(userProvider),
            child: const Text(
              "Esci",
              style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  // Finestra di conferma per il logout
  void _mostraConfirmLogout(UserProvider userProvider) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Conferma Logout"),
          content: const Text("Sei sicuro di voler uscire dal tuo account?"),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Annulla"),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(context);
                // Resettiamo il provider e disconnettiamo
                userProvider.reset();
                await _viewModel.disconnetti();
              },
              child: const Text("Esci", style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  // HELPER: CARD STATISTICHE
  Widget _buildStatCard(BuildContext context, String label, String value) {
    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: BorderSide(color: Colors.grey.shade100),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Column(
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 10,
                letterSpacing: 1,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: GoogleFonts.notoSerif(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // HELPER: MENU ITEM
  Widget _buildMenuItem(
    BuildContext context,
    IconData icon,
    String title, {
    VoidCallback? onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Card(
        elevation: 0,
        color: Colors.grey.shade50,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: ListTile(
          leading: Icon(icon, color: Colors.black87),
          title: Text(
            title,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
          ),
          trailing: const Icon(Icons.chevron_right, color: Colors.grey),
          onTap: onTap ?? () {},
        ),
      ),
    );
  }
}
