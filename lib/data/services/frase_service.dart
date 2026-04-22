import 'dart:convert';
import 'dart:math';
import 'package:flutter/services.dart';

class FraseService {
  //istanza privata statica
  static final FraseService _instance = FraseService._internal();

  //factory constructor che restituisce sempre la stessa istanza
  factory FraseService() {
    return _instance;
  }

  //costruttore privato
  FraseService._internal();

  List<String> _frasi = [];

  //inizializza le frasi
  Future<void> inizializza() async {
    try {
      final String response = await rootBundle.loadString(
        'assets/data/frasi.json',
      );
      final List<dynamic> data = json.decode(response);
      _frasi = data.cast<String>();
    } catch (e) {
      print("Errore durante il caricamento delle frasi: $e");
      _frasi = [
        "Cammina con la natura, cammina con te stesso.",
      ]; // Frase di default in caso di errore
    }
  }

  String frase() {
    if (_frasi.isEmpty) {
      return "Cammina con la natura, cammina con te stesso."; // Frase di default se la lista è vuota
    }
    final random = Random();
    return _frasi[random.nextInt(_frasi.length)];
  }
}
