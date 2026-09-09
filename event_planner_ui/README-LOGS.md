# README-LOGS — Commandes utilisées pour construire ce projet

Ce fichier liste, dans l'ordre, les commandes réellement exécutées pour créer et valider
`event_planner_ui`, ainsi que les fichiers écrits à la main entre chaque commande. Objectif :
que tu puisses rejouer les mêmes étapes toi-même et comprendre *pourquoi* chaque commande a
été lancée, pas seulement *quoi* copier-coller.

Contexte machine : projet développé sous WSL2 (Ubuntu 24.04), SDK Flutter et SDK Android
installés en natif Linux dans WSL, application testée sur un émulateur Android piloté depuis
Windows (Android Studio) et exposé à WSL via un pont `adb` en TCP — cf. section
"Environnement" en bas de ce fichier si tu dois reproduire ce setup sur une autre machine.

## 1. Création du projet

```bash
flutter create event_planner_ui
```

Génère le squelette standard (`pubspec.yaml`, `lib/main.dart` avec le compteur de démo,
dossiers `android/`, `test/`, etc.). C'est la seule commande de génération de code utilisée —
tout le reste du contenu métier (`Event`, `EventCard`, l'écran d'accueil...) a été écrit à la
main, il n'existe pas de générateur Flutter pour des widgets de mise en page métier.

## 2. Arborescence `lib/`

```bash
mkdir -p lib/data lib/utils lib/widgets lib/screens
```

Séparation par responsabilité plutôt que tout dans `main.dart` :
- `data/` : le modèle `Event` et le jeu de données codé en dur
- `utils/` : fonctions pures sans dépendance UI (formatage de date)
- `widgets/` : composants réutilisables et paramétrés (carte, en-tête, barre de stats...)
- `screens/` : assemblage des widgets en écran complet

## 3. Fichiers écrits (dans l'ordre)

