// lib/pages/explore_savoirs_page.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../models/savoir.dart';
import '../models/user.dart';
import '../constants.dart';
import 'propose_echange_page.dart';
import '../widgets/custom_appbar.dart'; // chemin correct vers ton CustomAppBar

class ExploreSavoirsPage extends StatefulWidget {
  final AppUser currentUser;
  const ExploreSavoirsPage({required this.currentUser, Key? key}) : super(key: key);

  @override
  State<ExploreSavoirsPage> createState() => _ExploreSavoirsPageState();
}

class _ExploreSavoirsPageState extends State<ExploreSavoirsPage> {
  List<Savoir> _allSavoirs = [];
  List<Savoir> _filteredSavoirs = [];
  String _searchText = '';
  String _selectedCategory = 'Toutes';

  @override
  void initState() {
    super.initState();
    _loadSavoirs();
  }

  void _loadSavoirs() async {
    final snapshot = await FirebaseFirestore.instance.collection('savoirs').get();
    final list = snapshot.docs.map((doc) => Savoir.fromMap(doc.data())).toList();
    setState(() {
      _allSavoirs = list;
      _filteredSavoirs = List.from(_allSavoirs);
    });
  }

  void _filter() {
    setState(() {
      _filteredSavoirs = _allSavoirs.where((s) {
        final matchesSearch = s.title.toLowerCase().contains(_searchText.toLowerCase());
        final matchesCategory = _selectedCategory == 'Toutes' || s.category == _selectedCategory;
        return matchesSearch && matchesCategory;
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(title: 'Explorer les savoirs', showBackButton: true),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            TextField(
              decoration: const InputDecoration(
                labelText: 'Recherche par titre',
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: (val) {
                _searchText = val;
                _filter();
              },
            ),
            const SizedBox(height: 10),
            DropdownButton<String>(
              value: _selectedCategory,
              items: categoriesList
                  .map((cat) => DropdownMenuItem(value: cat, child: Text(cat)))
                  .toList(),
              onChanged: (val) {
                if (val != null) {
                  _selectedCategory = val;
                  _filter();
                }
              },
            ),
            const SizedBox(height: 10),
            Expanded(
              child: _filteredSavoirs.isEmpty
                  ? const Center(child: Text('Aucun savoir trouvé'))
                  : ListView.builder(
                itemCount: _filteredSavoirs.length,
                itemBuilder: (_, i) {
                  final s = _filteredSavoirs[i];
                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 6),
                    child: ListTile(
                      title: Text(s.title),
                      subtitle: Text(
                        '${s.category} - Proposé par ${s.offererName?.isNotEmpty == true ? s.offererName : "Utilisateur inconnu"}',
                      ),
                      trailing: ElevatedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ProposeEchangePage(
                                savoir: s,
                                currentUser: widget.currentUser,
                              ),
                            ),
                          );
                        },
                        child: const Text('Proposer échange'),
                      ),
                    ),
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
