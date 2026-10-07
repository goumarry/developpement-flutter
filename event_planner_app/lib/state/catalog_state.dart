import 'package:flutter/foundation.dart';

import '../domain/failures.dart';
import '../domain/models/app_preferences.dart';
import '../domain/models/catalog_snapshot.dart';
import '../domain/models/event.dart';
import '../domain/repositories/catalog_cache.dart';
import '../domain/repositories/event_repository.dart';
import '../domain/rules/pagination.dart';

/// Les quatre rendus possibles du corps du catalogue.
enum CatalogStatus {
  /// Premier chargement d'une liste (aucun élément à montrer).
  loading,
  loaded,

  /// Réponse réussie mais vide (recherche sans résultat) : pas une erreur.
  empty,

  /// Échec, et aucune copie locale à montrer à la place.
  error,
}

/// État du catalogue : pagination, recherche, tri et mode dégradé.
///
/// N'importe que `foundation.dart` (pour [ChangeNotifier]) et le domaine :
/// ni `material.dart`, ni `data/`. Les dépôts arrivent par le constructeur
/// sous forme d'interfaces, ce qui permet de tester cette classe avec des
/// doubles, sans réseau ni disque.
class CatalogState extends ChangeNotifier {
  CatalogState({
    required this._repository,
    required this._cache,
    EventSort initialSort = EventSort.date,
    this._clock = DateTime.now,
  }) : _sort = initialSort;

  final EventRepository _repository;
  final CatalogCache _cache;
  final DateTime Function() _clock;

  CatalogStatus _status = CatalogStatus.loading;
  List<Event> _loaded = const []; // dans l'ordre du serveur
  List<Event> _sorted = const []; // vue triée exposée aux écrans
  int _total = 0;
  String _query = '';
  EventSort _sort;
  String? _errorMessage;
  bool _isLoadingMore = false;
  String? _loadMoreError;
  DateTime? _staleSince;

  /// Numéro de la dernière recherche lancée. Une réponse qui arrive après
  /// qu'une recherche plus récente a démarré est ignorée (sinon une réponse
  /// lente pourrait écraser les résultats de la recherche suivante).
  int _requestId = 0;

  CatalogStatus get status => _status;

  /// Événements chargés, triés selon [sort]. Liste non modifiable.
  List<Event> get events => _sorted;
  int get total => _total;
  String get query => _query;
  EventSort get sort => _sort;

  /// Message de l'échec plein écran ([CatalogStatus.error]) ou de l'échec qui
  /// a déclenché le mode dégradé.
  String? get errorMessage => _errorMessage;

  bool get isLoadingMore => _isLoadingMore;

  /// Échec du chargement d'une page **suivante** : les pages déjà affichées
  /// restent en place, seul le pied de liste signale l'erreur.
  String? get loadMoreError => _loadMoreError;

  /// Mode dégradé : les données viennent de la copie locale.
  bool get isStale => _staleSince != null;

  /// Date de la dernière réponse réussie du serveur, en mode dégradé.
  DateTime? get staleSince => _staleSince;

  /// Reste-t-il des pages à demander ? Jamais en mode dégradé : la copie
  /// locale est figée.
  bool get hasMore =>
      !isStale && Pagination.hasMore(loaded: _loaded.length, total: _total);

  /// Taille de la prochaine page (la dernière peut être partielle).
  int get nextPageSize => Pagination.itemsOnPage(
    skip: _loaded.length,
    total: _total,
    limit: Pagination.pageSize,
  );

  int get pageCount =>
      Pagination.pageCount(total: _total, limit: Pagination.pageSize);