| Fichier | Rôle | Lien avec l'énoncé |
|---|---|---|
| `lib/data/sample_events.dart` | Classe `Event` (reprise telle quelle de l'énoncé) + 8 événements | Partie « Jeu de données imposé » — inclut volontairement les 5 cas limites demandés (titre >70 caractères, `isSoldOut`, événement en ligne sans ville, `registered > capacity`, lieu au nom long) |
| `lib/utils/date_label.dart` | Fonction pure `dateLabel(DateTime) → String`, tables de jours/mois en français écrites à la main | Partie A, contrainte « sans `intl` » |
| `lib/widgets/event_card.dart` | `EventCard` + 2 sous-widgets privés extraits (`_StatusBadge`, `_CapacityGauge`) | Partie A dans son intégralité (vignette carrée, `Expanded` pour le texte, jauge en `Stack`) |
| `lib/widgets/hero_header.dart` | `HeroHeader` : image + dégradé + avatar en débordement | Partie B, en-tête hero |
| `lib/widgets/stats_bar.dart` | `StatsBar` + `StatItem` (classe de paramétrage) | Partie B, barre de statistiques |
| `lib/widgets/category_filters.dart` | `CategoryFilters`, pastilles dans un `Wrap` | Partie B, filtres par catégorie |
| `lib/widgets/section_header.dart` | `SectionHeader` : titre + compteur alignés aux extrémités | Partie B, en-tête de la liste d'événements |
| `lib/screens/home_screen.dart` | `HomeScreen` : assemble tout dans un unique `SingleChildScrollView` | Partie B, écran complet |
| `lib/main.dart` | Réécrit pour ne garder qu'un `MaterialApp` pointant vers `HomeScreen` | Partie A, étape 1 (« videz `main.dart` ») |

Aucun fichier n'a été généré par une commande — chaque widget a été rédigé directement selon
la structure d'arborescence imposée par l'énoncé (ordre `Container` → `Row` → vignette +
`Column`, etc.), puis vérifié par les commandes ci-dessous.

## 4. Correction du test généré par défaut

`flutter create` génère `test/widget_test.dart` avec un test du compteur de démo
(`MyApp`, bouton `+`), qui ne correspond plus au projet une fois `main.dart` réécrit. Réécrit
pour tester le jeu de données plutôt que le rendu visuel :

```bash
flutter analyze
```

→ a d'abord signalé `MyApp` introuvable dans le test (nom de classe obsolète), corrigé en
remplaçant le test du compteur par des assertions sur `sampleEvents` et `dateLabel` (voir
`test/widget_test.dart`). Pourquoi ne pas tester le rendu visuel des widgets ? Parce que
`Image.network` échoue systématiquement pendant `flutter test` (aucune requête réseau réelle
n'est permise en mode test, c'est documenté et attendu) — un test de rendu sur `EventCard` ou
`HeroHeader` échouerait à cause du réseau, pas à cause d'un bug de mise en page. Le vrai test
de non-débordement se fait visuellement sur l'émulateur (étape 6), conformément à l'énoncé qui
définit le critère de réussite comme « aucun message RenderFlex overflowed [...] ni en
console, ni à l'écran ».

## 5. Vérification statique

```bash
flutter analyze   # No issues found!
flutter test      # 8/8 tests passed
```

## 6. Vérification visuelle sur l'émulateur

```bash
flutter devices                       # confirme que emulator-5554 est vu par Flutter
flutter run -d emulator-5554 --no-hot # build + installation + lancement
```

Premier lancement : Gradle télécharge le NDK Android (28.2) et compile le module Kotlin —
c'est normal et long uniquement la première fois (caches Gradle ensuite réutilisés). Objectif
de cette étape : confirmer dans la sortie console l'absence de tout message
`A RenderFlex overflowed by ... pixels`, en particulier avec l'événement au titre de plus de
70 caractères et celui au nom de lieu long, qui sont les deux cas construits spécifiquement
pour révéler un débordement si l'`Expanded`/l'`ellipsis` manquait quelque part.

---

## Environnement (setup machine, à ne faire qu'une fois)

Ces commandes ne concernent pas le projet lui-même mais l'installation de la chaîne d'outils
sous WSL2 — utile seulement si tu reproduis ce setup sur une autre machine WSL :

```bash
# SDK Flutter (Linux, dans WSL)
curl -o flutter_linux.tar.xz https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_3.47.2-stable.tar.xz
tar xf flutter_linux.tar.xz -C ~/development
export PATH="$PATH:$HOME/development/flutter/bin"   # ajouté à ~/.bashrc

# SDK Android en ligne de commande (Linux, dans WSL — pas Android Studio, juste les cmdline-tools)
curl -o cmdline-tools.zip https://dl.google.com/android/repository/commandlinetools-linux-11076708_latest.zip
unzip cmdline-tools.zip -d ~/Android/Sdk/cmdline-tools && mv ~/Android/Sdk/cmdline-tools/cmdline-tools ~/Android/Sdk/cmdline-tools/latest
sdkmanager --licenses
sdkmanager "platform-tools" "platforms;android-34" "platforms;android-36" "build-tools;34.0.0" "build-tools;28.0.3"
flutter config --android-sdk ~/Android/Sdk

# JDK requis par Gradle
sudo apt-get install -y openjdk-17-jdk
```

Pont adb WSL ↔ émulateur Windows (Android Studio doit rester **fermé** pendant le dev,
sinon il reprend le port 5037 en local uniquement) :

```powershell
# Côté Windows (PowerShell, dans le dossier platform-tools du SDK Windows)
taskkill /F /IM studio64.exe
taskkill /F /IM adb.exe
.\adb.exe -a -P 5037 nodaemon server      # serveur adb ouvert à toutes les interfaces
.\emulator.exe -avd Pixel_7_Pro           # lance l'émulateur
```

```bash
# Côté WSL (~/.bashrc)
export ADB_SERVER_SOCKET=tcp:172.31.112.1:5037   # 172.31.112.1 = passerelle WSL, `ip route show default`
```
