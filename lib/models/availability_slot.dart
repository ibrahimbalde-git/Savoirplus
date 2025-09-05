class AvailabilitySlot {
  final String id; // Firestore doc id (utile à l’UI)
  final DateTime date; // date du jour (à minuit)
  final String start; // "HH:mm"
  final String end;   // "HH:mm"
  final String mode;  // "En ligne" | "Présentiel"
  final String location;
  final String notes;

  AvailabilitySlot({
    required this.id,
    required this.date,
    required this.start,
    required this.end,
    required this.mode,
    this.location = '',
    this.notes = '',
  });

  Map<String, dynamic> toMap() => {
    'date': date,
    'start': start,
    'end': end,
    'mode': mode,
    'location': location,
    'notes': notes,
    'createdAt': DateTime.now(),
  };

  factory AvailabilitySlot.fromMap(String id, Map<String, dynamic> map) {
    final ts = map['date'];
    final DateTime d =
    ts is DateTime ? ts : (ts?.toDate() as DateTime? ?? DateTime.now());
    return AvailabilitySlot(
      id: id,
      date: DateTime(d.year, d.month, d.day),
      start: (map['start'] ?? '') as String,
      end: (map['end'] ?? '') as String,
      mode: (map['mode'] ?? '') as String,
      location: (map['location'] ?? '') as String,
      notes: (map['notes'] ?? '') as String,
    );
  }
}
