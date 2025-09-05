import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user.dart';
import '../models/echange.dart';
import 'conversations_Page.dart';
import 'chat_Page.dart';
import '../widgets/icon_with_badge.dart';

class EchangesPage extends StatefulWidget {
  final AppUser currentUser;
  const EchangesPage({required this.currentUser, Key? key}) : super(key: key);

  @override
  State<EchangesPage> createState() => _EchangesPageState();
}

class _EchangesPageState extends State<EchangesPage> {
  List<Echange> _echanges = [];

  @override
  void initState() {
    super.initState();
    _loadEchanges();
  }

  Future<void> _loadEchanges() async {
    try {
      final snapshot = await FirebaseFirestore.instance.collection('echanges').get();
      final list = snapshot.docs.map((doc) => Echange.fromMap(doc.data())).toList();
      if (mounted) {
        setState(() {
          _echanges = list;
        });
      }
    } catch (e) {
      print('Erreur Firestore lors du chargement des échanges : $e');
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur Firestore : $e')));
    }
  }

  Future<void> _updateEchange(Echange echange, String newStatus) async {
    try {
      final ref = FirebaseFirestore.instance.collection('echanges').doc(echange.id);
      echange.status = newStatus;
      echange.dateReponse = DateTime.now();
      await ref.set(echange.toMap());

      if (newStatus == 'accepté') {
        final otherUserEmail = echange.proposerEmail == widget.currentUser.email
            ? echange.receveurEmail
            : echange.proposerEmail;

        final existingMessagesQuery = await FirebaseFirestore.instance
            .collection('messages')
            .where('participants', arrayContains: widget.currentUser.email)
            .get();

        final exists = existingMessagesQuery.docs.any((doc) {
          final data = doc.data();
          final participants = List<String>.from(data['participants'] ?? []);
          return participants.contains(widget.currentUser.email) && participants.contains(otherUserEmail);
        });

        if (!exists) {
          await FirebaseFirestore.instance.collection('messages').add({
            "fromUserEmail": widget.currentUser.email,
            "toUserEmail": otherUserEmail,
            "content": "Vous pouvez maintenant discuter suite à l'échange accepté.",
            "timestamp": FieldValue.serverTimestamp(),
            "isRead": false,
            "participants": [widget.currentUser.email, otherUserEmail],
          });
        }

        final otherUser = await _getUserByEmail(otherUserEmail);
        if (otherUser != null && mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ChatPage(currentUser: widget.currentUser, otherUser: otherUser),
            ),
          );
        }
      }

      await _loadEchanges();
    } catch (e) {
      print('Erreur Firestore lors de la mise à jour d échange : $e');
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur Firestore : $e')));
    }
  }

  Future<AppUser?> _getUserByEmail(String email) async {
    try {
      final q = await FirebaseFirestore.instance
          .collection('users')
          .where('email', isEqualTo: email)
          .limit(1)
          .get();
      if (q.docs.isNotEmpty) {
        return AppUser.fromMap(q.docs.first.data());
      }
      return null;
    } catch (e) {
      print('Erreur Firestore lors de la récupération utilisateur : $e');
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final proposesRecus = _echanges
        .where((e) => e.receveurEmail == widget.currentUser.email && e.status == 'proposé')
        .toList();
    final historique = _echanges
        .where((e) =>
    (e.proposerEmail == widget.currentUser.email || e.receveurEmail == widget.currentUser.email) &&
        e.status != 'proposé')
        .toList();

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          elevation: 6,
          backgroundColor: Colors.teal,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
          ),
          centerTitle: true,
          title: const Text(
            'Mes échanges',
            style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.1),
          ),
          bottom: TabBar(
            tabs: [
              Tab(
                child: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('echanges')
                      .where('receveurEmail', isEqualTo: widget.currentUser.email)
                      .where('status', isEqualTo: 'proposé')
                      .snapshots(),
                  builder: (context, snapshot) {
                    int count = 0;
                    if (snapshot.hasData) count = snapshot.data!.docs.length;
                    return IconWithBadge(iconData: Icons.inbox, notificationCount: count);
                  },
                ),
              ),
              const Tab(icon: Icon(Icons.history)),
              Tab(
                child: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('messages')
                      .where('participants', arrayContains: widget.currentUser.email)
                      .where('isRead', isEqualTo: false)
                      .snapshots(),
                  builder: (context, snapshot) {
                    int count = 0;
                    if (snapshot.hasData) {
                      final unreadDocs = snapshot.data!.docs.where((doc) {
                        final data = doc.data() as Map<String, dynamic>?;
                        return data != null && data['fromUserEmail'] != widget.currentUser.email;
                      }).toList();
                      count = unreadDocs.length;
                    }
                    return IconWithBadge(iconData: Icons.message, notificationCount: count);
                  },
                ),
              ),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            // Propositions reçues
            ListView.builder(
              itemCount: proposesRecus.length,
              itemBuilder: (_, i) {
                final echange = proposesRecus[i];
                return FutureBuilder<AppUser?>(
                  future: _getUserByEmail(echange.proposerEmail),
                  builder: (context, snapshot) {
                    final proposerName = snapshot.hasData ? snapshot.data!.name : 'Utilisateur';
                    return Card(
                      child: ListTile(
                        title: Text(echange.savoirTitle),
                        subtitle: Text('Proposé par: $proposerName\nLe: ${echange.dateProposition.toLocal()}'),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                                icon: const Icon(Icons.check, color: Colors.green),
                                onPressed: () => _updateEchange(echange, 'accepté')),
                            IconButton(
                                icon: const Icon(Icons.close, color: Colors.red),
                                onPressed: () => _updateEchange(echange, 'refusé')),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),

            // Historique
            ListView.builder(
              itemCount: historique.length,
              itemBuilder: (_, i) {
                final echange = historique[i];
                final isAccepted = echange.status == 'accepté';
                final otherUserEmail =
                echange.proposerEmail == widget.currentUser.email ? echange.receveurEmail : echange.proposerEmail;

                return FutureBuilder<AppUser?>(
                  future: _getUserByEmail(otherUserEmail),
                  builder: (context, snapshot) {
                    final otherUserName = snapshot.hasData ? snapshot.data!.name : 'Utilisateur';
                    if (!snapshot.hasData && snapshot.connectionState == ConnectionState.waiting)
                      return const ListTile(title: Text('Chargement utilisateur...'));
                    if (snapshot.hasError || snapshot.data == null)
                      return const ListTile(title: Text('Infos indisponibles'));

                    return Card(
                      child: ListTile(
                        title: Text(echange.savoirTitle),
                        subtitle: Text(
                          'Avec: $otherUserName\nStatut: ${echange.status}\nDate réponse: ${echange.dateReponse?.toLocal() ?? '-'}',
                        ),
                        trailing: isAccepted
                            ? ElevatedButton(
                          child: const Text('Discuter'),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    ChatPage(currentUser: widget.currentUser, otherUser: snapshot.data!),
                              ),
                            );
                          },
                        )
                            : null,
                      ),
                    );
                  },
                );
              },
            ),

            // Conversations
            ConversationsPage(currentUser: widget.currentUser),
          ],
        ),
      ),
    );
  }
}
