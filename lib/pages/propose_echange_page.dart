import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import '../models/user.dart';
import '../models/echange.dart';
import '../models/savoir.dart';
import '../widgets/custom_appbar.dart';

class ProposeEchangePage extends StatefulWidget {
  final Savoir savoir;
  final AppUser currentUser;

  const ProposeEchangePage({super.key, required this.savoir, required this.currentUser});

  @override
  State<ProposeEchangePage> createState() => _ProposeEchangePageState();
}

class _ProposeEchangePageState extends State<ProposeEchangePage> {

  Future<void> _submit() async {
    final newEchange = Echange(
      id: Uuid().v4(),
      savoirTitle: widget.savoir.title,
      proposerEmail: widget.currentUser.email, // reste interne, pas affiché
      receveurEmail: widget.savoir.offeredBy,  // reste interne, pas affiché
      dateProposition: DateTime.now(),
    );

    try {
      await FirebaseFirestore.instance
          .collection('echanges')
          .doc(newEchange.id)
          .set(newEchange.toMap());

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Proposition d’échange envoyée avec succès !')),
      );
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur lors de l’envoi : $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: 'Échange : ${widget.savoir.title}',
        showBackButton: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Vous proposez un échange pour le savoir :',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              widget.savoir.title,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Text(
              'Ce savoir est proposé par :',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            // ⚡ Affiche uniquement le nom, jamais l'email
            Text(
              widget.savoir.offererName ?? 'Utilisateur',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const Spacer(),
            Center(
              child: ElevatedButton.icon(
                icon: const Icon(Icons.send),
                label: const Text('Envoyer la proposition'),
                onPressed: _submit,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  textStyle: const TextStyle(fontSize: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
