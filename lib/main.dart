import 'dart:async';
import 'dart:developer' as developer;

import 'package:bs/providers/theme_provider.dart';
import 'package:bs/screens/create_event_screen.dart';
import 'package:bs/screens/create_group_screen.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';

import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'firebase_options.dart';
import 'package:bs/services/firebase_service.dart';
import 'package:bs/providers/main_view_model.dart';

import 'package:bs/screens/camera_screen.dart';
import 'package:bs/screens/events_screen.dart';
import 'package:bs/screens/groups_screen.dart';
import 'package:bs/screens/home_screen.dart';
import 'package:bs/screens/interest_selection_screen.dart';
import 'package:bs/screens/login_screen.dart';
import 'package:bs/screens/post_detail_screen.dart';
import 'package:bs/screens/profile_screen.dart';
import 'package:bs/screens/settings_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  final dataService = FirebaseDataService();
  // await dataService.migrateDatabase();

  // Create instances of providers
  final authProvider = AuthProvider();
  final mainViewModel = MainViewModel();
  final themeProvider = ThemeProvider();

  // Capturar errores globales
  FlutterError.onError = (FlutterErrorDetails details) {
    developer.log('FlutterError: ${details.exceptionAsString()}', name: 'main');
    developer.log(details.stack.toString(), name: 'main');
  };

  runZonedGuarded(() {
    runApp(
      MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: authProvider),
          ChangeNotifierProvider.value(value: mainViewModel),
          ChangeNotifierProvider.value(value: themeProvider),
        ],
        child: PhotoSharingApp(authProvider: authProvider),
      ),
    );
  }, (error, stackTrace) {
    developer.log('Zoned Error: $error', name: 'main');
    developer.log(stackTrace.toString(), name: 'main');
  });
}

class AuthProvider with ChangeNotifier {
  String? _userId;
  String? get userId => _userId;

  void setUser(String? userId) {
    if (_userId != userId) {
      _userId = userId;
      notifyListeners();
    }
  }

