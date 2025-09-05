class Savoir {
  final String id; // AJOUTÉ : Important pour identifier le savoir
  final String title;
  final String description;
  final String category;
  final String offeredBy; // Ceci devrait être l'email ou l'ID de l'utilisateur
  final String? offererName; // AJOUTÉ : Le nom de l'utilisateur qui propose
  final DateTime? dateAdded;
  final int popularity;

  Savoir({
    required this.id, // AJOUTÉ
    required this.title,
    required this.description,
    required this.category,
    required this.offeredBy,
    this.offererName, // AJOUTÉ
    this.dateAdded,
    this.popularity = 0,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id, // AJOUTÉ
      'title': title,
      'description': description,
      'category': category,
      'offeredBy': offeredBy,
      'offererName': offererName, // AJOUTÉ
      'dateAdded': dateAdded?.toIso8601String(),
      'popularity': popularity,
    };
  }

  factory Savoir.fromMap(Map<String, dynamic> map) {
    return Savoir(
      id: map['id'] ?? '', // AJOUTÉ
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      category: map['category'] ?? '',
      offeredBy: map['offeredBy'] ?? '',
      offererName: map['offererName'], // AJOUTÉ : Peut être null
      dateAdded: map['dateAdded'] != null ? DateTime.parse(map['dateAdded']) : null,
      popularity: map['popularity'] ?? 0,
    );
  }
}
