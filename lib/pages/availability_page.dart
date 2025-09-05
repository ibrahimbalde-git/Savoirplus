import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../models/user.dart';
import '../models/availability_slot.dart';

class AvailabilityPage extends StatefulWidget {
  final AppUser currentUser;
  final String currentUserId; // uid Firebase du user connecté

  const AvailabilityPage({
    Key? key,
    required this.currentUser,
    required this.currentUserId,
  }) : super(key: key);

  @override
  State<AvailabilityPage> createState() => _AvailabilityPageState();
}

class _AvailabilityPageState extends State<AvailabilityPage> {
  DateTime _selectedDay = DateTime.now();

  Future<List<AvailabilitySlot>> _loadSlotsForDay(DateTime day) async {
    final dateStart = DateTime(day.year, day.month, day.day);
    final dateEnd = dateStart.add(const Duration(days: 1));

    final snap = await FirebaseFirestore.instance
        .collection('users')
        .doc(widget.currentUserId)
        .collection('availability')
        .where('date', isGreaterThanOrEqualTo: dateStart)
        .where('date', isLessThan: dateEnd)
        .orderBy('date')
        .get();

    return snap.docs
        .map((d) => AvailabilitySlot.fromMap(d.id, d.data()))
        .toList();
  }

  Future<void> _addSlotDialog() async {
    final date = _selectedDay;
    final startCtrl = TextEditingController();
    final endCtrl = TextEditingController();
    String mode = 'En ligne';
    final locationCtrl = TextEditingController();
    final notesCtrl = TextEditingController();

    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Ajouter un créneau'),
        content: SingleChildScrollView(
          child: Column(
            children: [
              _TimeField(label: 'Début (HH:mm)', controller: startCtrl),
              const SizedBox(height: 8),
              _TimeField(label: 'Fin (HH:mm)', controller: endCtrl),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: mode,
                decoration: const InputDecoration(labelText: 'Mode'),
                items: const [
                  DropdownMenuItem(value: 'En ligne', child: Text('En ligne')),
                  DropdownMenuItem(value: 'Présentiel', child: Text('Présentiel')),
                ],
                onChanged: (v) => mode = v ?? 'En ligne',
              ),
              const SizedBox(height: 8),
              TextField(
                controller: locationCtrl,
                decoration: const InputDecoration(
                  labelText: 'Lieu (si présentiel)',
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: notesCtrl,
                maxLines: 2,
                decoration: const InputDecoration(labelText: 'Notes'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Annuler')),
          ElevatedButton(
            onPressed: () async {
              if (startCtrl.text.trim().isEmpty || endCtrl.text.trim().isEmpty) return;

              final slotDoc = FirebaseFirestore.instance
                  .collection('users')
                  .doc(widget.currentUserId)
                  .collection('availability')
                  .doc();

              await slotDoc.set({
                'date': DateTime(date.year, date.month, date.day),
                'start': startCtrl.text.trim(),
                'end': endCtrl.text.trim(),
                'mode': mode,
                'location': locationCtrl.text.trim(),
                'notes': notesCtrl.text.trim(),
                'createdAt': FieldValue.serverTimestamp(),
              });

              if (mounted) Navigator.pop(context);
              setState(() {}); // refresh
            },
            child: const Text('Ajouter'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteSlot(String slotId) async {
    await FirebaseFirestore.instance
        .collection('users')
        .doc(widget.currentUserId)
        .collection('availability')
        .doc(slotId)
        .delete();
    setState(() {});
  }

  Future<void> _pickDay() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDay,
      firstDate: DateTime.now().subtract(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
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
      appBar: AppBar(title: const Text('Mes créneaux')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addSlotDialog,
        icon: const Icon(Icons.add),
        label: const Text('Ajouter'),
      ),
      body: Column(
        children: [
          const SizedBox(height: 8),
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
          const Divider(),
          Expanded(
            child: FutureBuilder<List<AvailabilitySlot>>(
              future: _loadSlotsForDay(_selectedDay),
              builder: (_, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                final slots = snap.data ?? [];
                if (slots.isEmpty) {
                  return const Center(child: Text('Aucun créneau ce jour.'));
                }
                return ListView.builder(
                  itemCount: slots.length,
                  itemBuilder: (_, i) {
                    final s = slots[i];
                    return Card(
                      child: ListTile(
                        title: Text("${s.start} → ${s.end} • ${s.mode}"),
                        subtitle: Text(s.location.isNotEmpty ? s.location : (s.notes.isNotEmpty ? s.notes : '')),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete),
                          onPressed: () => _deleteSlot(s.id),
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
    );
  }
}

class _TimeField extends StatelessWidget {
  final String label;
  final TextEditingController controller;

  const _TimeField({required this.label, required this.controller, Key? key}) : super(key: key);

  Future<void> _pickTime(BuildContext context) async {
    final initial = TimeOfDay.now();
    final t = await showTimePicker(context: context, initialTime: initial);
    if (t != null) {
      controller.text = t.hour.toString().padLeft(2, '0') + ':' + t.minute.toString().padLeft(2, '0');
    }
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      readOnly: true,
      decoration: InputDecoration(
        labelText: label,
        suffixIcon: IconButton(
          icon: const Icon(Icons.access_time),
          onPressed: () => _pickTime(context),
        ),
      ),
    );
  }
}
