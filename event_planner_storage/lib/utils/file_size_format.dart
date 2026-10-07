/// Formate une taille de fichier en octets ou kio, unité affichée (TP 7,
/// partie B — taille des brouillons dans la liste).
String formatFileSize(int bytes) {
  if (bytes < 1024) return '$bytes o';
  final kio = bytes / 1024;
  return '${kio.toStringAsFixed(kio < 10 ? 2 : 1)} kio';
}
