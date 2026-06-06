// lib/domain/models/iniziativa_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class IniziativaModel {
  final String id;
  final String creatoreId;
  final String nomeCreatore;
  final String titolo;
  final String descrizione;
  final String obiettivo;
  final int maxPartecipanti;
  final DateTime dataOra;
  final String luogo;
  final GeoPoint posizione;
  final List<String> partecipantiIds;
  final String? immagineCopertina;

  IniziativaModel({
    required this.id,
    required this.creatoreId,
    required this.nomeCreatore,
    required this.titolo,
    required this.descrizione,
    required this.obiettivo,
    required this.maxPartecipanti,
    required this.dataOra,
    required this.luogo,
    required this.posizione,
    this.immagineCopertina,
    this.partecipantiIds = const [],
  });

  Map<String, dynamic> toMap() {
    return {
      'creatoreId': creatoreId,
      'nomeCreatore': nomeCreatore,
      'titolo': titolo,
      'descrizione': descrizione,
      'obiettivo': obiettivo,
      'maxPartecipanti': maxPartecipanti,
      'dataOra': dataOra,
      'luogo': luogo,
      'posizione': posizione,
      'immagineCopertina': immagineCopertina,
      'partecipantiIds': partecipantiIds,
    };
  }

  factory IniziativaModel.fromFirestore(DocumentSnapshot doc) {
    Map data = doc.data() as Map<String, dynamic>;
    return IniziativaModel(
      id: doc.id,
      creatoreId: data['creatoreId'] ?? '',
      nomeCreatore: data['nomeCreatore'] ?? '',
      titolo: data['titolo'] ?? '',
      descrizione: data['descrizione'] ?? '',
      obiettivo: data['obiettivo'] ?? '',
      maxPartecipanti: data['maxPartecipanti'] ?? 0,
      dataOra: (data['dataOra'] as Timestamp).toDate(),
      luogo: data['luogo'] ?? '',
      posizione: data['posizione'] as GeoPoint,
      immagineCopertina: data['immagineCopertina'] ?? '',
      partecipantiIds: List<String>.from(data['partecipantiIds'] ?? []),
    );
  }
}
