import 'package:flutter/material.dart';
import '../models/user.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'edit_profile_page.dart';

class LoginPage extends StatefulWidget {
  final Function(AppUser) onLoginSuccess;
  final Function() onRegisterClicked;
  final Function(Locale) onLocaleChange;

  const LoginPage({
    required this.onLoginSuccess,
    required this.onRegisterClicked,
    required this.onLocaleChange,
    Key? key,
  }) : super(key: key);

  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _loading = false;

  List<String> _parseList(dynamic v) {
    if (v == null) return [];
    if (v is List) return v.cast<String>();
    if (v is String) return [v];
    return [];
  }

  // ----------------------------
  // Connexion email/password
  // ----------------------------
  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);

    try {
      final cred = await fb.FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailCtrl.text.trim(),
        password: _passwordCtrl.text.trim(),
      );

      final user = cred.user!;
      if (!user.emailVerified) {
        await user.sendEmailVerification();
        _showError("Email non vérifié. Un email de confirmation a été renvoyé.");
        setState(() => _loading = false);
        return;
      }

      await _handleUserLogin(user);

    } on fb.FirebaseAuthException catch (e) {
      _showError("Erreur de connexion: ${e.message}");
    } catch (e) {
      _showError("Erreur: $e");
    } finally {
      setState(() => _loading = false);
    }
  }

  // ----------------------------
  // Connexion Google
  // ----------------------------
  Future<void> _loginWithGoogle() async {
    setState(() => _loading = true);
    try {
      final googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) {
        setState(() => _loading = false);
        return;
      }

      final googleAuth = await googleUser.authentication;
      final credential = fb.GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final cred = await fb.FirebaseAuth.instance.signInWithCredential(credential);
      await _handleUserLogin(cred.user!, isGoogle: true);

    } on fb.FirebaseAuthException catch (e) {
      _showError("Erreur Google: ${e.message}");
    } catch (e) {
      _showError("Erreur: $e");
    } finally {
      setState(() => _loading = false);
    }
  }

  // ----------------------------
  // Gestion Firestore → AppUser
  // ----------------------------
  Future<void> _handleUserLogin(fb.User firebaseUser, {bool isGoogle = false}) async {
    final docRef = FirebaseFirestore.instance.collection('users').doc(firebaseUser.uid);
    final doc = await docRef.get();

    AppUser user;

    if (doc.exists) {
      final data = doc.data()!;
      user = AppUser(
        id: firebaseUser.uid,
        email: data['email'] ?? firebaseUser.email ?? '',
        name: data['name'] ?? firebaseUser.displayName ?? '',
        country: data['country'] ?? '',
        spokenLanguages: _parseList(data['spokenLanguages']),
        skillsOffered: _parseList(data['skillsOffered']),
        skillsWanted: _parseList(data['skillsWanted']),
        description: data['description'] ?? '',
        availability: _parseList(data['availability']),
        photoUrl: data['photoUrl'] ?? firebaseUser.photoURL ?? '',
        rating: (data['rating'] is num) ? (data['rating'] as num).toDouble() : 0.0,
      );
    } else {
      // ⚡ Nouveau compte Google → profil minimal
      user = AppUser(
        id: firebaseUser.uid,
        email: firebaseUser.email ?? '',
        name: firebaseUser.displayName ?? '',
        country: '',
        spokenLanguages: [],
        skillsOffered: [],
        skillsWanted: [],
        description: '',
        availability: [],
        photoUrl: firebaseUser.photoURL ?? '',
        rating: 0.0,
      );
      await docRef.set(user.toMap());
    }

    // ⚡ Si utilisateur Google avec profil incomplet → redirection vers EditProfile
    final needsProfileCompletion = isGoogle &&
        (user.country.isEmpty || user.spokenLanguages.isEmpty || user.availability.isEmpty);

    if (needsProfileCompletion) {
      final updatedUser = await Navigator.push<AppUser>(
        context,
        MaterialPageRoute(
          builder: (_) => EditProfilePage(user: user, isGoogleUser: true),
        ),
      );

      if (updatedUser != null) widget.onLoginSuccess(updatedUser);
    } else {
      widget.onLoginSuccess(user);
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Connexion')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              DropdownButton<Locale>(
                value: Localizations.localeOf(context),
                items: const [
                  DropdownMenuItem(child: Text('Français'), value: Locale('fr')),
                  DropdownMenuItem(child: Text('English'), value: Locale('en')),
                ],
                onChanged: (locale) {
                  if (locale != null) widget.onLocaleChange(locale);
                },
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _emailCtrl,
                decoration: const InputDecoration(labelText: 'Email'),
                validator: (val) =>
                val != null && val.contains('@') ? null : 'Email invalide',
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _passwordCtrl,
                decoration: const InputDecoration(labelText: 'Mot de passe'),
                obscureText: true,
                validator: (val) =>
                val != null && val.length >= 6 ? null : 'Min 6 caractères',
              ),
              const SizedBox(height: 20),
              _loading
                  ? const Center(child: CircularProgressIndicator())
                  : ElevatedButton(
                onPressed: _login,
                child: const Text('Se connecter'),
              ),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: _loginWithGoogle,
                icon: Image.asset("assets/google_logo.png", height: 24),
                label: const Text("Se connecter avec Google"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.black,
                ),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: widget.onRegisterClicked,
                child: const Text("Créer un nouveau compte"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
