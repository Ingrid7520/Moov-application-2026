// lib/main.dart
// ✅ VERSION FINALE COMPLÈTE - Notifications + Images + Toutes vos routes

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'screens/auth/auth_screens.dart';
import 'screens/profile/profile_screen.dart';
import 'screens/home/home_screen.dart';
import 'screens/diagnostic/diagnostic_screen.dart';
import 'screens/market/market_screen.dart';
import 'screens/marketplace/marketplace_screen.dart';
import 'screens/chat/chat_screen.dart';
import 'screens/help/help_screen.dart';
import 'screens/support/support_screen.dart';
import 'screens/settings/settings_screen.dart';
import 'screens/settings/privacy_screen.dart';
import 'screens/notifications/notifications_screen.dart'; // ✅ NOUVEAU
import 'services/user_service.dart';
import 'services/notification_service.dart'; // ✅ NOUVEAU

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ✅ INITIALISER LE SERVICE NOTIFICATIONS
  await NotificationService().initialize();

  runApp(const AgriSmartApp());
}

class AgriSmartApp extends StatelessWidget {
  const AgriSmartApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AgriSmart CI',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.green,
        scaffoldBackgroundColor: Colors.grey[50],
        useMaterial3: true,
        textTheme: GoogleFonts.montserratTextTheme(),
      ),
      routes: {
        '/': (context) => const AuthCheck(),
        '/help': (context) => const HelpScreen(),
        '/support': (context) => const SupportScreen(),
        '/settings': (context) => const SettingsScreen(),
        '/privacy': (context) => const PrivacyScreen(),
        '/notifications': (context) => const NotificationsScreen(), // ✅ NOUVEAU
      },
      initialRoute: '/',
    );
  }
}

class AuthCheck extends StatelessWidget {
  const AuthCheck({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: UserService.isLoggedIn(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            backgroundColor: Colors.white,
            body: SafeArea(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.green[400]!, Colors.green[700]!],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.green.withOpacity(0.3),
                            blurRadius: 20,
                            spreadRadius: 5,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.spa,
                        size: 60,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 32),
                    const Text(
                      "AgriSmart CI",
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "Votre compagnon agricole",
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 40),
                    const CircularProgressIndicator(
                      color: Colors.green,
                      strokeWidth: 3,
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        if (snapshot.hasData && snapshot.data == true) {
          return const MainScaffold();
        }

        return const LoginScreen();
      },
    );
  }
}

class MainScaffold extends StatefulWidget {
  const MainScaffold({super.key});

  @override
  State<MainScaffold> createState() => _MainScaffoldState();
}

class _MainScaffoldState extends State<MainScaffold> {
  int _currentIndex = 0;
  String _userType = 'buyer';
  String? _userId;
  String? _userName;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserType();
    // Le polling démarre automatiquement dans NotificationService
  }

  @override
  void dispose() {
    // ✅ ARRÊTER LE POLLING
    NotificationService().stopPolling();
    super.dispose();
  }

  Future<void> _reloadUserData() async {
    print('🔄 Rechargement des données utilisateur...');

    await Future.delayed(const Duration(milliseconds: 500));

    final userData = await UserService.getUserData();

    if (userData != null) {
      setState(() {
        _userId = userData['id'];
        _userName = userData['name'];
        _userType = userData['user_type'] ?? 'buyer';
        _isLoading = false;
      });

      print('✅ DONNÉES UTILISATEUR RECHARGÉES');
      print('🆔 UserId: $_userId');
      print('👤 UserName: $_userName');
      print('🏷️ UserType: $_userType');
    } else {
      print('❌ Impossible de recharger les données utilisateur');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadUserType() async {
    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    print('CHARGEMENT DU PROFIL');
    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');

    final userData = await UserService.getUserData();

    if (userData == null) {
      print('⚠️ UserData NULL - Tentative de récupération depuis API...');

      final profile = await UserService.fetchProfile();

      if (profile != null) {
        print('✅ Profil récupéré depuis API');
        await _reloadUserData();
        return;
      } else {
        print('❌ Impossible de récupérer le profil');
        setState(() {
          _isLoading = false;
        });
        return;
      }
    }

    setState(() {
      _userId = userData['id'];
      _userName = userData['name'];
      _userType = userData['user_type'] ?? 'buyer';
      _isLoading = false;
    });

    print('✅ DONNÉES UTILISATEUR CHARGÉES');
    print('🆔 UserId: $_userId');
    print('👤 UserName: $_userName');
    print('🏷️ UserType: $_userType');
    print('📍 Location: ${userData['location']}');
    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
  }

  List<Widget> get _screens {
    if (_userType == 'both') {
      return const [
        HomeScreen(),
        DiagnosticScreen(),
        MarketScreen(),
        MarketplaceScreen(),
        ChatScreen(),
        ProfileScreen(),
      ];
    } else if (_userType == 'producer' || _userType == 'admin') {
      return const [
        HomeScreen(),
        DiagnosticScreen(),
        MarketScreen(),
        ChatScreen(),
        ProfileScreen(),
      ];
    } else {
      return const [
        HomeScreen(),
        MarketplaceScreen(),
        ChatScreen(),
        ProfileScreen(),
      ];
    }
  }

  List<BottomNavigationBarItem> get _navItems {
    if (_userType == 'both') {
      return const [
        BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Accueil'),
        BottomNavigationBarItem(icon: Icon(Icons.camera_alt), label: 'Diagnostic'),
        BottomNavigationBarItem(icon: Icon(Icons.trending_up), label: 'Marchés'),
        BottomNavigationBarItem(icon: Icon(Icons.shopping_cart), label: 'Achats'),
        BottomNavigationBarItem(icon: Icon(Icons.message), label: 'Chat'),
        BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profil'),
      ];
    } else if (_userType == 'producer' || _userType == 'admin') {
      return const [
        BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Accueil'),
        BottomNavigationBarItem(icon: Icon(Icons.camera_alt), label: 'Diagnostic'),
        BottomNavigationBarItem(icon: Icon(Icons.trending_up), label: 'Marchés'),
        BottomNavigationBarItem(icon: Icon(Icons.message), label: 'Chat'),
        BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profil'),
      ];
    } else {
      return const [
        BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Accueil'),
        BottomNavigationBarItem(icon: Icon(Icons.shopping_cart), label: 'Achats'),
        BottomNavigationBarItem(icon: Icon(Icons.message), label: 'Chat'),
        BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profil'),
      ];
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: SafeArea(
          child: Center(
            child: CircularProgressIndicator(color: Colors.green),
          ),
        ),
      );
    }

    return Scaffold(
      body: SafeArea(
        child: _screens[_currentIndex],
      ),
      bottomNavigationBar: SafeArea(
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border(
              top: BorderSide(color: Colors.grey.shade200),
            ),
          ),
          child: BottomNavigationBar(
            currentIndex: _currentIndex,
            onTap: (index) => setState(() => _currentIndex = index),
            type: BottomNavigationBarType.fixed,
            backgroundColor: Colors.white,
            selectedItemColor: Colors.green[700],
            unselectedItemColor: Colors.grey[400],
            showUnselectedLabels: true,
            elevation: 0,
            items: _navItems,
          ),
        ),
      ),
    );
  }
}