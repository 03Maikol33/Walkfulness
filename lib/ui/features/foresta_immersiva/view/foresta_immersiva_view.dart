import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../../../core/providers/user_provider.dart';
import '../../main_wrapper/view_model/main_wrapper_view_model.dart';

class ForestaImmersivaView extends StatefulWidget {
  const ForestaImmersivaView({super.key});

  @override
  State<ForestaImmersivaView> createState() => _ForestaImmersivaViewState();
}

class _ForestaImmersivaViewState extends State<ForestaImmersivaView> {
  late final WebViewController _controller;
  bool _isCaricamentoCompletato = false;

  @override
  void initState() {
    super.initState();

    // Configuriamo il controller della WebView
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0x00000000))
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (_) {
            setState(() => _isCaricamentoCompletato = true);
          },
        ),
      );

    // Esecuzione dopo il primo frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _caricaAmbienteVirtuale();
    });
  }

  Future<void> _caricaAmbienteVirtuale() async {
    // 1. Recuperiamo i dati direttamente dal UserProvider (come fai nel profilo)
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final utente = userProvider.utente;

    final int livello = utente?.livelloCalcolato ?? 1;
    // Riportiamo la percentuale da 0-100 a un decimale 0.0-1.0 per l'HTML
    final double progress = (utente?.percentualeLivello ?? 0.0) / 100;

    try {
      // 2. Carichiamo l'asset (assicurati che il path sia giusto, tu avevi messo assets/html/foresta.html)
      final String htmlContent = await rootBundle.loadString(
        'assets/html/foresta.html',
      );

      // 3. Prepariamo l'URL fittizio
      final String queryParams = "?level=$livello&progress=$progress";
      final String fullUrl = "https://app.walkfulness.local/$queryParams";

      await _controller.loadHtmlString(htmlContent, baseUrl: fullUrl);
    } catch (e) {
      debugPrint("Errore nel caricamento della foresta immersiva: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    // Rendiamo la barra di stato trasparente per l'effetto immersivo
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
      ),
    );

    return Scaffold(
      backgroundColor: const Color(0xFF0D1F0E),
      body: Stack(
        children: [
          // WebView a tutto schermo
          SizedBox.expand(child: WebViewWidget(controller: _controller)),

          // Tasto di chiusura minimale in alto a sinistra
          Positioned(
            top: MediaQuery.of(context).padding.top + 10,
            left: 16,
            child: IconButton(
              icon: const Icon(Icons.close, color: Colors.white60, size: 32),
              onPressed: () {
                // USIAMO IL WRAPPER PER CHIUDERE LA SCHERMATA INTERNA
                context.read<MainWrapperViewModel>().chiudiPaginaInterna();
              },
            ),
          ),

          // Schermata di caricamento
          if (!_isCaricamentoCompletato)
            Container(
              color: const Color(0xFF0D1F0E),
              child: const Center(
                child: CircularProgressIndicator(color: Colors.greenAccent),
              ),
            ),
        ],
      ),
    );
  }
}
