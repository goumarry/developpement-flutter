/// Calculs de pagination `limit` / `skip` / `total` — fonctions pures.
abstract final class Pagination {
  /// Taille d'une page du catalogue.
  static const int pageSize = 20;

  /// Reste-t-il des éléments à charger ? Faux dès que [loaded] atteint (ou
  /// dépasse, si le total a diminué entre deux appels) le [total] du serveur.
  static bool hasMore({required int loaded, required int total}) =>
      loaded < total;

  /// Nombre de pages nécessaires pour [total] éléments. `total == 0` -> 0.
  static int pageCount({required int total, required int limit}) {
    if (total <= 0 || limit <= 0) return 0;
    return (total + limit - 1) ~/ limit;
  }

  /// Nombre d'éléments attendus à partir du décalage [skip] : `limit` pour une
  /// page pleine, le reliquat pour la dernière page partielle, 0 hors bornes
  /// (`skip` négatif ou au-delà du total) ou si le total est nul.
  static int itemsOnPage({
    required int skip,
    required int total,
    required int limit,
  }) {
    if (limit <= 0 || skip < 0 || skip >= total) return 0;
    final left = total - skip;
    return left < limit ? left : limit;
  }
}
