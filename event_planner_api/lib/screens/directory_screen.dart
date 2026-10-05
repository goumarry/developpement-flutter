import 'package:flutter/material.dart';

import '../api/exceptions.dart';
import '../api/users_api.dart';
import '../models/participant.dart';
import '../models/users_page.dart';
import '../widgets/participant_tile.dart';
import '../widgets/status_views.dart';
import 'add_participant_screen.dart';
import 'participant_detail_screen.dart';

/// Mots-clés prédéfinis en complément de la barre de recherche (TP : "un
/// champ de saisie minimal **ou** des boutons de mots-clés prédéfinis
/// suffisent, sans validation de formulaire" — un simple [TextField], sans
/// [Form]/[TextFormField] ni validateur, reste autorisé).
const _keywords = ['Emily', 'Michael', 'Sophia', 'James', 'Olivia'];

const _pageSize = 20;

class DirectoryScreen extends StatefulWidget {
  const DirectoryScreen({super.key});

  @override
  State<DirectoryScreen> createState() => _DirectoryScreenState();
}

class _DirectoryScreenState extends State<DirectoryScreen> {
  // Partie C : une unique instance de http.Client (ici via UsersApi),
  // réutilisée pour toutes les requêtes de cet écran, fermée dans dispose().
  final UsersApi _api = UsersApi();
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();

  // Partie C, "piège du FutureBuilder recréé à chaque build" : ce Future est
  // créé une seule fois par intention utilisateur (premier affichage,
  // recherche, tirage vers le bas) et mémorisé ici — jamais recréé dans
  // build(). Voir README pour la démonstration avant/après.
  late Future<UsersPage> _firstPage;

