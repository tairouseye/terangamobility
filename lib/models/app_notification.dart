import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';

/// Notification (table `notifications`), pour le client ou l'admin.
class AppNotification {
  final String id;
  final String? userId;
  final String? targetRole;
  final String title;
  final String? body;
  final String? type; // vehicle_request / quote / payment / tracking...
  final String? relatedId;
  final bool isRead;
  final DateTime? createdAt;

  const AppNotification({
    required this.id,
    this.userId,
    this.targetRole,
    required this.title,
    this.body,
    this.type,
    this.relatedId,
    this.isRead = false,
    this.createdAt,
  });

  factory AppNotification.fromJson(Map<String, dynamic> j) => AppNotification(
        id: j['id'] as String,
        userId: j['user_id'] as String?,
        targetRole: j['target_role'] as String?,
        title: (j['title'] ?? '') as String,
        body: j['body'] as String?,
        type: j['type'] as String?,
        relatedId: j['related_id'] as String?,
        isRead: (j['is_read'] ?? false) as bool,
        createdAt: j['created_at'] != null
            ? DateTime.tryParse(j['created_at'] as String)
            : null,
      );

  IconData get icon => switch (type) {
        'quote' => Icons.receipt_long,
        'payment' => Icons.payments,
        'tracking' => Icons.local_shipping,
        'vehicle_request' => Icons.directions_car,
        _ => Icons.notifications,
      };

  Color get color => switch (type) {
        'payment' => AppColors.vert,
        'quote' => AppColors.primary,
        'tracking' => AppColors.ambre,
        _ => AppColors.gris,
      };
}
