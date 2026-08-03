import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/teranga_logo.dart';
import '../shared/app_footer.dart';

/// Ecran de chargement pendant la resolution de l'auth/profil.
class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TerangaLogo(width: 280),
            SizedBox(height: 36),
            SizedBox(
              width: 26,
              height: 26,
              child: CircularProgressIndicator(
                  color: AppColors.primary, strokeWidth: 2.5),
            ),
          ],
        ),
      ),
      bottomNavigationBar: const AppFooter(),
    );
  }
}
