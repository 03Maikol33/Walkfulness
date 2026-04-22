import 'package:flutter/material.dart';

class MainWrapperViewModel extends ChangeNotifier {
  //stato
  int _currentIndex = 0;

  //getter
  int get currentIndex => _currentIndex;

  //logica

  void cambiaPagina(int index) {
    if (index == _currentIndex) return;
    _currentIndex = index;
    notifyListeners(); //notifica i listener del cambiamento
  }

  void tornaAllaHome() {
    if (_currentIndex == 0) return;
    _currentIndex = 0;
    notifyListeners();
  }
}
