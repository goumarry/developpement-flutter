/// Brouillon d'événement persisté sur disque (TP 7).
///
/// **Nommage** : volontairement `DraftRecord`, pas `EventDraft` — ce dernier
/// nom est déjà pris par le modèle (immuable, sans persistance) produit par
/// le formulaire de création du TP 6, conservé dans ce projet fusionné. Les
/// deux ne se recouvrent pas : `EventDraft` (TP 6) est la sortie typée d'un
/// formulaire validé en une fois ; `DraftRecord` (TP 7) est un brouillon
/// *partiel*, *persistant*, rechargé et modifié au fil de plusieurs
/// sessions.
///
/// `toJson`/`fromJson` écrits à la main. [fromJson] migre silencieusement un
/// JSON de schéma version 1 (champ `city`) vers la forme version 2 (champ
/// `location`, plus `reminderEnabled` par défaut) — voir README, partie C.2.
class DraftRecord {
  const DraftRecord({
    required this.id,
    required this.title,
    required this.location,
    required this.date,
    required this.category,
    required this.lastModified,
    this.reminderEnabled = false,
  });

  /// Schéma actuel. Toute sérialisation nouvelle utilise cette version.
  static const int currentSchemaVersion = 2;

  final String id;
  final String title;
  final String location;

  /// Nullable : un brouillon n'a pas forcément de date encore choisie.
  final DateTime? date;
  final String category;
  final DateTime lastModified;
  final bool reminderEnabled;

  /// Brouillon vide pour un nouvel identifiant (fichier absent, ou
  /// identifiant inconnu — cas limite explicitement traité, pas une erreur).
  factory DraftRecord.empty(String id) => DraftRecord(
        id: id,
        title: '',
        location: '',
        date: null,
        category: '',
        lastModified: DateTime.now(),
      );

  DraftRecord copyWith({
    String? title,
    String? location,
    DateTime? date,
    bool clearDate = false,
    String? category,
    bool? reminderEnabled,
  }) {
    return DraftRecord(
      id: id,
      title: title ?? this.title,
      location: location ?? this.location,
      date: clearDate ? null : (date ?? this.date),
      category: category ?? this.category,
      lastModified: DateTime.now(),
      reminderEnabled: reminderEnabled ?? this.reminderEnabled,
    );
  }

  Map<String, dynamic> toJson() => {
        'schemaVersion': currentSchemaVersion,
        'id': id,
        'title': title,
        'location': location,
        'date': date?.toIso8601String(),
        'category': category,
        'lastModified': lastModified.toIso8601String(),
        'reminderEnabled': reminderEnabled,
      };

  /// Migration de schéma : un JSON sans `schemaVersion` ou avec
  /// `schemaVersion == 1` porte encore le champ `city` (renommé `location`
  /// en version 2) et n'a pas `reminderEnabled` (ajouté en version 2, valeur
  /// par défaut `false`). Relu ici sans perte du champ renommé.
  factory DraftRecord.fromJson(Map<String, dynamic> json) {
    final schemaVersion = json['schemaVersion'];
    final isLegacyV1 = schemaVersion == null || schemaVersion == 1;

    final location = isLegacyV1
        ? (json['city'] as String? ?? '')
        : (json['location'] as String? ?? '');

    final dateRaw = json['date'] as String?;

    return DraftRecord(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      location: location,
      date: dateRaw == null ? null : DateTime.tryParse(dateRaw),
      category: json['category'] as String? ?? '',
      lastModified: DateTime.tryParse(json['lastModified'] as String? ?? '') ??
          DateTime.now(),
      reminderEnabled: isLegacyV1 ? false : (json['reminderEnabled'] as bool? ?? false),
    );
  }
}
