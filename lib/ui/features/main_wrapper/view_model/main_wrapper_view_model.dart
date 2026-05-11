import 'package:flutter/material.dart';

class MainWrapperViewModel extends ChangeNotifier {
  //stato
  int _currentIndex = 0;
  Widget? _paginaInterna;
  //getter
  int get currentIndex => _currentIndex;
  Widget? get paginaInterna => _paginaInterna;

  void cambiaPagina(int index) {
    if (index == _currentIndex) return;
    _currentIndex = index;
    _paginaInterna =
        null; // Resetta la pagina interna quando si cambia sezione dalla bottom navigation
    notifyListeners(); //notifica i listener del cambiamento
  }

  void apriPaginaInterna(Widget pagina) {
    _paginaInterna = pagina;
    notifyListeners();
  }

  void chiudiPaginaInterna() {
    _paginaInterna = null;
    notifyListeners();
  }

  void tornaAllaHome() {
    if (_currentIndex == 0) return;
    _currentIndex = 0;
    _paginaInterna =
        null; // Resetta la pagina interna quando si torna alla home
    notifyListeners();
  }
}
