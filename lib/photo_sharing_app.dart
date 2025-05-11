import 'dart:developer' as developer;
import 'package:bs/photo_sharing_app_initializer.dart';
import 'package:bs/screens/search_screen.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:lottie/lottie.dart';
import 'package:bs/providers/theme_provider.dart';
import 'package:bs/providers/main_view_model.dart';
import 'package:bs/screens/create_event_screen.dart';
import 'package:bs/screens/create_group_screen.dart';
import 'package:bs/screens/event_detail_screen.dart';
import 'package:bs/screens/gallery_screen.dart';
import 'package:bs/screens/group_detail_screen.dart';
import 'package:bs/screens/events_screen.dart';
import 'package:bs/screens/groups_screen.dart';
import 'package:bs/screens/home_screen.dart';
import 'package:bs/screens/interest_selection_screen.dart';
import 'package:bs/screens/login_screen.dart';
import 'package:bs/screens/post_detail_screen.dart';
import 'package:bs/screens/profile_screen.dart';
import 'package:bs/screens/settings_screen.dart';
import 'package:bs/screens/camera_screen.dart';
import 'package:bs/services/firebase_service.dart';
import 'package:bs/widgets/custom_scaffold.dart';
import 'package:bs/widgets/radial_menu.dart';
import 'package:bs/providers/auth_provider.dart';
import 'package:google_fonts/google_fonts.dart';

// CustomBottomNavigationBar remains unchanged (same as provided)
class CustomBottomNavigationBar extends StatefulWidget {
  final int currentIndex;
  final Function(int) onTap;

  const CustomBottomNavigationBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  _CustomBottomNavigationBarState createState() => _CustomBottomNavigationBarState();
}

class _CustomBottomNavigationBarState extends State<CustomBottomNavigationBar> with TickerProviderStateMixin {
  late AnimationController _homeController;
  late AnimationController _eventsController;
  late AnimationController _profileController;
  late AnimationController _cameraController;

  @override
  void initState() {
    super.initState();
    _homeController = AnimationController(vsync: this, duration: const Duration(seconds: 2));
    _eventsController = AnimationController(vsync: this, duration: const Duration(seconds: 2));
    _profileController = AnimationController(vsync: this, duration: const Duration(seconds: 2));
    _cameraController = AnimationController(vsync: this, duration: const Duration(seconds: 2));
    _updateAnimationState();
  }

