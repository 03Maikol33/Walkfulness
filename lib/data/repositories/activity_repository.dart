import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/models/activity_model.dart';

class ActivityRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Salva l'attività e aggiorna i progressi dell'utente
  Future<String> salvaAttivita(ActivityModel attivita) async {
    try {
      //garantisce che le operazioni vengano effettutate iun modo atomico
      WriteBatch batch = _firestore.batch(); //ottiene un batch

      DocumentReference activityRef = _firestore.collection('activities').doc();
      batch.set(activityRef, attivita.toMap()); //salva l'attività nel batch

      //ottiene l'utente dell'attività
      DocumentReference userRef = _firestore
          .collection('users')
          .doc(attivita.userId);

      batch.update(userRef, {
        'kmPercorsi': FieldValue.increment(
          attivita.km,
        ), //incrementa i km percorsi dell'utente
        'oreInNatura': FieldValue.increment(
          attivita.durata.inSeconds / 3600,
        ), //incrementa le ore in natura dell'utente
      });

      await batch.commit();
      return activityRef.id;
    } catch (e) {
      print("Errore nel salvataggio attività: $e");
      rethrow;
    }
  }

  Future<void> aggiornaQuestionario(
    String activityId,
    Map<String, dynamic> dati,
  ) async {
    try {
      await _firestore.collection('activities').doc(activityId).update(dati);
    } catch (e) {
      print("Errore aggiornamento questionario: $e");
      rethrow;
    }
  }

  // Recupera lo storico attività di un utente specifico
  Future<List<ActivityModel>> getStoricoUtente(String uid) async {
    final snapshot = await _firestore
        .collection('activities')
        .where('userId', isEqualTo: uid)
        .orderBy('data', descending: true)
        .get();

    return snapshot.docs
        .map((doc) => ActivityModel.fromMap(doc.data(), doc.id))
        .toList();
  }
}
