import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/parts_request.dart';
import '../services/request_service.dart';
import 'auth_providers.dart';

final requestServiceProvider = Provider<RequestService>((ref) {
  return RequestService(ref.watch(supabaseClientProvider));
});

/// Demandes de pieces de l'utilisateur connecte.
final myRequestsProvider = FutureProvider<List<PartsRequest>>((ref) async {
  final uid = ref.watch(authServiceProvider).currentUser?.id;
  if (uid == null) return [];
  return ref.watch(requestServiceProvider).listForClient(uid);
});
