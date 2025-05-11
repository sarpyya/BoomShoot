import 'dart:math' as Math;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lottie/lottie.dart';

class RadialMenu extends StatelessWidget {
  final String userId;
  final BuildContext parentContext; // 👈 Se añade el context válido

  const RadialMenu({
    Key? key,
    required this.userId,
    required this.parentContext,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    const double menuSize = 175;
    const double buttonRadius = 24;

    return Dialog(
      backgroundColor: Colors.transparent,
      shape: const CircleBorder(),
      alignment: Alignment.topLeft,
      child: SizedBox(
        width: menuSize,
        height: menuSize,
        child: Stack(
          alignment: Alignment.center,
          children: [
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
            _buildLottieButton(
              context,
              lottieAsset: 'assets/icons/profile.json',
              tooltip: 'Perfil',
              angle: 0,
              onPressed: () {
                parentContext.go('/profile?userId=$userId');
              },
              menuSize: menuSize,
              buttonRadius: buttonRadius,
            ),
            _buildIconButton(
              context,
              icon: Icons.settings,
              tooltip: 'Ajustes',
              angle: 90,
              onPressed: () {
                parentContext.go('/settings');
              },
              menuSize: menuSize,
              buttonRadius: buttonRadius,
            ),
            _buildIconButton(
              context,
              icon: Icons.group,
              tooltip: 'Grupos',
              angle: 270,
              onPressed: () {
                parentContext.go('/groups');
              },
              menuSize: menuSize,
              buttonRadius: buttonRadius,
            ),
            _buildIconButton(
              context,
              icon: Icons.event,
              tooltip: 'Eventos',
              angle: 180,
              onPressed: () {
                parentContext.go('/events');
              },
              menuSize: menuSize,
              buttonRadius: buttonRadius,
            ),
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

  Widget _buildIconButton(
      BuildContext context, {
        required IconData icon,
        required String tooltip,
        required double angle,
        required VoidCallback onPressed,
        required double menuSize,
        required double buttonRadius,
      }) {
    final double radius = (menuSize / 2) - buttonRadius - 10;
    final double rad = angle * (Math.pi / 180);
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
          backgroundColor: Colors.black.withOpacity(0.5),
          padding: const EdgeInsets.all(8),
          fixedSize: Size(buttonRadius * 2, buttonRadius * 2),
        ),
      ),
    );
  }

  Widget _buildLottieButton(
      BuildContext context, {
        required String lottieAsset,
        required String tooltip,
        required double angle,
        required VoidCallback onPressed,
        required double menuSize,
        required double buttonRadius,
      }) {
    final double radius = (menuSize / 2) - buttonRadius - 10;
    final double rad = angle * (Math.pi / 180);
    final double dx = radius * Math.cos(rad);
    final double dy = radius * Math.sin(rad);

    return Transform.translate(
      offset: Offset(dx, dy),
      child: InkWell(
        onTap: () {
          Navigator.pop(context);
          onPressed();
        },
        borderRadius: BorderRadius.circular(buttonRadius),
        child: Container(
          width: buttonRadius * 2,
          height: buttonRadius * 2,
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.black.withOpacity(0.5),
          ),
          child: Lottie.asset(lottieAsset),
        ),
      ),
    );
  }
}
