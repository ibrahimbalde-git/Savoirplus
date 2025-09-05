import 'package:cloud_firestore/cloud_firestore.dart';

class Appointment {
  final String id;
  final String fromUid;
  final String fromName;
  final String toName;           // Nom du proposant (depuis Savoir.offeredBy)
  final String savoirTitle;      // Pour contexte
  final String type;             // 'visio' | 'presentiel' | 'chat'
  final String note;             // optionnel
  final String status;           // 'pending' | 'accepted' | 'rejected'
  final DateTime dateTime;
  final DateTime createdAt;

  Appointment({
    required this.id,
    required this.fromUid,
    required this.fromName,
    required this.toName,
    required this.savoirTitle,
    required this.type,
    required this.note,
    required this.status,
    required this.dateTime,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() => {
    'fromUid': fromUid,
    'fromName': fromName,
    'toName': toName,
    'savoirTitle': savoirTitle,
    'type': type,
    'note': note,
    'status': status,
    'dateTime': Timestamp.fromDate(dateTime),
    'createdAt': Timestamp.fromDate(createdAt),
  };

  factory Appointment.fromDoc(DocumentSnapshot doc) {
    final m = doc.data() as Map<String, dynamic>;
    return Appointment(
      id: doc.id,
      fromUid: m['fromUid'] ?? '',
      fromName: m['fromName'] ?? '',
      toName: m['toName'] ?? '',
      savoirTitle: m['savoirTitle'] ?? '',
      type: m['type'] ?? 'visio',
      note: m['note'] ?? '',
      status: m['status'] ?? 'pending',
      dateTime: (m['dateTime'] as Timestamp).toDate(),
      createdAt: (m['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}
