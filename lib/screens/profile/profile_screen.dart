// lib/screens/profile/profile_screen.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../widgets/common_widgets.dart';
import '../../services/user_service.dart';
import '../auth/auth_screens.dart';
import '../products/my_products_screen.dart';
import '../marketplace/my_purchases_screen.dart';
import '../../constants/api_constants.dart';

// Modèle de données utilisateur
class User {
  final String id;
  final String phoneNumber;
  final String name;
  final String userType;
  final String location;
  final String status;
  final bool isVerified;
  final double rating;

  User({
    required this.id,
    required this.phoneNumber,
    required this.name,
    required this.userType,
    required this.location,
    required this.status,
    required this.isVerified,
    required this.rating,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as String,
      phoneNumber: (json['phone_number'] as String?) ?? 'Non renseigné',
      name: (json['name'] as String?) ?? 'Utilisateur Inconnu',
      userType: (json['user_type'] as String?) ?? 'unknown',
      location: (json['location'] as String?) ?? 'Non spécifié',
      status: (json['status'] as String?) ?? 'inactive',
      isVerified: (json['is_verified'] as bool?) ?? false,
      rating: ((json['rating'] as num?)?.toDouble()) ?? 0.0,
    );
  }

  String get userTypeLabel {
    switch (userType) {
      case 'producer':
        return 'Producteur';
      case 'buyer':
        return 'Acheteur';
      case 'both':
        return 'Producteur & Acheteur';
      default:
        return 'Non défini';
    }
  }

  bool get isProducer {
    return userType == 'producer' || userType == 'both' || userType == 'admin';
  }

  bool get isBuyer {
    return userType == 'buyer' || userType == 'both' || userType == 'admin';
  }
}

// Service API
class ProfileService {
  final _storage = const FlutterSecureStorage();

  Future<User> fetchUserProfile() async {
    final token = await _storage.read(key: 'jwt_token');
    if (token == null) {
      throw Exception("Token non trouvé. Veuillez vous reconnecter.");
    }

    print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━");
    print("CHARGEMENT DU PROFIL");
    print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━");

    final response = await http.get(
      Uri.parse('http://10.0.2.2:8001/api/auth/me'),
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      },
    );

    print("Status Code: ${response.statusCode}");

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data == null) {
        throw Exception("Réponse API vide ou invalide.");
      }
      print("✅ Profil chargé avec succès");
      return User.fromJson(data);
    } else if (response.statusCode == 401) {
      print("❌ Session expirée");
      throw Exception("Session expirée. Reconnexion nécessaire.");
    } else {
      print("❌ Erreur ${response.statusCode}");
      throw Exception("Impossible de charger le profil (Code: ${response.statusCode})");
    }
  }

  Future<void> logout() async {
    await UserService.logout();
    print("✅ Déconnexion réussie");
  }
}

