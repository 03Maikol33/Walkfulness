import 'package:flutter/material.dart';
import '../../../../data/services/auth_service.dart';

class ProfiloViewModel extends ChangeNotifier {
  final AuthService _authService = AuthService();
  bool isLoading = false;

  Future<void> disconnetti() async {
    await _authService.logout();
  }
}
