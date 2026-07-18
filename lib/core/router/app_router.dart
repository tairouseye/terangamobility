import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../models/enums.dart';
import '../../providers/auth_providers.dart';
import '../../features/auth/login_screen.dart';
import '../../features/auth/reset_password_screen.dart';
import '../../features/auth/signup_screen.dart';
import '../../features/auth/splash_screen.dart';
import '../../features/client/client_dashboard.dart';
import '../../features/partner_kr/partner_dashboard.dart';
import '../../features/admin/admin_dashboard.dart';
import '../../features/vehicles_kr/catalog_screen.dart';

/// Chemins accessibles SANS compte.
/// Le catalogue vehicules est volontairement public (vitrine commerciale) :
/// il ne contient ni prix ni donnee personnelle. Le compte n'est exige qu'au
/// moment de « Demander le prix ».
bool _isPublic(String loc) =>
    loc == '/login' || loc == '/signup' || loc.startsWith('/vehicules');

/// Routeur global avec redirection selon l'etat d'auth et le role.
final routerProvider = Provider<GoRouter>((ref) {
  final refresh = _AuthRefresh(ref);

  return GoRouter(
    initialLocation: '/',
    refreshListenable: refresh,
    routes: [
      GoRoute(path: '/', builder: (_, _) => const SplashScreen()),
      GoRoute(path: '/login', builder: (_, _) => const LoginScreen()),
      GoRoute(path: '/signup', builder: (_, _) => const SignupScreen()),
      GoRoute(
          path: '/reset-password',
          builder: (_, _) => const ResetPasswordScreen()),
      // Catalogue public (visiteurs anonymes bienvenus).
      GoRoute(
          path: '/vehicules', builder: (_, _) => const VehicleCatalogScreen()),
      GoRoute(path: '/client', builder: (_, _) => const ClientDashboard()),
      GoRoute(path: '/partner', builder: (_, _) => const PartnerDashboard()),
      GoRoute(path: '/admin', builder: (_, _) => const AdminDashboard()),
    ],
    redirect: (context, state) {
      final authState = ref.read(authStateProvider);
      final loc = state.matchedLocation;

      // Recuperation de mot de passe : on force l'ecran dedie.
      if (ref.read(passwordRecoveryProvider)) {
        return loc == '/reset-password' ? null : '/reset-password';
      }

      // Auth en cours de resolution -> on reste sur le splash.
      if (authState.isLoading) return loc == '/' ? null : '/';

      final session = ref.read(authServiceProvider).currentSession;
      final onAuthPage = loc == '/login' || loc == '/signup';

      // Non connecte : login/signup + catalogue public.
      if (session == null) {
        return _isPublic(loc) ? null : '/login';
      }

      // Connecte : on attend le profil pour connaitre le role.
      final profile = ref.read(currentProfileProvider).value;
      if (profile == null) return loc == '/' ? null : '/';

      final home = switch (profile.role) {
        UserRole.client => '/client',
        UserRole.partnerKr => '/partner',
        UserRole.admin => '/admin',
      };

      // Sur splash/auth -> renvoie vers le dashboard du role.
      if (loc == '/' || onAuthPage) return home;
      return null;
    },
  );
});

/// Rafraichit go_router quand l'auth ou le profil change.
class _AuthRefresh extends ChangeNotifier {
  _AuthRefresh(Ref ref) {
    ref.listen(authStateProvider, (_, next) {
      // Lien de recuperation ouvert -> bascule vers l'ecran nouveau mot de passe.
      if (next.valueOrNull?.event == AuthChangeEvent.passwordRecovery) {
        ref.read(passwordRecoveryProvider.notifier).state = true;
      }
      notifyListeners();
    });
    ref.listen(currentProfileProvider, (_, _) => notifyListeners());
  }
}