  void signOut() {
    _userId = null;
    notifyListeners();
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

  static const List<String> _navRoutes = [
    '/home',
    '/events',
    '/profile',
    '/camera',
  ];

  @override
  void initState() {
    super.initState();
    final firebaseAuth = firebase_auth.FirebaseAuth.instance;
    firebaseAuth.authStateChanges().listen((user) {
      if (user != null && widget.authProvider.userId != user.uid) {
        developer.log('Usuario autenticado: ${user.uid}', name: 'PhotoSharingApp');
        widget.authProvider.setUser(user.uid);
      } else if (user == null && widget.authProvider.userId != null) {
        developer.log('Usuario deslogueado', name: 'PhotoSharingApp');
        widget.authProvider.signOut();
        context.read<MainViewModel>().reset();
      }
    });
    final navigatorKey = GlobalKey<NavigatorState>();
    _router = GoRouter(
      navigatorKey: navigatorKey,
      initialLocation: '/login',
      debugLogDiagnostics: true,
      refreshListenable: widget.authProvider,
      redirect: (context, state) async {
        final userId = widget.authProvider.userId;

        if (userId == null && state.uri.path != '/login') return '/login';

        if (userId != null) {
          final user = await dataService.getUserById(userId);
          if ((user?.interests ?? []).isEmpty && state.uri.path != '/interest_selection') {
            return '/interest_selection?userId=$userId';
          }
        }

        if (state.uri.path == '/login' && userId != null) return '/home';
        return null;
      },
      routes: [
        GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
        GoRoute(
          path: '/interest_selection',
          builder: (context, state) {
            final userId = state.uri.queryParameters['userId'] ?? widget.authProvider.userId;
            return userId == null ? const LoginScreen() : InterestSelectionScreen(userId: userId);
          },
        ),
        ShellRoute(
          builder: (context, state, child) {
            final currentPath = state.uri.path;
            _selectedIndex = _navRoutes.indexWhere((route) => currentPath == route);
            if (_selectedIndex == -1) {
              if (currentPath.startsWith('/profile')) {
                _selectedIndex = 2;
              } else {
                _selectedIndex = 0;
              }
            }

            return Scaffold(
              body: child,
              bottomNavigationBar: BottomNavigationBar(
                currentIndex: _selectedIndex,
                selectedItemColor: Theme.of(context).colorScheme.primary,
                unselectedItemColor: Colors.grey,
                backgroundColor: Theme.of(context).colorScheme.surface,
                onTap: (index) => _onItemTapped(context, index),
                items: const [
                  BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Inicio'),
                  BottomNavigationBarItem(icon: Icon(Icons.event), label: 'Eventos'),
                  BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Perfil'),
                  BottomNavigationBarItem(icon: Icon(Icons.camera_alt), label: 'Cámara'),
                ],
              ),
            );
          },
          routes: [
            GoRoute(
              path: '/home',
              builder: (context, state) => HomeScreen(userId: widget.authProvider.userId ?? ''),
            ),
            GoRoute(
              path: '/events',
              builder: (context, state) => EventsScreen(userId: widget.authProvider.userId ?? ''),
            ),
            GoRoute(
              path: '/profile',
              builder: (context, state) {
                final userId = state.uri.queryParameters['userId'] ?? widget.authProvider.userId;
                return userId == null ? const LoginScreen() : ProfileScreen(userId: userId);
              },
            ),
            GoRoute(
              path: '/camera',
              builder: (context, state) {
                final userId = widget.authProvider.userId ?? '';
                return CameraScreen(userId: userId);
              },
            ),
            GoRoute(
              path: '/groups',
              builder: (context, state) => GroupsScreen(userId: widget.authProvider.userId ?? ''),
            ),
            GoRoute(
              path: '/post/:postId',
              builder: (context, state) {
                final postId = state.pathParameters['postId']!;
                return PostDetailScreen(postId: postId, userId: widget.authProvider.userId ?? '');
              },
            ),
            GoRoute(
              path: '/settings',
              builder: (context, state) {
                final userId = widget.authProvider.userId ?? '';
                return SettingsScreen(userId: userId);
              },
            ),
            GoRoute(
              path: '/create_event',
              builder: (context, state) =>
                  CreateEventScreen(userId: widget.authProvider.userId ?? ''),
            ),
            GoRoute(
              path: '/create_group',
              builder: (context, state) =>
                  CreateGroupScreen(userId: widget.authProvider.userId ?? ''),
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
    final userId = widget.authProvider.userId ?? '';
    final route = index == 2 ? '/profile?userId=$userId' : _navRoutes[index];
    _router.go(route);
    developer.log('Navegando a $route, índice: $index', name: 'PhotoSharingApp');
  }

  Future<bool> _onPopInvoked() async {
    // Mostrar un diálogo de confirmación para salir de la app
    return await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Salir de la aplicación',
          style: TextStyle(color: Theme.of(context).colorScheme.primary),
        ),
        content: Text(
          '¿Estás seguro de que quieres salir de la aplicación?',
          style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
        ),
        backgroundColor: Theme.of(context).colorScheme.surface,
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Cancelar',
              style: TextStyle(color: Theme.of(context).colorScheme.primary),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              'Salir',
              style: TextStyle(color: Theme.of(context).colorScheme.primary),
            ),
          ),
        ],
      ),
    ) ??
        false; // Por defecto, no salir si el diálogo se cierra sin selección
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();

    return PopScope(
      canPop: false, // Desactivar el comportamiento predeterminado del botón "Back"
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;

        // Obtener la ruta actual usando GoRouterState.of(context)
        final currentLocation = GoRouterState.of(context).matchedLocation;
        developer.log('Current location: $currentLocation', name: 'PhotoSharingApp');

        // Verificar si estamos en la pantalla raíz
        if (currentLocation == '/home' || _selectedIndex == 0) {
          // Mostrar diálogo de confirmación para salir
          final shouldExit = await _onPopInvoked();
          if (shouldExit) {
            // Permitir salir de la app si el usuario confirma
            Navigator.of(context).pop();
          }
        } else {
          // Navegar hacia atrás usando go_router para otras pantallas
          _router.go(_navRoutes[0]); // Navigate back to /home
        }
      },
      child: MaterialApp.router(
        title: 'Boom-Shoot',
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: lightColorScheme,
          scaffoldBackgroundColor: lightColorScheme.surface,
          appBarTheme: AppBarTheme(
            backgroundColor: lightColorScheme.primary,
            foregroundColor: lightColorScheme.onPrimary,
          ),
        ),
        darkTheme: ThemeData(
          useMaterial3: true,
          colorScheme: darkColorScheme,
          scaffoldBackgroundColor: darkColorScheme.surface,
          appBarTheme: AppBarTheme(
            backgroundColor: darkColorScheme.primary,
            foregroundColor: darkColorScheme.onPrimary,
          ),
        ),
        themeMode: themeProvider.themeMode,
        routerConfig: _router,
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}