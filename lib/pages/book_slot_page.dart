import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../models/user.dart';
import '../models/availability_slot.dart';

class BookSlotPage extends StatefulWidget {
  final AppUser currentUser;
  final String currentUserId; // uid du user connecté

  const BookSlotPage({
    Key? key,
    required this.currentUser,
    required this.currentUserId,
  }) : super(key: key);

  @override
  State<BookSlotPage> createState() => _BookSlotPageState();
}

class _BookSlotPageState extends State<BookSlotPage> {
  final _emailCtrl = TextEditingController();
  String? _ownerUid; // uid de la personne à réserver
  DateTime _selectedDay = DateTime.now();
  final _messageCtrl = TextEditingController();

  Future<void> _findOwnerByEmail() async {
    final email = _emailCtrl.text.trim();
    if (email.isEmpty) return;

    final q = await FirebaseFirestore.instance
        .collection('users')
        .where('email', isEqualTo: email)
        .limit(1)
        .get();

    if (q.docs.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Utilisateur introuvable.')));
      return;
    }
    setState(() => _ownerUid = q.docs.first.id);
  }

  Future<List<AvailabilitySlot>> _loadSlotsOfOwnerForDay(String ownerId, DateTime day) async {
    final dateStart = DateTime(day.year, day.month, day.day);
    final dateEnd = dateStart.add(const Duration(days: 1));

    final snap = await FirebaseFirestore.instance
        .collection('users')
        .doc(ownerId)
        .collection('availability')
        .where('date', isGreaterThanOrEqualTo: dateStart)
        .where('date', isLessThan: dateEnd)
        .orderBy('date')
        .get();

    return snap.docs.map((d) => AvailabilitySlot.fromMap(d.id, d.data())).toList();
  }

  Future<void> _requestBooking(AvailabilitySlot slot) async {
    if (_ownerUid == null) return;

    final meetings = FirebaseFirestore.instance.collection('meetings').doc();
    await meetings.set({
      'slotOwnerId': _ownerUid,
      'requesterId': widget.currentUserId,
      'slotId': slot.id,
      'status': 'pending',
      'message': _messageCtrl.text.trim(),
      'createdAt': FieldValue.serverTimestamp(),
    });

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Demande envoyée ✅')));
  }

  Future<void> _pickDay() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDay,
      firstDate: DateTime.now().subtract(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 180)),
    );
    if (picked != null) {
      setState(() => _selectedDay = picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    final dayLabel =
        "${_selectedDay.day.toString().padLeft(2, '0')}/${_selectedDay.month.toString().padLeft(2, '0')}/${_selectedDay.year}";

    return Scaffold(
      appBar: AppBar(title: const Text('Réserver un créneau')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _emailCtrl,
              decoration: const InputDecoration(
                labelText: "Email de l'utilisateur à contacter",
                prefixIcon: Icon(Icons.search),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                ElevatedButton.icon(
                  onPressed: _findOwnerByEmail,
                  icon: const Icon(Icons.person_search),
                  label: const Text('Rechercher'),
                ),
                const SizedBox(width: 12),
                if (_ownerUid != null)
                  Chip(label: Text('Cible trouvée')),
              ],
            ),
            const Divider(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('Jour : $dayLabel', style: const TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(width: 12),
                OutlinedButton.icon(
                  onPressed: _pickDay,
                  icon: const Icon(Icons.calendar_today),
                  label: const Text('Changer'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _messageCtrl,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'Message (optionnel)',
                hintText: 'Présente brièvement ta demande…',
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: _ownerUid == null
                  ? const Center(child: Text('Renseigne un email et recherche.'))
                  : FutureBuilder<List<AvailabilitySlot>>(
                future: _loadSlotsOfOwnerForDay(_ownerUid!, _selectedDay),
                builder: (_, snap) {
                  if (snap.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final slots = snap.data ?? [];
                  if (slots.isEmpty) {
                    return const Center(child: Text('Aucun créneau dispo ce jour.'));
                  }
                  return ListView.builder(
                    itemCount: slots.length,
                    itemBuilder: (_, i) {
                      final s = slots[i];
                      return Card(
                        child: ListTile(
                          title: Text("${s.start} → ${s.end} • ${s.mode}"),
                          subtitle: Text(s.location.isNotEmpty ? s.location : (s.notes.isNotEmpty ? s.notes : '')),
                          trailing: ElevatedButton(
                            onPressed: () => _requestBooking(s),
                            child: const Text('Demander'),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
