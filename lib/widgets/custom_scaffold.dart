//lib/widgets/custom_scaffold.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:lottie/lottie.dart';

class BaseAppBar extends StatefulWidget implements PreferredSizeWidget {
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
  _BaseAppBarState createState() => _BaseAppBarState();

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

class _BaseAppBarState extends State<BaseAppBar> with TickerProviderStateMixin {
  late AnimationController _menuController;
  bool _isMenuActive = false;

  @override
  void initState() {
    super.initState();
    _menuController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );
  }

  @override
  void dispose() {
    _menuController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return AppBar(
      leading: widget.showBackButton
          ? IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: () => context.pop(),
        tooltip: 'Volver',
        color: colorScheme.onSurface,
      )
          : widget.showMenuButton
          ? IconButton(
        icon: ColorFiltered(
          colorFilter: _isMenuActive
              ? ColorFilter.mode(colorScheme.onSurface, BlendMode.srcATop)
              : ColorFilter.mode(
            colorScheme.onSecondary ?? Colors.grey[300]!,
            BlendMode.srcATop,
          ),
          child: Lottie.asset(
            'assets/icons/menu.json',
            width: 24,
            height: 24,
            fit: BoxFit.contain,
            controller: _menuController,
          ),
        ),
        onPressed: () {
          setState(() {
            _isMenuActive = true;
          });
          _menuController.forward(from: 0.0);
          widget.onMenuPressed?.call();
          Future.delayed(const Duration(seconds: 2), () {
            if (mounted) {
              setState(() {
                _isMenuActive = false;
              });
            }
          });
        },
        tooltip: 'Menú',
      )
          : null,
      title: widget.showLogo
          ? Image.asset(
        "lib/assets/boomshot.png",
        height: 40,
      )
          : Text(
        widget.title ?? '',
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
      centerTitle: true,
      actions: widget.actions,
    );
  }
}

class CustomScaffold extends StatefulWidget {
  final Widget body;
  final String? title;
  final bool showBackButton;
  final bool showMenuButton;
  final VoidCallback? onMenuPressed;
  final List<Widget>? actions;
  final bool showLogo;
  final Widget? floatingActionButton;
  final Color? backgroundColor;
  final Widget? bottomNavigationBar;
  final String userId;

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
    this.bottomNavigationBar,
    required this.userId,
  });

  @override
  _CustomScaffoldState createState() => _CustomScaffoldState();
}

class _CustomScaffoldState extends State<CustomScaffold> with TickerProviderStateMixin {
  late AnimationController _profileController;
  late AnimationController _locationController;
  late AnimationController _settingsController;
  late AnimationController _eventController;
  late AnimationController _groupController;
  bool _isSpeedDialOpen = false;

