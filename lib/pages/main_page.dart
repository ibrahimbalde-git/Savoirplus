import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user.dart';
import 'home_page.dart';
import 'profile_page.dart';
import 'echanges_page.dart';
import '../widgets/icon_with_badge.dart';

class MainPage extends StatefulWidget {
  final AppUser user;
  final VoidCallback onLogout;
  final Function(Locale) onLocaleChange;

  const MainPage({
    required this.user,
    required this.onLogout,
    required this.onLocaleChange,
    Key? key,
  }) : super(key: key);

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  int _selectedIndex = 0;
  late List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _pages = [
      HomePage(user: widget.user),
      ProfilePage(user: widget.user),
      EchangesPage(currentUser: widget.user),
    ];
  }

  void _onItemTapped(int index) => setState(() => _selectedIndex = index);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        items: [
          const BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Accueil'),
          const BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profil'),
          BottomNavigationBarItem(
            icon: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('echanges')
                  .where('receveurEmail', isEqualTo: widget.user.email)
                  .where('status', isEqualTo: 'proposé')
                  .snapshots(),
              builder: (context, snapshot) {
                int count = 0;
                if (snapshot.hasData) count = snapshot.data!.docs.length;
                return IconWithBadge(iconData: Icons.swap_horiz, notificationCount: count);
              },
            ),
            label: 'Échanges',
          ),
        ],
      ),
    );
  }
}
