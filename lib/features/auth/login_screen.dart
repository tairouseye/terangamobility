import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_theme.dart';
import '../../core/widgets/teranga_logo.dart';
import '../../providers/auth_providers.dart';
import '../shared/gespro_credit.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await ref.read(authServiceProvider).signIn(
            email: _email.text.trim(),
            password: _password.text,
          );
      // La redirection est geree par le routeur (refresh sur authState).
    } catch (e) {
      setState(() => _error = 'Connexion impossible. Verifie tes identifiants.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 28),
                  const Center(child: TerangaLockup(badgeSize: 92)),
                  const SizedBox(height: 36),
                  TextField(
                    controller: _email,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(labelText: 'Email'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _password,
                    obscureText: true,
                    decoration: const InputDecoration(labelText: 'Mot de passe'),
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: 12),
                    Text(_error!, style: const TextStyle(color: AppColors.primary)),
                  ],
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: _loading ? null : _submit,
                    child: _loading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 2))
                        : const Text('Se connecter'),
                  ),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: () => context.push('/signup'),
                    child: const Text('Creer un compte'),
                  ),
                  const SizedBox(height: 8),
                  const Row(children: [
                    Expanded(child: Divider()),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 12),
                      child: Text('ou', style: TextStyle(color: AppColors.gris)),
                    ),
                    Expanded(child: Divider()),
                  ]),
                  const SizedBox(height: 8),
                  // Vitrine : on peut parcourir le catalogue sans compte.
                  OutlinedButton.icon(
                    onPressed: () => context.push('/vehicules'),
                    icon: const Icon(Icons.directions_car_filled, size: 18),
                    label: const Text('Voir les vehicules de Coree'),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(50),
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Consultation libre — un compte n\'est necessaire que pour '
                    'demander un prix.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 11.5, color: AppColors.gris),
                  ),
                  const SizedBox(height: 28),
                  const Divider(),
                  const SizedBox(height: 16),
                  // Bloc editeur + assistance + version, en bas de l'accueil.
                  const GesProCredit(),
                  const SizedBox(height: 12),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
