import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user.dart';
import '../constants.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../widgets/custom_appbar.dart';

class EditProfilePage extends StatefulWidget {
  final AppUser user;
  final bool isGoogleUser; // ⚡ Flag pour utilisateurs Google

  const EditProfilePage({required this.user, this.isGoogleUser = false, Key? key}) : super(key: key);

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  late TextEditingController nameController;
  late TextEditingController descriptionController;
  late TextEditingController passwordController;

  final List<String> _countries = countriesList;
  final List<String> _languages = languagesList;
  final List<String> _skills = skillsList;
  final List<String> _availabilities = availabilitiesList;

  String? _selectedCountry;
  List<String> _selectedAvailability = [];
  List<String> _selectedLanguages = [];
  List<String> _selectedSkillsOffered = [];
  List<String> _selectedSkillsWanted = [];
  String? _photoUrl;
  File? _pickedImage;

  bool _saving = false;

  @override
  void initState() {
    super.initState();
    nameController = TextEditingController(text: widget.user.name);
    descriptionController = TextEditingController(text: widget.user.description);
    passwordController = TextEditingController();

    _selectedCountry = widget.user.country.isNotEmpty ? widget.user.country : null;
    _selectedAvailability = List.from(widget.user.availability);
    _selectedLanguages = List.from(widget.user.spokenLanguages);
    _selectedSkillsOffered = List.from(widget.user.skillsOffered);
    _selectedSkillsWanted = List.from(widget.user.skillsWanted);
    _photoUrl = widget.user.photoUrl;
  }

  @override
  void dispose() {
    nameController.dispose();
    descriptionController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    // ⚠ Flutter Web ne supporte pas `dart:io`, mais ImagePicker fonctionne
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() {
        _photoUrl = picked.path; // ⚠ Web : URL temporaire
        _pickedImage = File(picked.path); // ⚠ Web ignore ce File
      });
    }
  }

  Future<void> _saveProfile() async {
    if (_selectedCountry == null || _selectedAvailability.isEmpty || _selectedLanguages.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Veuillez sélectionner pays, disponibilité et langues.")),
      );
      return;
    }

    setState(() => _saving = true);

    final updatedUser = widget.user.copyWith(
      name: nameController.text.trim(),
      country: _selectedCountry!,
      availability: _selectedAvailability,
      spokenLanguages: _selectedLanguages,
      skillsOffered: _selectedSkillsOffered,
      skillsWanted: _selectedSkillsWanted,
      description: descriptionController.text.trim(),
      photoUrl: _photoUrl,
      // L'email n'est pas inclus ici car il ne doit pas être modifié
      // Si votre modèle AppUser l'exige dans copyWith, assurez-vous de passer widget.user.email
    );

    try {
      final userRef = FirebaseFirestore.instance.collection('users').doc(updatedUser.id);
      await userRef.set(updatedUser.toMap(), SetOptions(merge: true));

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Profil mis à jour avec succès !")),
      );
      Navigator.pop(context, updatedUser);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Erreur lors de la mise à jour : $e")),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(title: 'Modifier le profil', showBackButton: true),
      body: _saving
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Stack(
                children: [
                  CircleAvatar(
                    radius: 60,
                    backgroundImage: _photoUrl != null
                        ? NetworkImage(_photoUrl!) as ImageProvider
                        : const AssetImage('assets/avatar_placeholder.png'),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: InkWell(
                      onTap: _pickImage,
                      child: const CircleAvatar(
                        radius: 20,
                        backgroundColor: Colors.blue,
                        child: Icon(Icons.camera_alt, color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            _buildTextField('Nom', nameController),

            const SizedBox(height: 8),
            // Email (non modifiable)
            TextFormField(
              initialValue: widget.user.email,
              decoration: const InputDecoration(labelText: 'Email'),
              readOnly: true, // Toujours en lecture seule
            ),

            // Mot de passe seulement si pas Google
            if (!widget.isGoogleUser) ...[
              const SizedBox(height: 8),
              _buildTextField('Mot de passe', passwordController, obscureText: true),
            ],

            const SizedBox(height: 16),
            const Text('Pays *', style: TextStyle(fontWeight: FontWeight.bold)),
            DropdownButton<String>(
              value: _selectedCountry,
              isExpanded: true,
              hint: const Text('Choisir un pays'),
              items: _countries.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
              onChanged: (val) => setState(() => _selectedCountry = val),
            ),
            const SizedBox(height: 16),

            const Text('Disponibilités *', style: TextStyle(fontWeight: FontWeight.bold)),
            Wrap(
              spacing: 8,
              children: _availabilities.map((a) {
                final selected = _selectedAvailability.contains(a);
                return FilterChip(
                  label: Text(a),
                  selected: selected,
                  onSelected: (bool selectedValue) {
                    setState(() {
                      if (selectedValue) {
                        _selectedAvailability.add(a);
                      } else {
                        _selectedAvailability.remove(a);
                      }
                    });
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 16),

            const Text('Langues parlées *', style: TextStyle(fontWeight: FontWeight.bold)),
            Wrap(
              spacing: 8,
              children: _languages.map((lang) {
                final selected = _selectedLanguages.contains(lang);
                return FilterChip(
                  label: Text(lang),
                  selected: selected,
                  onSelected: (bool selectedValue) {
                    setState(() {
                      if (selectedValue) {
                        _selectedLanguages.add(lang);
                      } else {
                        _selectedLanguages.remove(lang);
                      }
                    });
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 16),

            const Text('Compétences à offrir', style: TextStyle(fontWeight: FontWeight.bold)),
            Wrap(
              spacing: 8,
              children: _skills.map((skill) {
                final selected = _selectedSkillsOffered.contains(skill);
                return FilterChip(
                  label: Text(skill),
                  selected: selected,
                  onSelected: (bool selectedValue) {
                    setState(() {
                      if (selectedValue) {
                        _selectedSkillsOffered.add(skill);
                      } else {
                        _selectedSkillsOffered.remove(skill);
                      }
                    });
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 16),

            const Text('Compétences recherchées', style: TextStyle(fontWeight: FontWeight.bold)),
            Wrap(
              spacing: 8,
              children: _skills.map((skill) {
                final selected = _selectedSkillsWanted.contains(skill);
                return FilterChip(
                  label: Text(skill),
                  selected: selected,
                  onSelected: (bool selectedValue) {
                    setState(() {
                      if (selectedValue) {
                        _selectedSkillsWanted.add(skill);
                      } else {
                        _selectedSkillsWanted.remove(skill);
                      }
                    });
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 16),

            _buildTextField('Description', descriptionController, maxLines: 4),

            const SizedBox(height: 20),
            Center(
              child: ElevatedButton.icon(
                onPressed: _saveProfile,
                icon: const Icon(Icons.save),
                label: const Text('Enregistrer'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller,
      {int maxLines = 1, bool obscureText = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        obscureText: obscureText,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
      ),
    );
  }
}
