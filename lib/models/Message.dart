import 'package:cloud_firestore/cloud_firestore.dart';

class Message {
  final String id;
  final String fromUserEmail;
  final String toUserEmail;
  final String content; // texte ou nom du fichier
  final String? mediaUrl; // URL Firebase Storage (image/audio/fichier)
  final String type; // 'text', 'image', 'audio', 'file'
  final double? audioDuration; // en secondes si audio
  final bool isRead; // message lu ou non
  final DateTime timestamp;
  final List<String> participants;

  Message({
    required this.id,
    required this.fromUserEmail,
    required this.toUserEmail,
    required this.content,
    this.mediaUrl,
    required this.type,
    this.audioDuration,
    required this.isRead,
    required this.timestamp,
    required this.participants,
  });

  /// Convertit l'objet en Map pour Firestore
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'fromUserEmail': fromUserEmail,
      'toUserEmail': toUserEmail,
      'content': content,
      'mediaUrl': mediaUrl,
      'type': type,
      'audioDuration': audioDuration,
      'isRead': isRead,
      'timestamp': Timestamp.fromDate(timestamp),
      'participants': participants,
    };
  }

  /// Crée un objet Message depuis une Map Firestore
  factory Message.fromMap(Map<String, dynamic> map) {
    return Message(
      id: map['id'] ?? '',
      fromUserEmail: map['fromUserEmail'] ?? '',
      toUserEmail: map['toUserEmail'] ?? '',
      content: map['content'] ?? '',
      mediaUrl: map['mediaUrl'],
      type: map['type'] ?? 'text',
      audioDuration: (map['audioDuration'] != null)
          ? (map['audioDuration'] as num).toDouble()
          : null,
      isRead: (map['isRead'] is bool) ? map['isRead'] : false,
      timestamp: (map['timestamp'] is Timestamp)
          ? (map['timestamp'] as Timestamp).toDate()
          : DateTime.now(),
      participants: (map['participants'] != null)
          ? List<String>.from(map['participants'])
          : <String>[],
    );
  }

  @override
  String toString() =>
      'Message(id: $id, from: $fromUserEmail, to: $toUserEmail, type: $type, content: $content)';
}
