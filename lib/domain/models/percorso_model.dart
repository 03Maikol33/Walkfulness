import 'package:cloud_firestore/cloud_firestore.dart';

class PercorsoModel {
  final String? id;
  final String utenteId; // id dell'utente che ha creato il percorso
  final String nome;
  final String nomeCreatore; // nome dell'utente che ha creato il percorso
  final List<Map<String, dynamic>> tappe;
  final String? dataCreazione;
  bool isPublic;

  final String citta;
  final List<String> tags;

  PercorsoModel({
    this.id,
    required this.utenteId,
    required this.nome,
    required this.tappe,
    this.nomeCreatore = "Sconosciuto",
    this.dataCreazione,
    this.isPublic = false, //default i percorsi sono privati
    this.citta = "",
    this.tags = const [],
  });

  Map<String, dynamic> toMap() {
    return {
      'utenteId': utenteId,
      'nome': nome,
      'tappe': tappe,
      'dataCreazione': FieldValue.serverTimestamp(),
      'isPublic': isPublic,
      'nomeCreatore': nomeCreatore,
      'citta': citta.toLowerCase(),
      'tags': tags,
    };
  }

  factory PercorsoModel.fromMap(Map<String, dynamic> map, String documentId) {
    return PercorsoModel(
      id: documentId,
      utenteId: map['utenteId'] ?? '',
      nome: map['nome'] ?? '',
      tappe: List<Map<String, dynamic>>.from(map['tappe'] ?? []),
      nomeCreatore: map['nomeCreatore'] ?? 'Sconosciuto',
      isPublic: map['isPublic'] ?? false,
      dataCreazione: map['dataCreazione'] != null
          ? (map['dataCreazione'] as Timestamp).toDate().toString()
          : null,
      citta: map['citta'] ?? '',
      tags: List<String>.from(map['tags'] ?? []),
    );
  }
}