// Écran de profil
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late Future<User> _userProfileFuture;
  final ProfileService _profileService = ProfileService();

  @override
  void initState() {
    super.initState();
    _userProfileFuture = _profileService.fetchUserProfile();
  }

  void _handleLogout() async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text("Déconnexion"),
        content: const Text("Voulez-vous vraiment vous déconnecter ?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Annuler"),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text(
              "Déconnexion",
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );

    if (shouldLogout == true) {
      await _profileService.logout();
      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const LoginScreen()),
              (route) => false,
        );
      }
    }
  }

  void _retryLoadProfile() {
    setState(() {
      _userProfileFuture = _profileService.fetchUserProfile();
    });
  }

  Widget _buildProfileWithData(User user) {
    return SingleChildScrollView(
      child: Column(
        children: [
          // En-tête avec gradient
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(24, 60, 24, 40),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.green[600]!, Colors.green[700]!],
              ),
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(30),
                bottomRight: Radius.circular(30),
              ),
            ),
            child: Column(
              children: [
                CircleAvatar(
                  radius: 50,
                  backgroundColor: Colors.white,
                  child: Text(
                    user.name.isNotEmpty ? user.name[0].toUpperCase() : '?',
                    style: const TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  user.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "${user.userTypeLabel} • ${user.location}",
                  style: TextStyle(color: Colors.green[100], fontSize: 14),
                ),
                if (user.isVerified) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.verified, color: Colors.white, size: 18),
                        const SizedBox(width: 6),
                        Text(
                          "Compte vérifié",
                          style: TextStyle(
                            color: Colors.green[100],
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),

          // Stats Container
          Transform.translate(
            offset: const Offset(0, -30),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 24),
              padding: const EdgeInsets.symmetric(vertical: 20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  )
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  StatItem(
                    label: "Note",
                    value: user.rating.toStringAsFixed(1),
                  ),
                  const SizedBox(height: 30, child: VerticalDivider()),
                  StatItem(
                    label: "Statut",
                    value: user.status == 'active' ? 'Actif' : 'Inactif',
                  ),
                  const SizedBox(height: 30, child: VerticalDivider()),
                  StatItem(
                    label: "Type",
                    value: user.userType == 'both' ? '2' : '1',
                  ),
                ],
              ),
            ),
          ),

          // Menu
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              children: [
                // Section Compte
                _buildSectionTitle("Mon compte"),
                _buildProfileItem(
                  context,
                  Icons.person_outline,
                  "Informations personnelles",
                  null,
                  onTap: () {
                    // TODO: Implémenter l'édition du profil
                  },
                ),
                _buildProfileItem(
                  context,
                  Icons.phone,
                  "Téléphone",
                  user.phoneNumber,
                ),
                _buildProfileItem(
                  context,
                  Icons.location_on_outlined,
                  "Localisation",
                  user.location,
                ),

                const SizedBox(height: 24),

                // Section Producteur (seulement pour les producteurs)
                if (user.isProducer) ...[
                  _buildSectionTitle("Espace producteur"),
                  _buildProfileItem(
                    context,
                    Icons.inventory_2_outlined,
                    "Mes produits",
                    null,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const MyProductsScreen(),
                        ),
                      );
                    },
                    badge: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.green,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        'Gérer',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  _buildProfileItem(
                    context,
                    Icons.bar_chart,
                    "Statistiques de vente",
                    null,
                  ),
                  const SizedBox(height: 24),
                ],

                // Section Acheteur (pour tous les acheteurs)
                if (user.isBuyer) ...[
                  _buildSectionTitle("Mes achats"),
                  _buildProfileItem(
                    context,
                    Icons.shopping_bag,
                    "Historique des achats",
                    null,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const MyPurchasesScreen(),
                        ),
                      );
                    },
                    badge: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.blue,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        'Voir',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],

                // Section Général
                _buildSectionTitle("Général"),
                _buildProfileItem(
                  context,
                  Icons.notifications_outlined,
                  "Notifications",
                  null,
                ),
                _buildProfileItem(
                  context,
                  Icons.help_outline,
                  "Aide & Support",
                  null,
                ),
                _buildProfileItem(
                  context,
                  Icons.info_outline,
                  "À propos",
                  "Version 1.0.0",
                ),

                const SizedBox(height: 32),

                // Bouton Déconnexion
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _handleLogout,
                    icon: const Icon(Icons.logout, size: 20),
                    label: const Text(
                      "Se déconnecter",
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                  ),
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.grey[700],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileItem(
      BuildContext context,
      IconData icon,
      String title,
      String? subtitle, {
        VoidCallback? onTap,
        Widget? badge,
      }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.green[50],
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: Colors.green[700], size: 22),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                        ),
                      ),
                      if (subtitle != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          subtitle,
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 13,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
                if (badge != null) badge,
                const SizedBox(width: 8),
                if (onTap != null)
                  Icon(Icons.chevron_right, color: Colors.grey[400]),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: FutureBuilder<User>(
        future: _userProfileFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Colors.green),
            );
          } else if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.red[50],
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.error_outline,
                        color: Colors.red[400],
                        size: 60,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      "Erreur de chargement",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[800],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      snapshot.error.toString().replaceAll('Exception: ', ''),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 32),
                    ElevatedButton.icon(
                      onPressed: _retryLoadProfile,
                      icon: const Icon(Icons.refresh),
                      label: const Text("Réessayer"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green[700],
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 32,
                          vertical: 16,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextButton(
                      onPressed: _handleLogout,
                      child: const Text(
                        "Se déconnecter",
                        style: TextStyle(color: Colors.red),
                      ),
                    ),
                  ],
                ),
              ),
            );
          } else if (snapshot.hasData) {
            return _buildProfileWithData(snapshot.data!);
          } else {
            return const Center(
              child: Text("Aucune donnée de profil."),
            );
          }
        },
      ),
    );
  }
}