import 'package:cloud_firestore/cloud_firestore.dart';

class ActivityModel {
  final String? id; // ID Firestore
  final String userId; // utente che ha compiuto l'attività
  final double km; // Distanza totale percorsa
  final DateTime data;
  final Duration durata; // Durata totale dell'attività
  final List<GeoPoint> percorso; // La lista di punti GPS
  final String? meteo; // Opzionale: Condizioni meteo

  ActivityModel({
    this.id,
    required this.userId,
    required this.km,
    required this.data,
    required this.durata, //la durata totale è nota al momento dell'invocazione di questo cotruttore (cioè al termine dell'attività)
    required this.percorso,
    this.meteo,
  });

  // da oggetto a mappa siu Firestore
  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'km': km,
      'data': Timestamp.fromDate(data),
      'durataSecondi': durata.inSeconds,
      'percorso': percorso,
      'meteo': meteo,
    };
  }

  // da firestore a oggetto
  factory ActivityModel.fromMap(Map<String, dynamic> map, String documentId) {
    return ActivityModel(
      id: documentId,
      userId: map['userId'] ?? '',
      km: (map['km'] as num).toDouble(),
      data: (map['data'] as Timestamp).toDate(),
      durata: Duration(seconds: (map['durataSecondi'] as num).toInt() ?? 0),
      percorso: List<GeoPoint>.from(map['percorso'] ?? []),
      meteo: map['meteo'],
    );
  }
}
