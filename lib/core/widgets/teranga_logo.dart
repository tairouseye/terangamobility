import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Identite visuelle TerangaMobility — dessinee en vecteur (net a toute taille).
///
/// Concept : un engrenage (les pieces detachees) dont le cceur porte un
/// double chevron vers l'avant (l'acheminement Coree -> Senegal).
/// Palette « Bleu nuit & or » : bleu nuit / or / blanc.

/// Embleme nu (engrenage + chevron), sans fond.
class TerangaEmblem extends StatelessWidget {
  final double size;
  final Color gearColor;
  final Color chevronColor;
  const TerangaEmblem({
    super.key,
    this.size = 64,
    this.gearColor = AppColors.primary,
    this.chevronColor = AppColors.or,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _EmblemPainter(gearColor: gearColor, chevronColor: chevronColor),
      ),
    );
  }
}

/// Badge : tuile arrondie bleu nuit, engrenage blanc, chevron or.
/// Sert de logo d'application / splash.
class TerangaBadge extends StatelessWidget {
  final double size;
  const TerangaBadge({super.key, this.size = 96});

  @override
  Widget build(BuildContext context) {
    final radius = size * 0.24;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.primary, AppColors.primaryDark],
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryDark.withValues(alpha: 0.35),
            blurRadius: size * 0.12,
            offset: Offset(0, size * 0.05),
          ),
        ],
      ),
      child: Center(
        child: TerangaEmblem(
          size: size * 0.62,
          gearColor: Colors.white,
          chevronColor: AppColors.or,
        ),
      ),
    );
  }
}

/// Logotype texte : « Teranga Parts ».
class TerangaWordmark extends StatelessWidget {
  final double fontSize;
  final Color? color;
  final Color? accent;
  const TerangaWordmark({
    super.key,
    this.fontSize = 26,
    this.color,
    this.accent,
  });

  @override
  Widget build(BuildContext context) {
    final base = color ?? AppColors.anthracite;
    final acc = accent ?? AppColors.primary;
    return RichText(
      text: TextSpan(
        style: TextStyle(
          fontSize: fontSize,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.5,
          height: 1.0,
          color: base,
        ),
        children: [
          const TextSpan(text: 'Teranga'),
          TextSpan(text: 'Mobility', style: TextStyle(color: acc)),
        ],
      ),
    );
  }
}

/// Lockup vertical : badge + logotype + signature (pour accueil / splash).
class TerangaLockup extends StatelessWidget {
  final double badgeSize;
  final bool onDark;
  final bool showTagline;
  const TerangaLockup({
    super.key,
    this.badgeSize = 88,
    this.onDark = false,
    this.showTagline = true,
  });

  @override
  Widget build(BuildContext context) {
    final textColor = onDark ? Colors.white : AppColors.anthracite;
    final accent = onDark ? AppColors.or : AppColors.primary;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        onDark
            ? TerangaBadgeOnDark(size: badgeSize)
            : TerangaBadge(size: badgeSize),
        SizedBox(height: badgeSize * 0.22),
        TerangaWordmark(
          fontSize: badgeSize * 0.30,
          color: textColor,
          accent: accent,
        ),
        SizedBox(height: badgeSize * 0.07),
        Text(
          'PARTS & VÉHICULES',
          style: TextStyle(
            fontSize: badgeSize * 0.13,
            letterSpacing: 2.5,
            fontWeight: FontWeight.w700,
            color: onDark ? AppColors.or : AppColors.primary,
          ),
        ),
        if (showTagline) ...[
          SizedBox(height: badgeSize * 0.07),
          Text(
            'Pièces détachées & véhicules importés de Corée',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: badgeSize * 0.125,
              color: onDark ? Colors.white70 : AppColors.gris,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ],
    );
  }
}

/// Variante du badge posee sur fond bleu nuit : tuile blanche, engrenage
/// bleu nuit, chevron or.
class TerangaBadgeOnDark extends StatelessWidget {
  final double size;
  const TerangaBadgeOnDark({super.key, this.size = 96});

  @override
  Widget build(BuildContext context) {
    final radius = size * 0.24;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(radius),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.18),
            blurRadius: size * 0.12,
            offset: Offset(0, size * 0.05),
          ),
        ],
      ),
      child: Center(
        child: TerangaEmblem(
          size: size * 0.62,
          gearColor: AppColors.primary,
          chevronColor: AppColors.or,
        ),
      ),
    );
  }
}

class _EmblemPainter extends CustomPainter {
  final Color gearColor;
  final Color chevronColor;
  _EmblemPainter({required this.gearColor, required this.chevronColor});

  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);
    final outer = size.width * 0.5;
    final inner = outer * 0.80; // creux entre les dents
    final hole = outer * 0.52; // rayon interieur de l'anneau
    const teeth = 9;

    // --- Engrenage (anneau dente) ---
    final gear = Path();
    final steps = teeth * 4;
    for (var k = 0; k <= steps; k++) {
      final a = (k / steps) * 2 * math.pi - math.pi / 2;
      final r = (k % 4 < 2) ? outer : inner;
      final p = c + Offset(math.cos(a) * r, math.sin(a) * r);
      if (k == 0) {
        gear.moveTo(p.dx, p.dy);
      } else {
        gear.lineTo(p.dx, p.dy);
      }
    }
    gear.close();
    gear.addOval(Rect.fromCircle(center: c, radius: hole));
    gear.fillType = PathFillType.evenOdd;
    canvas.drawPath(gear, Paint()..color = gearColor);

    // --- Double chevron vers l'avant (dans le cceur) ---
    final stroke = size.width * 0.085;
    final chevPaint = Paint()
      ..color = chevronColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final h = hole * 0.52; // demi-hauteur du chevron
    final w = hole * 0.34; // largeur d'un chevron
    for (final dx in [-w * 0.62, w * 0.52]) {
      final path = Path()
        ..moveTo(c.dx + dx - w * 0.5, c.dy - h)
        ..lineTo(c.dx + dx + w * 0.5, c.dy)
        ..lineTo(c.dx + dx - w * 0.5, c.dy + h);
      canvas.drawPath(path, chevPaint);
    }
  }

  @override
  bool shouldRepaint(_EmblemPainter old) =>
      old.gearColor != gearColor || old.chevronColor != chevronColor;
}
