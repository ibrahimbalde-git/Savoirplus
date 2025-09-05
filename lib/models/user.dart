class AppUser {
  final String id; // 🆕 Identifiant unique Firestore
  final String email;
  final String name;
  final String country;
  final List<String> spokenLanguages;
  final List<String> skillsOffered;
  final List<String> skillsWanted;
  final String description;
  final String photoUrl;
  final List<String> availability;
  final double rating;

  AppUser({
    required this.id, // 🆕 devient obligatoire
    required this.email,
    required this.name,
    this.country = '',
    List<String>? spokenLanguages,
    List<String>? skillsOffered,
    List<String>? skillsWanted,
    this.description = '',
    this.photoUrl = '',
    List<String>? availability,
    this.rating = 0.0,
  })  : spokenLanguages = spokenLanguages ?? [],
        skillsOffered = skillsOffered ?? [],
        skillsWanted = skillsWanted ?? [],
        availability = availability ?? [];

  bool get isAvailable => availability.isNotEmpty;
  String get primaryLanguage =>
      spokenLanguages.isNotEmpty ? spokenLanguages.first : '';

  Map<String, dynamic> toMap() => {
    'id': id, // 🆕 ajouté
    'email': email,
    'name': name,
    'country': country,
    'spokenLanguages': spokenLanguages,
    'skillsOffered': skillsOffered,
    'skillsWanted': skillsWanted,
    'description': description,
    'photoUrl': photoUrl,
    'availability': availability,
    'rating': rating,
  };

  factory AppUser.fromMap(Map<String, dynamic> map, {String? id}) {
    List<String> parseField(dynamic v) {
      if (v == null) return [];
      if (v is List) return v.cast<String>();
      if (v is String) {
        return v
            .split(',')
            .map((e) => e.trim())
            .where((e) => e.isNotEmpty)
            .toList();
      }
      return [];
    }

    return AppUser(
      id: id ?? map['id'] ?? '', // 🆕 récupère l’id Firestore si dispo
      email: map['email'] ?? '',
      name: map['name'] ?? '',
      country: map['country'] ?? '',
      spokenLanguages: parseField(map['spokenLanguages']),
      skillsOffered: parseField(map['skillsOffered']),
      skillsWanted: parseField(map['skillsWanted']),
      description: map['description'] ?? '',
      photoUrl: map['photoUrl'] ?? '',
      availability: parseField(map['availability']),
      rating: (map['rating'] is num)
          ? (map['rating'] as num).toDouble()
          : 0.0,
    );
  }

  AppUser copyWith({
    String? id,
    String? email,
    String? name,
    String? country,
    List<String>? spokenLanguages,
    List<String>? skillsOffered,
    List<String>? skillsWanted,
    String? description,
    String? photoUrl,
    List<String>? availability,
    double? rating,
  }) {
    return AppUser(
      id: id ?? this.id, // 🆕 inclus
      email: email ?? this.email,
      name: name ?? this.name,
      country: country ?? this.country,
      spokenLanguages: spokenLanguages ?? this.spokenLanguages,
      skillsOffered: skillsOffered ?? this.skillsOffered,
      skillsWanted: skillsWanted ?? this.skillsWanted,
      description: description ?? this.description,
      photoUrl: photoUrl ?? this.photoUrl,
      availability: availability ?? this.availability,
      rating: rating ?? this.rating,
    );
  }
}
