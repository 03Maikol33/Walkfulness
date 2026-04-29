import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';
import 'package:latlong2/latlong.dart';

class PercorsoModel {
  final String? id;
  final String utenteId; // ID dell'utente che ha creato il percorso
  final String nome;
  final List<Map<String, dynamic>> tappe;
  bool isPublic;

  PercorsoModel({
    this.id,
    required this.utenteId,
    required this.nome,
    required this.tappe,
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
}
