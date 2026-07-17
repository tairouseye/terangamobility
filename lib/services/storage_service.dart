import 'dart:typed_data';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/config/supabase_config.dart';

/// Upload de fichiers (cartes grises, photos de pieces) vers Supabase Storage.
/// Travaille en bytes pour rester compatible mobile ET web.
class StorageService {
  final SupabaseClient _client;
  StorageService(this._client);

  /// Upload une carte grise ; retourne une URL signee.
  Future<String> uploadCarteGrise(String userId, Uint8List bytes,
      {String ext = 'jpg'}) {
    final path = '$userId/${DateTime.now().millisecondsSinceEpoch}.$ext';
    return _upload(SupabaseConfig.bucketDocuments, path, bytes);
  }

  /// Upload une photo de piece (demande ou proposition partenaire).
  Future<String> uploadPartPhoto(String ownerId, Uint8List bytes,
      {String ext = 'jpg'}) {
    final path = '$ownerId/${DateTime.now().millisecondsSinceEpoch}.$ext';
    return _upload(SupabaseConfig.bucketParts, path, bytes);
  }

  Future<String> _upload(String bucket, String path, Uint8List bytes) async {
    await _client.storage.from(bucket).uploadBinary(
          path,
          bytes,
          fileOptions: const FileOptions(upsert: true),
        );
    // URL signee valable 7 jours (buckets prives).
    return _client.storage.from(bucket).createSignedUrl(path, 60 * 60 * 24 * 7);
  }
}
