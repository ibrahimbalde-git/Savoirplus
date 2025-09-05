import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user.dart';
import '../constants.dart';
import '../widgets/custom_appbar.dart';
import 'edit_profile_page.dart';

class RegistrationPage extends StatefulWidget {
  final Function(AppUser) onRegister;
  final Function(Locale) onLocaleChange;

  const RegistrationPage({required this.onRegister, required this.onLocaleChange, Key? key}) : super(key: key);

  @override
  State<RegistrationPage> createState() => _RegistrationPageState();
}

class _RegistrationPageState extends State<RegistrationPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();
  final _descriptionCtrl = TextEditingController();

  String? _photoBase64;
  bool _loading = false;

  String? _selectedCountry;
  List<String> _selectedLanguages = [];
  List<String> _selectedSkillsOffered = [];
  List<String> _selectedSkillsWanted = [];
  String? _selectedAvailability;

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
    if (picked != null) {
      final bytes = await File(picked.path).readAsBytes();
      setState(() {
        _photoBase64 = base64Encode(bytes);
      });
    }
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCountry == null || _selectedAvailability == null || _selectedLanguages.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Veuillez sélectionner pays, disponibilité et langues.")),
      );
      return;
    }

    setState(() => _loading = true);

    try {
      final cred = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailCtrl.text.trim(),
        password: _passwordCtrl.text.trim(),
      );

      // ⚡ Envoi email de confirmation
      await cred.user!.sendEmailVerification();

      final uid = cred.user!.uid;

      await FirebaseFirestore.instance.collection('users').doc(uid).set({
        'email': _emailCtrl.text.trim(),
        'name': _nameCtrl.text.trim(),
        'country': _selectedCountry,
        'spokenLanguages': _selectedLanguages,
        'skillsOffered': _selectedSkillsOffered,
        'skillsWanted': _selectedSkillsWanted,
        'description': _descriptionCtrl.text.trim(),
        'availability': _selectedAvailability != null ? [_selectedAvailability!] : [],
        'photoUrl': _photoBase64 ?? '',
        'createdAt': FieldValue.serverTimestamp(),
        'rating': 0.0,
      });

      final appUser = AppUser(
        id: uid,
        email: _emailCtrl.text.trim(),
        name: _nameCtrl.text.trim(),
        country: _selectedCountry ?? '',
        spokenLanguages: _selectedLanguages,
        skillsOffered: _selectedSkillsOffered,
        skillsWanted: _selectedSkillsWanted,
        description: _descriptionCtrl.text.trim(),
        availability: _selectedAvailability != null ? [_selectedAvailability!] : [],
        photoUrl: _photoBase64 ?? '',
        rating: 0.0,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Compte créé ! Veuillez vérifier votre email.")),
      );

      widget.onRegister(appUser);

    } on FirebaseAuthException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Erreur Firebase: ${e.code} - ${e.message}")),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Erreur inattendue: $e")),
      );
    } finally {
      setState(() => _loading = false);
    }
  }

  Widget _chipsFromList(List<String> source, List<String> selected, void Function(String, bool) onToggle) {
    return Wrap(
      spacing: 8,
      children: source.map((item) {
        final isSel = selected.contains(item);
        return FilterChip(
          label: Text(item),
          selected: isSel,
          onSelected: (sel) => onToggle(item, sel),
        );
      }).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context);

    return Scaffold(
      appBar: CustomAppBar(title: 'Créer un compte', showBackButton: true),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              DropdownButton<Locale>(
                value: locale,
                items: const [
                  DropdownMenuItem(child: Text('Français'), value: Locale('fr')),
                  DropdownMenuItem(child: Text('English'), value: Locale('en')),
                ],
                onChanged: (l) {
                  if (l != null) widget.onLocaleChange(l);
                },
              ),
              const SizedBox(height: 8),
              if (_photoBase64 != null)
                Center(child: CircleAvatar(radius: 40, backgroundImage: MemoryImage(base64Decode(_photoBase64!)))),
              TextButton.icon(
                onPressed: _pickImage,
                icon: const Icon(Icons.photo),
                label: const Text("Choisir une photo"),
              ),
              TextFormField(
                controller: _nameCtrl,
                decoration: const InputDecoration(labelText: 'Nom complet'),
                validator: (v) => v != null && v.trim().isNotEmpty ? null : 'Nom requis',
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _emailCtrl,
                decoration: const InputDecoration(labelText: 'Email'),
                keyboardType: TextInputType.emailAddress,
                validator: (v) => v != null && v.contains('@') ? null : 'Email invalide',
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _passwordCtrl,
                decoration: const InputDecoration(labelText: 'Mot de passe'),
                obscureText: true,
                validator: (v) => v != null && v.length >= 6 ? null : 'Min 6 caractères',
              ),
              const SizedBox(height: 16),
              const Text('Pays *', style: TextStyle(fontWeight: FontWeight.bold)),
              DropdownButtonFormField<String>(
                value: _selectedCountry,
                hint: const Text('Choisir un pays'),
                items: countriesList.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                onChanged: (v) => setState(() => _selectedCountry = v),
                validator: (v) => v == null ? 'Choisir un pays' : null,
              ),
              const SizedBox(height: 12),
              const Text('Langues parlées *', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              _chipsFromList(languagesList, _selectedLanguages, (item, sel) {
                setState(() {
                  if (sel) _selectedLanguages.add(item);
                  else _selectedLanguages.remove(item);
                });
              }),
              const SizedBox(height: 12),
              const Text('Compétences à offrir', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              _chipsFromList(skillsList, _selectedSkillsOffered, (item, sel) {
                setState(() {
                  if (sel) _selectedSkillsOffered.add(item);
                  else _selectedSkillsOffered.remove(item);
                });
              }),
              const SizedBox(height: 12),
              const Text('Compétences recherchées', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              _chipsFromList(skillsList, _selectedSkillsWanted, (item, sel) {
                setState(() {
                  if (sel) _selectedSkillsWanted.add(item);
                  else _selectedSkillsWanted.remove(item);
                });
              }),
              const SizedBox(height: 12),
              const Text('Disponibilité *', style: TextStyle(fontWeight: FontWeight.bold)),
              DropdownButtonFormField<String>(
                value: _selectedAvailability,
                hint: const Text('Choisir disponibilité'),
                items: availabilitiesList.map((a) => DropdownMenuItem(value: a, child: Text(a))).toList(),
                onChanged: (v) => setState(() => _selectedAvailability = v),
                validator: (v) => v == null ? 'Choisir disponibilité' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _descriptionCtrl,
                decoration: const InputDecoration(labelText: 'Description'),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              _loading
                  ? const Center(child: CircularProgressIndicator())
                  : ElevatedButton(
                onPressed: _register,
                child: const Text("S'inscrire"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
