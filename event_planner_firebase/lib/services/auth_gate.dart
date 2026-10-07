import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../screens/login_screen.dart';
import '../screens/register_screen.dart';
import '../screens/reset_password_screen.dart';

/// Garde d'accès de l'application (TP 8, partie B).
///
/// Un unique [StreamBuilder] sur `authStateChanges()` à la racine de la
/// navigation — aucun état global ne duplique cette information :
/// * pas de session -> [_AuthFlow] (connexion / inscription / réinitialisation) ;
/// * session valide -> [signedIn] (l'application).
///
/// **Inatteignable structurellement** : l'espace connecté n'existe pas dans
/// l'arbre de widgets tant que le flux n'a pas émis un utilisateur non nul.
/// À la déconnexion, le builder remplace toute la branche : la pile de
/// navigation de l'espace privé (Navigator imbriqués des onglets) est
/// détruite avec elle, donc le bouton retour ne peut pas y revenir.
///
/// **Restauration de session** : le SDK relit la session persistée puis émet
/// l'utilisateur ; tant qu'aucun événement n'est arrivé on affiche un écran
/// d'attente, jamais l'écran de connexion (pas de flash parasite).
class AuthGate extends StatelessWidget {
  const AuthGate({super.key, required this.signedIn});

  final WidgetBuilder signedIn;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (snapshot.data == null) return const _AuthFlow();
        return signedIn(context);
      },
    );
  }
}

/// Navigateur **propre à la branche déconnectée**. Les écrans d'inscription et
/// de réinitialisation sont empilés ici, pas sur le Navigator racine : quand
/// la connexion réussit, [AuthGate] remplace toute la branche et ces routes
/// disparaissent avec elle (sinon l'écran d'inscription resterait par-dessus
/// l'application).
class _AuthFlow extends StatelessWidget {
  const _AuthFlow();

  static const String _login = '/';
  static const String _register = '/register';
  static const String _reset = '/reset';

  @override
  Widget build(BuildContext context) {
    return Navigator(
      initialRoute: _login,
      onGenerateRoute: (settings) {
        final Widget page = switch (settings.name) {
          _register => const RegisterScreen(),
          _reset => const ResetPasswordScreen(),
          _ => const LoginScreen(),
        };
        return MaterialPageRoute<void>(settings: settings, builder: (_) => page);
      },
    );
  }
}

/// Noms de routes du flux d'authentification (utilisés par les écrans).
abstract final class AuthRoutes {
  const AuthRoutes._();
  static const String register = '/register';
  static const String reset = '/reset';
}
