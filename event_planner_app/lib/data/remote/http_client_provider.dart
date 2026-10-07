import 'package:http/http.dart' as http;

/// Seul endroit de l'application où un [http.Client] est instancié.
///
/// `main()` l'appelle **une fois** et injecte le client dans les dépôts par
/// leur constructeur : une seule instance réutilisée (les connexions restent
/// ouvertes entre deux requêtes vers le même hôte), et des dépôts qui ne
/// créent jamais leur propre client — en test, on leur passe un double.
///
/// Le client vit aussi longtemps que le processus : il n'y a pas d'instant
/// « fin de l'application » fiable sur mobile où le fermer.
http.Client provideHttpClient() => http.Client();
