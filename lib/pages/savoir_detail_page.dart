import 'package:flutter/material.dart';
import '../models/savoir.dart';
import '../models/user.dart';
import '../widgets/custom_appbar.dart'; // <- Import CustomAppBar
import 'propose_echange_page.dart';

class SavoirDetailPage extends StatelessWidget {
  final Savoir savoir;
  final AppUser currentUser;

  const SavoirDetailPage({
    required this.savoir,
    required this.currentUser,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: CustomAppBar(
        title: savoir.title,
        showBackButton: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            Text(
              savoir.title,
              style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),

            _infoTile('Catégorie', savoir.category),
            _infoTile('Proposé par', savoir.offeredBy.isNotEmpty ? savoir.offeredBy : '?'),

            if (savoir.description.isNotEmpty) ...[
              const SizedBox(height: 10),
              Text('Description :', style: theme.textTheme.titleMedium),
              const SizedBox(height: 5),
              Text(savoir.description),
            ],

            if (savoir.dateAdded != null) ...[
              const SizedBox(height: 16),
              Text('Ajouté le : ${_formatDate(savoir.dateAdded!)}'),
            ],

            const SizedBox(height: 30),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ProposeEchangePage(
                      savoir: savoir,
                      currentUser: currentUser,
                    ),
                  ),
                );
              },
              icon: const Icon(Icons.swap_horiz),
              label: const Text('Proposer un échange'),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return date.toLocal().toString().split(' ')[0];
  }

  Widget _infoTile(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Text('$label : ', style: const TextStyle(fontWeight: FontWeight.bold)),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}
