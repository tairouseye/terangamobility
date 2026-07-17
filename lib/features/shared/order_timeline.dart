import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../models/enums.dart';

/// Timeline verticale des 13 statuts du workflow commande.
/// Les etapes atteintes sont vertes, l'etape courante est mise en avant,
/// les etapes a venir sont grisees.
class OrderTimeline extends StatelessWidget {
  final OrderStatus current;
  const OrderTimeline({super.key, required this.current});

  @override
  Widget build(BuildContext context) {
    final statuses = OrderStatus.values;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: List.generate(statuses.length, (i) {
        final s = statuses[i];
        final reached = s.index <= current.index;
        final isCurrent = s.index == current.index;
        final isLast = i == statuses.length - 1;
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
                        color: isCurrent ? AppColors.primary : Colors.transparent,
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
                padding: EdgeInsets.only(bottom: isLast ? 0 : 18, top: 1),
                child: Text(
                  s.label,
                  style: TextStyle(
                    fontWeight:
                        isCurrent ? FontWeight.w700 : FontWeight.w400,
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
