import '../models/catalog_snapshot.dart';

/// Copie locale du dernier catalogue chargé (mode dégradé hors connexion).
abstract class CatalogCache {
  /// `null` si rien n'a encore été enregistré, ou si le contenu est illisible.
  Future<CatalogSnapshot?> read();

  Future<void> write(CatalogSnapshot snapshot);
}
