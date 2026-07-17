import 'enums.dart';

/// Profil utilisateur (table `profiles`, id = auth.uid).
class AppUser {
  final String id;
  final String fullName;
  final String whatsapp;
  final UserRole role;
  final DateTime? createdAt;

  const AppUser({
    required this.id,
    required this.fullName,
    required this.whatsapp,
    required this.role,
    this.createdAt,
  });

  factory AppUser.fromJson(Map<String, dynamic> j) => AppUser(
        id: j['id'] as String,
        fullName: (j['full_name'] ?? '') as String,
        whatsapp: (j['whatsapp'] ?? '') as String,
        role: UserRole.fromDb(j['role'] as String?),
        createdAt: j['created_at'] != null
            ? DateTime.tryParse(j['created_at'] as String)
            : null,
      );

  Map<String, dynamic> toInsert() => {
        'id': id,
        'full_name': fullName,
        'whatsapp': whatsapp,
        'role': role.dbValue,
      };
}
