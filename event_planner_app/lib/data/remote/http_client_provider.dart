import 'package:http/http.dart' as http;

/// Fournit **l'unique** instance de [http.Client] de l'application.
///
/// Une seule instance réutilisée (les connexions restent ouvertes entre deux
/// requêtes vers le même hôte) et un seul endroit où la fermer. Les dépôts
/// reçoivent le client par leur constructeur : en test, on leur passe un
/// double à la place, sans toucher à cette classe.
class SharedHttpClient {
  http.Client? _client;

  http.Client get client => _client ??= http.Client();

  void close() {
    _client?.close();
    _client = null;
  }
}
