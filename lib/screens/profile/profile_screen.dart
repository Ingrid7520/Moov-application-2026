// lib/screens/profile/profile_screen.dart
// ✅ VERSION FINALE - Avec redirections Settings + Privacy

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../services/user_service.dart';
import '../auth/auth_screens.dart';
import '../products/my_products_screen.dart';
import '../marketplace/my_purchases_screen.dart';
import '../marketplace/my_sales_screen.dart';
import '../help/help_screen.dart';
import '../support/support_screen.dart';
import '../settings/settings_screen.dart';
import '../settings/privacy_screen.dart';

// =============================================================================
// Modèle de données utilisateur
// =============================================================================
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
      status: 'active',  // ✅ TOUJOURS ACTIF
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

  bool get isBoth {
    return userType == 'both';
  }
}

// =============================================================================
// Service API
// =============================================================================
class ProfileService {
  Future<User> fetchUserProfile() async {
    final token = await UserService.getToken();

    if (token == null) {
      throw Exception("Token non trouvé. Veuillez vous reconnecter.");
    }

    print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━");
    print("🔍 CHARGEMENT PROFIL");
    print("Token trouvé: ${token.substring(0, 20)}...");
    print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━");

    final response = await http.get(
      Uri.parse('http://192.168.1.161:8001/api/auth/me'),
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      },
    );

    print("📥 Réponse API: ${response.statusCode}");

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      print("✅ Profil chargé: ${data['name']}");
      return User.fromJson(data);
    } else if (response.statusCode == 401) {
      print("❌ Token expiré");
      throw Exception("Session expirée. Veuillez vous reconnecter.");
    } else {
      print("❌ Erreur serveur: ${response.statusCode}");
      print("Body: ${response.body}");
      throw Exception("Erreur serveur: ${response.statusCode}");
    }
  }
}

