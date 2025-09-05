import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/savoir.dart';
import '../models/user.dart';

import 'add_savoir_page.dart';
import 'explore_savoirs_page.dart';

class HomePage extends StatefulWidget {
  final AppUser user;

  const HomePage({required this.user, Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<Savoir> _allSavoirs = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSavoirsFromFirestore();
  }

  Future<void> _loadSavoirsFromFirestore() async {
    try {
      final snapshot =
      await FirebaseFirestore.instance.collection('savoirs').get();

      final data = snapshot.docs.map((doc) {
        final map = doc.data();
        return Savoir.fromMap(map);
      }).toList();

      setState(() {
        _allSavoirs = data;
        _isLoading = false;
      });
    } catch (e) {
      print('Erreur chargement Firebase : $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _logout() async {
    await FirebaseAuth.instance.signOut();
    // Ici, tu peux naviguer vers la page login ou la remplacer
    Navigator.pushReplacementNamed(context, '/login');
  }

  @override
  Widget build(BuildContext context) {
    final recentSavoirs =
    _allSavoirs.where((s) => s.dateAdded != null).toList()
      ..sort((a, b) => b.dateAdded!.compareTo(a.dateAdded!));
    final displayedRecent = recentSavoirs.take(5).toList();

    final popularSavoirs = _allSavoirs.toList()
      ..sort((a, b) => (b.popularity ?? 0).compareTo(a.popularity ?? 0));
    final displayedPopular = popularSavoirs.take(5).toList();

    return Scaffold(
      appBar: AppBar(
        elevation: 6,
        backgroundColor: Colors.teal,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            bottom: Radius.circular(24),
          ),
        ),
        title: const Text(
          "Savoir+",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            tooltip: "Rechercher",
            icon: const Icon(Icons.search),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Recherche bientôt disponible !')),
              );
            },
          ),
          // IconButton pour le Profil supprimé
          IconButton(
            tooltip: "Se déconnecter",
            icon: const Icon(Icons.logout),
            onPressed: _logout,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              'Échangez vos savoirs.\nCréez du lien.\nGratuitement.',
              textAlign: TextAlign.center,
              style: Theme.of(context)
                  .textTheme
                  .headlineMedium
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            const Text(
              'Share your knowledge. Build connections. For free.',
              style: TextStyle(fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              alignment: WrapAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            ExploreSavoirsPage(currentUser: widget.user),
                      ),
                    );
                  },
                  child: const Text('Explorer les savoirs'),
                ),
                OutlinedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => AddSavoirPage(user: widget.user),
                      ),
                    );
                  },
                  child: const Text('Proposer un savoir'),
                ),
                ElevatedButton(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('Communauté bientôt disponible !')),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white),
                  child: const Text('Rejoindre la communauté'),
                ),
              ],
            ),
            const SizedBox(height: 40),
            Text('Comment ça marche ?',
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _stepCard(Icons.person_add, 'Créez votre profil',
                    'Create your profile'),
                _stepCard(Icons.search, 'Trouvez une personne',
                    'Find someone'),
                _stepCard(Icons.handshake, 'Échangez un savoir',
                    'Exchange knowledge'),
              ],
            ),
            const SizedBox(height: 40),
            if (displayedRecent.isNotEmpty) ...[
              Text('Savoirs récents',
                  style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 10),
              _buildSavoirList(displayedRecent),
              const SizedBox(height: 30),
            ],
            if (displayedPopular.isNotEmpty) ...[
              Text('Savoirs populaires',
                  style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 10),
              _buildSavoirList(displayedPopular),
            ],
          ],
        ),
      ),
    );
  }

  Widget _stepCard(IconData icon, String title, String subtitle) {
    return Column(
      children: [
        CircleAvatar(
          radius: 30,
          backgroundColor: Colors.teal.shade100,
          child: Icon(icon, size: 30, color: Colors.teal),
        ),
        const SizedBox(height: 10),
        Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        Text(subtitle, style: const TextStyle(color: Colors.grey)),
      ],
    );
  }

  Widget _buildSavoirList(List<Savoir> savoirs) {
    return Column(
      children: savoirs.map((s) {
        return Card(
          elevation: 3,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          margin: const EdgeInsets.symmetric(vertical: 6),
          child: ListTile(
            leading: const Icon(Icons.book, color: Colors.teal),
            title: Text(s.title),
            subtitle: Text(
                '${s.category} - Proposé par ${s.offererName?.isNotEmpty == true ? s.offererName : "Utilisateur inconnu"}'),
          ),
        );
      }).toList(),
    );
  }
}
