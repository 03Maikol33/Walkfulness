class MindfulnessService {
  
  Future<String> generaFrasePerPOI(String nomePoi) async {
    await Future.delayed(const Duration(seconds: 1));

    return "Fermati un istante. Davanti a te c'è $nomePoi. Fai un respiro profondo e ascolta il suono dell'ambiente che ti circonda.";
  }

  // Metodo per la User Story U6 (Velocità del passo)
  Future<String> generaEsercizioRespirazione(double velocitaAttuale) async {
    await Future.delayed(const Duration(seconds: 1));

    if (velocitaAttuale > 6.0) {
      return "Il tuo passo è molto energico. Sincronizza il respiro: inspira per tre passi, espira per tre passi.";
    } else {
      return "Stai camminando con calma. Porta la tua attenzione sulla pianta del piede che tocca il terreno.";
    }
  }
}
