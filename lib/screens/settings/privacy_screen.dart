// lib/screens/settings/privacy_screen.dart
import 'package:flutter/material.dart';

class PrivacyScreen extends StatefulWidget {
  const PrivacyScreen({super.key});

  @override
  State<PrivacyScreen> createState() => _PrivacyScreenState();
}

class _PrivacyScreenState extends State<PrivacyScreen> {
  bool _profileVisible = true;
  bool _phoneVisible = false;
  bool _locationVisible = true;
  bool _activityVisible = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Colors.green[700],
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text('Confidentialité'),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // En-tête
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.green[300]!, Colors.green[600]!],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Row(
              children: [
                Icon(Icons.privacy_tip, color: Colors.white, size: 40),
                SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Vos données sont protégées',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Contrôlez qui peut voir vos informations',
                        style: TextStyle(color: Colors.white70, fontSize: 13),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Section Visibilité du profil
          _buildSectionTitle('Visibilité du profil'),
          _buildCard([
            _buildSwitchTile(
              'Profil public',
              'Votre profil est visible par tous',
              _profileVisible,
                  (value) => setState(() => _profileVisible = value),
              Icons.person,
            ),
            const Divider(height: 1),
            _buildSwitchTile(
              'Numéro de téléphone',
              'Afficher votre numéro aux acheteurs',
              _phoneVisible,
                  (value) => setState(() => _phoneVisible = value),
              Icons.phone,
            ),
            const Divider(height: 1),
            _buildSwitchTile(
              'Localisation',
              'Partager votre position',
              _locationVisible,
                  (value) => setState(() => _locationVisible = value),
              Icons.location_on,
            ),
          ]),

          const SizedBox(height: 20),

          // Section Activité
          _buildSectionTitle('Activité'),
          _buildCard([
            _buildSwitchTile(
              'Historique d\'activité',
              'Conserver votre historique',
              _activityVisible,
                  (value) => setState(() => _activityVisible = value),
              Icons.history,
            ),
          ]),

          const SizedBox(height: 20),

          // Section Données
          _buildSectionTitle('Gestion des données'),
          _buildCard([
            _buildActionTile(
              'Télécharger mes données',
              'Obtenir une copie de vos données',
              Icons.download,
                  () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Fonctionnalité bientôt disponible')),
                );
              },
            ),
            const Divider(height: 1),
            _buildActionTile(
              'Supprimer mes données',
              'Effacer définitivement vos données',
              Icons.delete_sweep,
                  () => _showDeleteDataDialog(),
              textColor: Colors.red,
            ),
          ]),

          const SizedBox(height: 20),

          // Section Sécurité
          _buildSectionTitle('Sécurité'),
          _buildCard([
            _buildActionTile(
              'Sessions actives',
              'Voir les appareils connectés',
              Icons.devices,
                  () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Fonctionnalité bientôt disponible')),
                );
              },
            ),
            const Divider(height: 1),
            _buildActionTile(
              'Activité de connexion',
              'Historique des connexions',
              Icons.login,
                  () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Fonctionnalité bientôt disponible')),
                );
              },
            ),
          ]),

          const SizedBox(height: 20),

          // Politique de confidentialité
          _buildSectionTitle('Documents légaux'),
          _buildCard([
            _buildActionTile(
              'Politique de confidentialité',
              'Lire notre politique',
              Icons.description,
                  () => _showPrivacyPolicy(),
            ),
            const Divider(height: 1),
            _buildActionTile(
              'Conditions d\'utilisation',
              'Lire les CGU',
              Icons.gavel,
                  () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Fonctionnalité bientôt disponible')),
                );
              },
            ),
          ]),

          const SizedBox(height: 30),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: Colors.grey[700],
        ),
      ),
    );
  }

  Widget _buildCard(List<Widget> children) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(children: children),
    );
  }

  Widget _buildSwitchTile(String title, String subtitle, bool value, Function(bool) onChanged, IconData icon) {
    return SwitchListTile(
      secondary: Icon(icon, color: Colors.green[700]),
      title: Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
      subtitle: Text(subtitle, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
      value: value,
      activeColor: Colors.green[700],
      onChanged: onChanged,
    );
  }

  Widget _buildActionTile(String title, String subtitle, IconData icon, VoidCallback onTap, {Color? textColor}) {
    return ListTile(
      leading: Icon(icon, color: textColor ?? Colors.green[700]),
      title: Text(
        title,
        style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: textColor),
      ),
      subtitle: Text(subtitle, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
      trailing: Icon(Icons.chevron_right, color: Colors.grey[400]),
      onTap: onTap,
    );
  }

  void _showDeleteDataDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer les données'),
        content: const Text('Êtes-vous sûr de vouloir supprimer toutes vos données ? Cette action est irréversible.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Fonctionnalité bientôt disponible'), backgroundColor: Colors.red),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
  }

  void _showPrivacyPolicy() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Politique de confidentialité'),
        content: const SingleChildScrollView(
          child: Text(
            'AgriSmart CI s\'engage à protéger vos données personnelles.\n\n'
                '1. Collecte de données\n'
                'Nous collectons uniquement les données nécessaires au fonctionnement de l\'application.\n\n'
                '2. Utilisation des données\n'
                'Vos données sont utilisées pour améliorer votre expérience et faciliter les transactions.\n\n'
                '3. Partage des données\n'
                'Nous ne partageons jamais vos données avec des tiers sans votre consentement.\n\n'
                '4. Sécurité\n'
                'Toutes les transactions sont sécurisées par blockchain.\n\n'
                '5. Vos droits\n'
                'Vous pouvez demander l\'accès, la modification ou la suppression de vos données à tout moment.',
            style: TextStyle(fontSize: 14, height: 1.5),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fermer'),
          ),
        ],
      ),
    );
  }
}