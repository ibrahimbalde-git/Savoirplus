import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart'; // AJOUTÉ
import '../models/savoir.dart';
import '../models/user.dart';
import '../constants.dart'; // categoriesList & knowledgeByCategory viennent d'ici
import '../widgets/custom_appbar.dart'; // <-- Import du CustomAppBar

class AddSavoirPage extends StatefulWidget {
  final AppUser user;
  const AddSavoirPage({required this.user, Key? key}) : super(key: key);

  @override
  State<AddSavoirPage> createState() => _AddSavoirPageState();
}

class _AddSavoirPageState extends State<AddSavoirPage> {
  final _formKey = GlobalKey<FormState>();

  String? _selectedTitle;
  String? _category;
  String _description = '';

  List<String> _availableTitles = [];

  void _saveSavoir() async {
    if (_formKey.currentState?.validate() ?? false) {
      _formKey.currentState!.save();

      if (_category == null) {
        if (!mounted) return;
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Veuillez choisir une catégorie')));
        return;
      }
      if (_selectedTitle == null) {
        if (!mounted) return;
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Veuillez choisir un titre')));
        return;
      }

      final savoirId = const Uuid().v4(); // Générer un ID unique

      final newSavoir = Savoir(
        id: savoirId, // Fournir l'ID généré
        title: _selectedTitle!,
        category: _category!,
        description: _description,
        offeredBy: widget.user.email, // CORRIGÉ: Utiliser l'email (ou ID) pour offeredBy
        offererName: widget.user.name, // NOUVEAU: Fournir le nom de l'utilisateur
        dateAdded: DateTime.now(),
        // popularity est déjà initialisé à 0 par défaut dans le modèle
      );

      try {
        await FirebaseFirestore.instance
            .collection('savoirs')
            .doc(newSavoir.id) // Utiliser .doc(id).set()
            .set(newSavoir.toMap());

        if (!mounted) return;
        Navigator.pop(context);
        if (!mounted) return;
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Savoir ajouté avec succès !')));
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Erreur lors de l'ajout du savoir : $e")), // CORRIGÉ ICI
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final creatableCategories = categoriesList.where((c) => c != 'Toutes').toList();

    return Scaffold(
      appBar: CustomAppBar(
        title: 'Proposer un savoir',
        showBackButton: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            tooltip: 'Aide',
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Remplissez les champs pour proposer un savoir à la communauté !'),
                ),
              );
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(labelText: 'Catégorie'),
                items: creatableCategories
                    .map((cat) => DropdownMenuItem(value: cat, child: Text(cat)))
                    .toList(),
                initialValue: _category, // CORRIGÉ ICI
                onChanged: (val) {
                  setState(() {
                    _category = val;
                    _selectedTitle = null;
                    // Utilisation de knowledgeByCategory (que vous avez mentionné provenir de constants.dart)
                    if (val != null && knowledgeByCategory.containsKey(val)) {
                      _availableTitles = knowledgeByCategory[val]!; // CORRIGÉ ICI (cast enlevé)
                    } else {
                      _availableTitles = [];
                    }
                  });
                },
                validator: (val) => val == null || val.isEmpty ? 'Ce champ est requis' : null,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(labelText: 'Titre du savoir'),
                items: _availableTitles
                    .map((title) => DropdownMenuItem(value: title, child: Text(title)))
                    .toList(),
                initialValue: _selectedTitle, // CORRIGÉ ICI
                onChanged: (val) {
                  setState(() {
                    _selectedTitle = val;
                  });
                },
                validator: (val) => val == null || val.isEmpty ? 'Ce champ est requis' : null,
                hint: Text(
                  _category == null
                      ? 'Choisissez d\'abord une catégorie'
                      : _availableTitles.isEmpty
                      ? 'Aucun titre pour cette catégorie'
                      : 'Sélectionnez un titre',
                ),
                disabledHint: Text(_category == null
                    ? 'Choisissez d\'abord une catégorie'
                    : 'Aucun titre pour cette catégorie'),
              ),
              const SizedBox(height: 16),
              TextFormField(
                decoration: const InputDecoration(labelText: 'Description'),
                onSaved: (val) => _description = val ?? '',
                maxLines: 5,
                validator: (val) => val == null || val.isEmpty ? 'Ce champ est requis' : null,
              ),
              const SizedBox(height: 24),
              ElevatedButton(onPressed: _saveSavoir, child: const Text('Ajouter le savoir')),
            ],
          ),
        ),
      ),
    );
  }
}
