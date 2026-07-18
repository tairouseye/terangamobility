import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/app_user.dart';
import '../services/auth_service.dart';
import '../services/storage_service.dart';

/// Client Supabase global (initialise dans main.dart).
final supabaseClientProvider = Provider<SupabaseClient>((ref) {
  return Supabase.instance.client;
});

final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService(ref.watch(supabaseClientProvider));
});

final storageServiceProvider = Provider<StorageService>((ref) {
  return StorageService(ref.watch(supabaseClientProvider));
});

/// Flux d'etat d'authentification (login / logout).
final authStateProvider = StreamProvider<AuthState>((ref) {
  return ref.watch(authServiceProvider).onAuthChange;
});

/// Vrai quand l'utilisateur arrive via un lien de recuperation de mot de passe
/// (evenement passwordRecovery) : le routeur force alors l'ecran « nouveau
/// mot de passe ».
final passwordRecoveryProvider = StateProvider<bool>((ref) => false);

/// Profil de l'utilisateur courant (null si deconnecte).
/// Recharge automatiquement a chaque changement d'auth.
final currentProfileProvider = FutureProvider<AppUser?>((ref) async {
  // Redeclenche la lecture quand l'etat d'auth change.
  ref.watch(authStateProvider);
  final auth = ref.watch(authServiceProvider);
  if (auth.currentUser == null) return null;
  return auth.fetchProfile();
});
