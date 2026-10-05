/// Modèle d'un participant de l'annuaire, construit à la main depuis le JSON
/// renvoyé par DummyJSON (`/users`, `/users/search`, `/users/{id}`).
class Participant {
  const Participant({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.imageUrl,
    required this.companyName,
    this.address,
    this.phone,
  });

  final int id;
  final String firstName;
  final String lastName;
  final String email;
  final String imageUrl;
  final String companyName;

  /// Champs disponibles seulement sur l'endpoint de détail (`/users/{id}`).
  final String? address;
  final String? phone;

  String get fullName => '$firstName $lastName'.trim();

  factory Participant.fromJson(Map<String, dynamic> json) {
    return Participant(
      id: _readInt(json['id']),
      firstName: _readString(json['firstName']),
      lastName: _readString(json['lastName']),
      email: _readString(json['email']),
      imageUrl: _readString(json['image']),
      companyName: _readCompanyName(json['company']),
      address: _readAddress(json['address']),
      phone: _readOptionalString(json['phone']),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'firstName': firstName,
        'lastName': lastName,
        'email': email,
        'image': imageUrl,
        'company': {'name': companyName},
        'address': address,
        'phone': phone,
      };

  // --- Conversion défensive ------------------------------------------------
  // DummyJSON est globalement cohérent, mais ces helpers protègent le modèle
  // contre un champ absent, nul, d'un type inattendu ("id": "5" au lieu de 5),
  // ou un sous-objet incomplet — sans jamais lever d'exception.

  static int _readInt(dynamic value) {
    if (value is int) return value;
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  static String _readString(dynamic value) {
    if (value is String) return value;
    return '';
  }

  static String? _readOptionalString(dynamic value) {
    if (value is String && value.isNotEmpty) return value;
    return null;
  }

  static String _readCompanyName(dynamic company) {
    if (company is Map) {
      final name = company['name'];
      if (name is String && name.isNotEmpty) return name;
    }
    return 'Non renseigné';
  }

  static String? _readAddress(dynamic address) {
    if (address is Map) {
      final street = address['address'];
      final city = address['city'];
      final parts = [street, city]
          .whereType<String>()
          .where((value) => value.isNotEmpty);
      if (parts.isNotEmpty) return parts.join(', ');
    }
    return null;
  }
}
