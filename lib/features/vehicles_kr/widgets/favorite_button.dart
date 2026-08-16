import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../providers/auth_providers.dart';
import '../../../providers/favorites_providers.dart';

/// Bouton « J'aime » (coeur) reutilisable sur toutes les fiches vehicule.
/// - colore selon l'etat (aime / pas aime) pour l'utilisateur courant ;
/// - bascule le favori et rafraichit les vues qui en dependent ;
/// - invite a se connecter si l'utilisateur est anonyme.
class FavoriteButton extends ConsumerWidget {
  final String reference;
  final double size;

  /// Style « pastille » (coeur blanc sur fond sombre) pour poser le bouton
  /// par-dessus une photo.
  final bool onPhoto;

  const FavoriteButton({
    super.key,
    required this.reference,
    this.size = 22,
    this.onPhoto = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final liked =
        ref.watch(favoriteRefsProvider).valueOrNull?.contains(reference) ??
            false;

    Future<void> toggle() async {
      final loggedIn = ref.read(authServiceProvider).currentUser != null;
      if (!loggedIn) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Connectez-vous pour enregistrer vos favoris.')));
        return;
      }
      try {
        await ref.read(favoritesServiceProvider).toggle(reference, liked);
      } catch (_) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Action impossible.')));
        }
      }
      ref.invalidate(favoriteRefsProvider);
      ref.invalidate(favoriteVehiclesProvider);
    }

    final button = IconButton(
      tooltip: liked ? 'Retirer des favoris' : 'J\'aime',
      visualDensity: VisualDensity.compact,
      icon: Icon(
        liked ? Icons.favorite : Icons.favorite_border,
        size: size,
        color: liked
            ? AppColors.danger
            : (onPhoto ? Colors.white : AppColors.gris),
      ),
      onPressed: toggle,
    );

    if (onPhoto) {
      return Material(
        color: Colors.black.withValues(alpha: 0.38),
        shape: const CircleBorder(),
        child: button,
      );
    }
    return button;
  }
}
