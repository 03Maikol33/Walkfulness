import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../view_model/registrazione_view_model.dart';

class RegistrazioneView extends StatefulWidget {
  const RegistrazioneView({super.key});

  @override
  State<RegistrazioneView> createState() => _RegistrazioneViewState();
}

class _RegistrazioneViewState extends State<RegistrazioneView> {
  // Controller per catturare l'input
  final _nomeController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confermaPasswordController = TextEditingController();

  final _viewModel = RegistrazioneViewModel();

  @override
  void dispose() {
    // Pulizia dei controller
    _nomeController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confermaPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ListenableBuilder(
      listenable: _viewModel,
      builder: (context, _) {
        return Scaffold(
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            foregroundColor: Colors.black,
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(30.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Crea il tuo profilo",
                  style: GoogleFonts.notoSerif(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 8),
                const Text("Unisciti alla tribù e inizia a seminare."),

                const SizedBox(height: 40),

                // Messaggio di errore dinamico
                if (_viewModel.errorMessage != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16.0),
                    child: Text(
                      _viewModel.errorMessage!,
                      style: const TextStyle(
                        color: Colors.red,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),

                _buildRegField(
                  "Nome Completo",
                  Icons.person_outline,
                  _nomeController,
                ),
                const SizedBox(height: 20),
                _buildRegField("Email", Icons.email_outlined, _emailController),
                const SizedBox(height: 20),
                _buildRegField(
                  "Password",
                  Icons.lock_outline,
                  _passwordController,
                  obscure: true,
                ),
                const SizedBox(height: 20),
                _buildRegField(
                  "Conferma Password",
                  Icons.lock_reset_outlined,
                  _confermaPasswordController,
                  obscure: true,
                ),

                const SizedBox(height: 40),

                SizedBox(
                  width: double.infinity,
                  height: 55,
                  child: ElevatedButton(
                    // [cite: 420, 424]
                    onPressed: _viewModel.isLoading
                        ? null
                        : () async {
                            final success = await _viewModel.registra(
                              email: _emailController.text.trim(),
                              password: _passwordController.text.trim(),
                              confermaPassword: _confermaPasswordController.text
                                  .trim(),
                              nome: _nomeController.text.trim(),
                            );
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.colorScheme.primary,
                      shape: const StadiumBorder(),
                    ),
                    child: _viewModel.isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text(
                            "Registrati",
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // Helper aggiornato per accettare il controller
  Widget _buildRegField(
    String label,
    IconData icon,
    TextEditingController controller, {
    bool obscure = false,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      decoration: InputDecoration(
        prefixIcon: Icon(icon),
        labelText: label,
        border: UnderlineInputBorder(
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
      ),
    );
  }
}
