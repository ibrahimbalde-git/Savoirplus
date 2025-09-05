import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import '../models/message.dart';
import '../models/user.dart';
import '../widgets/custom_appbar.dart';
import 'package:jitsi_meet_flutter_sdk/jitsi_meet_flutter_sdk.dart';
import './user_profile_page.dart';

class ChatPage extends StatefulWidget {
  final AppUser currentUser;
  final AppUser otherUser;

  const ChatPage({
    required this.currentUser,
    required this.otherUser,
    Key? key,
  }) : super(key: key);

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final TextEditingController _controller = TextEditingController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final ScrollController _scrollController = ScrollController();
  final _jitsiMeet = JitsiMeet();

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _sendTextMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    final newId = Uuid().v4();
    final message = Message(
      id: newId,
      fromUserEmail: widget.currentUser.email,
      toUserEmail: widget.otherUser.email,
      content: text,
      type: 'text',
      isRead: false,
      timestamp: DateTime.now(),
      participants: [widget.currentUser.email, widget.otherUser.email],
    );

    await _firestore.collection('messages').doc(newId).set(message.toMap());
    _controller.clear();
    _scrollToBottom();
  }

  Stream<List<Message>> _messageStream() {
    return _firestore
        .collection('messages')
        .where('participants', arrayContains: widget.currentUser.email)
        .orderBy('timestamp')
        .snapshots()
        .map((snap) {
      try {
        return snap.docs
            .map((d) => Message.fromMap(d.data() as Map<String, dynamic>))
            .where((m) =>
        (m.fromUserEmail == widget.currentUser.email &&
            m.toUserEmail == widget.otherUser.email) ||
            (m.fromUserEmail == widget.otherUser.email &&
                m.toUserEmail == widget.currentUser.email))
            .toList();
      } catch (e) {
        print("Erreur conversion Message: $e");
        return [];
      }
    });
  }

  void _markAsRead(Message msg) {
    if (msg.id.isEmpty) return;
    if (msg.toUserEmail == widget.currentUser.email && !msg.isRead) {
      _firestore.collection('messages').doc(msg.id).update({'isRead': true});
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Widget _buildMessageWidget(Message msg) {
    if (msg.type == "system") {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Center(
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.green.shade100,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              msg.content,
              style: const TextStyle(
                fontSize: 14,
                fontStyle: FontStyle.italic,
                color: Colors.black87,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }

    final isMe = msg.fromUserEmail == widget.currentUser.email;
    final bubbleColor = isMe ? Colors.indigo.shade200 : Colors.grey.shade300;
    final textColor = Colors.black87;

    if (!isMe) _markAsRead(msg);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment:
        isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMe)
            CircleAvatar(
              radius: 16,
              child: Text(widget.otherUser.name[0]),
            ),
          if (!isMe) const SizedBox(width: 8),
          Flexible(
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: bubbleColor,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: Radius.circular(isMe ? 16 : 4),
                  bottomRight: Radius.circular(isMe ? 4 : 16),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(13),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Flexible(
                    child: Text(
                      msg.content,
                      style: TextStyle(color: textColor, fontSize: 16),
                    ),
                  ),
                  if (isMe) const SizedBox(width: 6),
                  if (isMe)
                    Icon(
                      msg.isRead ? Icons.done_all : Icons.check,
                      size: 18,
                      color: msg.isRead ? Colors.blue : Colors.black45,
                    ),
                ],
              ),
            ),
          ),
          if (isMe) const SizedBox(width: 8),
          if (isMe)
            CircleAvatar(
              radius: 16,
              child: Text(widget.currentUser.name[0]),
            ),
        ],
      ),
    );
  }

  void _notAvailable(String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("$feature bientôt disponible !")),
    );
  }

  String _generateRoomName() {
    List<String> emails = [widget.currentUser.email, widget.otherUser.email];
    emails.sort();
    String rawName = emails.join('-');
    return rawName.replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_');
  }

  Future<void> _joinJitsiConference({bool audioOnly = false}) async {
    final roomName = _generateRoomName();
    try {
      final options = JitsiMeetConferenceOptions(
        room: roomName,
        userInfo: JitsiMeetUserInfo(
          displayName: widget.currentUser.name,
          email: widget.currentUser.email,
          avatar:
          widget.currentUser.photoUrl.isNotEmpty ? widget.currentUser.photoUrl : null,
        ),
        configOverrides: {
          "startWithVideoMuted": audioOnly,
          "startWithAudioMuted": false,
        },
        featureFlags: {
          "chat.enabled": true,
          "invite.enabled": true,
          "raise-hand.enabled": true,
          "live-streaming.enabled": false,
          "recording.enabled": false,
          "ios.screensharing.enabled": true,
          "lobby-mode.enabled": false,
          "welcomepage.enabled": false,
          "tile-view.enabled": true,
        },
      );
      await _jitsiMeet.join(options);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Erreur pour rejoindre la conférence: $error")),
      );
    }
  }

  void _startVideoCall() => _notAvailable("Les appels vidéo");
  void _startAudioCall() => _notAvailable("Les appels audio");

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: widget.otherUser.name,
        actions: [
          IconButton(
            icon: const Icon(Icons.videocam),
            onPressed: _startVideoCall,
            color: Colors.white,
          ),
          IconButton(
            icon: const Icon(Icons.call),
            onPressed: _startAudioCall,
            color: Colors.white,
          ),
          IconButton(
            icon: const Icon(Icons.info),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => UserProfilePage(
                    user: widget.otherUser, // ✅ Ajouté
                  ),
                ),
              );
            },
            color: Colors.white,
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<List<Message>>(
              stream: _messageStream(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final messages = snapshot.data!;
                if (messages.isEmpty) {
                  return const Center(
                      child: Text("Aucun message pour le moment."));
                }
                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(12),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final msg = messages[index];
                    return _buildMessageWidget(msg);
                  },
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.image),
                  onPressed: () => _notAvailable("Envoi d'image"),
                  color: Colors.green,
                ),
                IconButton(
                  icon: const Icon(Icons.mic),
                  onPressed: () => _notAvailable("Enregistrement audio"),
                  color: Colors.red,
                ),
                IconButton(
                  icon: const Icon(Icons.attach_file),
                  onPressed: () => _notAvailable("Envoi de fichiers"),
                  color: Colors.orange,
                ),
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: const InputDecoration(
                      hintText: "Écrire un message...",
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: _sendTextMessage,
                  color: Colors.blue,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
