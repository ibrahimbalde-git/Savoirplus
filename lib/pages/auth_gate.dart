// lib/pages/auth_gate.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb; // Alias
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user.dart'; // AppUser
import '../constants.dart'; // Tes listes de constantes : defaultLangues, defaultSavoirs, defaultDisponibilites, defaultPays
import 'registration_page.dart';
import 'login_page.dart';
import 'main_page.dart';

class AuthGate extends StatefulWidget {
  final Function(Locale) onLocaleChange;
  AuthGate({required this.onLocaleChange});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  final fb.FirebaseAuth _auth = fb.FirebaseAuth.instance;
  AppUser? _currentUser;
  bool _loading = true;
  bool _showRegistration = false; // Pour afficher inscription ou connexion

  @override
  void initState() {
    super.initState();
    _auth.authStateChanges().listen(_handleAuthChange);
  }

  Future<void> _handleAuthChange(fb.User? firebaseUser) async {
    if (firebaseUser != null) {
      setState(() => _loading = true);
      final doc = await FirebaseFirestore.instance.collection('users').doc(firebaseUser.uid).get();
      if (doc.exists) {
        setState(() {
          // ⚡ On ajoute l'id dans le fromMap
          final data = doc.data()!;
          data['id'] = firebaseUser.uid;
          _currentUser = AppUser.fromMap(data);
          _loading = false;
        });
      } else {
        // ⚡ Si pas dans Firestore, crée un AppUser minimal
        setState(() {
          _currentUser = AppUser(
            id: firebaseUser.uid, // ✅ ajouté ici
            email: firebaseUser.email ?? '',
            name: firebaseUser.displayName ?? '',
            country: countriesList.first,
            spokenLanguages: [languagesList.first],
            skillsOffered: [categoriesList.first],
            skillsWanted: [categoriesList.first],
            description: '',
            availability: [availabilitiesList.first],
            photoUrl: firebaseUser.photoURL ?? '',
            rating: 0.0,
          );
          _loading = false;
        });
      }
    } else {
      setState(() {
        _currentUser = null;
        _loading = false;
        _showRegistration = false; // Retour à la connexion quand déconnecté
      });
    }
  }

  void _logout() async {
    await _auth.signOut();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_currentUser != null) {
      return MainPage(
        user: _currentUser!,
        onLogout: _logout,
        onLocaleChange: widget.onLocaleChange,
      );
    }

    if (_showRegistration) {
      return RegistrationPage(
        onRegister: (AppUser user) {
          setState(() {
            _currentUser = user;
            _showRegistration = false;
          });
        },
        onLocaleChange: widget.onLocaleChange,
      );
    }

    // Page de connexion
    return LoginPage(
      onLocaleChange: widget.onLocaleChange,
      onLoginSuccess: (AppUser user) {
        setState(() {
          _currentUser = user;
        });
      },
      onRegisterClicked: () {
        setState(() {
          _showRegistration = true;
        });
      },
    );
  }
}
