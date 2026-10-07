import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../domain/models/app_preferences.dart';
import '../../state/catalog_state.dart';
import '../routes.dart';
import '../widgets/event_collection.dart';
import '../widgets/offline_banner.dart';
import '../widgets/state_views.dart';

/// Catalogue public : recherche, tri, pagination, mode dégradé. Accessible
/// sans connexion.
class CatalogScreen extends StatefulWidget {
  const CatalogScreen({super.key});

  @override
  State<CatalogScreen> createState() => _CatalogScreenState();
}

class _CatalogScreenState extends State<CatalogScreen> {
  final _searchController = TextEditingController();
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  /// Pagination au défilement : la page suivante est demandée un peu avant
  /// la fin. `loadMore` ignore lui-même les appels en double.
  void _onScroll() {
    if (_scrollController.position.extentAfter < 400) {
      context.read<CatalogState>().loadMore();
    }
  }

  void _search(String query) {
    FocusScope.of(context).unfocus();
    context.read<CatalogState>().loadFirstPage(query: query);
  }

  void _clearSearch() {
    _searchController.clear();
    _search('');
  }

  @override
  Widget build(BuildContext context) {
    final catalog = context.watch<CatalogState>();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Catalogue'),
        actions: [
          PopupMenuButton<EventSort>(
            tooltip: 'Trier (actuellement : ${catalog.sort.label})',
            icon: const Icon(Icons.sort),
            initialValue: catalog.sort,
            onSelected: catalog.setSort,
            itemBuilder: (_) => [
              for (final sort in EventSort.values)
                PopupMenuItem(
                  value: sort,
                  child: Text('Trier par ${sort.label.toLowerCase()}'),
                ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 4, 12, 8),
            child: TextField(
              controller: _searchController,
              textInputAction: TextInputAction.search,
              onSubmitted: _search,
              decoration: InputDecoration(
                hintText: 'Rechercher un événement',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: ListenableBuilder(
                  listenable: _searchController,
                  builder: (context, _) => _searchController.text.isEmpty
                      ? const SizedBox.shrink()
                      : IconButton(
                          tooltip: 'Effacer la recherche',
                          icon: const Icon(Icons.clear),
                          onPressed: _clearSearch,
                        ),
                ),
              ),
            ),
          ),
          OfflineBanner(
            staleSince: catalog.staleSince,
            onRetry: catalog.refresh,
          ),
          Expanded(
            // Animation implicite : fondu entre les états du catalogue.
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              child: KeyedSubtree(
                key: ValueKey(catalog.status),
                child: _body(catalog),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _body(CatalogState catalog) {
    switch (catalog.status) {
      case CatalogStatus.loading:
        return const LoadingView(label: 'Chargement du catalogue…');
      case CatalogStatus.error:
        return ErrorView(
          message: catalog.errorMessage ?? 'Le catalogue est indisponible.',
          onRetry: catalog.refresh,
        );
      case CatalogStatus.empty:
        return catalog.query.isEmpty
            ? EmptyView(
                title: 'Aucun événement pour le moment',
                actionLabel: 'Actualiser',
                onAction: catalog.refresh,
              )
            : EmptyView(
                icon: Icons.search_off,
                title: 'Aucun résultat',
                message:
                    'Aucun événement ne correspond à « ${catalog.query} ».',
                actionLabel: 'Effacer la recherche',
                onAction: _clearSearch,
              );
      case CatalogStatus.loaded:
        return RefreshIndicator(
          onRefresh: catalog.refresh,
          child: CustomScrollView(
            controller: _scrollController,
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              EventCollectionSliver(
                events: catalog.events,
                onTap: (event) => Navigator.of(context).pushNamed(
                  AppRoutes.eventDetail,
                  arguments: EventDetailArgs.of(event),
                ),
              ),
              SliverToBoxAdapter(child: _CatalogFooter(catalog: catalog)),
            ],
          ),
        );
    }
  }
}

/// Pied de liste : état de la pagination. Ne masque jamais les événements
/// déjà chargés — un échec de page suivante s'affiche ici, avec reprise.
class _CatalogFooter extends StatelessWidget {
  const _CatalogFooter({required this.catalog});

  final CatalogState catalog;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final count = '${catalog.events.length} sur ${catalog.total} événement(s)';
    final Widget content;
    if (catalog.isLoadingMore) {
      content = const Padding(
        padding: EdgeInsets.all(8),
        child: CircularProgressIndicator(
          semanticsLabel: 'Chargement de la page suivante',
        ),
      );
    } else if (catalog.loadMoreError != null) {
      content = Column(
        children: [
          Text(
            catalog.loadMoreError!,
            textAlign: TextAlign.center,
            style: TextStyle(color: theme.colorScheme.error),
          ),
          TextButton.icon(
            onPressed: catalog.loadMore,
            icon: const Icon(Icons.refresh),
            label: const Text('Réessayer'),
          ),
        ],
      );
    } else if (catalog.hasMore) {
      // Alternative explicite au défilement : indispensable si la première
      // page ne remplit pas l'écran (tablette) ou pour qui ne défile pas.
      content = OutlinedButton(
        onPressed: catalog.loadMore,
        child: Text('Afficher ${catalog.nextPageSize} événement(s) de plus'),
      );
    } else {
      content = Text(
        catalog.isStale ? 'Fin de la copie locale' : 'Fin du catalogue',
        style: theme.textTheme.bodySmall,
      );
    }
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      child: Column(
        children: [
          Text(
            catalog.isStale || catalog.pageCount <= 1
                ? count
                : '$count · ${catalog.pageCount} pages',
            style: theme.textTheme.bodySmall,
          ),
          const SizedBox(height: 8),
          content,
        ],
      ),
    );
  }
}
