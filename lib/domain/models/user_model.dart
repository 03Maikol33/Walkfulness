import 'dart:math';

class UserModel {
  final String uid; // L'ID univoco fornito da Firebase
  final String email;
  final String? nome;
  final double kmPercorsi;
  final int livelloForesta;
  final double oreInNatura;

  UserModel({
    required this.uid,
    required this.email,
    this.nome,
    this.kmPercorsi = 0.0,
    this.livelloForesta = 1,
    this.oreInNatura = 0.0,
  });

  int get livelloCalcolato {
    if (kmPercorsi <= 0) return 1;
    // Formula inversa: L = floor(0.5 + sqrt(0.25 + 0.2 * K))
    return (0.5 + sqrt(0.25 + 0.2 * kmPercorsi)).floor();
  }

  double get percentualeLivello {
    int L = livelloCalcolato;
    int kmInizio = 5 * L * (L - 1); // Traguardo livello attuale
    int kmFine = 5 * (L + 1) * L; // Traguardo livello successivo

    if (kmFine == kmInizio) return 0.0;

    double progresso = (kmPercorsi - kmInizio) / (kmFine - kmInizio);
    return (progresso * 100).clamp(0.0, 100.0);
  }
}
