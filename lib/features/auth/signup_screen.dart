import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_theme.dart';
import '../../models/enums.dart';
import '../../providers/auth_providers.dart';

class SignupScreen extends ConsumerStatefulWidget {
  const SignupScreen({super.key});

  @override
  ConsumerState<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends ConsumerState<SignupScreen> {
  final _fullName = TextEditingController();
  final _whatsapp = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  // Inscription = compte client (le role partenaire n'est plus propose).
  final UserRole _role = UserRole.client;
  bool _loading = false;
  bool _obscure = true;
  String? _error;

  @override
  void dispose() {
    _fullName.dispose();
    _whatsapp.dispose();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_fullName.text.trim().isEmpty || _email.text.trim().isEmpty) {
      setState(() => _error = 'Nom et email obligatoires.');
      return;
    }
    final waDigits = _whatsapp.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (waDigits.length < 8) {
      setState(() => _error =
          'Un numéro WhatsApp valide est obligatoire (indispensable pour le suivi de vos commandes).');
      return;
    }
    if (_password.text.length < 8) {
      setState(() =>
          _error = 'Le mot de passe doit faire au moins 8 caractères.');
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await ref.read(authServiceProvider).signUp(
            email: _email.text.trim(),
            password: _password.text,
            fullName: _fullName.text.trim(),
            whatsapp: _whatsapp.text.trim(),
            role: _role,
          );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Compte cree. Tu peux te connecter.')),
        );
        context.go('/login');
      }
    } catch (e) {
      setState(() => _error = 'Inscription impossible : $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Creer un compte')),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Inscription = compte client. Le role partenaire n'est plus
                  // propose (l'admin gere le sourcing pieces). _role reste client.
                  TextField(
                    controller: _fullName,
                    decoration: const InputDecoration(labelText: 'Nom complet'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _whatsapp,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(
                      labelText: 'Numéro WhatsApp *',
                      helperText: 'Obligatoire — utilisé pour le suivi de vos commandes',
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _email,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(labelText: 'Email'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _password,
                    obscureText: _obscure,
                    decoration: InputDecoration(
                      labelText: 'Mot de passe (min. 8 caractères)',
                      suffixIcon: IconButton(
                        tooltip: _obscure ? 'Afficher' : 'Masquer',
                        icon: Icon(_obscure
                            ? Icons.visibility
                            : Icons.visibility_off),
                        onPressed: () => setState(() => _obscure = !_obscure),
                      ),
                    ),
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
                        : const Text('Creer mon compte'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
