import 'package:cloud_firestore/cloud_firestore.dart';

class PercorsoModel {
  final String? id;
  final String utenteId; // ID dell'utente che ha creato il percorso
  final String nome;
  final List<Map<String, dynamic>> tappe;
  final String? dataCreazione;
  bool isPublic;

  PercorsoModel({
    this.id,
    required this.utenteId,
    required this.nome,
    required this.tappe,
    this.dataCreazione,
    this.isPublic = false, // Di default i percorsi sono privati
  });

  Map<String, dynamic> toMap() {
    return {
      'utenteId': utenteId,
      'nome': nome,
      'tappe': tappe,
      'dataCreazione': FieldValue.serverTimestamp(),
      'isPublic': isPublic,
    };
  }

  factory PercorsoModel.fromMap(Map<String, dynamic> map, String documentId) {
    return PercorsoModel(
      id: documentId,
      utenteId: map['utenteId'] ?? '',
      nome: map['nome'] ?? '',
      tappe: List<Map<String, dynamic>>.from(map['tappe'] ?? []),
      isPublic: map['isPublic'] ?? false,
      dataCreazione: map['dataCreazione'] != null
          ? (map['dataCreazione'] as Timestamp).toDate().toString()
          : null,
    );
  }
}
