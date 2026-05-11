import 'package:flutter/material.dart';

class MainWrapperViewModel extends ChangeNotifier {
  //stato
  int _currentIndex = 0;
  Widget? _paginaInterna;
  Object? _arguments;
  //getter
  int get currentIndex => _currentIndex;
  Widget? get paginaInterna => _paginaInterna;
  Object? get arguments => _arguments;

  void cambiaPagina(int index) {
    if (index == _currentIndex) return;
    _currentIndex = index;
    _paginaInterna =
        null; // Resetta la pagina interna quando si cambia sezione dalla bottom navigation
    _arguments = null; // Resetta gli argomenti quando si cambia pagina
    notifyListeners(); //notifica i listener del cambiamento
  }

  void apriPaginaInterna(Widget pagina, {Object? arguments}) {
    _paginaInterna = pagina;
    _arguments = arguments;
    notifyListeners();
  }

  void chiudiPaginaInterna() {
    _paginaInterna = null;
    _arguments =
        null; // Resetta gli argomenti quando si chiude la pagina interna
    notifyListeners();
  }

  void tornaAllaHome() {
    if (_currentIndex == 0) return;
    _currentIndex = 0;
    _paginaInterna =
        null; // Resetta la pagina interna quando si torna alla home
    _arguments = null; // Resetta gli argomenti quando si torna alla home
    notifyListeners();
  }
}
