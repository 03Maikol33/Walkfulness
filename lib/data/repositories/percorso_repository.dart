import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:walkfulness/domain/models/percorso_model.dart';

class PercorsoRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Estrae solo i percorsi creati dall'utente attualmente loggato
  Future<List<PercorsoModel>> getMieiPercorsi(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('percorsi')
          .where('utenteId', isEqualTo: userId)
          .orderBy('dataCreazione', descending: true)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        return PercorsoModel.fromMap(data, doc.id);
      }).toList();
    } catch (e) {
      debugPrint("Errore nel recupero dei miei percorsi: $e");
      return [];
    }
  }

  // Estrae tutti i percorsi che hanno il flag isPublic a true
  Future<List<PercorsoModel>> getPercorsiCommunity({
    String? citta,
    String? tag,
  }) async {
    try {
      Query query = _firestore
          .collection('percorsi')
          .where('isPublic', isEqualTo: true);

      if (citta != null && citta.trim().isNotEmpty) {
        query = query.where('citta', isEqualTo: citta.trim().toLowerCase());
      }

      if (tag != null && tag.isNotEmpty) {
        query = query.where('tags', arrayContains: tag);
      }

      final snapshot = await query.limit(30).get();

      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return PercorsoModel.fromMap(data, doc.id);
      }).toList();
    } catch (e) {
      debugPrint("Errore nel recupero della community: $e");
      return [];
    }
  }

  //ELIMINA PERCORSO
  Future<bool> eliminaPercorso(String percorsoId) async {
    try {
      await _firestore.collection('percorsi').doc(percorsoId).delete();
      return true;
    } catch (e) {
      debugPrint("Errore durante l'eliminazione del percorso: $e");
      return false;
    }
  }

  Future<bool> cambiaVisibilita(String percorsoId, bool nuovaVisibilita) async {
    try {
      await _firestore.collection('percorsi').doc(percorsoId).update({
        'isPublic': nuovaVisibilita,
      });
      return true;
    } catch (e) {
      debugPrint("Errore cambio visibilità: $e");
      return false;
    }
  }
}
