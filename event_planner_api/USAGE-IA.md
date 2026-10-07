USAGE-IA - TP 10 — Goumarre Yoann

Outil(s) utilisé(s) : Claude Code (modèle Claude Opus 5.5)
Déclaration : [ ] je n'ai utilisé aucune IA / [x] entrées ci-dessous

1. Génération de l'Architecture et Configuration (Entrées 1, 6, 7, 8)

Demande : Création de l'arborescence (4 couches), configuration Firebase et compilation de l'APK Release.

Arbitrage et Corrections : J'ai dû intervenir à plusieurs reprises. L'IA a généré des conflits d'imports (HttpClientProvider) et a affirmé à tort avoir réussi la compilation Release. J'ai pris la main pour corriger les erreurs de compilation, relancer les builds manuellement, et ajouter la permission INTERNET qu'elle avait omise dans le manifeste principal. J'ai également vérifié manuellement le bon branchement de Firebase via l'émulateur, refusant de me fier aux simples affirmations de l'IA.

2. Logique Métier, États et Sécurité (Entrées 2, 3, 5)

Demande : Liaison catalogue (DummyJSON), gestion du panier utilisateur et script de preuve des règles Firestore.

Arbitrage et Corrections : J'ai refusé une architecture basée sur ChangeNotifierProxyProvider proposée par l'IA, car elle provoquait des erreurs de build. J'ai repensé la liaison en utilisant des addListener sur AuthState. Pour la sécurité, j'ai fait générer un script de preuve REST que j'ai exécuté moi-même pour garantir que l'isolation des événements était réelle (10 refus 403, 3 succès 200).

3. Tests et Documentation (Entrées 4, 9)

Demande : Rédaction des 84 tests requis et des documents de livraison.

Arbitrage et Corrections : L'IA a rédigé les tests (gain de temps majeur), mais j'ai dû corriger de fausses assertions liées à des recherches de texte ambiguës. Pour ce fichier de déclaration, l'IA a tenté d'inventer de fausses entrées de prompt : j'ai strictement expurgé le document pour ne garder que la vérité de ma session.

4. Synthèse de la Revue de Code (Partie C.3)

J'ai soumis l'ensemble du projet à une revue par Claude, dont j'ai filtré les retours avec un esprit critique :

Retenues : Sécurisation de l'état UI lors de la rotation (GlobalKey), suppression du code mort identifié, et correction sémantique des messages d'erreur.

Refusées car dangereuses ou hors-sujet : J'ai rejeté le remplacement de AppFailure par un catch (e) générique (qui aurait masqué les bugs de développement), et j'ai refusé d'incrémenter directement les compteurs Firestore car cela aurait violé les contraintes de sécurité imposées par l'énoncé.

Bilan

Ce qui m'a fait gagner du temps : La mise en place du boilerplate de l'architecture, la génération massive des cas de test, et l'adaptation de mes anciens scripts.

Ce qui m'a coûté du temps : Le volume colossal à relire et comprendre. Les "hallucinations" de l'IA (étapes prétendument terminées) m'ont obligé à tout vérifier avec mes propres commandes (git status, adb, requêtes REST).

Ce que je retiens : Je suis très à l'aise avec la composition UI, le routage, les Providers et les API. Ma priorité de révision pour la soutenance portera sur l'injection de dépendances globale et le détail des tests de widgets avec doubles, dont le code a été très largement produit par l'outil.