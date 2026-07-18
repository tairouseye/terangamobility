import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/app_user.dart';
import '../models/enums.dart';

/// Acces centralise a Supabase Auth + profil.
class AuthService {
  final SupabaseClient _client;
  AuthService(this._client);

  SupabaseClient get client => _client;
  Session? get currentSession => _client.auth.currentSession;
  User? get currentUser => _client.auth.currentUser;

  Stream<AuthState> get onAuthChange => _client.auth.onAuthStateChange;

  /// Inscription. Le profil est cree cote serveur par le trigger
  /// handle_new_user() a partir des metadata.
  Future<void> signUp({
    required String email,
    required String password,
    required String fullName,
    required String whatsapp,
    UserRole role = UserRole.client,
  }) async {
    await _client.auth.signUp(
      email: email,
      password: password,
      data: {
        'full_name': fullName,
        'whatsapp': whatsapp,
        'role': role.dbValue,
      },
    );
  }

  Future<void> signIn({required String email, required String password}) {
    return _client.auth.signInWithPassword(email: email, password: password);
  }

  Future<void> signOut() => _client.auth.signOut();

  /// Envoie un email de reinitialisation du mot de passe.
  /// [redirectTo] : URL de retour dans l'app (ou le lien de recuperation ouvre
  /// l'ecran « nouveau mot de passe »).
  Future<void> sendPasswordReset(String email, {String? redirectTo}) {
    return _client.auth.resetPasswordForEmail(email, redirectTo: redirectTo);
  }

  /// Definit un nouveau mot de passe (session de recuperation active).
  Future<void> updatePassword(String newPassword) {
    return _client.auth.updateUser(UserAttributes(password: newPassword));
  }

  /// Recupere le profil (dont le role) de l'utilisateur connecte.
  Future<AppUser?> fetchProfile() async {
    final uid = currentUser?.id;
    if (uid == null) return null;
    final data =
        await _client.from('profiles').select().eq('id', uid).maybeSingle();
    if (data == null) return null;
    return AppUser.fromJson(data);
  }
}
