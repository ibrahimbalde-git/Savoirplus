import 'dart:io' show File; // ⚠️ reste uniquement pour mobile/desktop
import 'package:flutter/foundation.dart' show kIsWeb; // pour détecter le web
import 'package:flutter/material.dart';
import '../models/user.dart';
import 'edit_profile_page.dart';

class ProfilePage extends StatefulWidget {
  final AppUser user;

  const ProfilePage({required this.user, Key? key}) : super(key: key);

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  late AppUser currentUser;

  @override
  void initState() {
    super.initState();
    currentUser = widget.user;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        elevation: 6,
        backgroundColor: Colors.teal,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            bottom: Radius.circular(24),
          ),
        ),
        centerTitle: true,
        title: const Text(
          'Profil utilisateur',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            letterSpacing: 1.1,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: CircleAvatar(
                radius: 60,
                backgroundImage: _getProfileImage(currentUser.photoUrl),
                child: (currentUser.photoUrl.isEmpty)
                    ? const Icon(Icons.person, size: 60)
                    : null,
              ),
            ),
            const SizedBox(height: 20),
            Center(
              child: Text(
                currentUser.name,
                style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 30),
            _buildSectionTitle(context, 'Informations personnelles'),
            _buildDetailItem('Email', currentUser.email),
            _buildDetailItem('Pays', currentUser.country),
            _buildDetailItem(
              'Disponibilité',
              (currentUser.availability.isNotEmpty) ? currentUser.availability.join(', ') : 'Non renseigné',
            ),
            const SizedBox(height: 20),
            _buildSectionTitle(context, 'Compétences et langues'),
            _buildDetailItem(
              'Langues parlées',
              (currentUser.spokenLanguages.isNotEmpty) ? currentUser.spokenLanguages.join(', ') : 'Non renseigné',
            ),
            _buildDetailItem(
              'Compétences à offrir',
              (currentUser.skillsOffered.isNotEmpty) ? currentUser.skillsOffered.join(', ') : 'Non renseigné',
            ),
            _buildDetailItem(
              'Compétences recherchées',
              (currentUser.skillsWanted.isNotEmpty) ? currentUser.skillsWanted.join(', ') : 'Non renseigné',
            ),
            const SizedBox(height: 20),
            _buildSectionTitle(context, 'Description'),
            Text(
              currentUser.description,
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 30),
            Center(
              child: ElevatedButton.icon(
                onPressed: () async {
                  final updatedUser = await Navigator.push<AppUser>(
                    context,
                    MaterialPageRoute(
                      builder: (_) => EditProfilePage(user: currentUser),
                    ),
                  );

                  if (updatedUser != null) {
                    setState(() {
                      currentUser = updatedUser;
                    });
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Profil mis à jour !')),
                    );
                  }
                },
                icon: const Icon(Icons.edit),
                label: const Text('Modifier le profil'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Gère les images selon la plateforme
  ImageProvider? _getProfileImage(String photoUrl) {
    if (photoUrl.isEmpty) return null;

    if (kIsWeb) {
      // Sur Web → utilise NetworkImage (Firebase storage, URL, etc.)
      return NetworkImage(photoUrl);
    } else {
      // Sur Mobile/Desktop → fichier local
      final file = File(photoUrl);
      if (file.existsSync()) {
        return FileImage(file);
      } else {
        return null;
      }
    }
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.bold,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }

  Widget _buildDetailItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("$label : ", style: const TextStyle(fontWeight: FontWeight.w600)),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}
