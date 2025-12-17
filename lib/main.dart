// lib/main.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'screens/auth/auth_screens.dart';
import 'screens/profile/profile_screen.dart';
import 'screens/home/home_screen.dart';
import 'screens/diagnostic/diagnostic_screen.dart';
import 'screens/market/market_screen.dart'; // Pour producteurs (prix du marché)
import 'screens/marketplace/marketplace_screen.dart'; // Pour acheteurs (achats)
import 'screens/chat/chat_screen.dart';
import 'services/user_service.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const AgriSmartApp());
}

// =============================================================================
// APPLICATION PRINCIPALE
// =============================================================================
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
      home: const AuthCheck(),
    );
  }
}

// =============================================================================
// VÉRIFICATION DE L'AUTHENTIFICATION AU DÉMARRAGE
// =============================================================================
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
            body: Center(
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

// =============================================================================
// STRUCTURE PRINCIPALE DE L'APPLICATION (NAVIGATION BAR)
// =============================================================================
class MainScaffold extends StatefulWidget {
  const MainScaffold({super.key});

  @override
  State<MainScaffold> createState() => _MainScaffoldState();
}

class _MainScaffoldState extends State<MainScaffold> {
  int _currentIndex = 0;
  bool _isProducer = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserType();
  }

  Future<void> _loadUserType() async {
    final isProducer = await UserService.isProducer();
    setState(() {
      _isProducer = isProducer;
      _isLoading = false;
    });
  }

  /// Liste des écrans selon le type d'utilisateur
  List<Widget> get _screens {
    if (_isProducer) {
      // Producteur / Both / Admin → 5 pages avec Diagnostic + Marchés (prix)
      return const [
        HomeScreen(),
        DiagnosticScreen(),
        MarketScreen(), // ← Écran prix du marché pour producteurs
        ChatScreen(),
        ProfileScreen(),
      ];
    } else {
      // Acheteur uniquement → 4 pages sans Diagnostic + Achats (marketplace)
      return const [
        HomeScreen(),
        MarketplaceScreen(), // ← Écran achats pour acheteurs
        ChatScreen(),
        ProfileScreen(),
      ];
    }
  }

  /// Items de la barre de navigation selon le type d'utilisateur
  List<BottomNavigationBarItem> get _navItems {
    if (_isProducer) {
      // Producteur / Both / Admin → 5 items avec "Marchés"
      return const [
        BottomNavigationBarItem(
          icon: Icon(Icons.home),
          label: 'Accueil',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.camera_alt),
          label: 'Diagnostic',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.trending_up), // Icône prix du marché
          label: 'Marchés', // Label pour producteurs
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.message),
          label: 'Chat',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.person),
          label: 'Profil',
        ),
      ];
    } else {
      // Acheteur uniquement → 4 items avec "Achats"
      return const [
        BottomNavigationBarItem(
          icon: Icon(Icons.home),
          label: 'Accueil',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.shopping_cart), // Icône achats
          label: 'Achats', // Label pour acheteurs
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.message),
          label: 'Chat',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.person),
          label: 'Profil',
        ),
      ];
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: Colors.green),
        ),
      );
    }

    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: Container(
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
    );
  }
}