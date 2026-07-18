import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_theme.dart';
import '../../core/widgets/teranga_logo.dart';
import '../../providers/auth_providers.dart';

/// Ecran atteint via le lien de recuperation : l'utilisateur choisit un
/// nouveau mot de passe (session de recuperation active).
class ResetPasswordScreen extends ConsumerStatefulWidget {
  const ResetPasswordScreen({super.key});

  @override
  ConsumerState<ResetPasswordScreen> createState() =>
      _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends ConsumerState<ResetPasswordScreen> {
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  bool _obscure = true;
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final pwd = _password.text;
    if (pwd.length < 6) {
      setState(() => _error = 'Le mot de passe doit faire au moins 6 caractères.');
      return;
    }
    if (pwd != _confirm.text) {
      setState(() => _error = 'Les deux mots de passe ne correspondent pas.');
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final auth = ref.read(authServiceProvider);
      await auth.updatePassword(pwd);
      // Fin de la recuperation : on nettoie l'etat et on renvoie au login.
      ref.read(passwordRecoveryProvider.notifier).state = false;
      await auth.signOut();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text(
                'Mot de passe mis à jour. Connectez-vous avec le nouveau.')));
        context.go('/login');
      }
    } catch (e) {
      setState(() => _error = 'Échec de la mise à jour : $e');
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
                  const Center(child: TerangaLockup(badgeSize: 84)),
                  const SizedBox(height: 28),
                  const Text('Nouveau mot de passe',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          fontSize: 18, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 4),
                  const Text('Choisissez un nouveau mot de passe pour votre compte.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 13, color: AppColors.gris)),
                  const SizedBox(height: 24),
                  TextField(
                    controller: _password,
                    obscureText: _obscure,
                    decoration: InputDecoration(
                      labelText: 'Nouveau mot de passe',
                      suffixIcon: IconButton(
                        icon: Icon(_obscure
                            ? Icons.visibility
                            : Icons.visibility_off),
                        onPressed: () => setState(() => _obscure = !_obscure),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _confirm,
                    obscureText: _obscure,
                    decoration: const InputDecoration(
                        labelText: 'Confirmer le mot de passe'),
                    onSubmitted: (_) => _submit(),
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: 12),
                    Text(_error!,
                        style: const TextStyle(color: AppColors.primary)),
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
                        : const Text('Enregistrer'),
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: () {
                      ref.read(passwordRecoveryProvider.notifier).state = false;
                      context.go('/login');
                    },
                    child: const Text('Annuler'),
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
