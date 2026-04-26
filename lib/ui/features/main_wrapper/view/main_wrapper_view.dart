import 'package:flutter/material.dart';

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
  //istanziazione del view model
  final MainWrapperViewModel _viewModel = MainWrapperViewModel();

  //lista delle pagine raggiungibili tramite il bottom navigation
  final List<Widget> _pages = [
    const ForestaView(), // La tua schermata già pronta!
    const CreaView(), // La tua schermata già pronta!
    const TribuView(), // La tua schermata già pronta!
    const ProfiloView(), // La tua schermata già pronta!
  ];

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _viewModel,
      builder: (context, child) {
        return Scaffold(
          appBar: AppBar(
            title:
                //const Text('Walkfulness')
                Image.asset('assets/images/logo_decorated.png', height: 40),
            centerTitle: false,
          ),
          body: IndexedStack(index: _viewModel.currentIndex, children: _pages),

          bottomNavigationBar: NavigationBar(
            selectedIndex: _viewModel.currentIndex,
            onDestinationSelected: _viewModel.cambiaPagina,

            destinations: const [
              NavigationDestination(
                icon: Icon(Icons.forest_outlined),
                selectedIcon: Icon(
                  Icons.forest,
                ), // Icona piena quando selezionata
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
        );
      },
    );
  }
}
