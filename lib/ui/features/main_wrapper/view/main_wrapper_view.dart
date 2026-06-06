import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../view_model/main_wrapper_view_model.dart';
import '../../crea/view/crea_view.dart';
import '../../foresta/view/foresta_view.dart';
import '../../tribu/view/tribu_view.dart';
import '../../profilo/view/profilo_view.dart';

class MainWrapperView extends StatefulWidget {
  const MainWrapperView({super.key});

  @override
  State<MainWrapperView> createState() => _MainWrapperViewState();
}

class _MainWrapperViewState extends State<MainWrapperView> {
  // Lista delle pagine principali corrispondenti ai tab della navbar
  final List<Widget> _pages = [
    const ForestaView(),
    const CreaView(),
    const TribuView(),
    const ProfiloView(),
  ];

  @override
  Widget build(BuildContext context) {
    // Ascolta i cambiamenti nel ViewModel globale
    final viewModel = context.watch<MainWrapperViewModel>();

    return PopScope(
      // Impedisce la chiusura dell'app se c'è una pagina interna aperta
      canPop: viewModel.paginaInterna == null,
      onPopInvokedWithResult: (bool didPop, Object? result) {
        if (didPop) return;
        // Se l'utente usa il tasto indietro fisico chiude la pagina interna
        if (viewModel.paginaInterna != null) {
          viewModel.chiudiPaginaInterna();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Image.asset('assets/images/logo_decorated.png', height: 40),
          centerTitle: false,
        ),
        //se c'è una pagina interna viene mostrata, altrimenti usa l'IndexedStack
        body: viewModel.paginaInterna != null
            ? viewModel.paginaInterna!
            : IndexedStack(index: viewModel.currentIndex, children: _pages),
        bottomNavigationBar: NavigationBar(
          selectedIndex: viewModel.currentIndex,
          onDestinationSelected: viewModel.cambiaPagina,
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.forest_outlined),
              selectedIcon: Icon(Icons.forest),
              label: "Foresta",
            ),
            NavigationDestination(
              icon: Icon(Icons.add_circle_outline),
              selectedIcon: Icon(Icons.add_circle),
              label: "Crea",
            ),
            NavigationDestination(
              icon: Icon(Icons.groups_outlined),
              selectedIcon: Icon(Icons.groups),
              label: "Tribù",
            ),
            NavigationDestination(
              icon: Icon(Icons.person_outline),
              selectedIcon: Icon(Icons.person),
              label: "Profilo",
            ),
          ],
        ),
      ),
    );
  }
}
