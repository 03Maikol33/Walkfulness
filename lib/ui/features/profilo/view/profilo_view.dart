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
  final ProfiloViewModel _viewModel = ProfiloViewModel();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<UserProvider>().caricaUtente();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 30.0),
      child: Column(
        children: [
          // 1. ZONA UTENTE (Unico pezzo che ascolta i cambiamenti)
          Consumer<UserProvider>(
            builder: (context, userProvider, _) {
              if (userProvider.isLoading) {
                return const Center(child: CircularProgressIndicator());
              }

              final utente = userProvider.utente;
              if (utente == null) {
                return const Center(
                  child: Text("Errore nel caricamento dei dati"),
                );
              }

              return Column(
                children: [
                  Center(
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: ClipOval(
                        child: SizedBox(
                          width: 120,
                          height: 120,
                          child: Stack(
                            children: [
                              Positioned.fill(
                                child: Image.asset(
                                  'assets/images/default_profile_pic.png',
                                  fit: BoxFit.cover,
                                ),
                              ),
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
                  Text(
                    utente.nome ?? "Non disponibile",
                    style: GoogleFonts.notoSerif(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 40),
                  IntrinsicHeight(
                    child: Row(
                      children: [
                        Expanded(
                          child: _buildStatCard(
                            "KM PERCORSI",
                            "${utente.kmPercorsi.toStringAsFixed(1)} km",
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildStatCard(
                            "ORE IN NATURA",
                            "${utente.oreInNatura.toStringAsFixed(1)} h",
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  ForestCard(
                    livello: utente.livelloCalcolato,
                    percentuale: utente.percentualeLivello.toInt(),
                    onTap: () {
                      context.read<MainWrapperViewModel>().apriPaginaInterna(
                        const ForestaImmersivaView(),
                      );
                    },
                  ),
                ],
              );
            },
          ),

          const SizedBox(height: 32),

          // 2. MENU E LOGOUT (Pezzo 100% Statico!)
          _buildMenuItem(
            Icons.history,
            "Storico Attività",
            onTap: () => context.read<MainWrapperViewModel>().apriPaginaInterna(
              const StoricoAttivitaView(),
            ),
          ),
          _buildMenuItem(
            Icons.map_outlined,
            "I Miei Percorsi",
            onTap: () => context.read<MainWrapperViewModel>().apriPaginaInterna(
              const MieiPercorsiView(),
            ),
          ),
          _buildMenuItem(Icons.info_outline, "Informazioni"),

          const SizedBox(height: 40),
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
            onPressed: () => _mostraConfirmLogout(),
            child: const Text(
              "Esci",
              style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  void _mostraConfirmLogout() {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text("Conferma Logout"),
          content: const Text("Sei sicuro di voler uscire dal tuo account?"),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text("Annulla"),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(dialogContext);
                context.read<UserProvider>().reset(); // Usa read, non ascolta!
                await _viewModel.disconnetti();
              },
              child: const Text("Esci", style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  Widget _buildStatCard(String label, String value) {
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

  Widget _buildMenuItem(IconData icon, String title, {VoidCallback? onTap}) {
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
