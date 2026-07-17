import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../models/vehicle_enums.dart';

/// Timeline verticale des étapes de la commande véhicule (import maritime).
class VehicleTimeline extends StatelessWidget {
  final VehicleOrderStatus current;
  const VehicleTimeline({super.key, required this.current});

  @override
  Widget build(BuildContext context) {
    final steps = VehicleOrderStatus.values;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: List.generate(steps.length, (i) {
        final s = steps[i];
        final reached = s.index <= current.index;
        final isCurrent = s.index == current.index;
        final isLast = i == steps.length - 1;
        return IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                children: [
                  Container(
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: reached ? AppColors.vert : AppColors.grisClair,
                      border: Border.all(
                        color:
                            isCurrent ? AppColors.primary : Colors.transparent,
                        width: 2,
                      ),
                    ),
                    child: reached
                        ? const Icon(Icons.check, size: 14, color: Colors.white)
                        : null,
                  ),
                  if (!isLast)
                    Expanded(
                      child: Container(
                        width: 2,
                        color: s.index < current.index
                            ? AppColors.vert
                            : AppColors.grisClair,
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 12),
              Padding(
                padding: EdgeInsets.only(bottom: isLast ? 0 : 16, top: 1),
                child: Text(
                  s.label,
                  style: TextStyle(
                    fontWeight: isCurrent ? FontWeight.w700 : FontWeight.w400,
                    color: reached ? AppColors.anthracite : AppColors.gris,
                  ),
                ),
              ),
            ],
          ),
        );
      }),
    );
  }
}

/// Petite pastille de statut véhicule (couleur selon l'étape).
class VehicleStatusBadge extends StatelessWidget {
  final VehicleOrderStatus status;
  const VehicleStatusBadge(this.status, {super.key});

  @override
  Widget build(BuildContext context) {
    final c = status.color;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: c.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: c.withValues(alpha: 0.4)),
      ),
      child: Text(
        '${status.step}. ${status.label}',
        style: TextStyle(color: c, fontSize: 12, fontWeight: FontWeight.w600),
      ),
    );
  }
}
