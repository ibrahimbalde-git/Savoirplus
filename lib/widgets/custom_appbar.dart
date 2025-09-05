import 'package:flutter/material.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final bool showBackButton;
  final List<Widget>? actions;
  final PreferredSizeWidget? bottom; // <-- ajout du bottom

  const CustomAppBar({
    required this.title,
    this.showBackButton = false,
    this.actions,
    this.bottom,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      elevation: 6,
      backgroundColor: Colors.teal,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          bottom: Radius.circular(24),
        ),
      ),
      centerTitle: true,
      title: Text(
        title,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          letterSpacing: 1.1,
        ),
      ),
      leading: showBackButton
          ? IconButton(
        icon: const Icon(Icons.arrow_back),
        tooltip: 'Retour',
        onPressed: () => Navigator.pop(context),
      )
          : null,
      actions: actions,
      bottom: bottom, // <-- appliquer ici
    );
  }

  @override
  Size get preferredSize => Size.fromHeight(
    kToolbarHeight + 10 + (bottom?.preferredSize.height ?? 0),
  );
}