  @override
  void didUpdateWidget(CustomBottomNavigationBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentIndex != widget.currentIndex) {
      _updateAnimationState();
    }
  }

  void _updateAnimationState() {
    if (widget.currentIndex == 0) {
      _homeController.repeat();
      _eventsController.stop();
      _profileController.stop();
      _cameraController.stop();
    } else if (widget.currentIndex == 1) {
      _homeController.stop();
      _eventsController.repeat();
      _profileController.stop();
      _cameraController.stop();
    } else if (widget.currentIndex == 2) {
      _homeController.stop();
      _eventsController.stop();
      _profileController.repeat();
      _cameraController.stop();
    } else if (widget.currentIndex == 3) {
      _homeController.stop();
      _eventsController.stop();
      _profileController.stop();
      _cameraController.repeat();
    } else {
      _homeController.stop();
      _eventsController.stop();
      _profileController.stop();
      _cameraController.stop();
    }
  }

  @override
  void dispose() {
    _homeController.dispose();
    _eventsController.dispose();
    _profileController.dispose();
    _cameraController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    const orangeColor = Color(0xFFF5B52A);

    return Stack(
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 20.0, left: 20.0, right: 20),
          child: Container(
            height: 80,
            color: Colors.transparent,
          ),
        ),
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: Padding(
            padding: EdgeInsets.only(bottom: MediaQuery.of(context).padding.bottom + 5, left: 20, right: 20),
            child: Material(
              color: Colors.transparent,
              elevation: 8.0,
              shadowColor: colorScheme.shadow.withValues(alpha: 0.5),
              child: Container(
                height: 48,
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.all(Radius.circular(32)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 10,
                      spreadRadius: 2,
                    ),
                  ],
                  color: colorScheme.surface,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildNavItem(context, 0, 'Inicio', 'assets/icons/home.json', _homeController, orangeColor),
                    _buildNavItem(context, 1, 'Eventos', 'assets/icons/menu.json', _eventsController, orangeColor),
                    _buildNavItem(context, 2, 'Perfil', 'assets/icons/profile.json', _profileController, orangeColor),
                    _buildNavItem(context, 3, 'Cámara', 'assets/icons/camera.json', _cameraController, orangeColor, isCamera: true),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNavItem(
      BuildContext context,
      int index,
      String label,
      String iconPath,
      AnimationController controller,
      Color orangeColor, {
        bool isCamera = false,
      }) {
    final isSelected = widget.currentIndex == index;
    final color = isSelected ? orangeColor : Theme.of(context).colorScheme.onSecondary;

    return SizedBox(
      width: isCamera ? 80 : 64,
      height: 64,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            widget.onTap(index);
            if (isSelected) {
              controller.forward().then((_) => controller.reverse());
            }
          },
          borderRadius: BorderRadius.circular(32),
          child: Padding(
            padding: EdgeInsets.zero,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  width: isCamera ? 48 : 24,
                  height: isCamera ? 48 : 24,
                  child: ColorFiltered(
                    colorFilter: ColorFilter.mode(color, BlendMode.srcATop),
                    child: Lottie.asset(
                      iconPath,
                      width: isCamera ? 48 : 24,
                      height: isCamera ? 48 : 24,
                      fit: BoxFit.contain,
                      controller: controller,
                    ),
                  ),
                ),
                if (!isCamera) const SizedBox(height: 4),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class PhotoSharingApp extends StatefulWidget {
  final AuthProvider authProvider;

  const PhotoSharingApp({super.key, required this.authProvider});

  @override
  State<PhotoSharingApp> createState() => _PhotoSharingAppState();
}

class _PhotoSharingAppState extends State<PhotoSharingApp> {
  final dataService = FirebaseDataService();
  late GoRouter _router;
  int _selectedIndex = 0;
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();
  static const platform = MethodChannel('com.example.bs/back_handler');

  static const List<String> _navRoutes = [
    '/home',
    '/events',
    '/profile',
    '/camera',
  ];

  @override
  void initState() {
    super.initState();
    developer.log('initState: Starting setup', name: 'PhotoSharingApp');

    WidgetsBinding.instance.addPostFrameCallback((_) {
      developer.log('Setting up MethodChannel handler', name: 'PhotoSharingApp');
      platform.setMethodCallHandler((call) async {
        if (call.method == 'onBackPressed') {
          final navigatorContext = _navigatorKey.currentContext;
          if (navigatorContext == null) {
            developer.log('Navigator context not available, navigating to /home', name: 'PhotoSharingApp');
            if (mounted) {
              setState(() => _selectedIndex = 0);
              _router.go('/home');
            }
            return false;
          }

          final currentLocation = GoRouterState.of(navigatorContext).uri.path;
          developer.log('Back button pressed, current: $currentLocation, canPop: ${_router.canPop()}', name: 'PhotoSharingApp');

          const rootScreens = ['/home', '/events', '/profile', '/camera'];
          const navigateBackScreens = [
            '/groups',
            '/settings',
            '/create_event',
            '/create_group',
            '/gallery',
          ];

          if (currentLocation == '/login' || currentLocation.startsWith('/interest_selection') || rootScreens.contains(currentLocation)) {
            return await _showBackDialog() ?? false;
          } else if (navigateBackScreens.contains(currentLocation) || currentLocation.startsWith('/post/') || currentLocation.startsWith('/group/') || currentLocation.startsWith('/event/')) {
            if (mounted) {
              setState(() => _selectedIndex = 0);
              _router.go('/home');
            }
            return false;
          } else if (_router.canPop()) {
            _router.pop();
            return false;
          }
          return await _showBackDialog() ?? false;
        }
        return false;
      });
    });

    final _shellNavigatorKey = GlobalKey<NavigatorState>();
    _router = GoRouter(
      initialLocation: '/login',
      debugLogDiagnostics: true,
      refreshListenable: widget.authProvider,
      navigatorKey: _navigatorKey,
      redirect: (context, state) async {
        final userId = widget.authProvider.userId;
        final path = state.uri.path;

        if (path.startsWith('/gallery/')) return null;

        if (userId == null && path != '/login') {
          return '/login?redirect=${Uri.encodeComponent(path)}';
        }

        if (userId != null) {
          final user = await dataService.getUserById(userId);
          if ((user?.interests ?? []).isEmpty && path != '/interest_selection') {
            return '/interest_selection?userId=$userId';
          }
        }

        if (path == '/login' && userId != null) {
          final redirect = state.uri.queryParameters['redirect'] ?? '/home';
          return redirect;
        }

        return null;
      },
      routes: [
        GoRoute(
          path: '/login',
          builder: (context, state) => const LoginScreen(),
        ),
        GoRoute(
          path: '/interest_selection',
          builder: (context, state) {
            final userId = state.uri.queryParameters['userId'] ?? widget.authProvider.userId;
            return userId == null ? const LoginScreen() : InterestSelectionScreen(userId: userId);
          },
        ),
        ShellRoute(
          navigatorKey: _shellNavigatorKey,
          builder: (context, state, child) {
            final path = state.uri.path;
            final selectedIndex = _calculateSelectedIndex(path);
            final title = _getTitleForPath(path);
            final showBackButton = !_navRoutes.contains(path);

            return CustomScaffold(
              title: title,
              showBackButton: showBackButton,
              showMenuButton: true,
              onMenuPressed: () {
                final userId = widget.authProvider.userId ?? '';
                showDialog(
                  context: context,
                  barrierColor: Colors.black.withAlpha(60),
                  builder: (dialogContext) => RadialMenu(userId: userId, parentContext: context),
                );
              },
              showLogo: !showBackButton,
              actions: [
                if (path == '/settings')
                  IconButton(
                    icon: Icon(Icons.logout, color: Theme.of(context).colorScheme.onSurface),
                    onPressed: () async {
                      await widget.authProvider.signOut();
                      context.read<MainViewModel>().reset();
                      _router.go('/login');
                    },
                    tooltip: 'Cerrar sesión',
                  ),
              ],
              body: child,
              bottomNavigationBar: _navRoutes.contains(path)
                  ? CustomBottomNavigationBar(
                currentIndex: selectedIndex,
                onTap: (index) => _onItemTapped(context, index),
              )
                  : null,
              userId: widget.authProvider.userId ?? '',
            );
          },
          routes: [
            GoRoute(path: '/home', builder: (context, state) => HomeScreen(userId: widget.authProvider.userId ?? '')),
            GoRoute(path: '/events', builder: (context, state) => EventsScreen(userId: widget.authProvider.userId ?? '')),
            GoRoute(path: '/profile', builder: (context, state) => const ProfileScreen()),
            GoRoute(path: '/search', builder: (context, state) => SearchScreen(userId: widget.authProvider.userId ?? '')),
            GoRoute(path: '/camera', builder: (context, state) => CameraScreen(userId: widget.authProvider.userId ?? '')),
            GoRoute(path: '/groups', builder: (context, state) => GroupsScreen(userId: widget.authProvider.userId ?? '')),
            GoRoute(
              path: '/post/:postId',
              builder: (context, state) {
                final postId = state.pathParameters['postId']!;
                return PostDetailScreen(postId: postId, userId: widget.authProvider.userId ?? '');
              },
            ),
            GoRoute(path: '/settings', builder: (context, state) => const SettingsScreen()),
            GoRoute(path: '/create_event', builder: (context, state) => CreateEventScreen(userId: widget.authProvider.userId ?? '')),
            GoRoute(path: '/create_group', builder: (context, state) => CreateGroupScreen(userId: widget.authProvider.userId ?? '')),
            GoRoute(
              path: '/group/:groupId',
              builder: (context, state) {
                final groupId = state.pathParameters['groupId']!;
                return GroupDetailScreen(groupId: groupId);
              },
            ),
            GoRoute(
              path: '/event/:eventId',
              builder: (context, state) {
                final eventId = state.pathParameters['eventId']!;
                return EventDetailScreen(eventId: eventId);
              },
            ),
            GoRoute(
              path: '/gallery/:eventId',
              builder: (context, state) {
                final eventId = state.pathParameters['eventId']!;
                return GalleryScreen(eventId: eventId);
              },
            ),
          ],
        ),
      ],
      errorBuilder: (context, state) => Scaffold(
        body: Center(
          child: Text(
            'Error: ${state.error}',
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
        ),
      ),
    );
  }

  void _onItemTapped(BuildContext context, int index) {
    setState(() => _selectedIndex = index);
    final route = _navRoutes[index];
    _router.go(route);
    developer.log('Navegando a $route, índice: $index', name: 'PhotoSharingApp');
  }

  Future<bool?> _showBackDialog() async {
    final navigatorContext = _navigatorKey.currentContext;
    if (navigatorContext == null || !mounted) {
      developer.log('Navigator context not available or widget not mounted', name: 'PhotoSharingApp');
      return false;
    }

    return showDialog<bool>(
      context: navigatorContext,
      barrierDismissible: false,
      builder: (context) {
        final theme = Theme.of(context);
        final colorScheme = theme.colorScheme;
        return AlertDialog(
          title: Text('Salir de la aplicación', style: GoogleFonts.poppins(color: colorScheme.primary)),
          content: Text('¿Estás seguro de que quieres salir?', style: GoogleFonts.poppins(color: colorScheme.onSurface)),
          backgroundColor: colorScheme.surface,
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text('Cancelar', style: GoogleFonts.poppins(color: colorScheme.primary)),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text('Salir', style: GoogleFonts.poppins(color: colorScheme.primary)),
            ),
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    developer.log('Disposing PhotoSharingApp', name: 'PhotoSharingApp');
    context.read<MainViewModel>().reset();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final lightColorScheme = ColorScheme.fromSeed(seedColor: Colors.blue, brightness: Brightness.light);
    final darkColorScheme = ColorScheme.fromSeed(seedColor: Colors.blue, brightness: Brightness.dark);

    return MaterialApp.router(
      title: 'Boom-Shoot',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: lightColorScheme,
        scaffoldBackgroundColor: lightColorScheme.surface,
        appBarTheme: AppBarTheme(
          backgroundColor: lightColorScheme.primary.withOpacity(0.1),
          foregroundColor: lightColorScheme.onPrimary,
        ),
        textTheme: GoogleFonts.poppinsTextTheme(),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        colorScheme: darkColorScheme,
        scaffoldBackgroundColor: darkColorScheme.surface,
        appBarTheme: AppBarTheme(
          backgroundColor: darkColorScheme.primary.withOpacity(0.0),
          foregroundColor: darkColorScheme.onPrimary,
        ),
        textTheme: GoogleFonts.poppinsTextTheme(),
      ),
      themeMode: themeProvider.themeMode,
      routerConfig: _router,
      debugShowCheckedModeBanner: false,
    );
  }
}

int _calculateSelectedIndex(String path) {
  final navRoutes = ['/home', '/events', '/profile', '/camera'];
  if (navRoutes.contains(path)) {
    return navRoutes.indexOf(path);
  }
  if (path.startsWith('/profile') || path.startsWith('/group/') || path.startsWith('/event/') || path.startsWith('/gallery/')) {
    return 2;
  }
  return 0;
}

String _getTitleForPath(String path) {
  if (path.startsWith('/post/')) return 'Publicación';
  if (path.startsWith('/group/')) return 'Grupo';
  if (path.startsWith('/event/')) return 'Evento';
  if (path.startsWith('/gallery/')) return 'Galería';
  return {
    '/home': 'Inicio',
    '/events': 'Eventos',
    '/profile': 'Perfil',
    '/camera': 'Cámara',
    '/groups': 'Grupos',
    '/settings': 'Ajustes',
    '/create_event': 'Crear Evento',
    '/create_group': 'Crear Grupo',
    '/search': 'Búsqueda',
  }[path] ?? 'Boom-Shoot';
}