  @override
  void initState() {
    super.initState();
    _profileController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );
    _locationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );
    _settingsController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );
    _eventController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );
    _groupController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );
  }

  @override
  void dispose() {
    _profileController.dispose();
    _locationController.dispose();
    _settingsController.dispose();
    _eventController.dispose();
    _groupController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: widget.backgroundColor,
      appBar: BaseAppBar(
        title: widget.title,
        showBackButton: widget.showBackButton,
        showMenuButton: widget.showMenuButton,
        onMenuPressed: widget.onMenuPressed,
        actions: widget.actions,
        showLogo: widget.showLogo,
      ),
      body: SafeArea(child: widget.body),
      floatingActionButton: widget.floatingActionButton ?? _buildDefaultSpeedDial(context),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      bottomNavigationBar: widget.bottomNavigationBar,
    );
  }

  Widget _buildDefaultSpeedDial(BuildContext context) {
    final theme = Theme.of(context);
    return SpeedDial(
      icon: Icons.add,
      activeIcon: Icons.close,
      spacing: 16.0,
      childMargin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      childrenButtonSize: const Size(56, 56),
      buttonSize: const Size(56, 56),
      overlayColor: Colors.black,
      overlayOpacity: 0.4,
      direction: SpeedDialDirection.up,
      onOpen: () {
        setState(() {
          _isSpeedDialOpen = true;
        });
      },
      onClose: () {
        setState(() {
          _isSpeedDialOpen = false;
        });
        // Stop animations when closing SpeedDial
        _profileController.stop();
        _locationController.stop();
        _settingsController.stop();
        _eventController.stop();
        _groupController.stop();
      },
      children: [
        SpeedDialChild(
          child: SizedBox(
            width: 24,
            height: 24,
            child: ColorFiltered(
              colorFilter: _isSpeedDialOpen
                  ? const ColorFilter.mode(Color(0xFFF5B52A), BlendMode.srcATop)
                  : ColorFilter.mode(
                theme.colorScheme.onSecondary ?? Colors.grey[300]!,
                BlendMode.srcATop,
              ),
              child: Lottie.asset(
                'assets/icons/profile.json',
                controller: _profileController,
                fit: BoxFit.contain,
              ),
            ),
          ),
          label: 'Perfil',
          onTap: () {
            _profileController.forward(from: 0.0);
            context.push('/profile?userId=${widget.userId}'); // Pass userId
          },
        ),
        SpeedDialChild(
          child: SizedBox(
            width: 24,
            height: 24,
            child: ColorFiltered(
              colorFilter: _isSpeedDialOpen
                  ? const ColorFilter.mode(Color(0xFFF5B52A), BlendMode.srcATop)
                  : ColorFilter.mode(
                theme.colorScheme.onSecondary ?? Colors.grey[300]!,
                BlendMode.srcATop,
              ),
              child: Lottie.asset(
                'assets/icons/menu.json',
                controller: _locationController,
                fit: BoxFit.contain,
              ),
            ),
          ),
          label: 'Ubicación',
          onTap: () {
            _locationController.forward(from: 0.0);
            // Handle location action (e.g., open a location picker)
          },
        ),
        SpeedDialChild(
          child: SizedBox(
            width: 24,
            height: 24,
            child: ColorFiltered(
              colorFilter: _isSpeedDialOpen
                  ? const ColorFilter.mode(Color(0xFFF5B52A), BlendMode.srcATop)
                  : ColorFilter.mode(
                theme.colorScheme.onSecondary ?? Colors.grey[300]!,
                BlendMode.srcATop,
              ),
              child: Lottie.asset(
                'assets/icons/event.json',
                controller: _eventController,
                fit: BoxFit.contain,
              ),
            ),
          ),
          label: 'Crear Evento',
          onTap: () {
            _eventController.forward(from: 0.0);
            context.push('/create_event');
          },
        ),
        SpeedDialChild(
          child: SizedBox(
            width: 24,
            height: 24,
            child: ColorFiltered(
              colorFilter: _isSpeedDialOpen
                  ? const ColorFilter.mode(Color(0xFFF5B52A), BlendMode.srcATop)
                  : ColorFilter.mode(
                theme.colorScheme.onSecondary ?? Colors.grey[300]!,
                BlendMode.srcATop,
              ),
              child: Lottie.asset(
                'assets/icons/group.json',
                controller: _groupController,
                fit: BoxFit.contain,
              ),
            ),
          ),
          label: 'Crear Grupo',
          onTap: () {
            _groupController.forward(from: 0.0);
            context.push('/create_group');
          },
        ),
        SpeedDialChild(
          child: SizedBox(
            width: 24,
            height: 24,
            child: ColorFiltered(
              colorFilter: _isSpeedDialOpen
                  ? const ColorFilter.mode(Color(0xFFF5B52A), BlendMode.srcATop)
                  : ColorFilter.mode(
                theme.colorScheme.onSecondary ?? Colors.grey[300]!,
                BlendMode.srcATop,
              ),
              child: Lottie.asset(
                'assets/icons/settings.json',
                controller: _settingsController,
                fit: BoxFit.contain,
              ),
            ),
          ),
          label: 'Ajustes',
          onTap: () {
            _settingsController.forward(from: 0.0);
            context.push('/settings');
          },
        ),
      ],
    );
  }
}