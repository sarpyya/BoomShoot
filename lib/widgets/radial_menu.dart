import 'dart:math' as Math;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class RadialMenu extends StatelessWidget {
  final String userId;

  const RadialMenu({Key? key, required this.userId}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    const double menuSize = 175; // Size of the circular menu
    const double buttonRadius = 24; // Radius of the IconButton (including background)

    return Dialog(
      backgroundColor: Colors.transparent,
      shape: const CircleBorder(),
      alignment: Alignment.topLeft,
      child: SizedBox(
        width: menuSize,
        height: menuSize,
        child: Stack(
          alignment: Alignment.center, // Ensure all children are centered
          children: [
            // Background circle for the menu
            Container(
              width: menuSize,
              height: menuSize,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.black.withOpacity(0.3),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 10,
                    spreadRadius: 2,
                  ),
                ],
              ),
            ),
            // Radial buttons
            _buildButton(
              context,
              icon: Icons.person,
              tooltip: 'Perfil',
              angle: 0,
              onPressed: () => context.go('/profile?userId=$userId'),
              menuSize: menuSize,
              buttonRadius: buttonRadius,
            ),
            _buildButton(
              context,
              icon: Icons.settings,
              tooltip: 'Ajustes',
              angle: 90,
              onPressed: () => context.go('/settings'),
              menuSize: menuSize,
              buttonRadius: buttonRadius,
            ),
            _buildButton(
              context,
              icon: Icons.group,
              tooltip: 'Grupos',
              angle: 270,
              onPressed: () => context.go('/groups'),
              menuSize: menuSize,
              buttonRadius: buttonRadius,
            ),
            _buildButton(
              context,
              icon: Icons.event,
              tooltip: 'Eventos',
              angle: 180,
              onPressed: () => context.go('/events'),
              menuSize: menuSize,
              buttonRadius: buttonRadius,
            ),
            // Close button at the center
            IconButton(
              icon: const Icon(Icons.close, color: Colors.white, size: 28),
              onPressed: () => Navigator.pop(context),
              tooltip: 'Cerrar',
              style: IconButton.styleFrom(
                backgroundColor: Colors.black.withOpacity(0.5),
                padding: const EdgeInsets.all(8),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildButton(
      BuildContext context, {
        required IconData icon,
        required String tooltip,
        required double angle,
        required VoidCallback onPressed,
        required double menuSize,
        required double buttonRadius,
      }) {
    final double radius = (menuSize / 2) - buttonRadius - 10; // Distance from center to button
    final double rad = angle * (Math.pi / 180); // Convert angle to radians

    // Calculate the offset for the button position
    final double dx = radius * Math.cos(rad);
    final double dy = radius * Math.sin(rad);

    return Transform.translate(
      offset: Offset(dx, dy),
      child: IconButton(
        icon: Icon(icon, color: Colors.white, size: 24),
        onPressed: () {
          Navigator.pop(context);
          onPressed();
        },
        tooltip: tooltip,
        style: IconButton.styleFrom(
          backgroundColor: Colors.black.withOpacity(0.5), // Add a background for visibility
          padding: const EdgeInsets.all(8), // Ensure consistent size
          fixedSize: Size(buttonRadius * 2, buttonRadius * 2), // Ensure button is circular
        ),
      ),
    );
  }
}