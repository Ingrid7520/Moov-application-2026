// lib/screens/profile/profile_screen.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../widgets/common_widgets.dart';
import '../auth/auth_screens.dart';
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
    print("URL: ${ApiConstants.baseUrl}/auth/me");
    print("Token: ${token.substring(0, 20)}...");
    print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━");

    final response = await http.get(
      Uri.parse('${'http://10.0.2.2:8001/api'}/auth/me'),
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      },
    );

    print("Status Code: ${response.statusCode}");
    print("Response: ${response.body}");

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
    await _storage.delete(key: 'jwt_token');
    print("✅ Token supprimé - Déconnexion réussie");
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
        title: const Text("Déconnexion"),
        content: const Text("Voulez-vous vraiment vous déconnecter ?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Annuler"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              "Déconnexion",
              style: TextStyle(color: Colors.red),
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
            ),
            child: Column(
              children: [
                CircleAvatar(
                  radius: 40,
                  backgroundColor: Colors.white,
                  child: Text(
                    user.name.isNotEmpty ? user.name[0].toUpperCase() : '?',
                    style: const TextStyle(
                      fontSize: 40,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  user.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "${user.userTypeLabel} - ${user.location}",
                  style: TextStyle(color: Colors.green[100]),
                ),
                if (user.isVerified) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.verified, color: Colors.white, size: 16),
                        const SizedBox(width: 4),
                        Text(
                          "Compte vérifié",
                          style: TextStyle(
                            color: Colors.green[100],
                            fontSize: 12,
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
                    color: Colors.black12,
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
                _buildProfileItem(
                  Icons.person_outline,
                  "Informations personnelles",
                  null,
                ),
                _buildProfileItem(
                  Icons.phone,
                  "Téléphone",
                  user.phoneNumber,
                ),
                _buildProfileItem(
                  Icons.location_on_outlined,
                  "Localisation",
                  user.location,
                ),
                _buildProfileItem(
                  Icons.inventory_2_outlined,
                  "Mes produits",
                  null,
                ),
                _buildProfileItem(
                  Icons.bar_chart,
                  "Statistiques",
                  null,
                ),
                _buildProfileItem(
                  Icons.notifications_outlined,
                  "Notifications",
                  null,
                ),

                const SizedBox(height: 20),

                // Bouton Déconnexion
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _handleLogout,
                    icon: const Icon(Icons.logout),
                    label: const Text("Se déconnecter"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 30),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileItem(IconData icon, String title, String? badge) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        tileColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: Colors.grey.shade100),
        ),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.grey[100],
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: Colors.grey[700], size: 20),
        ),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (badge != null)
              Flexible(
                child: Text(
                  badge,
                  style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            const SizedBox(width: 8),
            const Icon(Icons.chevron_right, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
                    const Icon(
                      Icons.error_outline,
                      color: Colors.red,
                      size: 60,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      "Erreur de chargement",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[800],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      snapshot.error.toString(),
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: _retryLoadProfile,
                      icon: const Icon(Icons.refresh),
                      label: const Text("Réessayer"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 12),
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