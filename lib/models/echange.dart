// lib/models/echange.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class Echange {
  final String id;
  final String savoirTitle;
  final String proposerEmail;
  final String receveurEmail;
  String status; // "proposé", "accepté", "refusé"
  final DateTime dateProposition;
  DateTime? dateReponse;

  Echange({
    required this.id,
    required this.savoirTitle,
    required this.proposerEmail,
    required this.receveurEmail,
    this.status = 'proposé',
    required this.dateProposition,
    this.dateReponse,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'savoirTitle': savoirTitle,
    'proposerEmail': proposerEmail,
    'receveurEmail': receveurEmail,
    'status': status,
    'dateProposition': Timestamp.fromDate(dateProposition),
    'dateReponse': dateReponse != null ? Timestamp.fromDate(dateReponse!) : null,
  };

  factory Echange.fromMap(Map map) => Echange(
    id: map['id'] ?? '',
    savoirTitle: map['savoirTitle'] ?? '',
    proposerEmail: map['proposerEmail'] ?? '',
    receveurEmail: map['receveurEmail'] ?? '',
    status: map['status'] ?? 'proposé',
    dateProposition: map['dateProposition'] is Timestamp
        ? (map['dateProposition'] as Timestamp).toDate()
        : DateTime.tryParse(map['dateProposition']?.toString() ?? '') ?? DateTime.now(),
    dateReponse: map['dateReponse'] != null
        ? (map['dateReponse'] is Timestamp
        ? (map['dateReponse'] as Timestamp).toDate()
        : DateTime.tryParse(map['dateReponse'].toString()))
        : null,
  );
}
