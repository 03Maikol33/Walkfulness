// lib/data/repositories/tribu_repository.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/models/iniziativa_model.dart';

class TribuRepository {
  final CollectionReference _db = FirebaseFirestore.instance.collection('iniziative');

  // Recupera tutte le iniziative anche filtrate
  Future<List<IniziativaModel>> getIniziative() async {
    final snapshot = await _db.orderBy('dataOra', descending: false).get();
    return snapshot.docs.map((doc) => IniziativaModel.fromFirestore(doc)).toList();
  }

  // Crea nuova iniziativa
  Future<void> creaIniziativa(IniziativaModel iniziativa) async {
    await _db.add(iniziativa.toMap());
  }

  Future<void> aggiornaIniziativa(String id, IniziativaModel iniziativa) async {
    await _db.doc(id).update(iniziativa.toMap());
  }

  // Partecipa a un'iniziativa
  Future<void> partecipaIniziativa(String iniziativaId, String userId) async {
    await _db.doc(iniziativaId).update({
      'partecipantiIds': FieldValue.arrayUnion([userId])
    });
  }

  Future<void> abbandonaIniziativa(String iniziativaId, String userId) async {
    await _db.doc(iniziativaId).update({
      'partecipantiIds': FieldValue.arrayRemove([userId])
    });
  }

  // Elimina iniziativa
  Future<void> eliminaIniziativa(String id) async {
    await _db.doc(id).delete();
  }
}