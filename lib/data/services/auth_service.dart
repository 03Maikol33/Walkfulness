import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Metodo per il Login
  Future<User?> login(String email, String password) async {
    try {
      UserCredential result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return result.user; // Restituisce l'utente se il login va a buon fine
    } on FirebaseAuthException catch (e) {
      rethrow;
    } catch (e) {
      print("Errore login: $e");
      return null;
    }
  }

  // Metodo per la Registrazione
  Future<User?> register(String email, String password) async {
    try {
      UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      return result.user;
    } on FirebaseAuthException catch (e) {
      print("Errore registrazione: $e");
      rethrow;
    } catch (e) {
      return null;
    }
  }

  // Metodo per il Logout
  Future<void> logout() async {
    await _auth.signOut();
  }
}
