import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../domain/models/user_model.dart';

//permette di trasformare i dati provenienti da Firestore in oggetti UserModel e di gestire le operazioni di lettura/scrittura su Firestore relative agli utenti
class UserRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> createUser(UserModel user) async {
    try {
      await _firestore.collection('users').doc(user.uid).set({
        'uid': user.uid,
        'nome': user.nome,
        'email': user.email,
        'kmPercorsi': user.kmPercorsi,
        'livelloForesta': user.livelloForesta,
        'oreInNatura': user.oreInNatura,
      });
    } catch (e) {
      print("Errore nella creazione del documento utente: $e");
      rethrow;
    }
  }

  Future<UserModel?> getUserData(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();

      if (doc.exists) {
        final data = doc.data();
        return UserModel(
          uid: data?['uid'] ?? '',
          nome: data?['nome'] ?? '',
          email: data?['email'] ?? '',
          // Castiamo a num e poi convertiamo in double per sicurezza
          kmPercorsi: (data?['kmPercorsi'] as num?)?.toDouble() ?? 0.0,
          livelloForesta: data?['livelloForesta'] ?? 1,
          oreInNatura: (data?['oreInNatura'] as num?)?.toDouble() ?? 0.0,
        );
      } else {
        print("Documento utente non trovato in Firestore per uid: $uid");
        return null;
      }
    } catch (e) {
      print("Errore durante il recupero dei dati utente: $e");
      rethrow;
    }
  }

  Future<void> updateProgress(String uid, double nuoviKm) async {
    // Calcoliamo il nuovo livello con la stessa formula
    int nuovoLivello = (0.5 + sqrt(0.25 + 0.2 * nuoviKm)).floor();

    await _firestore.collection('users').doc(uid).update({
      'kmPercorsi': nuoviKm,
      'livelloForesta': nuovoLivello,
    });
  }
}
