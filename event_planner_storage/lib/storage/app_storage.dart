import 'draft_repository.dart';
import 'preferences_store.dart';

/// Instances uniques de la couche de stockage (TP 7), créées ici et
/// initialisées dans `main()` (voir `prefsStore.init()`) avant `runApp`.
///
/// Volontairement **pas de `provider`** : ce sont des services d'accès au
/// disque / aux préférences — non réactifs, aucun `ChangeNotifier`, aucune
/// notion d'état d'UI partagé au sens de la séance 4. Les écrans qui en ont
/// besoin les importent directement ou les reçoivent en paramètre de
/// constructeur ; aucun `context.watch`/`context.read` n'est utilisé pour
/// eux.
final PreferencesStore prefsStore = SharedPreferencesStore();
final DraftRepository draftRepository = DraftRepository();
