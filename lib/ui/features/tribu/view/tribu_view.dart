import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class TribuView extends StatelessWidget {
  const TribuView({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      // 1. IL BOTTONE FLOTTANTE (Extended FAB)
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => print("Crea iniziativa"),
        backgroundColor: const Color(0xFF012D1C),
        icon: const Icon(Icons.add, color: Colors.white),
        label: Text(
          "Crea iniziativa",
          style: GoogleFonts.inter(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            //titolo
            Text(
              "Iniziative collettive",
              style: theme.textTheme.headlineLarge, //stile del testo
            ),
            const SizedBox(height: 8),
            Text("Partecipa ad iniziative collettive nella tua zona."),
            const SizedBox(height: 24),

            // 2. FILTRI RAPIDI (FilterChip)
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildFilterChip("Qui vicino", isSelected: true),
                  const SizedBox(width: 8),
                  _buildFilterChip("Questo weekend"),
                  const SizedBox(width: 8),
                  _buildFilterChip("Settimana"),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // 3. CARD INIZIATIVA
            Card(
              elevation: 4,
              shadowColor: Colors.black12,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(32),
              ),
              clipBehavior: Clip.antiAlias,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Image.asset(
                    'assets/images/iniziativa_default.jpg',
                    height: 200,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),

                  // IMMAGINE COPERTINA
                  /*Image.network(
                    'https://images.unsplash.com/photo-1441974231531-c6227db76b6e?auto=format&fit=crop&w=800&q=80',
                    height: 250,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),*/
                  Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // LOCATION
                        Row(
                          children: [
                            const Icon(
                              Icons.location_on_outlined,
                              size: 14,
                              color: Colors.grey,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              "PARCO NAZIONALE XY",
                              style: TextStyle(
                                fontSize: 10,
                                letterSpacing: 1.2,
                                color: Colors.grey.shade600,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        // TITOLO
                        Text(
                          "Sunday Path Restoration",
                          style: GoogleFonts.notoSerif(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.primary,
                          ),
                        ),

                        const SizedBox(height: 20),

                        // PARTECIPANTI E DISPONIBILITÀ
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _buildAvatarGroup(),
                            _buildAvailabilityBadge(),
                          ],
                        ),

                        const SizedBox(height: 24),

                        // SEZIONE GOAL (FilledCard Small)
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.surfaceVariant.withOpacity(
                              0.3,
                            ),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.eco_outlined,
                                color: Colors.green,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      "ECO-IMPACT GOAL",
                                      style: TextStyle(
                                        fontSize: 9,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.grey,
                                      ),
                                    ),
                                    Text(
                                      "Pulire il sentiero dalle microplastiche.",
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: theme.colorScheme.primary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // HELPER: FILTER CHIP
  Widget _buildFilterChip(String label, {bool isSelected = false}) {
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (bool value) {},
      backgroundColor: Colors.grey.shade100,
      selectedColor: const Color(0xFF012D1C),
      checkmarkColor: Colors.white,
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : Colors.black87,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
      shape: const StadiumBorder(),
      side: BorderSide.none,
    );
  }

  // HELPER: AVATAR GROUP (Volti sovrapposti)
  Widget _buildAvatarGroup() {
    return Row(
      children: [
        SizedBox(
          width: 80,
          height: 32,
          child: Stack(
            children: [
              _avatar(0, 'https://i.pravatar.cc/150?u=1'),
              _avatar(20, 'https://i.pravatar.cc/150?u=2'),
              Positioned(
                left: 40,
                child: CircleAvatar(
                  radius: 16,
                  backgroundColor: const Color(0xFF184D4F),
                  child: const Text(
                    "+12",
                    style: TextStyle(fontSize: 10, color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        const Text(
          "14 partecipanti",
          style: TextStyle(fontSize: 12, color: Colors.grey),
        ),
      ],
    );
  }

  Positioned _avatar(double left, String url) {
    return Positioned(
      left: left,
      child: CircleAvatar(
        radius: 16,
        backgroundColor: Colors.white,
        child: CircleAvatar(radius: 14, backgroundImage: NetworkImage(url)),
      ),
    );
  }

  // HELPER: BADGE DISPONIBILITÀ
  Widget _buildAvailabilityBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFC7EBEB),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: const [
          Text("Ancora", style: TextStyle(fontSize: 9, color: Colors.black54)),
          Text(
            "20 posti",
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: Color(0xFF184D4F),
            ),
          ),
        ],
      ),
    );
  }
}
