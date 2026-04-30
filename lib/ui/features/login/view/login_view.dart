import 'package:flutter/material.dart';
import '../../registrazione/view/registrazione_view.dart';
import '../view_model/login_view_model.dart';

class LoginView extends StatefulWidget {
  const LoginView({super.key});

  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
  //Istanzia il ViewModel e i Controller
  final LoginViewModel _viewModel = LoginViewModel();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    // Importante: pulisce i controller per evitare memory leak
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ListenableBuilder(
      listenable: _viewModel,
      builder: (context, _) {
        return Scaffold(
          backgroundColor: Colors.white,
          body: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(
              horizontal: 30.0,
              vertical: 60.0,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 50),
                Image.asset(
                  "assets/images/logo_decorated.png",
                  width: 250,
                  height: 250,
                ),

                //MESSAGGIO DI ERRORE
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

                //CAMPI DI INPUT
                _buildTextField(
                  label: "Email",
                  icon: Icons.email_outlined,
                  obscure: false,
                  controller: _emailController,
                ),
                const SizedBox(height: 20),
                _buildTextField(
                  label: "Password",
                  icon: Icons.lock_outline,
                  obscure: true,
                  controller: _passwordController,
                ),

                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () {
                      /* Logica recupero password */
                    },
                    child: Text(
                      "Password dimenticata?",
                      style: TextStyle(
                        color: theme.colorScheme.primary,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 30),

                //BOTTONE LOGIN CON LOGICA INTEGRATA
                SizedBox(
                  width: double.infinity,
                  height: 55,
                  child: ElevatedButton(
                    onPressed: _viewModel.isLoading
                        ? null // Disabilita il tasto durante il caricamento
                        : () async {
                            // Chiamata al ViewModel
                            await _viewModel.accedi(
                              _emailController.text.trim(),
                              _passwordController.text.trim(),
                            );
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.colorScheme.primary,
                      shape: const StadiumBorder(),
                      elevation: 0,
                    ),
                    child: _viewModel.isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text(
                            "Accedi",
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                  ),
                ),

                const SizedBox(height: 40),

                // 5. COLLEGAMENTO ALLA REGISTRAZIONE
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text("Nuovo qui?"),
                    TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const RegistrazioneView(),
                          ),
                        );
                      },
                      child: Text(
                        "Inizia il tuo viaggio",
                        style: TextStyle(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // HELPER
  Widget _buildTextField({
    required String label,
    required IconData icon,
    required bool obscure,
    required TextEditingController controller,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      decoration: InputDecoration(
        prefixIcon: Icon(icon, size: 20),
        labelText: label,
        filled: true,
        fillColor: Colors.grey.shade50,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: BorderSide.none,
        ),
        floatingLabelStyle: const TextStyle(color: Colors.grey),
      ),
    );
  }
}