  /// Charge la première page pour [query] (recherche vide = tout le catalogue).
  Future<void> loadFirstPage({String query = ''}) async {
    final request = ++_requestId;
    _query = query.trim();
    _status = CatalogStatus.loading;
    _isLoadingMore = false;
    _loadMoreError = null;
    notifyListeners();

    try {
      final page = await _repository.fetchEvents(
        limit: Pagination.pageSize,
        skip: 0,
        query: _query.isEmpty ? null : _query,
      );
      if (request != _requestId) return;
      _staleSince = null;
      _errorMessage = null;
      _setLoaded(page.events, total: page.total);
    } on AppFailure catch (failure) {
      final snapshot = await _cache.read();
      if (request != _requestId) return;
      _errorMessage = failure.message;
      if (snapshot == null) {
        _setLoaded(const [], total: 0);
        _status = CatalogStatus.error;
      } else {
        // Mode dégradé : la recherche s'applique localement à la copie.
        final matches = _query.isEmpty
            ? snapshot.events
            : [
                for (final event in snapshot.events)
                  if (event.title.toLowerCase().contains(_query.toLowerCase()))
                    event,
              ];
        _staleSince = snapshot.savedAt;
        _setLoaded(matches, total: matches.length);
      }
    }
    notifyListeners();
    await _saveSnapshot();
  }

  /// Relance la recherche courante (bouton « Réessayer », tirer pour
  /// rafraîchir, retour du réseau).
  Future<void> refresh() => loadFirstPage(query: _query);

  /// Charge la page suivante. Sans effet si un chargement est déjà en cours
  /// ou s'il n'y a plus rien à charger.
  Future<void> loadMore() async {
    if (_isLoadingMore || !hasMore || _status != CatalogStatus.loaded) return;
    final request = _requestId;
    _isLoadingMore = true;
    _loadMoreError = null;
    notifyListeners();

    try {
      final page = await _repository.fetchEvents(
        limit: Pagination.pageSize,
        skip: _loaded.length,
        query: _query.isEmpty ? null : _query,
      );
      if (request != _requestId) return;
      // Une page vide alors qu'on en attendait une : le total a changé côté
      // serveur. On s'aligne sur ce qui est chargé pour arrêter de paginer.
      _setLoaded([
        ..._loaded,
        ...page.events,
      ], total: page.events.isEmpty ? _loaded.length : page.total);
    } on AppFailure catch (failure) {
      if (request != _requestId) return;
      _loadMoreError = failure.message;
    }
    _isLoadingMore = false;
    notifyListeners();
    await _saveSnapshot();
  }

  void setSort(EventSort sort) {
    if (sort == _sort) return;
    _sort = sort;
    _sorted = _sortedCopy(_loaded);
    notifyListeners();
  }

  /// Recharge un événement par son identifiant (écran de détail). Lève une
  /// `AppFailure` : l'écran de détail décide quoi afficher.
  Future<Event> fetchEvent(String id) => _repository.fetchEventById(id);

  void _setLoaded(List<Event> events, {required int total}) {
    _loaded = events;
    _total = total;
    _sorted = _sortedCopy(events);
    _status = events.isEmpty ? CatalogStatus.empty : CatalogStatus.loaded;
  }

  List<Event> _sortedCopy(List<Event> source) {
    final copy = [...source];
    switch (_sort) {
      case EventSort.date:
        copy.sort((a, b) => a.start.compareTo(b.start));
      case EventSort.title:
        copy.sort(
          (a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()),
        );
      case EventSort.remainingSeats:
        copy.sort((a, b) => b.remainingSeats.compareTo(a.remainingSeats));
    }
    return List.unmodifiable(copy);
  }

  /// Conserve le catalogue **complet** (recherche vide) fraîchement chargé.
  /// Un disque plein ou illisible ne doit pas casser le catalogue : l'échec
  /// d'écriture est ignoré, le mode dégradé sera simplement indisponible.
  Future<void> _saveSnapshot() async {
    if (isStale || _query.isNotEmpty || _loaded.isEmpty) return;
    try {
      await _cache.write(
        CatalogSnapshot(events: _loaded, total: _total, savedAt: _clock()),
      );
    } on Exception {
      // Voir le commentaire de la méthode.
    }
  }
}