  final List<Participant> _items = [];
  int _total = 0;
  String? _activeKeyword;
  bool _loadingMore = false;
  String? _loadMoreErrorMessage;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _firstPage = _loadFirstPage();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    _api.close();
    super.dispose();
  }

  // --- Chargement de la première page (normal, recherche, ou démo) --------

  Future<UsersPage> _loadFirstPage({
    int? forcedDelayMs,
    bool forceServerError = false,
  }) {
    final future = forceServerError
        ? _api.triggerForcedServerError()
        : (_activeKeyword == null
            ? _api.fetchUsers(limit: _pageSize, skip: 0, delayMs: forcedDelayMs)
            : _api.searchUsers(_activeKeyword!, limit: _pageSize));
    // Effet de bord enregistré une seule fois à la création du Future — pas
    // pendant build() — pour alimenter la liste mutable affichée par la
    // ListView. Le FutureBuilder observe le même Future indépendamment et
    // affiche toujours correctement sa propre branche d'erreur.
    future.then(_applyFirstPage, onError: (_) {});
    return future;
  }

  void _applyFirstPage(UsersPage page) {
    if (!mounted) return;
    setState(() {
      _items
        ..clear()
        ..addAll(page.participants);
      _total = page.total;
    });
  }

  void _selectKeyword(String? keyword) {
    _searchController.text = keyword ?? '';
    setState(() {
      _activeKeyword = keyword;
      _items.clear();
      _total = 0;
      _loadMoreErrorMessage = null;
      _firstPage = _loadFirstPage();
    });
  }

  /// Soumission de la barre de recherche (champ de saisie minimal, sans
  /// `Form`/validation — cf. remarque en tête de fichier).
  void _submitSearch(String value) {
    final trimmed = value.trim();
    _selectKeyword(trimmed.isEmpty ? null : trimmed);
  }

  Future<void> _onRefresh() async {
    setState(() {
      _items.clear();
      _total = 0;
      _loadMoreErrorMessage = null;
      _firstPage = _loadFirstPage(); // repart bien de skip = 0
    });
    try {
      await _firstPage;
    } catch (_) {
      // L'erreur est déjà affichée par la branche hasError du FutureBuilder.
    }
  }

  // --- Pagination au défilement --------------------------------------------

  void _onScroll() {
    if (_activeKeyword != null) return; // la recherche n'est pas paginée
    if (_loadingMore) return;
    if (_items.length >= _total) return;
    if (!_scrollController.hasClients) return;
    final position = _scrollController.position;
    const anticipation = 600.0; // ~3 tuiles avant le bas visible
    if (position.pixels >= position.maxScrollExtent - anticipation) {
      _loadNextPage();
    }
  }

  Future<void> _loadNextPage() async {
    setState(() {
      _loadingMore = true;
      _loadMoreErrorMessage = null;
    });
    try {
      final page = await _api.fetchUsers(limit: _pageSize, skip: _items.length);
      if (!mounted) return;
      setState(() {
        _items.addAll(page.participants);
        _total = page.total;
        _loadingMore = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _loadingMore = false;
        _loadMoreErrorMessage = e.message;
      });
    }
  }

  // --- Navigation -----------------------------------------------------------

  void _openDetail(int id) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => ParticipantDetailScreen(userId: id)),
    );
  }

  void _openAddParticipant() async {
    final added = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => const AddParticipantScreen()),
    );
    if (added == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Inscription envoyée au serveur de test.')),
      );
    }
  }

  // --- Démonstration (requêtes imposées par le sujet : &delay, /http/500) -

  void _debugForceSlowLoad() {
    setState(() {
      _items.clear();
      _total = 0;
      _firstPage = _loadFirstPage(forcedDelayMs: 1500);
    });
  }

  void _debugForceServerError() {
    setState(() {
      _items.clear();
      _total = 0;
      _firstPage = _loadFirstPage(forceServerError: true);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Annuaire des participants'),
        actions: [
          IconButton(
            tooltip: 'Nouvelle inscription (partie D)',
            icon: const Icon(Icons.person_add_alt),
            onPressed: _openAddParticipant,
          ),
          PopupMenuButton<VoidCallback>(
            tooltip: 'Scénarios de démonstration',
            icon: const Icon(Icons.bug_report_outlined),
            onSelected: (action) => action(),
            itemBuilder: (context) => [
              PopupMenuItem(
                value: _debugForceSlowLoad,
                child: const Text('Simuler un chargement lent (+1,5 s)'),
              ),
              PopupMenuItem(
                value: _debugForceServerError,
                child: const Text('Simuler une erreur serveur (500)'),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 0),
            child: TextField(
              controller: _searchController,
              textInputAction: TextInputAction.search,
              onSubmitted: _submitSearch,
              decoration: InputDecoration(
                hintText: 'Rechercher un participant par nom…',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _activeKeyword == null
                    ? null
                    : IconButton(
                        icon: const Icon(Icons.clear),
                        tooltip: 'Effacer la recherche',
                        onPressed: () => _selectKeyword(null),
                      ),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                isDense: true,
              ),
            ),
          ),
          _KeywordBar(active: _activeKeyword, onSelected: _selectKeyword),
          const Divider(height: 1),
          Expanded(child: _buildBody(context)),
        ],
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    return FutureBuilder<UsersPage>(
      future: _firstPage,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const FullScreenLoader(label: 'Chargement de l\'annuaire…');
        }
        if (snapshot.hasError) {
          return ErrorView(
            message: ErrorView.messageFor(snapshot.error),
            onRetry: () => _selectKeyword(_activeKeyword),
          );
        }
        // snapshot.hasData : on affiche désormais l'état mutable (_items),
        // pas snapshot.data — qui ne reflète que la toute première page.
        if (_items.isEmpty) {
          return EmptyView(
            message: _activeKeyword == null
                ? 'Aucun participant à afficher.'
                : 'Aucun résultat pour « $_activeKeyword ».',
          );
        }
        final reachedEnd = _items.length >= _total;
        return RefreshIndicator(
          onRefresh: _onRefresh,
          child: ListView.builder(
            controller: _scrollController,
            itemCount: _items.length + 1,
            itemBuilder: (context, index) {
              if (index == _items.length) {
                return ListFooterStatus(
                  isLoading: _loadingMore,
                  errorMessage: _loadMoreErrorMessage,
                  onRetry: _loadNextPage,
                  reachedEnd: reachedEnd && _activeKeyword == null,
                );
              }
              final participant = _items[index];
              return ParticipantTile(
                participant: participant,
                onTap: () => _openDetail(participant.id),
              );
            },
          ),
        );
      },
    );
  }
}

class _KeywordBar extends StatelessWidget {
  const _KeywordBar({required this.active, required this.onSelected});

  final String? active;
  final ValueChanged<String?> onSelected;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        children: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: const Text('Tous'),
              selected: active == null,
              onSelected: (_) => onSelected(null),
            ),
          ),
          for (final keyword in _keywords)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ChoiceChip(
                label: Text(keyword),
                selected: active == keyword,
                onSelected: (_) => onSelected(keyword),
              ),
            ),
        ],
      ),
    );
  }
}
