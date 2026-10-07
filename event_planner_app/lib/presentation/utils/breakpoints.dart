/// Seuils de mise en page adaptative, comparés à la largeur **disponible**
/// (`LayoutBuilder`), pas à la taille de l'écran : un écran reste correct en
/// fenêtre partagée ou dans un volet.
abstract final class Breakpoints {
  /// En dessous : téléphone (une colonne, barre de navigation en bas).
  /// Au-dessus : tablette (grille, rail de navigation latéral, deux volets).
  static const double tablet = 600;

  /// Largeur maximale d'un formulaire ou d'un bloc de lecture : au-delà, les
  /// lignes deviennent trop longues pour être lues confortablement.
  static const double readableWidth = 560;
}
