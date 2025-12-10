import 'package:flutter/material.dart';
import '../widgets/common_widgets.dart';
import 'auth_screens.dart'; // Import pour la redirection vers LoginScreen

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(24, 60, 24, 40),
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [Colors.green[600]!, Colors.green[700]!]),
              ),
              child: Column(
                children: [
                  const CircleAvatar(
                    radius: 40,
                    backgroundColor: Colors.white,
                    child: Icon(Icons.person, size: 40, color: Colors.green),
                  ),
                  const SizedBox(height: 12),
                  const Text("Emmanuel S.",
                      style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
                  Text("Producteur de cacao - Yamoussoukro",
                      style: TextStyle(color: Colors.green[100])),
                ],
              ),
            ),

            // Stats Container (chevauchement)
            Transform.translate(
              offset: const Offset(0, -30),
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 24),
                padding: const EdgeInsets.symmetric(vertical: 20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10, offset: const Offset(0, 5))],
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    StatItem(label: "Cultures", value: "3"),
                    SizedBox(height: 30, child: VerticalDivider()),
                    StatItem(label: "Hectares", value: "5.2"),
                    SizedBox(height: 30, child: VerticalDivider()),
                    StatItem(label: "Années", value: "12"),
                  ],
                ),
              ),
            ),

            // Menu
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  _buildProfileItem(Icons.person_outline, "Informations personnelles", null),
                  _buildProfileItem(Icons.inventory_2_outlined, "Mes cultures", null),
                  _buildProfileItem(Icons.account_balance_wallet_outlined, "Portefeuille", "45,000 FCFA"),
                  _buildProfileItem(Icons.notifications_outlined, "Notifications", null),
                  _buildProfileItem(Icons.bar_chart, "Statistiques", null),

                  const SizedBox(height: 20),

                  // Bouton Déconnexion
                  SizedBox(
                    width: double.infinity,
                    child: TextButton.icon(
                      onPressed: () {
                        // Action de déconnexion
                        // Utilisation de pushAndRemoveUntil pour effacer l'historique et retourner au login
                        Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute(builder: (context) => const LoginScreen()),
                              (route) => false,
                        );
                      },
                      icon: const Icon(Icons.logout, color: Colors.red),
                      label: const Text(
                          "Se déconnecter",
                          style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 16)
                      ),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: Colors.red.withOpacity(0.05),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 30), // Marge en bas
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildProfileItem(IconData icon, String title, String? badge) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        tileColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.grey.shade100)),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: Colors.grey[100], shape: BoxShape.circle),
          child: Icon(icon, color: Colors.grey[700], size: 20),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (badge != null) Text(badge, style: const TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.bold)),
            const SizedBox(width: 8),
            const Icon(Icons.chevron_right, color: Colors.grey),
          ],
        ),
      ),
    );
  }
}