// =============================================================================
// Écran principal
// =============================================================================
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final ProfileService _profileService = ProfileService();
  late Future<User> _userProfileFuture;

  @override
  void initState() {
    super.initState();
    print("🚀 ProfileScreen initState");
    _loadProfile();
  }

  void _loadProfile() {
    setState(() {
      _userProfileFuture = _profileService.fetchUserProfile();
    });
  }

  Future<void> _handleLogout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Déconnexion'),
        content: const Text('Voulez-vous vraiment vous déconnecter ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Déconnexion'),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      await UserService.logout();
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
            (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: FutureBuilder<User>(
        future: _userProfileFuture,
        builder: (context, snapshot) {
          // Chargement
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text("Chargement du profil...", style: TextStyle(fontSize: 14)),
                ],
              ),
            );
          }

          // Erreur
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
                    const SizedBox(height: 16),
                    const Text(
                      "Erreur de chargement",
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      snapshot.error.toString(),
                      style: TextStyle(color: Colors.grey[600], fontSize: 13),
                      textAlign: TextAlign.center,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: _loadProfile,
                      icon: const Icon(Icons.refresh, size: 20),
                      label: const Text("Réessayer"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          // Données chargées
          if (!snapshot.hasData) {
            return const Center(child: Text("Aucune donnée disponible"));
          }

          final user = snapshot.data!;
          return _buildProfileContent(user);
        },
      ),
    );
  }

  Widget _buildProfileContent(User user) {
    return CustomScrollView(
      slivers: [
        // En-tête avec avatar
        SliverToBoxAdapter(
          child: Container(
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.green[600]!, Colors.green[800]!],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
                child: Column(
                  children: [
                    // Avatar
                    Stack(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(3),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 3),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.2),
                                blurRadius: 8,
                                spreadRadius: 1,
                              ),
                            ],
                          ),
                          child: CircleAvatar(
                            radius: 45,
                            backgroundColor: Colors.white,
                            child: Icon(
                              Icons.person,
                              size: 50,
                              color: Colors.green[700],
                            ),
                          ),
                        ),
                        if (user.isVerified)
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: Container(
                              padding: const EdgeInsets.all(3),
                              decoration: BoxDecoration(
                                color: Colors.blue,
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white, width: 2),
                              ),
                              child: const Icon(
                                Icons.verified,
                                size: 18,
                                color: Colors.white,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // Nom
                    Text(
                      user.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),

                    // Téléphone
                    Text(
                      user.phoneNumber,
                      style: TextStyle(
                        color: Colors.green[100],
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Badge rôle
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        user.userTypeLabel,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Rating
                    if (user.rating > 0)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.star, color: Colors.amber, size: 18),
                          const SizedBox(width: 4),
                          Text(
                            user.rating.toStringAsFixed(1),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),

        // Contenu principal
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Informations personnelles
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Informations',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 14),
                        _buildInfoRow(
                          Icons.location_on,
                          'Localisation',
                          user.location,
                        ),
                        const Divider(height: 20),
                        _buildInfoRow(
                          Icons.check_circle,
                          'Statut',
                          'Actif',  // ✅ TOUJOURS ACTIF
                          statusColor: Colors.green,
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // Section Producteur
                if (user.isProducer) ...[
                  _buildSectionTitle("Espace producteur"),
                  _buildProfileItem(
                    context,
                    Icons.inventory,
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
                    badgeText: 'Vente',
                    badgeColor: Colors.green,
                  ),
                  _buildProfileItem(
                    context,
                    Icons.sell,
                    "Historique des ventes",
                    null,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const MySalesScreen(),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 20),
                ],

                // Section Acheteur
                if (user.isBuyer) ...[
                  _buildSectionTitle("Espace acheteur"),
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
                    badgeText: 'Achat',
                    badgeColor: Colors.blue,
                  ),
                  const SizedBox(height: 20),
                ],

                // Section Aide & Support
                _buildSectionTitle("Aide & Support"),
                _buildProfileItem(
                  context,
                  Icons.help_outline,
                  "Aide",
                  "FAQ et guides",
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const HelpScreen(),
                      ),
                    );
                  },
                ),
                _buildProfileItem(
                  context,
                  Icons.headset_mic,
                  "Support & Service Client",
                  "Contactez-nous",
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const SupportScreen(),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 20),

                // Section Général
                _buildSectionTitle("Général"),
                _buildProfileItem(
                  context,
                  Icons.settings,
                  "Paramètres",
                  "Gérer votre compte",
                  onTap: () {
                    // ✅ NAVIGATION vers SettingsScreen
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const SettingsScreen(),
                      ),
                    );
                  },
                ),
                _buildProfileItem(
                  context,
                  Icons.privacy_tip_outlined,
                  "Confidentialité",
                  "Politique de confidentialité",
                  onTap: () {
                    // ✅ NAVIGATION vers PrivacyScreen
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const PrivacyScreen(),
                      ),
                    );
                  },
                ),

                const SizedBox(height: 20),

                // Bouton Déconnexion
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _handleLogout,
                    icon: const Icon(Icons.logout, size: 20),
                    label: const Text(
                      'Déconnexion',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 2,
                    ),
                  ),
                ),
                const SizedBox(height: 30),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.bold,
          color: Colors.grey[700],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value, {Color? statusColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, color: statusColor ?? Colors.green[700], size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                ),
                const SizedBox(height: 3),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: statusColor,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileItem(
      BuildContext context,
      IconData icon,
      String title,
      String? subtitle, {
        VoidCallback? onTap,
        String? badgeText,
        Color? badgeColor,
      }) {
    return Card(
      elevation: 1,
      margin: const EdgeInsets.only(bottom: 7),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        leading: Container(
          padding: const EdgeInsets.all(7),
          decoration: BoxDecoration(
            color: Colors.green[50],
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: Colors.green[700], size: 22),
        ),
        title: Row(
          children: [
            Flexible(
              child: Text(
                title,
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (badgeText != null) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: badgeColor ?? Colors.green,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  badgeText,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ],
        ),
        subtitle: subtitle != null
            ? Text(
          subtitle,
          style: TextStyle(fontSize: 11, color: Colors.grey[600]),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        )
            : null,
        trailing: Icon(Icons.chevron_right, color: Colors.grey[400], size: 20),
        onTap: onTap,
      ),
    );
  }
}