import 'package:flutter/foundation.dart';

import '../domain/failures.dart';
import '../domain/models/event.dart';
import '../domain/repositories/event_repository.dart';

enum CatalogStatus { loading, loaded, error }

/// État du catalogue — jalon « parcours vertical » : une seule page, pas de
/// recherche, pas de pagination. N'importe que `foundation.dart` et le
/// domaine (jamais `material.dart`, jamais `data/`).
class CatalogState extends ChangeNotifier {
  CatalogState({required this._repository});

  final EventRepository _repository;

  CatalogStatus _status = CatalogStatus.loading;
  List<Event> _events = const [];
  String? _errorMessage;

  CatalogStatus get status => _status;
  List<Event> get events => _events;
  String? get errorMessage => _errorMessage;

  Future<void> load() async {
    _status = CatalogStatus.loading;
    notifyListeners();
    try {
      final page = await _repository.fetchEvents(limit: 20, skip: 0);
      _events = page.events;
      _status = CatalogStatus.loaded;
    } on AppFailure catch (failure) {
      _errorMessage = failure.message;
      _status = CatalogStatus.error;
    }
    notifyListeners();
  }
}
