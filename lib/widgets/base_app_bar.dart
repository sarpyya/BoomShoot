import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

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
