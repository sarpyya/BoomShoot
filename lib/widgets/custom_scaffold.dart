import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart'; // Import flutter_speed_dial

class BaseAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String? title;
  final bool showBackButton;
  final List<Widget>? actions;
  final bool showMenuButton;
  final VoidCallback? onMenuPressed;
  final bool showLogo;

  const BaseAppBar({
    super.key,
    this.title,
    this.showBackButton = false,
    this.actions,
    this.showMenuButton = false,
    this.onMenuPressed,
    this.showLogo = false,
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      leading: showBackButton
          ? IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: () => context.pop(),
        tooltip: 'Volver',
      )
          : showMenuButton
          ? IconButton(
        icon: const Icon(Icons.menu),
        onPressed: onMenuPressed,
        tooltip: 'Menú',
      )
          : null,
      title: showLogo
          ? Image.asset(
        "lib/assets/boomshot.png",
        height: 40,
      )
          : Text(
        title ?? '',
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
      centerTitle: true,
      actions: actions,
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

class CustomScaffold extends StatelessWidget {
  final Widget body;
  final String? title;
  final bool showBackButton;
  final bool showMenuButton;
  final VoidCallback? onMenuPressed;
  final List<Widget>? actions;
  final bool showLogo;
  final Widget? floatingActionButton;
  final Color? backgroundColor;

  const CustomScaffold({
    super.key,
    required this.body,
    this.title,
    this.showBackButton = false,
    this.showMenuButton = false,
    this.onMenuPressed,
    this.actions,
    this.showLogo = false,
    this.floatingActionButton,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: BaseAppBar(
        title: title,
        showBackButton: showBackButton,
        showMenuButton: showMenuButton,
        onMenuPressed: onMenuPressed,
        actions: actions,
        showLogo: showLogo,
      ),
      body: SafeArea(child: body), // Wrap body with SafeArea
      floatingActionButton: floatingActionButton ?? _buildDefaultSpeedDial(context),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat, // Ensure proper positioning
    );
  }

  // Default SpeedDial implementation for the radial menu
  Widget _buildDefaultSpeedDial(BuildContext context) {
    return SpeedDial(
      icon: Icons.add, // Main icon for the FAB
      activeIcon: Icons.close, // Icon when the menu is open
      spacing: 16.0, // Increased spacing between child buttons for better separation
      childMargin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12), // Adjusted margin for child buttons
      childrenButtonSize: const Size(56, 56), // Size of the child buttons
      buttonSize: const Size(56, 56), // Ensure the main button matches the child button size
      overlayColor: Colors.black, // Optional: Add an overlay for better focus
      overlayOpacity: 0.4, // Optional: Adjust overlay opacity
      direction: SpeedDialDirection.up, // Ensure the menu expands upward
      children: [
        SpeedDialChild(
          child: const Icon(Icons.person),
          label: 'Perfil',
          onTap: () {
            // Navigate to profile or handle action
            context.push('/profile');
          },
        ),
        SpeedDialChild(
          child: const Icon(Icons.location_on),
          label: 'Ubicación',
          onTap: () {
            // Handle location action
          },
        ),
        SpeedDialChild(
          child: const Icon(Icons.settings),
          label: 'Ajustes',
          onTap: () {
            context.push('/settings');
          },
        ),
      ],
    );

  }
}