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

  //PERCORSI DELLA COMMUNITY
  // Estrae tutti i percorsi che hanno il flag isPublic a true
  Future<List<PercorsoModel>> getPercorsiCommunity() async {
    try {
      final snapshot = await _firestore
          .collection('percorsi')
          .where('isPublic', isEqualTo: true)
          .orderBy('dataCreazione', descending: true)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        return PercorsoModel.fromMap(data, doc.id);
      }).toList();
    } catch (e) {
      debugPrint("Errore nel recupero dei percorsi community: $e");
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
