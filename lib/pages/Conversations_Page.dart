import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user.dart';
import '../models/message.dart';
import 'chat_Page.dart';
import '../widgets/custom_appbar.dart'; // Ajouté pour l'uniformité

class ConversationsPage extends StatefulWidget {
  final AppUser currentUser;
  const ConversationsPage({required this.currentUser, Key? key}) : super(key: key);

  @override
  State<ConversationsPage> createState() => _ConversationsPageState();
}

class _ConversationsPageState extends State<ConversationsPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  bool _loading = true;
  Map<String, Message> _latestMessagesPerConversation = {};
  Map<String, AppUser> _usersPerConversation = {};

  @override
  void initState() {
    super.initState();
    _loadConversations();
  }

  Future<void> _loadConversations() async {
    try {
      final messagesSnapshot = await _firestore
          .collection('messages')
          .where('participants', arrayContains: widget.currentUser.email)
          .get();

      Map<String, Message> latestMessages = {};
      Map<String, String> conversationToOtherEmail = {};

      for (var doc in messagesSnapshot.docs) {
        final message = Message.fromMap(doc.data());
        final otherEmail = message.participants.firstWhere((email) => email != widget.currentUser.email);

        final convKeyList = [widget.currentUser.email, otherEmail]..sort();
        final convKey = convKeyList.join('_');

        if (!latestMessages.containsKey(convKey) || message.timestamp.isAfter(latestMessages[convKey]!.timestamp)) {
          latestMessages[convKey] = message;
          conversationToOtherEmail[convKey] = otherEmail;
        }
      }

      List<String> emails = conversationToOtherEmail.values.toSet().toList();
      Map<String, AppUser> users = {};
      if (emails.isNotEmpty) {
        if (emails.length <= 10) {
          final q = await _firestore.collection('users').where('email', whereIn: emails).get();
          for (var d in q.docs) {
            final data = d.data();
            users[data['email']] = AppUser.fromMap(data);
          }
        } else {
          for (var e in emails) {
            final q = await _firestore.collection('users').where('email', isEqualTo: e).limit(1).get();
            if (q.docs.isNotEmpty) users[e] = AppUser.fromMap(q.docs.first.data());
          }
        }
      }

      Map<String, AppUser> usersPerConversation = {};
      conversationToOtherEmail.forEach((convKey, email) {
        if (users.containsKey(email)) usersPerConversation[convKey] = users[email]!;
      });

      setState(() {
        _latestMessagesPerConversation = latestMessages;
        _usersPerConversation = usersPerConversation;
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur lors du chargement : $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_latestMessagesPerConversation.isEmpty) return const Center(child: Text('Aucune conversation trouvée'));

    final sortedConvKeys = _latestMessagesPerConversation.keys.toList()
      ..sort((a, b) => _latestMessagesPerConversation[b]!.timestamp.compareTo(_latestMessagesPerConversation[a]!.timestamp));

    return Scaffold(
      appBar: CustomAppBar(title: "Conversations"),
      body: ListView.builder(
        itemCount: sortedConvKeys.length,
        itemBuilder: (context, index) {
          final convKey = sortedConvKeys[index];
          final message = _latestMessagesPerConversation[convKey]!;
          final otherUser = _usersPerConversation[convKey];

          return ListTile(
            title: Text(otherUser?.name ?? (message.toUserEmail == widget.currentUser.email ? message.fromUserEmail : message.toUserEmail)),
            subtitle: Text(
              '${message.content}\n${message.timestamp.toLocal().toString().substring(0, 16)}',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            trailing: Text(
              _formatDate(message.timestamp),
              style: const TextStyle(color: Colors.grey, fontSize: 12),
            ),
            onTap: () async {
              AppUser? user = otherUser;
              if (user == null) {
                final otherEmail = message.participants.firstWhere((e) => e != widget.currentUser.email);
                final q = await _firestore.collection('users').where('email', isEqualTo: otherEmail).limit(1).get();
                if (q.docs.isNotEmpty) user = AppUser.fromMap(q.docs.first.data());
              }
              if (user != null) {
                Navigator.push(context, MaterialPageRoute(builder: (_) => ChatPage(currentUser: widget.currentUser, otherUser: user!)));
              } else {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Impossible de charger l\'utilisateur')));
              }
            },
          );
        },
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    if (difference.inDays == 0) return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    if (difference.inDays == 1) return 'Hier';
    if (difference.inDays < 7) return '${difference.inDays} j. ago';
    return '${date.day}/${date.month}/${date.year}';
  }
}
