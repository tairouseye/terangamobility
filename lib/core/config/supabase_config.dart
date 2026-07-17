/// Configuration de connexion au projet Supabase dedie a Teranga Parts.
///
/// Projet : TerangaParts (organisation TerangaMobility), region eu-west-3.
///
/// La cle « publishable » est PUBLIQUE par conception : elle est embarquee dans
/// le bundle web de toute application Supabase. Ce sont les policies RLS qui
/// protegent les donnees — jamais le secret de cette cle.
/// Ne JAMAIS mettre ici la cle `service_role` (elle contourne la RLS).
///
/// Les valeurs peuvent etre surchargees au build :
///   flutter build web --dart-define=SUPABASE_URL=... \
///                     --dart-define=SUPABASE_PUBLISHABLE_KEY=...
class SupabaseConfig {
  const SupabaseConfig._();

  static const String url = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://dfjikxgklnvqgjlexurv.supabase.co',
  );

  /// Nouvelle generation de cle Supabase (remplace l'ancienne cle `anon` JWT).
  static const String publishableKey = String.fromEnvironment(
    'SUPABASE_PUBLISHABLE_KEY',
    defaultValue: 'sb_publishable_BA0xa93kWrMnZ_RTEGydSQ_IpcW88bz',
  );

  /// Buckets Storage (crees par la migration 0006).
  static const String bucketDocuments = 'documents'; // cartes grises
  static const String bucketParts = 'parts'; // photos de pieces
  static const String bucketContracts = 'contracts'; // factures & contrats vehicule

  static bool get isConfigured =>
      url.startsWith('https://') && publishableKey.isNotEmpty;
}
