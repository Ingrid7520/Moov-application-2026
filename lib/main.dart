// lib/main.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'screens/auth/auth_screens.dart';
import 'screens/profile/profile_screen.dart';
import 'screens/home/home_screen.dart';
import 'screens/diagnostic/diagnostic_screen.dart';
import 'screens/market/market_screen.dart';
import 'screens/chat/chat_screen.dart';

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
      // Vérification de l'authentification au démarrage
      home: const AuthCheck(),
    );
  }
}

// =============================================================================
// VÉRIFICATION DE L'AUTHENTIFICATION AU DÉMARRAGE
// =============================================================================
/// Ce widget vérifie si un token JWT est stocké dans le secure storage
/// - Si OUI → Redirection vers MainScaffold (application principale)
/// - Si NON → Redirection vers LoginScreen (écran de connexion)
class AuthCheck extends StatelessWidget {
  const AuthCheck({super.key});

  static const _storage = FlutterSecureStorage();

  /// Vérifie l'existence d'un token JWT dans le stockage sécurisé
  Future<bool> _hasToken() async {
    try {
      final token = await _storage.read(key: 'jwt_token');
      return token != null && token.isNotEmpty;
    } catch (e) {
      print("Erreur lors de la lecture du token: $e");
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: _hasToken(),
      builder: (context, snapshot) {
        // ===== ÉTAT 1: En attente de la vérification =====
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            backgroundColor: Colors.white,
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Logo animé avec gradient
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
                  // Indicateur de chargement
                  const CircularProgressIndicator(
                    color: Colors.green,
                    strokeWidth: 3,
                  ),
                ],
              ),
            ),
          );
        }

        // ===== ÉTAT 2: Token trouvé → Accès direct à l'application =====
        if (snapshot.hasData && snapshot.data == true) {
          return const MainScaffold();
        }

        // ===== ÉTAT 3: Pas de token → Écran de connexion =====
        return const LoginScreen();
      },
    );
  }
}

// =============================================================================
// STRUCTURE PRINCIPALE DE L'APPLICATION (NAVIGATION BAR)
// =============================================================================
/// Accessible après la connexion via : Navigator.pushAndRemoveUntil(...)
class MainScaffold extends StatefulWidget {
  const MainScaffold({super.key});

  @override
  State<MainScaffold> createState() => _MainScaffoldState();
}

class _MainScaffoldState extends State<MainScaffold> {
  int _currentIndex = 0;

  // Liste des écrans principaux
  final List<Widget> _screens = [
    const HomeScreen(),
    const DiagnosticScreen(),
    const MarketScreen(),
    const ChatScreen(),
    const ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
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
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home),
              label: 'Accueil',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.camera_alt),
              label: 'Diagnostic',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.trending_up),
              label: 'Marchés',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.message),
              label: 'Chat',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person),
              label: 'Profil',
            ),
          ],
        ),
      ),
    );
  }
}